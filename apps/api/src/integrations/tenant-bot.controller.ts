import { 
    Controller, 
    Get, 
    Post, 
    Put, 
    Delete,
    Body, 
    Param,
    UseGuards,
    Request,
} from '@nestjs/common';
import { ApiTags, ApiOperation, ApiBearerAuth } from '@nestjs/swagger';
import { TenantTelegramService } from './tenant-telegram.service';
import { JwtAuthGuard } from '../auth/jwt.guard';
import { RolesGuard } from '../common/guards/roles.guard';
import { Roles } from '../common/decorators/roles.decorator';
import { UserRole } from '../users/user.entity';

class RegisterBotDto {
    botToken: string;
    botName?: string;
}

class UpdateBotSettingsDto {
    welcomeMessage?: string;
    supportUsername?: string;
    paymentProviderToken?: string;
    webAppUrl?: string;
}

@ApiTags('Tenant Bot')
@Controller('integrations/bot')
@UseGuards(JwtAuthGuard, RolesGuard)
@Roles(UserRole.SUPER_ADMIN, UserRole.DIRECTOR)
@ApiBearerAuth('JWT-auth')
export class TenantBotController {
    constructor(private readonly tenantTelegramService: TenantTelegramService) {}

    @Post('register')
    @ApiOperation({ summary: 'Register Telegram bot for current tenant' })
    async registerBot(@Request() req, @Body() dto: RegisterBotDto) {
        const tenantId = req.tenantId || 'public';
        return this.tenantTelegramService.registerBot(tenantId, dto.botToken, dto.botName);
    }

    @Get('info')
    @ApiOperation({ summary: 'Get bot info from Telegram API' })
    async getBotInfo(@Request() req) {
        const tenantId = req.tenantId || 'public';
        return this.tenantTelegramService.getMe(tenantId);
    }

    @Get('settings')
    @ApiOperation({ summary: 'Get bot settings' })
    async getSettings(@Request() req) {
        const tenantId = req.tenantId || 'public';
        const bot = await this.tenantTelegramService.getBotSettings(tenantId);
        // Не возвращаем токен в ответе
        const { botToken, ...safeBot } = bot as any;
        return safeBot;
    }

    @Put('settings')
    @ApiOperation({ summary: 'Update bot settings' })
    async updateSettings(@Request() req, @Body() dto: UpdateBotSettingsDto) {
        const tenantId = req.tenantId || 'public';
        return this.tenantTelegramService.updateBotSettings(tenantId, dto);
    }

    @Post('webhook')
    @ApiOperation({ summary: 'Set webhook for bot' })
    async setWebhook(@Request() req, @Body('webhookUrl') webhookUrl: string) {
        const tenantId = req.tenantId || 'public';
        return this.tenantTelegramService.setWebhook(tenantId, webhookUrl);
    }

    @Delete('webhook')
    @ApiOperation({ summary: 'Delete webhook' })
    async deleteWebhook(@Request() req) {
        const tenantId = req.tenantId || 'public';
        return this.tenantTelegramService.deleteWebhook(tenantId);
    }

    @Get('webhook-info')
    @ApiOperation({ summary: 'Get webhook info' })
    async getWebhookInfo(@Request() req) {
        const tenantId = req.tenantId || 'public';
        return this.tenantTelegramService.getWebhookInfo(tenantId);
    }

    @Post('test-message')
    @ApiOperation({ summary: 'Send test message' })
    async sendTestMessage(@Request() req, @Body('chatId') chatId: string) {
        const tenantId = req.tenantId || 'public';
        return this.tenantTelegramService.sendMessage(tenantId, {
            chatId,
            text: '✅ Бот успешно настроен!',
            parseMode: 'HTML',
        });
    }

    @Delete()
    @ApiOperation({ summary: 'Deactivate bot' })
    async deactivateBot(@Request() req) {
        const tenantId = req.tenantId || 'public';
        await this.tenantTelegramService.deactivateBot(tenantId);
        return { message: 'Bot deactivated' };
    }
}
