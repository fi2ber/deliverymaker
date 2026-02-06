import { Injectable, NotFoundException, BadRequestException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository, DataSource } from 'typeorm';
import { Subscription, SubscriptionStatus } from './subscription.entity';
import { ComboProduct, ComboStatus, SubscriptionPeriod } from './combo-product.entity';
import { CreateSubscriptionDto, CreateComboProductDto } from './dto/create-subscription.dto';
import { TENANT_CONNECTION } from '../database/database.module';
import { Inject } from '@nestjs/common';

@Injectable()
export class SubscriptionsService {
    constructor(
        @Inject(TENANT_CONNECTION) private dataSource: DataSource,
    ) {}

    private get subscriptionRepo() { return this.dataSource.getRepository(Subscription); }
    private get comboRepo() { return this.dataSource.getRepository(ComboProduct); }

    // ============ COMBO PRODUCTS ============

    async findAllCombos(): Promise<ComboProduct[]> {
        return this.comboRepo.find({
            where: { status: ComboStatus.ACTIVE },
            order: { subscriptionPrice: 'ASC' },
        });
    }

    async findCombosForTMA(): Promise<ComboProduct[]> {
        return this.comboRepo.find({
            where: { 
                status: ComboStatus.ACTIVE,
                isAvailableForTMA: true,
            },
            order: { subscriptionPrice: 'ASC' },
        });
    }

    async findComboById(id: string): Promise<ComboProduct> {
        const combo = await this.comboRepo.findOne({ where: { id } });
        if (!combo) {
            throw new NotFoundException('Combo product not found');
        }
        return combo;
    }

    async createCombo(dto: CreateComboProductDto): Promise<ComboProduct> {
        const combo = this.comboRepo.create({
            ...dto,
            status: ComboStatus.ACTIVE,
            discountPercent: dto.discountPercent || this.calculateDiscount(dto.basePrice, dto.subscriptionPrice),
        });
        return this.comboRepo.save(combo);
    }

    // ============ SUBSCRIPTIONS ============

    async createSubscription(clientId: string, dto: CreateSubscriptionDto): Promise<Subscription> {
        const combo = await this.findComboById(dto.comboProductId);
        
        if (combo.status !== ComboStatus.ACTIVE) {
            throw new BadRequestException('This combo is not available for subscription');
        }

        // Рассчитываем даты
        const startDate = new Date(dto.startDate);
        const endDate = this.calculateEndDate(startDate, combo.period);
        
        // Генерируем код заказа
        const orderCode = await this.generateOrderCode();

        const subscription = this.subscriptionRepo.create({
            orderCode,
            clientId,
            comboProductId: combo.id,
            comboProduct: combo,
            status: SubscriptionStatus.PENDING,
            startDate,
            endDate,
            nextDeliveryDate: startDate,
            deliveriesCompleted: 0,
            totalDeliveries: combo.totalDeliveries,
            pricePerDelivery: combo.subscriptionPrice / combo.totalDeliveries,
            totalAmount: combo.subscriptionPrice,
            paymentProvider: dto.paymentProvider,
            deliveryAddress: dto.deliveryAddress,
            deliverySchedule: dto.deliverySchedule,
            telegramData: dto.telegramData,
        });

        return this.subscriptionRepo.save(subscription);
    }

    async findSubscriptionsByClient(clientId: string): Promise<Subscription[]> {
        return this.subscriptionRepo.find({
            where: { clientId },
            relations: ['comboProduct'],
            order: { createdAt: 'DESC' },
        });
    }

    async findActiveSubscriptions(clientId: string): Promise<Subscription[]> {
        return this.subscriptionRepo.find({
            where: { 
                clientId,
                status: SubscriptionStatus.ACTIVE,
            },
            relations: ['comboProduct'],
            order: { nextDeliveryDate: 'ASC' },
        });
    }

