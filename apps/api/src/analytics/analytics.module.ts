import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { AnalyticsController } from './analytics.controller';
import { AnalyticsService } from './analytics.service';
import { Order } from '../sales/order.entity';
import { Product } from '../catalog/product.entity';
import { User } from '../users/user.entity';
import { Warehouse } from '../warehouse/warehouse.entity';

@Module({
    imports: [TypeOrmModule.forFeature([Order, Product, User, Warehouse])],
    controllers: [AnalyticsController],
    providers: [AnalyticsService],
    exports: [AnalyticsService],
})
export class AnalyticsModule {}
