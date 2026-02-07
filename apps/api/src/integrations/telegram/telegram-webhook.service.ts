import { Injectable, Logger } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Subscription, PaymentStatus } from '../../subscriptions/subscription.entity';
import { SubscriptionsService } from '../../subscriptions/subscriptions.service';

@Injectable()
export class TelegramWebhookService {
    private readonly logger = new Logger(TelegramWebhookService.name);

    constructor(
        @InjectRepository(Subscription)
        private subscriptionRepository: Repository<Subscription>,
        private subscriptionsService: SubscriptionsService,
    ) {}

    async processUpdate(tenantId: string, update: any): Promise<void> {
        this.logger.log(`Processing update for tenant ${tenantId}`);

        // Handle successful payment
        if (update.message?.successful_payment) {
            await this.handleSuccessfulPayment(update.message.successful_payment);
        }

        // Handle start command with deep link
        if (update.message?.text?.startsWith('/start')) {
            await this.handleStartCommand(update.message);
        }

        // Handle WebApp data
        if (update.message?.web_app_data) {
            await this.handleWebAppData(update.message.web_app_data);
        }
    }

    async confirmPayment(data: {
        subscriptionId: string;
        telegramPaymentChargeId: string;
        totalAmount: number;
    }): Promise<Subscription> {
        return this.subscriptionsService.confirmPayment(data.subscriptionId, {
            amount: data.totalAmount,
            provider: 'TELEGRAM' as any,
            telegramPaymentChargeId: data.telegramPaymentChargeId,
        });
    }

    private async handleSuccessfulPayment(payment: any): Promise<void> {
        this.logger.log(`Processing successful payment: ${payment.telegram_payment_charge_id}`);

        try {
            // Extract subscription ID from invoice payload
            const payload = JSON.parse(payment.invoice_payload);
            const subscriptionId = payload.subscriptionId;

            if (!subscriptionId) {
                this.logger.error('No subscription ID in payment payload');
                return;
            }

            // Confirm payment
            await this.confirmPayment({
                subscriptionId,
                telegramPaymentChargeId: payment.telegram_payment_charge_id,
                totalAmount: payment.total_amount / 100, // Convert from cents
            });

            // Send confirmation message
            await this.sendPaymentConfirmation(payment.chat_id, subscriptionId);
        } catch (error) {
            this.logger.error('Error processing payment:', error);
        }
    }

    private async handleStartCommand(message: any): Promise<void> {
        const text = message.text as string;
        const parts = text.split(' ');
        
        if (parts.length > 1) {
            const startParam = parts[1];
            this.logger.log(`Start command with param: ${startParam}`);
            
            // Could store referral info, track campaign, etc.
        }
    }

    private async handleWebAppData(data: any): Promise<void> {
        this.logger.log('Received WebApp data');
        
        try {
            const parsed = JSON.parse(data.data);
            // Handle different action types from WebApp
            switch (parsed.action) {
                case 'create_subscription':
                    // Handle subscription creation from WebApp
                    break;
                case 'update_profile':
                    // Handle profile update
                    break;
                default:
                    this.logger.warn(`Unknown WebApp action: ${parsed.action}`);
            }
        } catch (error) {
            this.logger.error('Error parsing WebApp data:', error);
        }
    }

    private async sendPaymentConfirmation(chatId: string, subscriptionId: string): Promise<void> {
        const botToken = process.env.TELEGRAM_BOT_TOKEN;
        
        if (!botToken) {
            this.logger.error('Bot token not configured');
            return;
        }

        const message = `
✅ <b>Оплата успешна!</b>

Ваша подписка активирована.

Мы свяжемся с вами для уточнения деталей доставки.
        `.trim();

        try {
            await fetch(`https://api.telegram.org/bot${botToken}/sendMessage`, {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({
                    chat_id: chatId,
                    text: message,
                    parse_mode: 'HTML',
                    reply_markup: {
                        inline_keyboard: [
                            [
                                { text: '📦 Мои заказы', callback_data: `orders:${subscriptionId}` },
                            ],
                        ],
                    },
                }),
            });
        } catch (error) {
            this.logger.error('Error sending confirmation:', error);
        }
    }
}
