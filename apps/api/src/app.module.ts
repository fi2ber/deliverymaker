import { Module, MiddlewareConsumer, RequestMethod } from '@nestjs/common';
import { ConfigModule, ConfigService } from '@nestjs/config';
import { JwtModule } from '@nestjs/jwt';
import { TenancyMiddleware } from './common/middlewares/tenancy.middleware';
import { DatabaseModule } from './database/database.module';
import { AuthModule } from './auth/auth.module';
import { UsersModule } from './users/users.module';
import { CatalogModule } from './catalog/catalog.module';
import { WarehouseModule } from './warehouse/warehouse.module';
import { SalesModule } from './sales/sales.module';
import { LogisticsModule } from './logistics/logistics.module';
import { IntegrationsModule } from './integrations/integrations.module';
import { FinanceModule } from './finance/finance.module';
import { NotificationsModule } from './notifications/notifications.module';
import { AiModule } from './ai/ai.module';
import { AnalyticsModule } from './analytics/analytics.module';
import { ScheduleModule } from '@nestjs/schedule';

@Module({
    imports: [
        ConfigModule.forRoot({ isGlobal: true }),
        // Global JWT module for middleware access
        JwtModule.registerAsync({
            global: true,
            imports: [ConfigModule],
            useFactory: async (configService: ConfigService) => ({
                secret: configService.get<string>('JWT_SECRET') || 'dev_secret',
                signOptions: { expiresIn: '60m' },
            }),
            inject: [ConfigService],
        }),
        DatabaseModule,
        AuthModule,
        UsersModule,
        CatalogModule,
        WarehouseModule,
        SalesModule,
        LogisticsModule,
        FinanceModule,
        IntegrationsModule,
        NotificationsModule,
        AnalyticsModule,
        ScheduleModule.forRoot(),
        AiModule,
    ],
    controllers: [],
    providers: [],
})
export class AppModule {
    configure(consumer: MiddlewareConsumer) {
        consumer
            .apply(TenancyMiddleware)
            .forRoutes({ path: '*', method: RequestMethod.ALL });
    }
}
