import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { SubscriptionsController } from './subscriptions.controller';
import { SubscriptionsService } from './subscriptions.service';
import { SubscriptionSchedulerService } from './subscription-scheduler.service';
import { Subscription } from './subscription.entity';
import { ComboProduct } from './combo-product.entity';
import { Order } from '../sales/order.entity';
import { NotificationsModule } from '../notifications/notifications.module';

@Module({
    imports: [
        TypeOrmModule.forFeature([Subscription, ComboProduct, Order]),
        NotificationsModule,
    ],
    controllers: [SubscriptionsController],
    providers: [SubscriptionsService, SubscriptionSchedulerService],
    exports: [SubscriptionsService],
})
export class SubscriptionsModule {}
