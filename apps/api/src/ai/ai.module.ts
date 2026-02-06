import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { AiService } from './ai.service';
import { AiController } from './ai.controller';
import { ForecastingService } from './forecasting.service';
import { SalesModule } from '../sales/sales.module';
import { NotificationsModule } from '../notifications/notifications.module';
import { AiScheduler } from './ai.scheduler';
import { Order } from '../sales/order.entity';
import { Product } from '../catalog/product.entity';
import { Stock } from '../warehouse/stock.entity';

@Module({
    imports: [
        TypeOrmModule.forFeature([Order, Product, Stock]),
        SalesModule,
        NotificationsModule,
    ],
    controllers: [AiController],
    providers: [AiService, ForecastingService, AiScheduler],
    exports: [AiService, ForecastingService],
})
export class AiModule { }
