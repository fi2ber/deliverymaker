import { Injectable, Logger } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';

export interface NotificationMessage {
    chatId: string;
    message: string;
    parseMode?: 'HTML' | 'Markdown';
    buttons?: Array<{
        text: string;
        callbackData?: string;
        url?: string;
    }>;
}

@Injectable()
export class NotificationsService {
    private readonly logger = new Logger(NotificationsService.name);

    constructor() {}

    /**
     * Create a notification record (stub for compatibility)
     */
    async create(data: any): Promise<any> {
        this.logger.log(`Creating notification: ${JSON.stringify(data)}`);
        return { id: 'stub', ...data };
    }

    /**
     * Get notifications for user (stub for compatibility)
     */
    async getForUser(userId: string): Promise<any[]> {
        return [];
    }

    /**
     * Mark notification as read (stub for compatibility)
     */
    async markAsRead(id: string): Promise<void> {
        this.logger.log(`Marking notification ${id} as read`);
    }

    /**
     * Send message to Telegram user
     */
    async sendToTelegram(data: NotificationMessage): Promise<void> {
        try {
            const botToken = process.env.TELEGRAM_BOT_TOKEN;
            if (!botToken) {
                this.logger.error('Telegram bot token not configured');
                return;
            }

            const keyboard = data.buttons ? {
                inline_keyboard: [data.buttons.map(b => ({
                    text: b.text,
                    callback_data: b.callbackData,
                    url: b.url,
                }))],
            } : undefined;

            const response = await fetch(`https://api.telegram.org/bot${botToken}/sendMessage`, {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({
                    chat_id: data.chatId,
                    text: data.message,
                    parse_mode: data.parseMode || 'HTML',
                    reply_markup: keyboard,
                }),
            });

            const result = await response.json();
            if (!result.ok) {
                this.logger.error(`Telegram API error: ${result.description}`);
            }
        } catch (error) {
            this.logger.error('Failed to send Telegram notification:', error);
        }
    }

    /**
     * Notify warehouse about new order
     */
    async notifyWarehouse(data: {
        tenantId: string;
        orderId: string;
        orderCode: string;
        priority: 'low' | 'normal' | 'high';
        message: string;
    }): Promise<void> {
        // In real implementation:
        // 1. Get warehouse staff Telegram IDs from tenant config
        // 2. Send to warehouse dashboard via WebSocket
        // 3. Send push notifications to warehouse app
        
        this.logger.log(`[Warehouse Notification] ${data.orderCode}: ${data.message}`);
        
        // Example: Send to warehouse group chat
        const warehouseChatId = process.env.WAREHOUSE_CHAT_ID;
        if (warehouseChatId) {
            await this.sendToTelegram({
                chatId: warehouseChatId,
                message: `📦 <b>Новый заказ</b>\n\n` +
                    `Код: <b>${data.orderCode}</b>\n` +
                    `Приоритет: ${data.priority}\n` +
                    `${data.message}`,
            });
        }
    }

    /**
     * Notify driver about new assignment
     */
    async notifyDriver(data: {
        driverId: string;
        driverTelegramId?: string;
        orderCode: string;
        address: string;
        phone: string;
        deliveryDate: Date;
    }): Promise<void> {
        if (!data.driverTelegramId) {
            this.logger.warn(`No Telegram ID for driver ${data.driverId}`);
            return;
        }

        const dateStr = data.deliveryDate.toLocaleDateString('ru-RU', {
            weekday: 'long',
            day: 'numeric',
            month: 'long',
        });

        await this.sendToTelegram({
            chatId: data.driverTelegramId,
            message: `🚚 <b>Новое назначение</b>\n\n` +
                `Заказ: <b>${data.orderCode}</b>\n` +
                `Дата: ${dateStr}\n` +
                `Адрес: ${data.address}\n` +
                `Телефон: ${data.phone}`,
            buttons: [
                { text: '📍 Открыть маршрут', callbackData: `route:${data.orderCode}` },
                { text: '☎️ Позвонить', callbackData: `call:${data.phone}` },
            ],
        });
    }

    /**
     * Send delivery reminder to customer
     */
    async sendDeliveryReminder(data: {
        customerTelegramId?: string;
        orderCode: string;
        deliveryDate: Date;
        driverName?: string;
        driverPhone?: string;
    }): Promise<void> {
        if (!data.customerTelegramId) return;

        const dateStr = data.deliveryDate.toLocaleDateString('ru-RU', {
            hour: '2-digit',
            minute: '2-digit',
        });

        let message = `📦 <b>Скоро доставка!</b>\n\n` +
            `Заказ: <b>${data.orderCode}</b>\n` +
            `Примерное время: ${dateStr}\n`;

        if (data.driverName) {
            message += `Курьер: ${data.driverName}\n`;
        }
        if (data.driverPhone) {
            message += `Телефон: ${data.driverPhone}\n`;
        }

        await this.sendToTelegram({
            chatId: data.customerTelegramId,
            message,
        });
    }

    /**
     * Send delivery confirmation to customer
     */
    async sendDeliveryConfirmation(data: {
        customerTelegramId?: string;
        orderCode: string;
        deliveredAt: Date;
        nextDeliveryDate?: Date;
    }): Promise<void> {
        if (!data.customerTelegramId) return;

        let message = `✅ <b>Заказ доставлен!</b>\n\n` +
            `Заказ: <b>${data.orderCode}</b>\n` +
            `Время доставки: ${data.deliveredAt.toLocaleTimeString('ru-RU')}\n\n` +
            `Спасибо за заказ! 🎉`;

        if (data.nextDeliveryDate) {
            message += `\n\n📅 Следующая доставка: ${data.nextDeliveryDate.toLocaleDateString('ru-RU')}`;
        }

        await this.sendToTelegram({
            chatId: data.customerTelegramId,
            message,
        });
    }
}
