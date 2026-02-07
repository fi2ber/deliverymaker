import { Injectable, HttpException, HttpStatus } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Subscription, PaymentProvider } from '../../subscriptions/subscription.entity';
import { Customer } from '../../customers/entities/customer.entity';

@Injectable()
export class TelegramInvoiceService {
    constructor(
        @InjectRepository(Subscription)
        private subscriptionRepository: Repository<Subscription>,
        @InjectRepository(Customer)
        private customerRepository: Repository<Customer>,
    ) {}

    async createInvoice(data: {
        subscriptionId: string;
        title: string;
        description: string;
        amount: number;
        payload: string;
        tenantId?: string;
    }): Promise<{ invoiceUrl: string; invoiceMessageId?: number }> {
        // Get subscription with customer
        const subscription = await this.subscriptionRepository.findOne({
            where: { id: data.subscriptionId },
            relations: ['customer'],
        });

        if (!subscription) {
            throw new HttpException('Subscription not found', HttpStatus.NOT_FOUND);
        }

        if (!subscription.customer?.telegramId) {
            throw new HttpException('Customer has no Telegram ID', HttpStatus.BAD_REQUEST);
        }

        // Get bot token for tenant
        const botToken = await this.getBotToken(data.tenantId);
        
        // Create invoice via Telegram Bot API
        const response = await fetch(`https://api.telegram.org/bot${botToken}/createInvoiceLink`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({
                title: data.title,
                description: data.description,
                payload: data.payload,
                provider_token: process.env.TELEGRAM_PAYMENT_PROVIDER_TOKEN,
                currency: 'UZS',
                prices: [{
                    label: data.title,
                    amount: data.amount,
                }],
                need_name: true,
                need_phone_number: true,
                need_shipping_address: true,
            }),
        });

        const result = await response.json();

        if (!result.ok) {
            throw new HttpException(
                `Telegram API error: ${result.description}`,
                HttpStatus.BAD_REQUEST,
            );
        }

        // Update subscription with invoice info
        subscription.telegramData = {
            ...subscription.telegramData,
            chatId: subscription.customer.telegramId,
        };
        await this.subscriptionRepository.save(subscription);

        return {
            invoiceUrl: result.result,
        };
    }

    async sendInvoiceToChat(data: {
        chatId: string;
        title: string;
        description: string;
        payload: string;
        amount: number;
        providerToken: string;
    }): Promise<{ messageId: number }> {
        const botToken = await this.getBotToken();

        const response = await fetch(`https://api.telegram.org/bot${botToken}/sendInvoice`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({
                chat_id: data.chatId,
                title: data.title,
                description: data.description,
                payload: data.payload,
                provider_token: data.providerToken,
                currency: 'UZS',
                prices: [{
                    label: data.title,
                    amount: data.amount,
                }],
                start_parameter: 'pay_subscription',
            }),
        });

        const result = await response.json();

        if (!result.ok) {
            throw new HttpException(
                `Telegram API error: ${result.description}`,
                HttpStatus.BAD_REQUEST,
            );
        }

        return {
            messageId: result.result.message_id,
        };
    }

    private async getBotToken(tenantId?: string): Promise<string> {
        // In multi-tenant setup, get token from tenant config
        // For now, use environment variable
        const token = process.env.TELEGRAM_BOT_TOKEN;
        
        if (!token) {
            throw new HttpException('Telegram bot token not configured', HttpStatus.INTERNAL_SERVER_ERROR);
        }

        return token;
    }
}
