import { Controller, Post, Body, Headers, Param, HttpCode, HttpStatus } from '@nestjs/common';
import { ApiTags, ApiOperation } from '@nestjs/swagger';
import { TelegramWebhookService } from './telegram-webhook.service';

@ApiTags('Telegram Webhooks')
@Controller('webhooks/telegram')
export class TelegramWebhookController {
    constructor(private readonly webhookService: TelegramWebhookService) {}

    @Post(':tenantId')
    @HttpCode(HttpStatus.OK)
    @ApiOperation({ summary: 'Handle Telegram bot webhook' })
    async handleWebhook(
        @Param('tenantId') tenantId: string,
        @Body() update: any,
    ) {
        await this.webhookService.processUpdate(tenantId, update);
        return { ok: true };
    }

    @Post('payments/telegram')
    @HttpCode(HttpStatus.OK)
    @ApiOperation({ summary: 'Handle Telegram payment confirmation' })
    async handlePaymentConfirmation(
        @Body() paymentData: {
            subscriptionId: string;
            telegramPaymentChargeId: string;
            totalAmount: number;
        },
    ) {
        const result = await this.webhookService.confirmPayment(paymentData);
        return {
            success: true,
            data: result,
        };
    }

    @Post('payments/pre-checkout')
    @HttpCode(HttpStatus.OK)
    @ApiOperation({ summary: 'Handle Telegram pre-checkout query' })
    async handlePreCheckout(@Body() query: any) {
        // Always answer pre-checkout queries to allow payment
        return { ok: true };
    }
}
