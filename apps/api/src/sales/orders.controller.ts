import { Controller, Get, Post, Body, Param, UseGuards } from '@nestjs/common';
import { ApiTags, ApiBearerAuth, ApiOperation, ApiResponse } from '@nestjs/swagger';
import { OrdersService } from './orders.service';
import { JwtAuthGuard } from '../auth/jwt.guard';
import { RolesGuard } from '../common/guards/roles.guard';
import { Roles } from '../common/decorators/roles.decorator';
import { UserRole } from '../users/user.entity';
import { CurrentUser } from '../common/decorators/current-user.decorator';

@ApiTags('Orders')
@ApiBearerAuth('JWT-auth')
@Controller('orders')
@UseGuards(JwtAuthGuard)
export class OrdersController {
    constructor(private readonly ordersService: OrdersService) { }

    @Post()
    @UseGuards(RolesGuard)
    @Roles(UserRole.SUPER_ADMIN, UserRole.OWNER, UserRole.DIRECTOR, UserRole.SALES_REP)
    async create(@Body() body: any) {
        return this.ordersService.create(body);
    }

    @Post('van-sale')
    @UseGuards(RolesGuard)
    @Roles(UserRole.DRIVER, UserRole.SALES_REP)
    async createVanSale(@CurrentUser() user: any, @Body() body: { clientId: string, items: { productId: string, quantity: number, price: number }[] }) {
        return this.ordersService.createVanSale(user.id, body);
    }

    @Get()
    @UseGuards(RolesGuard)
    @Roles(UserRole.SUPER_ADMIN, UserRole.OWNER, UserRole.DIRECTOR, UserRole.SALES_REP, UserRole.ACCOUNTANT)
    async findAll() {
        return this.ordersService.findAll();
    }

    @Get('debt/:clientId')
    @UseGuards(RolesGuard)
    @Roles(UserRole.SUPER_ADMIN, UserRole.OWNER, UserRole.SALES_REP)
    async getDebt(@Param('clientId') clientId: string) {
        return { debt: await this.ordersService.getDebt(clientId) };
    }

    @Get('my')
    @ApiOperation({ summary: 'Get my orders' })
    async getMyOrders(@CurrentUser() user: any) {
        return this.ordersService.findByClient(user.id);
    }

    @Get(':id')
    @ApiOperation({ summary: 'Get order by ID' })
    async getOrderById(@Param('id') id: string) {
        return this.ordersService.findById(id);
    }
}
