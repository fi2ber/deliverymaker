import { Module, Global } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { YandexService } from './yandex.service';
import { TelegramService } from './telegram.service';

@Global()
@Module({
    imports: [ConfigModule],
    providers: [YandexService, TelegramService],
    exports: [YandexService, TelegramService],
})
export class IntegrationsModule { }
