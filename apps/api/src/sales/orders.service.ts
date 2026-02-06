import { Inject, Injectable, BadRequestException, ForbiddenException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository, DataSource } from 'typeorm';
import { Order, OrderStatus, PaymentMethod, PaymentStatus } from './order.entity';
import { OrderItem } from './order-item.entity';
import { OrderItemAllocation } from './order-item-allocation.entity'; // Import allocation
import { WarehouseService } from '../warehouse/warehouse.service';
import { TENANT_CONNECTION } from '../database/database.module';
import { User } from '../users/user.entity';

@Injectable()
export class OrdersService {
    constructor(
        @Inject(TENANT_CONNECTION) private dataSource: DataSource,
        private warehouseService: WarehouseService,
    ) { }

    private get orderRepo() { return this.dataSource.getRepository(Order); }

    /**
     * Calculates the total outstanding debt for a client.
     * Debt = Sum of (Total Amount - Paid Amount) for non-cancelled orders.
     */
    async getDebt(clientId: string): Promise<number> {
        const { debt } = await this.orderRepo
            .createQueryBuilder('order')
            .select('SUM(order.totalAmount - order.paidAmount)', 'debt')
            .where('order.client.id = :clientId', { clientId })
            .andWhere('order.status NOT IN (:...statuses)', { statuses: [OrderStatus.CANCELLED, OrderStatus.RETURNED] })
            .getRawOne();

        return Number(debt || 0);
    }

    /**
     * Creates an order with STRICT stock reservation.
     * If stock is insufficient for ANY item, the entire order fails.
     */
    async create(data: { clientId: string, warehouseId: string, paymentMethod: PaymentMethod, items: { productId: string, quantity: number, price: number }[] }): Promise<Order> {
        // Debt Check for Credit Orders
        if (data.paymentMethod === PaymentMethod.CREDIT) {
            const currentDebt = await this.getDebt(data.clientId);
            if (currentDebt > 0) {
                // Throwing HTTP exception inside service is OK for this monolithic app, 
                // but ideally should be exception filter or domain error.
                // Using ForbiddenException requires @nestjs/common import
                throw new ForbiddenException({
                    message: 'Cannot place CREDIT order with outstanding debt',
                    currentDebt,
                    code: 'DEBT_BLOCK'
                });
            }
        }

        return this.dataSource.transaction(async (manager) => {
            // 1. Create Order Header
            const order = manager.create(Order, {
                status: OrderStatus.CONFIRMED, // Immediately confirmed if stock exists
                warehouse: { id: data.warehouseId }, // Must be set
                client: { id: data.clientId },
                paymentMethod: data.paymentMethod,
                totalAmount: data.items.reduce((sum, i) => sum + (i.price * i.quantity), 0),
                items: []
            });

            // 1.1 Update Debt
            // Initial order usually has 0 paid.
            await manager.increment(User, { id: data.clientId }, 'currentDebt', order.totalAmount);

            // 2. Process Items... (rest is same)
            for (const itemRequest of data.items) {
                try {
                    // Reserve Stock (throws if insufficient)
                    const deductedBatches = await this.warehouseService.deductStock(
                        data.warehouseId,
                        itemRequest.productId,
                        itemRequest.quantity,
                        manager // Pass transaction manager!
                    );

                    // Create Order Item
                    const orderItem = manager.create(OrderItem, {
                        product: { id: itemRequest.productId },
                        quantity: itemRequest.quantity,
                        price: itemRequest.price,
                        total: itemRequest.quantity * itemRequest.price,
                        allocations: []
                    });

                    for (const batchAlloc of deductedBatches) {
                        const allocation = manager.create(OrderItemAllocation, {
                            batch: { id: batchAlloc.batchId },
                            quantity: batchAlloc.quantity
                        });
                        orderItem.allocations.push(allocation);
                    }

                    order.items.push(orderItem);


                } catch (error) {
                    if (error.message.startsWith('INSUFFICIENT_STOCK')) {
                        // Find Substitutes logic here
                        // For now, simpler error with metadata
                        const product = await manager.findOne(Order, { where: { id: itemRequest.productId } }); // Quick lookup? Or assume ID is enough

                        // Find same category products
                        // This is complex inside a transaction properly, let's just abort with specific structure
                        throw new BadRequestException({
                            error: 'STOCK_MISMATCH',
                            productId: itemRequest.productId,
                            message: error.message,
                            suggestion: 'Please query GET /catalog/recommendations?productId=...'
                        });
                    }
                    throw error;
                }
            }

            // 3. Save Order (Cascades to Items and Allocations)
            return manager.save(Order, order);
        });
    }


