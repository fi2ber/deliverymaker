import { Injectable, NotFoundException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Subscription, SubscriptionStatus, PaymentProvider, PaymentStatus } from './subscription.entity';
import { ComboProduct } from './combo-product.entity';
import { CreateSubscriptionDto, UpdateSubscriptionDto } from './dto';

@Injectable()
export class SubscriptionsService {
    constructor(
        @InjectRepository(Subscription)
        private subscriptionRepository: Repository<Subscription>,
        @InjectRepository(ComboProduct)
        private comboRepository: Repository<ComboProduct>,
    ) {}

    // Self-service creation from TMA
    async createFromSelfService(dto: {
        comboProductId: string;
        customerId: string;
        deliveryAddress: {
            address: string;
            phone: string;
            comment?: string;
        };
        paymentProvider: 'telegram' | 'click' | 'payme';
        totalAmount: number;
    }): Promise<Subscription> {
        // Get combo for details
        const combo = await this.comboRepository.findOne({
            where: { id: dto.comboProductId },
        });

        if (!combo) {
            throw new NotFoundException('Combo product not found');
        }

        // Generate order code
        const orderCode = await this.generateOrderCode();

        // Create subscription
        const subscription = this.subscriptionRepository.create({
            orderCode,
            customerId: dto.customerId,
            comboProductId: dto.comboProductId,
            comboProduct: combo,
            status: SubscriptionStatus.PENDING,
            paymentStatus: PaymentStatus.PENDING,
            totalAmount: dto.totalAmount,
            pricePerDelivery: dto.totalAmount / combo.durationWeeks / combo.deliveriesPerWeek,
            totalDeliveries: combo.durationWeeks * combo.deliveriesPerWeek,
            deliveriesCompleted: 0,
            deliveryAddress: dto.deliveryAddress,
            paymentProvider: dto.paymentProvider.toUpperCase() as PaymentProvider,
        });

        return this.subscriptionRepository.save(subscription);
    }

    // Standard CRUD
    async create(dto: CreateSubscriptionDto): Promise<Subscription> {
        const orderCode = await this.generateOrderCode();
        
        const subscription = this.subscriptionRepository.create({
            ...dto,
            orderCode,
        });
        
        return this.subscriptionRepository.save(subscription);
    }

    async findAll(tenantId?: string): Promise<Subscription[]> {
        const where = tenantId ? { tenantId } : {};
        return this.subscriptionRepository.find({
            where,
            relations: ['customer', 'client', 'comboProduct'],
            order: { createdAt: 'DESC' },
        });
    }

    async findOne(id: string): Promise<Subscription> {
        const subscription = await this.subscriptionRepository.findOne({
            where: { id },
            relations: ['customer', 'client', 'comboProduct'],
        });
        
        if (!subscription) {
            throw new NotFoundException(`Subscription with ID ${id} not found`);
        }
        
        return subscription;
    }

    async findByCustomer(customerId: string): Promise<Subscription[]> {
        return this.subscriptionRepository.find({
            where: { customerId },
            relations: ['comboProduct'],
            order: { createdAt: 'DESC' },
        });
    }

    async update(id: string, dto: UpdateSubscriptionDto): Promise<Subscription> {
        const subscription = await this.findOne(id);
        Object.assign(subscription, dto);
        return this.subscriptionRepository.save(subscription);
    }

    async remove(id: string): Promise<void> {
        const subscription = await this.findOne(id);
        await this.subscriptionRepository.remove(subscription);
    }

    // Get active combos for TMA
    async getActiveCombos(): Promise<ComboProduct[]> {
        return this.comboRepository.find({
            where: { isActive: true },
            order: { createdAt: 'DESC' },
        });
    }

    // Payment confirmation
    async confirmPayment(subscriptionId: string, paymentData: {
        amount: number;
        provider: PaymentProvider;
        telegramPaymentChargeId?: string;
    }): Promise<Subscription> {
        const subscription = await this.findOne(subscriptionId);
        
        subscription.paidAmount = paymentData.amount;
        subscription.paidAt = new Date();
        subscription.paymentStatus = PaymentStatus.PAID;
        subscription.paymentProvider = paymentData.provider;
        
        if (paymentData.telegramPaymentChargeId) {
            subscription.telegramPaymentChargeId = paymentData.telegramPaymentChargeId;
        }

        // Activate subscription after payment
        if (subscription.status === SubscriptionStatus.PENDING) {
            subscription.status = SubscriptionStatus.ACTIVE;
            subscription.startDate = new Date();
            // Calculate end date based on duration
            const endDate = new Date();
            endDate.setDate(endDate.getDate() + (subscription.comboProduct?.durationWeeks || 1) * 7);
            subscription.endDate = endDate;
            subscription.nextDeliveryDate = new Date();
        }

        return this.subscriptionRepository.save(subscription);
    }

    // Generate unique order code
    private async generateOrderCode(): Promise<string> {
        const prefix = 'SUB';
        const date = new Date();
        const dateStr = date.toISOString().slice(2, 10).replace(/-/g, '');
        const random = Math.floor(Math.random() * 10000).toString().padStart(4, '0');
        return `${prefix}-${dateStr}-${random}`;
    }
}
