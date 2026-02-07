import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { Order } from './order.entity';
import { OrderItem } from './order-item.entity';
import { OrdersController } from './orders.controller';
import { OrdersService } from './orders.service';
import { WarehouseOrdersController } from '../warehouse/warehouse-orders.controller';
import { NotificationsModule } from '../notifications/notifications.module';

import { OrderItemAllocation } from './order-item-allocation.entity';

import { WarehouseModule } from '../warehouse/warehouse.module';

@Module({
    imports: [
        TypeOrmModule.forFeature([Order, OrderItem, OrderItemAllocation]),
        WarehouseModule,
        NotificationsModule,
    ],
    controllers: [OrdersController, WarehouseOrdersController],
    providers: [OrdersService],
    exports: [OrdersService],
})
export class SalesModule { }
