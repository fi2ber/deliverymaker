import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { ConfigModule } from '@nestjs/config';
import { SubscriptionsService } from './subscriptions.service';
import { SubscriptionsController } from './subscriptions.controller';
import { Subscription } from './subscription.entity';
import { ComboProduct } from './combo-product.entity';

@Module({
    imports: [TypeOrmModule.forFeature([Subscription, ComboProduct]), ConfigModule],
    providers: [SubscriptionsService],
    controllers: [SubscriptionsController],
    exports: [SubscriptionsService],
})
export class SubscriptionsModule {}
