import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { Route } from './route.entity';
import { RouteStop } from './route-stop.entity';
import { LogisticsController } from './logistics.controller';
import { LogisticsService } from './logistics.service';
import { Order } from '../sales/order.entity'; // Import Order logic

import { IntegrationsModule } from '../integrations/integrations.module';

@Module({
    imports: [
        TypeOrmModule.forFeature([Route, RouteStop, Order]),
        IntegrationsModule
    ],
    controllers: [LogisticsController],
    providers: [LogisticsService],
})
export class LogisticsModule { }
