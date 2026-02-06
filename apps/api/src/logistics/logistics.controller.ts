import { Controller, Post, Get, Body, Param, Put, UseGuards } from '@nestjs/common';
import { ApiTags, ApiBearerAuth, ApiOperation, ApiResponse } from '@nestjs/swagger';
import { LogisticsService } from './logistics.service';
import { JwtAuthGuard } from '../auth/jwt.guard';
import { RolesGuard } from '../common/guards/roles.guard';
import { Roles } from '../common/decorators/roles.decorator';
import { CurrentUser } from '../common/decorators/current-user.decorator';
import { UserRole } from '../users/user.entity';

@ApiTags('Logistics')
@ApiBearerAuth('JWT-auth')
@Controller('logistics')
@UseGuards(JwtAuthGuard)
export class LogisticsController {
    constructor(private readonly logisticsService: LogisticsService) { }

    @Post('routes')
    @UseGuards(RolesGuard)
    @Roles(UserRole.SUPER_ADMIN, UserRole.OWNER, UserRole.DIRECTOR, UserRole.SALES_REP)
    async createRoute(@Body() body: { driverId: string; date: Date }) {
        return this.logisticsService.createRoute(body.driverId, body.date);
    }

    @Get('routes')
    @UseGuards(RolesGuard)
    @Roles(UserRole.SUPER_ADMIN, UserRole.OWNER, UserRole.DIRECTOR, UserRole.SALES_REP, UserRole.DRIVER)
    async findAll() {
        return this.logisticsService.findAll();
    }

    @Post('routes/:id/orders')
    @UseGuards(RolesGuard)
    @Roles(UserRole.SUPER_ADMIN, UserRole.OWNER, UserRole.DIRECTOR, UserRole.SALES_REP)
    async addOrders(@Param('id') routeId: string, @Body() body: { orderIds: string[] }) {
        return this.logisticsService.addOrdersToRoute(routeId, body.orderIds);
    }

    @Get('routes/:id')
    @UseGuards(RolesGuard)
    @Roles(UserRole.SUPER_ADMIN, UserRole.OWNER, UserRole.DIRECTOR, UserRole.SALES_REP, UserRole.DRIVER)
    async getRoute(@Param('id') id: string) {
        return this.logisticsService.getRoute(id);
    }

    @Get('drivers/:driverId/active-route')
    @UseGuards(RolesGuard)
    @Roles(UserRole.SUPER_ADMIN, UserRole.OWNER, UserRole.DIRECTOR, UserRole.SALES_REP)
    async getActiveRoute(@Param('driverId') driverId: string) {
        return this.logisticsService.getActiveRoute(driverId);
    }

    @Get('routes/active/my')
    @UseGuards(RolesGuard)
    @Roles(UserRole.DRIVER, UserRole.SUPER_ADMIN)
    async getMyActiveRoute(@CurrentUser() user: any) {
        return this.logisticsService.getActiveRoute(user.id);
    }

    @Get('orders/unassigned')
    @UseGuards(RolesGuard)
    @Roles(UserRole.SUPER_ADMIN, UserRole.OWNER, UserRole.DIRECTOR, UserRole.SALES_REP)
    async getUnassignedOrders() {
        return this.logisticsService.getUnassignedOrders();
    }

    @Put('stops/:id/complete')
    @UseGuards(RolesGuard)
    @Roles(UserRole.SUPER_ADMIN, UserRole.DRIVER)
    async completeStop(@Param('id') id: string) {
        return this.logisticsService.completeStop(id);
    }

    @Post('orders/:id/delivery')
    @UseGuards(RolesGuard)
    @Roles(UserRole.SUPER_ADMIN, UserRole.DRIVER)
    async confirmDelivery(@Param('id') id: string, @Body() body: any) {
        return this.logisticsService.confirmDelivery(id, body);
    }
}
