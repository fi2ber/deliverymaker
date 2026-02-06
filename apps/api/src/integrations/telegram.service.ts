import { Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import axios from 'axios';

@Injectable()
export class TelegramService {
    private readonly logger = new Logger(TelegramService.name);
    private readonly botToken: string;

    constructor(private configService: ConfigService) {
        this.botToken = this.configService.get<string>('TELEGRAM_BOT_TOKEN');
    }

    async sendMessage(chatId: string, text: string) {
        if (!chatId || !this.botToken) {
            this.logger.warn('Skipping Telegram message: Missing chatId or Bot Token');
            return;
        }

        try {
            await axios.post(`https://api.telegram.org/bot${this.botToken}/sendMessage`, {
                chat_id: chatId,
                text: text,
                parse_mode: 'Markdown',
            });
            this.logger.log(`Sent Telegram message to ${chatId}`);
        } catch (e) {
            this.logger.error(`Failed to send Telegram message: ${e.message}`);
        }
    }
}
