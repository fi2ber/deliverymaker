import { Injectable, NotFoundException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository, Between } from 'typeorm';
import { Order, OrderStatus, OrderSource, PaymentStatus } from './order.entity';

@Injectable()
export class OrdersService {
    constructor(
        @InjectRepository(Order)
        private orderRepository: Repository<Order>,
    ) {}

    async create(data: Partial<Order>): Promise<Order> {
        const order = this.orderRepository.create(data);
        return this.orderRepository.save(order);
    }

    async findAll(tenantId?: string, filters?: {
        status?: OrderStatus;
        driverId?: string;
        dateFrom?: Date;
        dateTo?: Date;
    }): Promise<Order[]> {
        const where: any = tenantId ? { tenantId } : {};

        if (filters?.status) {
            where.status = filters.status;
        }

        if (filters?.driverId) {
            where.driverId = filters.driverId;
        }

        if (filters?.dateFrom && filters?.dateTo) {
            where.deliveryDate = Between(filters.dateFrom, filters.dateTo);
        }

        return this.orderRepository.find({
            where,
            relations: ['customer'],
            order: { createdAt: 'DESC' },
        });
    }

    async findOne(id: string): Promise<Order> {
        const order = await this.orderRepository.findOne({
            where: { id },
            relations: ['customer'],
        });

        if (!order) {
            throw new NotFoundException(`Order with ID ${id} not found`);
        }

        return order;
    }

    async findBySubscriptionAndDate(subscriptionId: string, date: Date): Promise<Order | null> {
        const startOfDay = new Date(date);
        startOfDay.setHours(0, 0, 0, 0);

        const endOfDay = new Date(date);
        endOfDay.setHours(23, 59, 59, 999);

        return this.orderRepository.findOne({
            where: {
                subscriptionId,
                deliveryDate: Between(startOfDay, endOfDay),
            },
        });
    }

    async updateStatus(id: string, status: OrderStatus, metadata?: any): Promise<Order> {
        const order = await this.findOne(id);
        order.status = status;

        if (status === OrderStatus.ASSIGNED) {
            order.assignedAt = new Date();
        }

        if (status === OrderStatus.IN_TRANSIT) {
            order.pickedUpAt = new Date();
        }

        if (status === OrderStatus.DELIVERED) {
            order.deliveredAt = new Date();
        }

        if (metadata) {
            order.metadata = { ...order.metadata, ...metadata };
        }

        return this.orderRepository.save(order);
    }

    async assignDriver(orderId: string, driverId: string, driverInfo: {
        name: string;
        phone: string;
    }): Promise<Order> {
        const order = await this.findOne(orderId);
        order.driverId = driverId;
        order.driverName = driverInfo.name;
        order.driverPhone = driverInfo.phone;
        order.status = OrderStatus.ASSIGNED;
        order.assignedAt = new Date();
        return this.orderRepository.save(order);
    }

    async submitDeliveryProof(orderId: string, proof: {
        photoUrl?: string;
        signatureUrl?: string;
        notes?: string;
    }): Promise<Order> {
        const order = await this.findOne(orderId);
        order.status = OrderStatus.DELIVERED;
        order.deliveredAt = new Date();
        order.deliveryProof = {
            ...proof,
            deliveredAt: new Date(),
        };
        return this.orderRepository.save(order);
    }

    async getDriverOrders(driverId: string, date?: Date): Promise<Order[]> {
        const where: any = { driverId };

        if (date) {
            const startOfDay = new Date(date);
            startOfDay.setHours(0, 0, 0, 0);
            const endOfDay = new Date(date);
            endOfDay.setHours(23, 59, 59, 999);
            where.deliveryDate = Between(startOfDay, endOfDay);
        }

        return this.orderRepository.find({
            where,
            relations: ['customer'],
            order: { deliveryDate: 'ASC' },
        });
    }

    async getWarehouseOrders(tenantId: string, date: Date): Promise<Order[]> {
        const startOfDay = new Date(date);
        startOfDay.setHours(0, 0, 0, 0);
        const endOfDay = new Date(date);
        endOfDay.setHours(23, 59, 59, 999);

        return this.orderRepository.find({
            where: {
                tenantId,
                deliveryDate: Between(startOfDay, endOfDay),
                status: Between(OrderStatus.PENDING, OrderStatus.READY),
            },
            relations: ['customer'],
            order: { createdAt: 'ASC' },
        });
    }

    // Legacy methods for backward compatibility
    async findById(id: string): Promise<Order | null> {
        return this.findOne(id).catch(() => null);
    }

    async findByClient(clientId: string): Promise<Order[]> {
        return this.orderRepository.find({
            where: { customerId: clientId },
            relations: ['customer'],
            order: { createdAt: 'DESC' },
        });
    }

    async getDebt(clientId: string): Promise<number> {
        const orders = await this.orderRepository.find({
            where: {
                customerId: clientId,
                paymentStatus: PaymentStatus.PENDING,
            },
        });
        return orders.reduce((sum, o) => sum + (o.totalAmount - (o.paidAmount || 0)), 0);
    }

    async createVanSale(driverId: string, data: { clientId: string; items: any[] }): Promise<Order> {
        const orderCode = `VS-${Date.now()}`;
        const order = this.orderRepository.create({
            orderCode,
            customerId: data.clientId,
            driverId,
            source: 'MANUAL' as OrderSource,
            status: OrderStatus.DELIVERED,
            items: data.items,
            totalAmount: data.items.reduce((sum, i) => sum + (i.price * i.quantity), 0),
            deliveryDate: new Date(),
            deliveredAt: new Date(),
            paymentStatus: PaymentStatus.PENDING,
        });
        return this.orderRepository.save(order);
    }
}
