import { Module, Global } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { TypeOrmModule } from '@nestjs/typeorm';
import { YandexService } from './yandex.service';
import { TelegramService } from './telegram.service';
import { TenantTelegramService } from './tenant-telegram.service';
import { TenantBotController } from './tenant-bot.controller';
import { TelegramWebhookController } from './telegram-webhook.controller';
import { TenantBot } from './tenant-bot.entity';
import { SubscriptionsService } from '../subscriptions/subscriptions.service';
import { OrdersService } from '../sales/orders.service';

@Global()
@Module({
    imports: [ConfigModule, TypeOrmModule.forFeature([TenantBot])],
    controllers: [TenantBotController, TelegramWebhookController],
    providers: [YandexService, TelegramService, TenantTelegramService],
    exports: [YandexService, TelegramService, TenantTelegramService],
})
export class IntegrationsModule { }
