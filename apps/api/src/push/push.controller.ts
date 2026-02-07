import { Controller, Post, Body, Headers } from '@nestjs/common';
import { ApiTags, ApiOperation } from '@nestjs/swagger';
import { PushService } from './push.service';

@ApiTags('Push Notifications')
@Controller('push')
export class PushController {
    constructor(private readonly pushService: PushService) {}

    @Post('register-token')
    @ApiOperation({ summary: 'Register device token for push notifications' })
    async registerToken(
        @Body() dto: {
            userId: string;
            role: string;
            token: string;
            platform: string;
            deviceName?: string;
            appVersion?: string;
        },
    ) {
        const device = await this.pushService.registerToken(
            dto.userId,
            dto.role as any,
            dto.token,
            dto.platform,
            dto.deviceName,
            dto.appVersion,
        );

        return {
            success: true,
            data: device,
        };
    }

    @Post('unregister-token')
    @ApiOperation({ summary: 'Unregister device token' })
    async unregisterToken(@Body() dto: { token: string }) {
        await this.pushService.unregisterToken(dto.token);
        return {
            success: true,
            message: 'Token unregistered',
        };
    }

    @Post('send-to-user')
    @ApiOperation({ summary: 'Send push notification to specific user' })
    async sendToUser(
        @Body() dto: {
            userId: string;
            title: string;
            body: string;
            data?: Record<string, any>;
        },
    ) {
        await this.pushService.sendToUser(
            dto.userId,
            dto.title,
            dto.body,
            dto.data,
        );

        return {
            success: true,
            message: 'Push notification sent',
        };
    }

    @Post('send-to-topic')
    @ApiOperation({ summary: 'Send push notification to topic' })
    async sendToTopic(
        @Body() dto: {
            topic: string;
            title: string;
            body: string;
            data?: Record<string, any>;
        },
    ) {
        await this.pushService.sendToTopic(
            dto.topic,
            dto.title,
            dto.body,
            dto.data,
        );

        return {
            success: true,
            message: 'Push notification sent to topic',
        };
    }

    @Post('test-otp')
    @ApiOperation({ summary: 'Test OTP notification' })
    async testOtp(@Body() dto: { phone: string; code: string }) {
        await this.pushService.sendOtp(dto.phone, dto.code);
        return {
            success: true,
            message: 'OTP notification sent',
        };
    }
}
