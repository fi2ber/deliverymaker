import { Injectable, BadRequestException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository, In } from 'typeorm';
import { Route, RouteStatus } from './route.entity';
import { RouteStop } from './route-stop.entity';
import { Order, OrderStatus, PaymentStatus } from '../sales/order.entity';
import { User } from '../users/user.entity';

import { YandexService } from '../integrations/yandex.service';

@Injectable()
export class LogisticsService {
    constructor(
        @InjectRepository(Route)
        private routeRepo: Repository<Route>,
        @InjectRepository(RouteStop)
        private stopRepo: Repository<RouteStop>,
        @InjectRepository(Order)
        private orderRepo: Repository<Order>,
        private yandexService: YandexService,
    ) { }

    async createRoute(driverId: string, date: Date): Promise<Route> {
        const route = this.routeRepo.create({
            driver: { id: driverId },
            date: date,
            status: RouteStatus.DRAFT,
            stops: []
        });
        return this.routeRepo.save(route);
    }

    async addOrdersToRoute(routeId: string, orderIds: string[]) {
        const route = await this.routeRepo.findOne({ where: { id: routeId }, relations: ['stops'] });
        if (!route) throw new BadRequestException('Route not found');

        const orders = await this.orderRepo.findBy({ id: In(orderIds) });

        // Validate orders
        const invalidOrders = orders.filter(o => o.status !== OrderStatus.CONFIRMED); // Only confirmed orders
        if (invalidOrders.length > 0) throw new BadRequestException(`Start orders are not CONFIRMED: ${invalidOrders.map(o => o.id)}`);

        // Optimize Route Sequence (Yandex)
        // Assuming Route has a warehouse... wait, Route is linked to Driver, but where does it start?
        // Let's assume Driver starts at a default Warehouse or the Warehouse of the first order?
        // For specific logistics, we usually define a starting point.
        // Let's assume the first order's warehouse is the start for now.
        const startWarehouse = orders[0].warehouse;
        let optimizedOrderIds = orderIds;

        if (startWarehouse && startWarehouse.latitude && startWarehouse.longitude) {
            const stopsData = orders
                .filter(o => o.location && o.location.lat && o.location.lng)
                .map(o => ({ id: o.id, lat: o.location.lat, lng: o.location.lng }));

            if (stopsData.length > 0) {
                optimizedOrderIds = await this.yandexService.optimizeRoute(
                    { lat: Number(startWarehouse.latitude), lng: Number(startWarehouse.longitude) },
                    stopsData
                );
                // Re-add orders that didn't have location (append to end)??
                // For now, let's just use the optimized list which contains IDs.
            }
        }

        // sort orders by optimizedIds
        const sortedOrders = optimizedOrderIds
            .map(id => orders.find(o => o.id === id))
            .filter(o => o !== undefined) as Order[];

        // Append remaining orders (no location)
        const remainingOrders = orders.filter(o => !optimizedOrderIds.includes(o.id));
        const finalOrderList = [...sortedOrders, ...remainingOrders];

        // Create stops
        let currentSequence = route.stops.length + 1;
        const newStops = [];

        for (const order of finalOrderList) {
            const stop = this.stopRepo.create({
                route,
                order,
                sequence: currentSequence++,
                estimatedArrivalTime: null // Logic to calculate this goes here
            });
            newStops.push(stop);

            // Update Order Status to "In Delivery" or similar if needed? 
            // Usually strictly "On Route" when route starts.
        }

        await this.stopRepo.save(newStops);
        return this.getRoute(routeId);
    }

    async getRoute(id: string) {
        return this.routeRepo.findOne({
            where: { id },
            relations: ['stops', 'stops.order', 'stops.order.client', 'driver']
        });
    }

    async findAll() {
        return this.routeRepo.find({
            relations: ['driver', 'stops', 'stops.order'],
            order: { date: 'DESC' }
        });
    }

    /**
     * Recovers the active route for a driver.
     * Useful if the app restarts or crashes.
     */
    async getActiveRoute(driverId: string) {
        // Find latest route that is NOT completed or cancelled
        return this.routeRepo.findOne({
            where: {
                driver: { id: driverId },
                status: In([RouteStatus.IN_PROGRESS, RouteStatus.ASSIGNED])
            },
            relations: ['stops', 'stops.order', 'stops.order.client'],
            order: { date: 'DESC' } // Most recent first
        });
    }

    async getUnassignedOrders() {
        // Unassigned Orders are CONFIRMED but NOT in any RouteStop
        // This query requires a "LEFT JOIN" or checking where order.stops is empty
        return this.orderRepo.createQueryBuilder('order')
            .leftJoinAndSelect('order.client', 'client')
            .leftJoin('order.stops', 'stops')
            .where('order.status = :status', { status: OrderStatus.CONFIRMED })
            .andWhere('stops.id IS NULL')
            .getMany();
    }

    // Driver Actions
    async completeStop(stopId: string) {
        const stop = await this.stopRepo.findOne({ where: { id: stopId }, relations: ['order'] });
        if (!stop) throw new BadRequestException('Stop not found');

        stop.isCompleted = true;
        stop.completionTime = new Date();
        await this.stopRepo.save(stop);

        // Update Order Status
        stop.order.status = OrderStatus.DELIVERED;
        await this.orderRepo.save(stop.order);

        return stop;
    }

    async confirmDelivery(orderId: string, data: { status: string, actualTotal: number, paymentMethod: string, items: any[] }) {
        const order = await this.orderRepo.findOne({ where: { id: orderId }, relations: ['items'] });
        if (!order) throw new BadRequestException('Order not found');

        // Update Order Header
        order.status = data.status === 'delivered' ? OrderStatus.DELIVERED : OrderStatus.RETURNED;
        order.totalAmount = data.actualTotal;
        // order.paymentMethod = data.paymentMethod; 

        if (data.paymentMethod === 'CASH') {
            order.paidAmount = data.actualTotal;
            order.paymentStatus = PaymentStatus.PAID;
        } else {
            // Credit
            order.paymentStatus = PaymentStatus.PENDING;
        }

        // Save
        return this.orderRepo.save(order);
    }
}
