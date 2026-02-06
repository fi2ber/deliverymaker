import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { Order } from './order.entity';
import { OrderItem } from './order-item.entity';
import { OrdersController } from './orders.controller';
import { OrdersService } from './orders.service';

import { OrderItemAllocation } from './order-item-allocation.entity';

import { WarehouseModule } from '../warehouse/warehouse.module';

@Module({
    imports: [
        TypeOrmModule.forFeature([Order, OrderItem, OrderItemAllocation]),
        WarehouseModule // Import to use exported WarehouseService
    ],
    controllers: [OrdersController],
    providers: [OrdersService],
})
export class SalesModule { }
