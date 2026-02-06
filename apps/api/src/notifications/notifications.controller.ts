import {
    Controller,
    Get,
    Post,
    Body,
    Param,
    Query,
    UseGuards,
    ParseUUIDPipe,
} from '@nestjs/common';
import { ApiTags, ApiBearerAuth, ApiOperation, ApiResponse } from '@nestjs/swagger';
import { JwtAuthGuard } from '../auth/jwt.guard';
import { RolesGuard } from '../common/guards/roles.guard';
import { Roles } from '../common/decorators/roles.decorator';
import { CurrentUser } from '../common/decorators/current-user.decorator';
import { UserRole } from '../users/user.entity';
import { NotificationsService } from './notifications.service';
import { PushService, PushMessage } from './push.service';
import { NotificationsGateway } from './notifications.gateway';
import { DevicePlatform } from './device-token.entity';

class RegisterDeviceDto {
    token: string;
    platform: DevicePlatform;
    deviceInfo?: string;
}

class SendNotificationDto {
    userIds?: string[];
    role?: string;
    title: string;
    body: string;
    data?: Record<string, string>;
}

@ApiTags('Notifications')
@ApiBearerAuth('JWT-auth')
@Controller('notifications')
@UseGuards(JwtAuthGuard)
export class NotificationsController {
    constructor(
        private readonly notificationsService: NotificationsService,
        private readonly pushService: PushService,
        private readonly gateway: NotificationsGateway,
    ) { }

    // ============ Device Management ============

    @Post('device')
    async registerDevice(
        @CurrentUser() user: any,
        @Body() dto: RegisterDeviceDto,
    ) {
        return this.pushService.registerDevice(
            user.userId,
            dto.token,
            dto.platform,
            dto.deviceInfo,
        );
    }

    @Post('device/unregister')
    async unregisterDevice(@Body('token') token: string) {
        await this.pushService.unregisterDevice(token);
        return { success: true };
    }

    // ============ User Notifications ============

    @Get('my')
    async getMyNotifications(@CurrentUser() user: any) {
        return this.notificationsService.getForUser(user.userId);
    }

    @Post(':id/read')
    async markAsRead(@Param('id', ParseUUIDPipe) id: string) {
        await this.notificationsService.markAsRead(id);
        return { success: true };
    }

    @Post('read-all')
    async markAllAsRead(@CurrentUser() user: any) {
        // TODO: Implement mark all as read
        return { success: true };
    }

    // ============ Admin Push Notifications ============

    @Post('send')
    @UseGuards(RolesGuard)
    @Roles(UserRole.SUPER_ADMIN, UserRole.OWNER, UserRole.DIRECTOR)
    async sendNotification(@Body() dto: SendNotificationDto) {
        const message: PushMessage = {
            title: dto.title,
            body: dto.body,
            data: dto.data,
        };

        if (dto.userIds && dto.userIds.length > 0) {
            await this.pushService.sendToUsers(dto.userIds, message);
        } else if (dto.role) {
            await this.pushService.sendToRole(dto.role, message);
        } else {
            await this.pushService.broadcast(message);
        }

        return { success: true, sent: true };
    }

    @Post('broadcast')
    @UseGuards(RolesGuard)
    @Roles(UserRole.SUPER_ADMIN, UserRole.OWNER)
    async broadcast(@Body() dto: Omit<SendNotificationDto, 'userIds' | 'role'>) {
        const message: PushMessage = {
            title: dto.title,
            body: dto.body,
            data: dto.data,
        };

        await this.pushService.broadcast(message);

        // Also send via WebSocket
        this.gateway.broadcast({
            title: dto.title,
            body: dto.body,
            timestamp: new Date().toISOString(),
        });

        return { success: true };
    }

    // ============ Status ============

    @Get('status/online')
    @UseGuards(RolesGuard)
    @Roles(UserRole.SUPER_ADMIN, UserRole.OWNER, UserRole.DIRECTOR)
    getOnlineStatus() {
        return {
            onlineUsers: this.gateway.getOnlineUsersCount(),
        };
    }

    @Get('status/my')
    isUserOnline(@CurrentUser() user: any) {
        return {
            isOnline: this.gateway.isUserOnline(user.userId),
        };
    }
}
