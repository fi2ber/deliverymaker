import { Module, Global } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { TypeOrmModule } from '@nestjs/typeorm';
import { YandexService } from './yandex.service';
import { TelegramService } from './telegram.service';
import { TenantTelegramService } from './tenant-telegram.service';
import { TenantBotController } from './tenant-bot.controller';
import { TenantBot } from './tenant-bot.entity';

@Global()
@Module({
    imports: [ConfigModule, TypeOrmModule.forFeature([TenantBot])],
    controllers: [TenantBotController],
    providers: [YandexService, TelegramService, TenantTelegramService],
    exports: [YandexService, TelegramService, TenantTelegramService],
})
export class IntegrationsModule { }
