import { Injectable, Logger } from '@nestjs/common';
import { Cron, CronExpression } from '@nestjs/schedule';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository, LessThanOrEqual, Between } from 'typeorm';
import { Subscription, SubscriptionStatus } from './subscription.entity';
import { Order, OrderStatus, OrderSource } from '../sales/order.entity';
import { NotificationsService } from '../notifications/notifications.service';

@Injectable()
export class SubscriptionSchedulerService {
    private readonly logger = new Logger(SubscriptionSchedulerService.name);

    constructor(
        @InjectRepository(Subscription)
        private subscriptionRepository: Repository<Subscription>,
        @InjectRepository(Order)
        private orderRepository: Repository<Order>,
        private notificationsService: NotificationsService,
    ) {}

    /**
     * Runs every day at 6:00 AM to generate upcoming deliveries
     */
    @Cron(CronExpression.EVERY_DAY_AT_6AM)
    async generateUpcomingDeliveries() {
        this.logger.log('Generating upcoming subscription deliveries...');

        const tomorrow = new Date();
        tomorrow.setDate(tomorrow.getDate() + 1);
        tomorrow.setHours(0, 0, 0, 0);

        const dayAfterTomorrow = new Date(tomorrow);
        dayAfterTomorrow.setDate(dayAfterTomorrow.getDate() + 1);

        // Find active subscriptions with delivery scheduled for tomorrow
        const subscriptions = await this.subscriptionRepository.find({
            where: {
                status: SubscriptionStatus.ACTIVE,
                nextDeliveryDate: LessThanOrEqual(dayAfterTomorrow),
            },
            relations: ['customer', 'comboProduct'],
        });

        this.logger.log(`Found ${subscriptions.length} subscriptions for delivery generation`);

        for (const subscription of subscriptions) {
            try {
                await this.createDeliveryOrder(subscription);
            } catch (error) {
                this.logger.error(
                    `Failed to create delivery for subscription ${subscription.id}:`,
                    error.message,
                );
            }
        }
    }

    /**
     * Create a delivery order from subscription
     */
    private async createDeliveryOrder(subscription: Subscription) {
        // Check if order already exists for this delivery date
        const startOfDay = new Date(subscription.nextDeliveryDate);
        startOfDay.setHours(0, 0, 0, 0);
        const endOfDay = new Date(subscription.nextDeliveryDate);
        endOfDay.setHours(23, 59, 59, 999);

        const existingOrder = await this.orderRepository.findOne({
            where: {
                subscriptionId: subscription.id,
                deliveryDate: Between(startOfDay, endOfDay),
            },
        });

        if (existingOrder) {
            this.logger.log(`Order already exists for subscription ${subscription.id} on ${subscription.nextDeliveryDate}`);
            return;
        }

        // Generate order code (SUB-XXX-D1, SUB-XXX-D2, etc.)
        const deliveryNumber = subscription.deliveriesCompleted + 1;
        const orderCode = `${subscription.orderCode}-D${deliveryNumber}`;

        // Create order
        const order = this.orderRepository.create({
            orderCode,
            subscriptionId: subscription.id,
            customerId: subscription.customerId,
            tenantId: subscription.tenantId,
            source: OrderSource.SUBSCRIPTION,
            status: OrderStatus.PENDING,
            deliveryDate: subscription.nextDeliveryDate,
            deliveryAddress: subscription.deliveryAddress,
            items: this.generateOrderItems(subscription),
            totalAmount: subscription.pricePerDelivery,
            notes: `Автоматическая доставка по подписке ${subscription.orderCode}. Доставка ${deliveryNumber} из ${subscription.totalDeliveries}`,
        });
        await this.orderRepository.save(order);

        this.logger.log(`Created order ${orderCode} for subscription ${subscription.id}`);

        // Notify customer
        await this.notifyCustomerAboutUpcomingDelivery(subscription, order);

        // Notify warehouse
        await this.notifyWarehouseAboutNewOrder(order);

        return order;
    }

    /**
     * Generate order items from subscription combo
     */
    private generateOrderItems(subscription: Subscription) {
        const combo = subscription.comboProduct;
        if (!combo?.products) {
            return [];
        }

        return combo.products.map((product) => ({
            productId: product.productId,
            quantity: product.quantity,
            // Prices will be fetched from catalog
        }));
    }

    /**
     * Update subscription after successful delivery
     */
    async completeDelivery(subscriptionId: string) {
        const subscription = await this.subscriptionRepository.findOne({
            where: { id: subscriptionId },
        });

        if (!subscription) {
            throw new Error('Subscription not found');
        }

        // Increment completed deliveries
        subscription.deliveriesCompleted++;

        // Check if all deliveries completed
        if (subscription.deliveriesCompleted >= subscription.totalDeliveries) {
            subscription.status = SubscriptionStatus.EXPIRED;
            subscription.nextDeliveryDate = null;
        } else {
            // Calculate next delivery date
            const nextDate = new Date();
            // Default: weekly delivery (7 days)
            const daysInterval = subscription.comboProduct?.deliveryFrequencyDays || 7;
            nextDate.setDate(nextDate.getDate() + daysInterval);
            subscription.nextDeliveryDate = nextDate;
        }

        await this.subscriptionRepository.save(subscription);

        this.logger.log(
            `Updated subscription ${subscriptionId}: ${subscription.deliveriesCompleted}/${subscription.totalDeliveries} deliveries completed`,
        );

        return subscription;
    }

    /**
     * Notify customer about upcoming delivery
     */
    private async notifyCustomerAboutUpcomingDelivery(
        subscription: Subscription,
        order: any,
    ) {
        if (!subscription.customer?.telegramId) {
            return;
        }

        const deliveryDate = new Date(order.deliveryDate).toLocaleDateString('ru-RU', {
            weekday: 'long',
            day: 'numeric',
            month: 'long',
        });

        await this.notificationsService.sendToTelegram({
            chatId: subscription.customer.telegramId,
            message: `📦 <b>Завтра доставка!</b>\n\n` +
                `Заказ: <b>${order.orderCode}</b>\n` +
                `Дата: <b>${deliveryDate}</b>\n` +
                `Адрес: ${order.deliveryAddress?.address || 'Не указан'}\n\n` +
                `Курьер свяжется с вами за 30 минут до прибытия.`,
        });
    }

    /**
     * Notify warehouse about new order
     */
    private async notifyWarehouseAboutNewOrder(order: any) {
        // This will be handled by warehouse module
        // Could send to warehouse dashboard, Telegram group, etc.
        await this.notificationsService.notifyWarehouse({
            tenantId: order.tenantId,
            orderId: order.id,
            orderCode: order.orderCode,
            priority: 'normal',
            message: `Новый заказ по подписке: ${order.orderCode}`,
        });
    }
}