    async findSubscriptionById(id: string): Promise<Subscription> {
        const subscription = await this.subscriptionRepo.findOne({
            where: { id },
            relations: ['comboProduct', 'client'],
        });
        if (!subscription) {
            throw new NotFoundException('Subscription not found');
        }
        return subscription;
    }

    async activateSubscription(id: string, paymentChargeId: string): Promise<Subscription> {
        const subscription = await this.findSubscriptionById(id);
        
        if (subscription.status !== SubscriptionStatus.PENDING) {
            throw new BadRequestException('Subscription is not in pending status');
        }

        subscription.status = SubscriptionStatus.ACTIVE;
        subscription.telegramPaymentChargeId = paymentChargeId;
        
        return this.subscriptionRepo.save(subscription);
    }

    async pauseSubscription(id: string): Promise<Subscription> {
        const subscription = await this.findSubscriptionById(id);
        
        if (subscription.status !== SubscriptionStatus.ACTIVE) {
            throw new BadRequestException('Only active subscriptions can be paused');
        }

        subscription.status = SubscriptionStatus.PAUSED;
        return this.subscriptionRepo.save(subscription);
    }

    async resumeSubscription(id: string): Promise<Subscription> {
        const subscription = await this.findSubscriptionById(id);
        
        if (subscription.status !== SubscriptionStatus.PAUSED) {
            throw new BadRequestException('Only paused subscriptions can be resumed');
        }

        subscription.status = SubscriptionStatus.ACTIVE;
        return this.subscriptionRepo.save(subscription);
    }

    async cancelSubscription(id: string): Promise<Subscription> {
        const subscription = await this.findSubscriptionById(id);
        
        if (subscription.status === SubscriptionStatus.CANCELLED || 
            subscription.status === SubscriptionStatus.EXPIRED) {
            throw new BadRequestException('Subscription is already cancelled or expired');
        }

        subscription.status = SubscriptionStatus.CANCELLED;
        return this.subscriptionRepo.save(subscription);
    }

    // Обработка доставки (вызывается при каждой доставке)
    async processDelivery(subscriptionId: string): Promise<Subscription> {
        const subscription = await this.findSubscriptionById(subscriptionId);
        
        if (subscription.status !== SubscriptionStatus.ACTIVE) {
            throw new BadRequestException('Subscription is not active');
        }

        subscription.deliveriesCompleted++;
        
        // Обновляем дату следующей доставки
        if (subscription.deliveriesCompleted < subscription.totalDeliveries) {
            const nextDate = new Date(subscription.nextDeliveryDate);
            nextDate.setDate(nextDate.getDate() + subscription.comboProduct.deliveryFrequencyDays);
            subscription.nextDeliveryDate = nextDate;
        } else {
            // Все доставки выполнены
            subscription.status = SubscriptionStatus.EXPIRED;
            subscription.nextDeliveryDate = null;
        }

        return this.subscriptionRepo.save(subscription);
    }

    // ============ HELPERS ============

    private calculateDiscount(basePrice: number, subscriptionPrice: number): number {
        return Math.round(((basePrice - subscriptionPrice) / basePrice) * 100);
    }

    private calculateEndDate(startDate: Date, period: SubscriptionPeriod): Date {
        const endDate = new Date(startDate);
        switch (period) {
            case SubscriptionPeriod.WEEKLY:
                endDate.setDate(endDate.getDate() + 7);
                break;
            case SubscriptionPeriod.MONTHLY:
                endDate.setMonth(endDate.getMonth() + 1);
                break;
            case SubscriptionPeriod.QUARTERLY:
                endDate.setMonth(endDate.getMonth() + 3);
                break;
            case SubscriptionPeriod.YEARLY:
                endDate.setFullYear(endDate.getFullYear() + 1);
                break;
        }
        return endDate;
    }

    private async generateOrderCode(): Promise<string> {
        const result = await this.dataSource.query(
            `SELECT COUNT(*) as count FROM subscriptions`
        );
        const count = parseInt(result[0].count, 10) + 1;
        return `SUB-${1000 + count}`;
    }
}
