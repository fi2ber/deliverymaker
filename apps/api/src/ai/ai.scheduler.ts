import { Injectable, Logger } from '@nestjs/common';
import { Cron, CronExpression } from '@nestjs/schedule';
import { AiService } from './ai.service';
import { NotificationsService } from '../notifications/notifications.service';
import { TelegramService } from '../integrations/telegram.service';

@Injectable()
export class AiScheduler {
    private readonly logger = new Logger(AiScheduler.name);

    constructor(
        private readonly aiService: AiService,
        private readonly notificationsService: NotificationsService,
        private readonly telegramService: TelegramService,
    ) { }

    @Cron(CronExpression.EVERY_DAY_AT_10AM)
    async handleSmartReminders() {
        this.logger.log('Running Smart Reminders job...');
        const clients = await this.aiService.getActiveClients();

        for (const client of clients) {
            try {
                const reminders = await this.aiService.getSmartReminders(client.id);
                if (reminders.length > 0) {
                    const items = reminders.map(r => r.productName).join(', ');
                    await this.notificationsService.create({
                        userId: client.id,
                        title: 'Your Regular Order',
                        message: `It seems you usually order these items around this time: ${items}. Would you like to add them to your cart?`,
                        type: 'INFO',
                        metadata: { type: 'smart_reminder', products: reminders }
                    });

                    // Send Push Notification (Telegram)
                    if (client.telegramChatId) {
                        await this.telegramService.sendMessage(
                            client.telegramChatId,
                            `🤖 *Smart Reminder*\n\nYou usually order these items around this time:\n${items}.\n\n[Open App to Order](https://t.me/DeliveryMakerBot/app)`
                        );
                    }
                }
            } catch (e) {
                this.logger.error(`Error processing client ${client.id}: ${e.message}`);
            }
        }
        this.logger.log('Smart Reminders job finished.');
    }
}
