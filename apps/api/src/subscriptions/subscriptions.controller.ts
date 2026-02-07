import { Controller, Get, Post, Put, Delete, Body, Param, Query, UseGuards } from '@nestjs/common';
import { ApiTags, ApiOperation, ApiResponse, ApiBearerAuth } from '@nestjs/swagger';
import { SubscriptionsService } from './subscriptions.service';
import { CreateSubscriptionDto, UpdateSubscriptionDto } from './dto';
import { Subscription } from './subscription.entity';

@ApiTags('Subscriptions')
@Controller('subscriptions')
export class SubscriptionsController {
    constructor(private readonly subscriptionsService: SubscriptionsService) {}

    // Self-service endpoint for TMA
    @Post('self-service')
    @ApiOperation({ summary: 'Create subscription (self-service from TMA)' })
    @ApiResponse({ status: 201, description: 'Subscription created successfully' })
    async createSelfService(@Body() dto: {
        comboProductId: string;
        customerId: string;
        deliveryAddress: {
            address: string;
            phone: string;
            comment?: string;
        };
        paymentProvider: 'telegram' | 'click' | 'payme';
        totalAmount: number;
    }) {
        const subscription = await this.subscriptionsService.createFromSelfService(dto);
        return {
            success: true,
            data: subscription,
        };
    }

    // Get my subscriptions (for TMA)
    @Get('my')
    @ApiOperation({ summary: 'Get customer subscriptions (for TMA)' })
    async getMySubscriptions(@Query('customerId') customerId: string) {
        if (!customerId) {
            return {
                success: false,
                message: 'Customer ID required',
            };
        }

        const subscriptions = await this.subscriptionsService.findByCustomer(customerId);
        return {
            success: true,
            data: subscriptions,
        };
    }

    // Get combos for TMA (public endpoint)
    @Get('combos/tma')
    @ApiOperation({ summary: 'Get combo products for TMA' })
    async getCombosForTma() {
        const combos = await this.subscriptionsService.getActiveCombos();
        return {
            success: true,
            data: combos,
        };
    }

    // Standard CRUD
    @Get()
    @ApiOperation({ summary: 'Get all subscriptions' })
    async findAll(@Query('tenantId') tenantId?: string) {
        const subscriptions = await this.subscriptionsService.findAll(tenantId);
        return {
            success: true,
            data: subscriptions,
        };
    }

    @Get(':id')
    @ApiOperation({ summary: 'Get subscription by ID' })
    async findOne(@Param('id') id: string) {
        const subscription = await this.subscriptionsService.findOne(id);
        return {
            success: true,
            data: subscription,
        };
    }

    @Post()
    @ApiOperation({ summary: 'Create subscription (manager)' })
    async create(@Body() dto: CreateSubscriptionDto) {
        const subscription = await this.subscriptionsService.create(dto);
        return {
            success: true,
            data: subscription,
        };
    }

    @Put(':id')
    @ApiOperation({ summary: 'Update subscription' })
    async update(@Param('id') id: string, @Body() dto: UpdateSubscriptionDto) {
        const subscription = await this.subscriptionsService.update(id, dto);
        return {
            success: true,
            data: subscription,
        };
    }

    @Delete(':id')
    @ApiOperation({ summary: 'Delete subscription' })
    async remove(@Param('id') id: string) {
        await this.subscriptionsService.remove(id);
        return {
            success: true,
            message: 'Subscription deleted successfully',
        };
    }
}
