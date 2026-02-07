import { Injectable, Logger } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository, In } from 'typeorm';
import { DeviceToken, UserRole } from './device-token.entity';

@Injectable()
export class PushService {
    private readonly logger = new Logger(PushService.name);
    private fcmUrl = 'https://fcm.googleapis.com/fcm/send';
    private serverKey: string;

    constructor(
        @InjectRepository(DeviceToken)
        private deviceTokenRepository: Repository<DeviceToken>,
    ) {
        this.serverKey = process.env.FCM_SERVER_KEY || '';
    }

    /**
     * Register or update device token
     */
    async registerToken(
        userId: string,
        role: UserRole,
        token: string,
        platform: string,
        deviceName?: string,
        appVersion?: string,
    ): Promise<DeviceToken> {
        // Check if token already exists
        let deviceToken = await this.deviceTokenRepository.findOne({
            where: { token },
        });

        if (deviceToken) {
            // Update existing
            deviceToken.userId = userId;
            deviceToken.role = role;
            deviceToken.platform = platform as any;
            deviceToken.deviceName = deviceName;
            deviceToken.appVersion = appVersion;
            deviceToken.isActive = true;
            deviceToken.lastUsedAt = new Date();
        } else {
            // Create new
            deviceToken = this.deviceTokenRepository.create({
                userId,
                role,
                token,
                platform: platform as any,
                deviceName,
                appVersion,
                isActive: true,
                lastUsedAt: new Date(),
            });
        }

        return this.deviceTokenRepository.save(deviceToken);
    }

    /**
     * Unregister device token
     */
    async unregisterToken(token: string): Promise<void> {
        await this.deviceTokenRepository.update(
            { token },
            { isActive: false },
        );
    }

    /**
     * Send push to specific user
     */
    async sendToUser(
        userId: string,
        title: string,
        body: string,
        data?: Record<string, any>,
    ): Promise<void> {
        const tokens = await this.deviceTokenRepository.find({
            where: { userId, isActive: true },
        });

        if (tokens.length === 0) {
            this.logger.warn(`No active tokens for user ${userId}`);
            return;
        }

        for (const device of tokens) {
            await this.sendPush(device.token, title, body, data);
        }
    }

    /**
     * Send push to topic
     */
    async sendToTopic(
        topic: string,
        title: string,
        body: string,
        data?: Record<string, any>,
    ): Promise<void> {
        await this.sendPush(`/topics/${topic}`, title, body, data);
    }

    /**
     * Send OTP notification
     */
    async sendOtp(
        phone: string,
        code: string,
        telegramId?: string,
    ): Promise<void> {
        // Find user by phone
        const tokens = await this.deviceTokenRepository
            .createQueryBuilder('token')
            .where('token.isActive = :isActive', { isActive: true })
            .getMany();

        // In production, you'd have a mapping from phone to userId
        // For now, send to sales reps who might be registering this customer
        const salesTokens = await this.deviceTokenRepository.find({
            where: { role: UserRole.SALES, isActive: true },
        });

        for (const device of salesTokens) {
            await this.sendPush(
                device.token,
                'Код подтверждения',
                `Код для клиента ${phone}: ${code}`,
                {
                    type: 'otp',
                    phone,
                    code,
                    telegramId: telegramId || '',
                },
            );
        }
    }

    /**
     * Notify driver about new order assignment
     */
    async notifyDriverNewOrder(
        driverId: string,
        orderCode: string,
        address: string,
    ): Promise<void> {
        await this.sendToUser(
            driverId,
            'Новая доставка назначена',
            `Заказ ${orderCode}: ${address}`,
            {
                type: 'newOrder',
                orderCode,
                address,
            },
        );
    }

    /**
     * Notify sales about sync complete
     */
    async notifySyncComplete(
        userId: string,
        syncedCount: number,
    ): Promise<void> {
        await this.sendToUser(
            userId,
            'Синхронизация завершена',
            `Синхронизировано ${syncedCount} записей`,
            {
                type: 'syncComplete',
                count: syncedCount,
            },
        );
    }

    /**
     * Send AI tip
     */
    async sendAiTip(
        userId: string,
        tip: string,
    ): Promise<void> {
        await this.sendToUser(
            userId,
            '💡 Подсказка',
            tip,
            {
                type: 'aiTip',
            },
        );
    }

    /**
     * Core push sending method
     */
    private async sendPush(
        to: string,
        title: string,
        body: string,
        data?: Record<string, any>,
    ): Promise<void> {
        if (!this.serverKey) {
            this.logger.error('FCM Server Key not configured');
            return;
        }

        const payload: any = {
            to,
            notification: {
                title,
                body,
                sound: 'default',
                badge: 1,
            },
            data: data || {},
            priority: 'high',
        };

        // Add Android specific
        payload.android = {
            notification: {
                channelId: data?.type || 'default',
                priority: 'high',
            },
        };

        // Add iOS specific
        payload.apns = {
            payload: {
                aps: {
                    alert: { title, body },
                    badge: 1,
                    sound: 'default',
                },
            },
        };

        try {
            const response = await fetch(this.fcmUrl, {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                    'Authorization': `key=${this.serverKey}`,
                },
                body: JSON.stringify(payload),
            });

            const result = await response.json();

            if (result.failure > 0) {
                this.logger.error('FCM send failed:', result);
                
                // If invalid token, deactivate it
                if (result.results?.[0]?.error === 'InvalidRegistration') {
                    await this.unregisterToken(to);
                }
            } else {
                this.logger.log(`Push sent successfully to ${to.substring(0, 20)}...`);
            }
        } catch (error) {
            this.logger.error('Failed to send push:', error);
        }
    }

    /**
     * Clean up old inactive tokens
     */
    async cleanupOldTokens(daysInactive: number = 30): Promise<number> {
        const cutoff = new Date();
        cutoff.setDate(cutoff.getDate() - daysInactive);

        const oldTokens = await this.deviceTokenRepository.find({
            where: {
                isActive: false,
                updatedAt: cutoff,
            },
        });

        await this.deviceTokenRepository.remove(oldTokens);
        return oldTokens.length;
    }
}