    /**
     * Creates a Van Sale order (Immediate delivery from Truck).
     */
    async createVanSale(driverId: string, data: { clientId: string, items: { productId: string, quantity: number, price: number }[] }): Promise<Order> {
        const warehouse = await this.warehouseService.getDriverWarehouse(driverId);
        if (!warehouse) throw new BadRequestException('Driver has no truck assigned');

        return this.dataSource.transaction(async (manager) => {

            // 1. Create Order Header
            const order = manager.create(Order, {
                status: OrderStatus.DELIVERED, // Immediate Delivery
                paymentStatus: PaymentStatus.PAID, // Immediate Payment
                warehouse: { id: warehouse.id },
                client: { id: data.clientId },
                paymentMethod: PaymentMethod.CASH,
                paidAmount: data.items.reduce((sum, i) => sum + (i.price * i.quantity), 0),
                totalAmount: data.items.reduce((sum, i) => sum + (i.price * i.quantity), 0),
                items: []
            });

            // 1.1 Update Client Debt (Use raw query for atomic increment)
            // For Van Sale, usually paid immediately, so Debt change is 0 (Total - Paid = 0).
            // But if PaymentStatus is PARTIAL or PENDING (credit), debt increases.
            // Here we assume PaymentStatus.PAID for simple Van Sale, so debt doesn't change.
            // But let's be robust:
            const debtChange = order.totalAmount - order.paidAmount;
            if (debtChange !== 0) {
                await manager.increment(User, { id: data.clientId }, 'currentDebt', debtChange);
            }

            // 2. Process Items (Deduct from Truck)
            for (const itemRequest of data.items) {
                // Check & Deduct Stock with OVERDRAFT = TRUE
                const deductedBatches = await this.warehouseService.deductStock(
                    warehouse.id,
                    itemRequest.productId,
                    itemRequest.quantity,
                    manager,
                    true // Allow Overdraft!
                );

                // Create Order Item
                const orderItem = manager.create(OrderItem, {
                    product: { id: itemRequest.productId },
                    quantity: itemRequest.quantity,
                    price: itemRequest.price,
                    total: itemRequest.quantity * itemRequest.price,
                    allocations: []
                });

                for (const batchAlloc of deductedBatches) {
                    const allocation = manager.create(OrderItemAllocation, {
                        batch: { id: batchAlloc.batchId },
                        quantity: batchAlloc.quantity
                    });
                    orderItem.allocations.push(allocation);
                }
                order.items.push(orderItem);
            }

            return manager.save(Order, order);
        });
    }

    async findAll(): Promise<Order[]> {
        return this.orderRepo.find({ relations: ['items', 'items.allocations', 'items.allocations.batch', 'client'] });
    }

    async findByClient(clientId: string): Promise<Order[]> {
        return this.orderRepo.find({
            where: { client: { id: clientId } },
            relations: ['items', 'items.product'],
            order: { createdAt: 'DESC' },
        });
    }

    async findById(id: string): Promise<Order | null> {
        return this.orderRepo.findOne({
            where: { id },
            relations: ['items', 'items.product', 'client', 'warehouse'],
        });
    }
}
