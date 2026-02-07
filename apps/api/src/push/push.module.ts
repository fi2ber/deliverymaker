import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { PushService } from './push.service';
import { PushController } from './push.controller';
import { DeviceToken } from './device-token.entity';

@Module({
    imports: [TypeOrmModule.forFeature([DeviceToken])],
    controllers: [PushController],
    providers: [PushService],
    exports: [PushService],
})
export class PushModule {}
