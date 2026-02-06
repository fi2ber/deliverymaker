import { Injectable, Logger, NotFoundException, BadRequestException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository, DataSource } from 'typeorm';
import { TenantBot, BotStatus } from './tenant-bot.entity';
import { TENANT_CONNECTION } from '../database/database.module';
import { Inject } from '@nestjs/common';
import axios from 'axios';

export interface TelegramMessage {
    chatId: string | number;
    text: string;
    parseMode?: 'HTML' | 'Markdown' | 'MarkdownV2';
    replyMarkup?: any;
    disableNotification?: boolean;
}

export interface TelegramInvoice {
    chatId: string | number;
    title: string;
    description: string;
    payload: string;
    providerToken: string;
    currency: string;
    prices: { label: string; amount: number }[];
    startParameter?: string;
}

@Injectable()
export class TenantTelegramService {
    private readonly logger = new Logger(TenantTelegramService.name);
    private readonly apiBase = 'https://api.telegram.org/bot';

    constructor(
        @Inject(TENANT_CONNECTION) private dataSource: DataSource,
    ) {}

    private get botRepo() { return this.dataSource.getRepository(TenantBot); }

    // ============ BOT MANAGEMENT ============

    async registerBot(tenantId: string, botToken: string, botName?: string): Promise<TenantBot> {
        // Проверяем валидность токена
        const botInfo = await this.validateToken(botToken);
        
        if (!botInfo.ok) {
            throw new BadRequestException('Invalid bot token');
        }

        const existing = await this.botRepo.findOne({ where: { tenantId } });
        
        if (existing) {
            // Обновляем существующего бота
            existing.botToken = botToken;
            existing.botUsername = botInfo.result.username;
            existing.botName = botName || botInfo.result.first_name;
            existing.status = BotStatus.ACTIVE;
            existing.errorCount = 0;
            existing.lastErrorAt = null;
            existing.lastErrorMessage = null;
            return this.botRepo.save(existing);
        }

        // Создаем нового бота
        const bot = this.botRepo.create({
            tenantId,
            botToken,
            botUsername: botInfo.result.username,
            botName: botName || botInfo.result.first_name,
            status: BotStatus.ACTIVE,
            settings: {},
        });

        return this.botRepo.save(bot);
    }

    async getBot(tenantId: string): Promise<TenantBot | null> {
        return this.botRepo.findOne({ where: { tenantId, status: BotStatus.ACTIVE } });
    }

    async getBotSettings(tenantId: string): Promise<TenantBot> {
        const bot = await this.botRepo.findOne({ where: { tenantId } });
        if (!bot) {
            throw new NotFoundException('Bot not registered for this tenant');
        }
        return bot;
    }

    async updateBotSettings(tenantId: string, settings: Partial<TenantBot['settings']>): Promise<TenantBot> {
        const bot = await this.getBotSettings(tenantId);
        bot.settings = { ...bot.settings, ...settings };
        return this.botRepo.save(bot);
    }

    async deactivateBot(tenantId: string): Promise<void> {
        const bot = await this.getBotSettings(tenantId);
        bot.status = BotStatus.INACTIVE;
        await this.botRepo.save(bot);
    }

    // ============ MESSAGE SENDING ============

    async sendMessage(tenantId: string, message: TelegramMessage): Promise<any> {
        const bot = await this.getActiveBot(tenantId);
        
        try {
            const url = `${this.apiBase}${bot.botToken}/sendMessage`;
            const response = await axios.post(url, {
                chat_id: message.chatId,
                text: message.text,
                parse_mode: message.parseMode,
                reply_markup: message.replyMarkup,
                disable_notification: message.disableNotification,
            });

            await this.incrementMessageCount(tenantId);
            return response.data;
        } catch (error) {
            await this.logError(tenantId, error);
            throw error;
        }
    }

