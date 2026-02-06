import { Injectable, Logger } from '@nestjs/common';
import { Inject } from '@nestjs/common';
import { DataSource } from 'typeorm';
import { TENANT_CONNECTION } from '../database/database.module';
import { DeviceToken, DevicePlatform } from './device-token.entity';
import { Notification } from './notification.entity';

export interface PushMessage {
    title: string;
    body: string;
    data?: Record<string, string>;
    priority?: 'high' | 'normal';
}

@Injectable()
export class PushService {
    private readonly logger = new Logger(PushService.name);

    constructor(
        @Inject(TENANT_CONNECTION) private dataSource: DataSource,
    ) { }

    private get deviceTokenRepo() { 
        return this.dataSource.getRepository(DeviceToken); 
    }

    private get notificationRepo() { 
        return this.dataSource.getRepository(Notification); 
    }

    /**
     * Register device token for push notifications
     */
    async registerDevice(
        userId: string, 
        token: string, 
        platform: DevicePlatform,
        deviceInfo?: string
    ): Promise<DeviceToken> {
        // Check if token already exists
        const existing = await this.deviceTokenRepo.findOne({
            where: { token, platform }
        });

        if (existing) {
            // Update user association if needed
            if (existing.user.id !== userId) {
                existing.user = { id: userId } as any;
                existing.isActive = true;
                existing.lastUsedAt = new Date();
                return this.deviceTokenRepo.save(existing);
            }
            existing.lastUsedAt = new Date();
            return this.deviceTokenRepo.save(existing);
        }

        // Create new token
        const deviceToken = this.deviceTokenRepo.create({
            token,
            platform,
            user: { id: userId } as any,
            deviceInfo,
            isActive: true,
            lastUsedAt: new Date(),
        });

        return this.deviceTokenRepo.save(deviceToken);
    }

    /**
     * Unregister device token
     */
    async unregisterDevice(token: string): Promise<void> {
        await this.deviceTokenRepo.update({ token }, { isActive: false });
    }

    /**
     * Send push notification to specific user
     */
    async sendToUser(userId: string, message: PushMessage): Promise<void> {
        // Save notification to database
        const notification = this.notificationRepo.create({
            title: message.title,
            message: message.body,
            type: 'INFO',
            metadata: message.data ? JSON.stringify(message.data) : null,
            user: { id: userId } as any,
        });
        await this.notificationRepo.save(notification);

        // Get active device tokens for user
        const tokens = await this.deviceTokenRepo.find({
            where: { user: { id: userId }, isActive: true },
        });

        if (tokens.length === 0) {
            this.logger.log(`No device tokens found for user ${userId}`);
            return;
        }

        // Send to all devices
        for (const device of tokens) {
            try {
                await this.sendPush(device, message);
            } catch (error) {
                this.logger.error(`Failed to send push to device ${device.id}:`, error);
                // Deactivate token if invalid
                if (this.isInvalidTokenError(error)) {
                    await this.deviceTokenRepo.update(device.id, { isActive: false });
                }
            }
        }
    }

    /**
     * Send push notification to multiple users
     */
    async sendToUsers(userIds: string[], message: PushMessage): Promise<void> {
        await Promise.all(userIds.map(id => this.sendToUser(id, message)));
    }

    /**
     * Send push notification to role
     */
    async sendToRole(role: string, message: PushMessage): Promise<void> {
        const users = await this.dataSource.getRepository('User').find({
            where: { role },
            select: ['id'],
        });
        
        await Promise.all(users.map((u: any) => this.sendToUser(u.id, message)));
    }

    /**
     * Send broadcast notification (all users in tenant)
     */
    async broadcast(message: PushMessage): Promise<void> {
        // Save broadcast notification (without specific user)
        const notification = this.notificationRepo.create({
            title: message.title,
            message: message.body,
            type: 'INFO',
            metadata: message.data ? JSON.stringify(message.data) : null,
        });
        await this.notificationRepo.save(notification);

        // Get all active device tokens
        const tokens = await this.deviceTokenRepo.find({
            where: { isActive: true },
        });

        // Send in batches to avoid rate limits
        const batchSize = 500;
        for (let i = 0; i < tokens.length; i += batchSize) {
            const batch = tokens.slice(i, i + batchSize);
            await Promise.all(batch.map(token => this.sendPush(token, message)));
        }
    }

