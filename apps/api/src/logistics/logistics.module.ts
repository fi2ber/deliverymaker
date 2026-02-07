import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { Route } from './route.entity';
import { RouteStop } from './route-stop.entity';
import { LogisticsController } from './logistics.controller';
import { LogisticsService } from './logistics.service';
import { DriverOrdersController } from './driver-orders.controller';
import { Order } from '../sales/order.entity';
import { Subscription } from '../subscriptions/subscription.entity';
import { OrdersService } from '../sales/orders.service';
import { NotificationsModule } from '../notifications/notifications.module';

import { IntegrationsModule } from '../integrations/integrations.module';

@Module({
    imports: [
        TypeOrmModule.forFeature([Route, RouteStop, Order, Subscription]),
        IntegrationsModule,
        NotificationsModule,
    ],
    controllers: [LogisticsController, DriverOrdersController],
    providers: [LogisticsService, OrdersService],
    exports: [LogisticsService],
})
export class LogisticsModule { }
