import { Controller, Get, Post, Put, Body, Param, Query, Headers } from '@nestjs/common';
import { ApiTags, ApiOperation } from '@nestjs/swagger';
import { OrdersService } from '../sales/orders.service';
import { SubscriptionSchedulerService } from '../subscriptions/subscription-scheduler.service';
import { OrderStatus } from '../sales/order.entity';

@ApiTags('Driver Orders')
@Controller('driver/orders')
export class DriverOrdersController {
    constructor(
        private readonly ordersService: OrdersService,
        private readonly subscriptionScheduler: SubscriptionSchedulerService,
    ) {}

    @Get('my')
    @ApiOperation({ summary: 'Get my assigned orders (driver view)' })
    async getMyOrders(
        @Query('driverId') driverId: string,
        @Query('date') dateStr?: string,
    ) {
        const date = dateStr ? new Date(dateStr) : new Date();
        const orders = await this.ordersService.getDriverOrders(driverId, date);

        // Group by status
        const grouped = {
            toPickup: orders.filter(o => o.status === OrderStatus.ASSIGNED || o.status === OrderStatus.READY),
            inTransit: orders.filter(o => o.status === OrderStatus.IN_TRANSIT),
            completed: orders.filter(o => o.status === OrderStatus.DELIVERED),
        };

        return {
            success: true,
            data: {
                all: orders,
                grouped,
                count: orders.length,
            },
        };
    }

    @Get('route')
    @ApiOperation({ summary: 'Get optimized route for today' })
    async getRoute(
        @Query('driverId') driverId: string,
        @Query('date') dateStr?: string,
    ) {
        const date = dateStr ? new Date(dateStr) : new Date();
        const orders = await this.ordersService.getDriverOrders(driverId, date);

        // Filter only orders that need delivery
        const deliveries = orders.filter(o => 
            o.status === OrderStatus.ASSIGNED || 
            o.status === OrderStatus.IN_TRANSIT
        );

        // Sort by delivery time/address (simple version)
        // In real app, would use routing optimization API
        const route = deliveries.map((order, index) => ({
            sequence: index + 1,
            orderId: order.id,
            orderCode: order.orderCode,
            customerName: order.customer?.firstName || 'Unknown',
            phone: order.deliveryAddress?.phone || order.customer?.phone,
            address: order.deliveryAddress?.address,
            comment: order.deliveryAddress?.comment,
            status: order.status,
            lat: order.deliveryAddress?.lat,
            lng: order.deliveryAddress?.lng,
        }));

        return {
            success: true,
            data: route,
        };
    }

    @Post(':id/pickup')
    @ApiOperation({ summary: 'Pick up order from warehouse' })
    async pickupOrder(
        @Param('id') id: string,
        @Body() data: { driverId: string; notes?: string },
    ) {
        const order = await this.ordersService.updateStatus(id, OrderStatus.IN_TRANSIT, {
            pickupNotes: data.notes,
        });

        return {
            success: true,
            data: order,
            message: 'Order picked up',
        };
    }

    @Post(':id/deliver')
    @ApiOperation({ summary: 'Mark order as delivered' })
    async deliverOrder(
        @Param('id') id: string,
        @Body() data: {
            driverId: string;
            photoUrl?: string;
            signatureUrl?: string;
            notes?: string;
        },
    ) {
        const order = await this.ordersService.submitDeliveryProof(id, {
            photoUrl: data.photoUrl,
            signatureUrl: data.signatureUrl,
            notes: data.notes,
        });

        // Update subscription if this is a subscription order
        if (order.subscriptionId) {
            await this.subscriptionScheduler.completeDelivery(order.subscriptionId);
        }

        return {
            success: true,
            data: order,
            message: 'Order delivered successfully',
        };
    }

    @Post(':id/failed')
    @ApiOperation({ summary: 'Mark delivery as failed' })
    async deliveryFailed(
        @Param('id') id: string,
        @Body() data: {
            driverId: string;
            reason: string;
        },
    ) {
        const order = await this.ordersService.updateStatus(id, OrderStatus.PENDING, {
            deliveryFailedReason: data.reason,
            deliveryFailedAt: new Date(),
        });

        return {
            success: true,
            data: order,
            message: 'Delivery marked as failed, will be rescheduled',
        };
    }

    @Get('stats/today')
    @ApiOperation({ summary: 'Get driver statistics for today' })
    async getTodayStats(
        @Query('driverId') driverId: string,
    ) {
        const today = new Date();
        const orders = await this.ordersService.getDriverOrders(driverId, today);

        const stats = {
            total: orders.length,
            pending: orders.filter(o => o.status === OrderStatus.ASSIGNED).length,
            inTransit: orders.filter(o => o.status === OrderStatus.IN_TRANSIT).length,
            delivered: orders.filter(o => o.status === OrderStatus.DELIVERED).length,
            completionRate: orders.length > 0 
                ? Math.round((orders.filter(o => o.status === OrderStatus.DELIVERED).length / orders.length) * 100)
                : 0,
        };

        return {
            success: true,
            data: stats,
        };
    }
}
