import { Module, Global } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { JwtModule } from '@nestjs/jwt';
import { NotificationsService } from './notifications.service';
import { PushService } from './push.service';
import { NotificationsController } from './notifications.controller';
import { NotificationsGateway } from './notifications.gateway';
import { Notification } from './notification.entity';
import { DeviceToken } from './device-token.entity';

@Global()
@Module({
    imports: [
        TypeOrmModule.forFeature([Notification, DeviceToken]),
        JwtModule,
    ],
    controllers: [NotificationsController],
    providers: [NotificationsService, PushService, NotificationsGateway],
    exports: [NotificationsService, PushService, NotificationsGateway],
})
export class NotificationsModule { }