    async sendInvoice(tenantId: string, invoice: TelegramInvoice): Promise<any> {
        const bot = await this.getActiveBot(tenantId);
        
        try {
            const url = `${this.apiBase}${bot.botToken}/sendInvoice`;
            const response = await axios.post(url, {
                chat_id: invoice.chatId,
                title: invoice.title,
                description: invoice.description,
                payload: invoice.payload,
                provider_token: invoice.providerToken,
                currency: invoice.currency,
                prices: invoice.prices,
                start_parameter: invoice.startParameter,
            });

            await this.incrementMessageCount(tenantId);
            return response.data;
        } catch (error) {
            await this.logError(tenantId, error);
            throw error;
        }
    }

    async sendPhoto(tenantId: string, chatId: string | number, photoUrl: string, caption?: string): Promise<any> {
        const bot = await this.getActiveBot(tenantId);
        
        try {
            const url = `${this.apiBase}${bot.botToken}/sendPhoto`;
            const response = await axios.post(url, {
                chat_id: chatId,
                photo: photoUrl,
                caption,
            });

            await this.incrementMessageCount(tenantId);
            return response.data;
        } catch (error) {
            await this.logError(tenantId, error);
            throw error;
        }
    }

    // ============ WEBHOOK MANAGEMENT ============

    async setWebhook(tenantId: string, webhookUrl: string): Promise<any> {
        const bot = await this.getActiveBot(tenantId);
        
        const url = `${this.apiBase}${bot.botToken}/setWebhook`;
        const response = await axios.post(url, {
            url: webhookUrl,
            allowed_updates: ['message', 'callback_query', 'pre_checkout_query', 'successful_payment'],
        });

        if (response.data.ok) {
            bot.webhookUrl = webhookUrl;
            await this.botRepo.save(bot);
        }

        return response.data;
    }

    async deleteWebhook(tenantId: string): Promise<any> {
        const bot = await this.getActiveBot(tenantId);
        
        const url = `${this.apiBase}${bot.botToken}/deleteWebhook`;
        const response = await axios.post(url);

        if (response.data.ok) {
            bot.webhookUrl = null;
            await this.botRepo.save(bot);
        }

        return response.data;
    }

    async getWebhookInfo(tenantId: string): Promise<any> {
        const bot = await this.getActiveBot(tenantId);
        
        const url = `${this.apiBase}${bot.botToken}/getWebhookInfo`;
        const response = await axios.get(url);
        return response.data;
    }

    // ============ BOT INFO ============

    async getMe(tenantId: string): Promise<any> {
        const bot = await this.getActiveBot(tenantId);
        
        const url = `${this.apiBase}${bot.botToken}/getMe`;
        const response = await axios.get(url);
        return response.data;
    }

    // ============ PRIVATE HELPERS ============

    private async validateToken(token: string): Promise<any> {
        try {
            const url = `${this.apiBase}${token}/getMe`;
            const response = await axios.get(url);
            return response.data;
        } catch (error) {
            return { ok: false };
        }
    }

    private async getActiveBot(tenantId: string): Promise<TenantBot> {
        const bot = await this.botRepo.findOne({ 
            where: { tenantId, status: BotStatus.ACTIVE } 
        });
        
        if (!bot) {
            throw new NotFoundException(`No active bot found for tenant ${tenantId}`);
        }
        
        return bot;
    }

    private async incrementMessageCount(tenantId: string): Promise<void> {
        await this.botRepo.increment({ tenantId }, 'messageCount', 1);
    }

    private async logError(tenantId: string, error: any): Promise<void> {
        const bot = await this.botRepo.findOne({ where: { tenantId } });
        if (bot) {
            bot.errorCount++;
            bot.lastErrorAt = new Date();
            bot.lastErrorMessage = error.message || 'Unknown error';
            await this.botRepo.save(bot);
        }
        
        this.logger.error(`Telegram API error for tenant ${tenantId}:`, error);
    }
}