    /**
     * Send push to specific device
     */
    private async sendPush(device: DeviceToken, message: PushMessage): Promise<void> {
        switch (device.platform) {
            case DevicePlatform.ANDROID:
            case DevicePlatform.IOS:
                await this.sendFCM(device.token, message);
                break;
            case DevicePlatform.WEB:
                await this.sendWebPush(device.token, message);
                break;
        }
    }

    /**
     * Send Firebase Cloud Message
     * NOTE: Requires firebase-admin setup
     */
    private async sendFCM(token: string, message: PushMessage): Promise<void> {
        // TODO: Implement when firebase-admin is configured
        // const messaging = admin.messaging();
        // await messaging.send({
        //     token,
        //     notification: { title: message.title, body: message.body },
        //     data: message.data,
        //     android: { priority: message.priority || 'normal' },
        //     apns: { payload: { aps: { sound: 'default' } } },
        // });
        
        this.logger.log(`[FCM] Would send to ${token}: ${message.title}`);
    }

    /**
     * Send Web Push notification
     * NOTE: Requires web-push setup
     */
    private async sendWebPush(token: string, message: PushMessage): Promise<void> {
        // TODO: Implement when web-push is configured
        // webpush.sendNotification(JSON.parse(token), JSON.stringify({
        //     title: message.title,
        //     body: message.body,
        //     data: message.data,
        // }));
        
        this.logger.log(`[WebPush] Would send to ${token}: ${message.title}`);
    }

    /**
     * Check if error indicates invalid token
     */
    private isInvalidTokenError(error: any): boolean {
        const invalidTokenErrors = [
            'messaging/invalid-registration-token',
            'messaging/registration-token-not-registered',
        ];
        return invalidTokenErrors.some(e => error.message?.includes(e));
    }

    // ============ Notification Triggers ============

    /**
     * Notify about new order
     */
    async notifyNewOrder(orderId: string, userId: string, amount: number): Promise<void> {
        await this.sendToUser(userId, {
            title: 'Новый заказ',
            body: `Заказ #${orderId.slice(0, 8)} на сумму ${amount.toLocaleString()} сум создан`,
            data: { orderId, type: 'NEW_ORDER' },
            priority: 'high',
        });
    }

    /**
     * Notify about order status change
     */
    async notifyOrderStatus(orderId: string, userId: string, status: string): Promise<void> {
        await this.sendToUser(userId, {
            title: 'Статус заказа изменен',
            body: `Заказ #${orderId.slice(0, 8)} теперь ${status}`,
            data: { orderId, status, type: 'ORDER_STATUS' },
        });
    }

    /**
     * Notify about low stock
     */
    async notifyLowStock(productName: string, userIds: string[]): Promise<void> {
        await this.sendToUsers(userIds, {
            title: '⚠️ Низкий запас',
            body: `Товар "${productName}" заканчивается на складе`,
            data: { type: 'LOW_STOCK', productName },
            priority: 'high',
        });
    }

    /**
     * Notify driver about new route
     */
    async notifyNewRoute(driverId: string, stopCount: number): Promise<void> {
        await this.sendToUser(driverId, {
            title: '🚚 Новый маршрут',
            body: `У вас ${stopCount} остановок на сегодня`,
            data: { type: 'NEW_ROUTE', stopCount: stopCount.toString() },
            priority: 'high',
        });
    }

    /**
     * Notify about payment received
     */
    async notifyPaymentReceived(userId: string, amount: number): Promise<void> {
        await this.sendToUser(userId, {
            title: '💰 Оплата получена',
            body: `Получено ${amount.toLocaleString()} сум`,
            data: { type: 'PAYMENT', amount: amount.toString() },
        });
    }
}
