import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { TelegramInvoiceController } from './telegram-invoice.controller';
import { TelegramInvoiceService } from './telegram-invoice.service';
import { TelegramWebhookController } from './telegram-webhook.controller';
import { TelegramWebhookService } from './telegram-webhook.service';
import { Subscription } from '../../subscriptions/subscription.entity';
import { Customer } from '../../customers/entities/customer.entity';
import { SubscriptionsService } from '../../subscriptions/subscriptions.service';
import { SubscriptionsModule } from '../../subscriptions/subscriptions.module';

@Module({
    imports: [
        TypeOrmModule.forFeature([Subscription, Customer]),
        SubscriptionsModule,
    ],
    controllers: [TelegramInvoiceController, TelegramWebhookController],
    providers: [TelegramInvoiceService, TelegramWebhookService],
    exports: [TelegramInvoiceService, TelegramWebhookService],
})
export class TelegramModule {}
