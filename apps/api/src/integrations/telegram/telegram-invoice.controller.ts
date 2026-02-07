import { Controller, Post, Body, Headers, HttpException, HttpStatus } from '@nestjs/common';
import { ApiTags, ApiOperation, ApiResponse } from '@nestjs/swagger';
import { TelegramInvoiceService } from './telegram-invoice.service';

@ApiTags('Telegram Integration')
@Controller('integrations/telegram')
export class TelegramInvoiceController {
    constructor(private readonly invoiceService: TelegramInvoiceService) {}

    @Post('invoice')
    @ApiOperation({ summary: 'Create Telegram invoice for payment' })
    @ApiResponse({ status: 201, description: 'Invoice created successfully' })
    async createInvoice(@Body() dto: {
        subscriptionId: string;
        title: string;
        description: string;
        amount: number; // in smallest units (cents/tiyins)
        payload: string;
    }, @Headers('x-tenant-id') tenantId?: string) {
        try {
            const result = await this.invoiceService.createInvoice({
                ...dto,
                tenantId,
            });
            
            return {
                success: true,
                data: result,
            };
        } catch (error) {
            throw new HttpException(
                {
                    success: false,
                    message: error.message || 'Failed to create invoice',
                },
                HttpStatus.BAD_REQUEST,
            );
        }
    }
}
