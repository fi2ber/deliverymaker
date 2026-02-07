import { Controller, Get, Post, Put, Delete, Body, Param, Query, Headers } from '@nestjs/common';
import { ApiTags, ApiOperation, ApiResponse } from '@nestjs/swagger';
import { CustomersService } from './customers.service';
import { CreateCustomerDto, UpdateCustomerDto } from './dto';
import { CustomerSource, CustomerStatus } from './entities/customer.entity';

@ApiTags('Customers')
@Controller('customers')
export class CustomersController {
    constructor(private readonly customersService: CustomersService) {}

    @Post('self-register')
    @ApiOperation({ summary: 'Self-register from Telegram WebApp' })
    @ApiResponse({ status: 201, description: 'Customer registered successfully' })
    @ApiResponse({ status: 409, description: 'Customer already exists' })
    async selfRegister(@Body() dto: {
        telegramId: number;
        firstName?: string;
        lastName?: string;
        username?: string;
        source?: string;
        startParam?: string;
    }) {
        // Check if customer already exists
        const existing = await this.customersService.findByTelegramId(dto.telegramId.toString());
        
        if (existing) {
            return {
                success: true,
                data: existing,
                message: 'Customer already registered',
            };
        }

        // Create new customer
        const createDto: CreateCustomerDto = {
            telegramId: dto.telegramId.toString(),
            firstName: dto.firstName || 'Telegram User',
            lastName: dto.lastName,
            telegramUsername: dto.username,
            source: (dto.source as CustomerSource) || CustomerSource.TELEGRAM_BOT,
            isPhoneVerified: false,
            status: CustomerStatus.ACTIVE,
            tenantId: dto.startParam ? this.extractTenantId(dto.startParam) : undefined,
        };
        const customer = await this.customersService.create(createDto);

        return {
            success: true,
            data: customer,
            message: 'Customer registered successfully',
        };
    }

    @Get('me')
    @ApiOperation({ summary: 'Get current customer by Telegram ID' })
    async getMe(@Query('telegramId') telegramId: string) {
        if (!telegramId) {
            return {
                success: false,
                message: 'Telegram ID required',
            };
        }

        const customer = await this.customersService.findByTelegramId(telegramId);
        
        if (!customer) {
            return {
                success: false,
                message: 'Customer not found',
            };
        }

        return {
            success: true,
            data: customer,
        };
    }

    @Get()
    @ApiOperation({ summary: 'Get all customers' })
    async findAll(@Query('tenantId') tenantId?: string) {
        const customers = await this.customersService.findAll(tenantId);
        return {
            success: true,
            data: customers,
        };
    }

    @Get(':id')
    @ApiOperation({ summary: 'Get customer by ID' })
    async findOne(@Param('id') id: string) {
        const customer = await this.customersService.findOne(id);
        return {
            success: true,
            data: customer,
        };
    }

    @Post()
    @ApiOperation({ summary: 'Create customer (manager)' })
    async create(@Body() dto: CreateCustomerDto) {
        const customer = await this.customersService.create(dto);
        return {
            success: true,
            data: customer,
        };
    }

    @Put(':id')
    @ApiOperation({ summary: 'Update customer' })
    async update(@Param('id') id: string, @Body() dto: UpdateCustomerDto) {
        const customer = await this.customersService.update(id, dto);
        return {
            success: true,
            data: customer,
        };
    }

    @Delete(':id')
    @ApiOperation({ summary: 'Delete customer' })
    async remove(@Param('id') id: string) {
        await this.customersService.remove(id);
        return {
            success: true,
            message: 'Customer deleted successfully',
        };
    }

    private extractTenantId(startParam: string): string | undefined {
        // Format: tenant_<id> or just <id>
        if (startParam.startsWith('tenant_')) {
            return startParam.replace('tenant_', '');
        }
        return startParam;
    }
}
