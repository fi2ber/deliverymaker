import { Controller, Get, Post, Put, Body, Param, Query } from '@nestjs/common';
import { ApiTags, ApiOperation } from '@nestjs/swagger';
import { OrdersService } from '../sales/orders.service';
import { OrderStatus } from '../sales/order.entity';

@ApiTags('Warehouse Orders')
@Controller('warehouse/orders')
export class WarehouseOrdersController {
    constructor(private readonly ordersService: OrdersService) {}

    @Get('today')
    @ApiOperation({ summary: 'Get orders for today (warehouse view)' })
    async getTodayOrders(@Query('tenantId') tenantId: string) {
        const today = new Date();
        const orders = await this.ordersService.getWarehouseOrders(tenantId, today);
        return {
            success: true,
            data: orders,
            count: orders.length,
        };
    }

    @Get('by-date')
    @ApiOperation({ summary: 'Get orders by date' })
    async getOrdersByDate(
        @Query('tenantId') tenantId: string,
        @Query('date') dateStr: string,
    ) {
        const date = dateStr ? new Date(dateStr) : new Date();
        const orders = await this.ordersService.getWarehouseOrders(tenantId, date);
        return {
            success: true,
            data: orders,
            count: orders.length,
        };
    }

    @Get(':id')
    @ApiOperation({ summary: 'Get order details' })
    async getOrder(@Param('id') id: string) {
        const order = await this.ordersService.findOne(id);
        return {
            success: true,
            data: order,
        };
    }

    @Post(':id/confirm')
    @ApiOperation({ summary: 'Confirm order (warehouse accepts)' })
    async confirmOrder(
        @Param('id') id: string,
        @Body() data: { confirmedBy: string },
    ) {
        const order = await this.ordersService.updateStatus(id, OrderStatus.CONFIRMED, {
            confirmedBy: data.confirmedBy,
        });
        return {
            success: true,
            data: order,
            message: 'Order confirmed',
        };
    }

    @Post(':id/start-packing')
    @ApiOperation({ summary: 'Start packing order' })
    async startPacking(
        @Param('id') id: string,
        @Body() data: { packedBy: string },
    ) {
        const order = await this.ordersService.updateStatus(id, OrderStatus.PACKING, {
            packedBy: data.packedBy,
        });
        return {
            success: true,
            data: order,
            message: 'Packing started',
        };
    }

    @Post(':id/ready')
    @ApiOperation({ summary: 'Mark order as ready for delivery' })
    async markReady(
        @Param('id') id: string,
        @Body() data: { checkedBy: string; notes?: string },
    ) {
        const order = await this.ordersService.updateStatus(id, OrderStatus.READY, {
            checkedBy: data.checkedBy,
            warehouseNotes: data.notes,
        });
        return {
            success: true,
            data: order,
            message: 'Order ready for delivery',
        };
    }

    @Post(':id/assign-driver')
    @ApiOperation({ summary: 'Assign driver to order' })
    async assignDriver(
        @Param('id') id: string,
        @Body() data: {
            driverId: string;
            driverName: string;
            driverPhone: string;
        },
    ) {
        const order = await this.ordersService.assignDriver(
            id,
            data.driverId,
            {
                name: data.driverName,
                phone: data.driverPhone,
            },
        );
        return {
            success: true,
            data: order,
            message: 'Driver assigned',
        };
    }

    @Get('stats/today')
    @ApiOperation({ summary: 'Get today\'s order statistics' })
    async getTodayStats(@Query('tenantId') tenantId: string) {
        const today = new Date();
        const orders = await this.ordersService.getWarehouseOrders(tenantId, today);

        const stats = {
            total: orders.length,
            pending: orders.filter(o => o.status === OrderStatus.PENDING).length,
            confirmed: orders.filter(o => o.status === OrderStatus.CONFIRMED).length,
            packing: orders.filter(o => o.status === OrderStatus.PACKING).length,
            ready: orders.filter(o => o.status === OrderStatus.READY).length,
            assigned: orders.filter(o => o.status === OrderStatus.ASSIGNED).length,
        };

        return {
            success: true,
            data: stats,
        };
    }
}
