import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository, Between } from 'typeorm';
import { Order, OrderStatus } from '../sales/order.entity';
import { Product } from '../catalog/product.entity';
import { User } from '../users/user.entity';
import { Warehouse } from '../warehouse/warehouse.entity';

export interface DateRange {
    startDate?: string;
    endDate?: string;
}

@Injectable()
export class AnalyticsService {
    constructor(
        @InjectRepository(Order)
        private orderRepo: Repository<Order>,
        @InjectRepository(Product)
        private productRepo: Repository<Product>,
        @InjectRepository(User)
        private userRepo: Repository<User>,
        @InjectRepository(Warehouse)
        private warehouseRepo: Repository<Warehouse>,
    ) {}

    private getDateRange(range: DateRange): { start: Date; end: Date } {
        const end = range.endDate ? new Date(range.endDate) : new Date();
        const start = range.startDate 
            ? new Date(range.startDate) 
            : new Date(end.getTime() - 30 * 24 * 60 * 60 * 1000); // 30 days default
        
        return { start, end };
    }

    // KPI показатели
    async getKPI(range: DateRange) {
        const { start, end } = this.getDateRange(range);

        const [currentPeriod, previousPeriod, totalCustomers, totalProducts] = await Promise.all([
            this.orderRepo.createQueryBuilder('order')
                .select([
                    'COUNT(*) as totalOrders',
                    'SUM(order.totalAmount) as totalRevenue',
                    'AVG(order.totalAmount) as avgOrderValue',
                ])
                .where('order.createdAt BETWEEN :start AND :end', { start, end })
                .andWhere('order.status NOT IN (:...excluded)', { excluded: [OrderStatus.CANCELLED, OrderStatus.RETURNED] })
                .getRawOne(),
            
            this.orderRepo.createQueryBuilder('order')
                .select([
                    'COUNT(*) as totalOrders',
                    'SUM(order.totalAmount) as totalRevenue',
                ])
                .where('order.createdAt BETWEEN :prevStart AND :prevEnd', {
                    prevStart: new Date(start.getTime() - (end.getTime() - start.getTime())),
                    prevEnd: start,
                })
                .andWhere('order.status NOT IN (:...excluded)', { excluded: [OrderStatus.CANCELLED, OrderStatus.RETURNED] })
                .getRawOne(),

            this.userRepo.count(),
            this.productRepo.count({ where: { isActive: true } }),
        ]);

        const revenueChange = previousPeriod.totalRevenue 
            ? ((parseFloat(currentPeriod.totalRevenue || 0) - parseFloat(previousPeriod.totalRevenue)) / parseFloat(previousPeriod.totalRevenue) * 100)
            : 0;

        const ordersChange = previousPeriod.totalOrders
            ? ((parseInt(currentPeriod.totalOrders || 0) - parseInt(previousPeriod.totalOrders)) / parseInt(previousPeriod.totalOrders) * 100)
            : 0;

        return {
            totalRevenue: parseFloat(currentPeriod.totalRevenue || 0),
            totalOrders: parseInt(currentPeriod.totalOrders || 0),
            avgOrderValue: parseFloat(currentPeriod.avgOrderValue || 0),
            totalCustomers,
            totalProducts,
            revenueChange: Math.round(revenueChange * 100) / 100,
            ordersChange: Math.round(ordersChange * 100) / 100,
            periodDays: Math.round((end.getTime() - start.getTime()) / (1000 * 60 * 60 * 24)),
        };
    }

    // Динамика продаж по дням
    async getSalesTrend(range: DateRange) {
        const { start, end } = this.getDateRange(range);

        const data = await this.orderRepo.createQueryBuilder('order')
            .select([
                'DATE(order.createdAt) as date',
                'COUNT(*) as orders',
                'SUM(order.totalAmount) as revenue',
            ])
            .where('order.createdAt BETWEEN :start AND :end', { start, end })
            .andWhere('order.status NOT IN (:...excluded)', { excluded: [OrderStatus.CANCELLED, OrderStatus.RETURNED] })
            .groupBy('DATE(order.createdAt)')
            .orderBy('date', 'ASC')
            .getRawMany();

        return data.map(row => ({
            date: row.date,
            orders: parseInt(row.orders),
            revenue: parseFloat(row.revenue),
        }));
    }

    // Топ товаров
    async getTopProducts(range: DateRange, limit: number = 10) {
        const { start, end } = this.getDateRange(range);

        const data = await this.orderRepo.createQueryBuilder('order')
            .innerJoin('order.items', 'item')
            .innerJoin('item.product', 'product')
            .select([
                'product.id as productId',
                'product.name as productName',
                'product.sku as sku',
                'SUM(item.quantity) as quantitySold',
                'SUM(item.total) as revenue',
                'COUNT(DISTINCT order.id) as orderCount',
            ])
            .where('order.createdAt BETWEEN :start AND :end', { start, end })
            .andWhere('order.status NOT IN (:...excluded)', { excluded: [OrderStatus.CANCELLED, OrderStatus.RETURNED] })
            .groupBy('product.id, product.name, product.sku')
            .orderBy('revenue', 'DESC')
            .limit(limit)
            .getRawMany();

        return data.map(row => ({
            id: row.productId,
            name: row.productName,
            sku: row.sku,
            quantitySold: parseFloat(row.quantitySold),
            revenue: parseFloat(row.revenue),
            orderCount: parseInt(row.orderCount),
        }));
    }

    // Топ клиентов
    async getTopCustomers(range: DateRange, limit: number = 10) {
        const { start, end } = this.getDateRange(range);

        const data = await this.orderRepo.createQueryBuilder('order')
            .innerJoin('order.client', 'client')
            .select([
                'client.id as clientId',
                'client.fullName as clientName',
                'client.email as email',
                'COUNT(*) as orderCount',
                'SUM(order.totalAmount) as totalSpent',
                'AVG(order.totalAmount) as avgOrderValue',
            ])
            .where('order.createdAt BETWEEN :start AND :end', { start, end })
            .andWhere('order.status NOT IN (:...excluded)', { excluded: [OrderStatus.CANCELLED, OrderStatus.RETURNED] })
            .groupBy('client.id, client.fullName, client.email')
            .orderBy('totalSpent', 'DESC')
            .limit(limit)
            .getRawMany();

        return data.map(row => ({
            id: row.clientId,
            name: row.clientName,
            email: row.email,
            orderCount: parseInt(row.orderCount),
            totalSpent: parseFloat(row.totalSpent),
            avgOrderValue: parseFloat(row.avgOrderValue),
        }));
    }

    // Эффективность водителей
    async getDriverPerformance(range: DateRange) {
        const { start, end } = this.getDateRange(range);

        const data = await this.orderRepo.createQueryBuilder('order')
            .innerJoin('order.driver', 'driver')
            .select([
                'driver.id as driverId',
                'driver.fullName as driverName',
                'COUNT(*) as deliveries',
                'SUM(order.totalAmount) as totalDelivered',
                'AVG(order.totalAmount) as avgDeliveryValue',
            ])
            .where('order.createdAt BETWEEN :start AND :end', { start, end })
            .andWhere('order.status = :status', { status: OrderStatus.DELIVERED })
            .groupBy('driver.id, driver.fullName')
            .orderBy('deliveries', 'DESC')
            .getRawMany();

        return data.map(row => ({
            id: row.driverId,
            name: row.driverName,
            deliveries: parseInt(row.deliveries),
            totalDelivered: parseFloat(row.totalDelivered),
            avgDeliveryValue: parseFloat(row.avgDeliveryValue),
        }));
    }

    // Отчет по дебиторской задолженности
    async getDebtReport(params: DateRange & { minDebt: number }) {
        const { minDebt } = params;

        const data = await this.userRepo.createQueryBuilder('user')
            .select([
                'user.id as clientId',
                'user.fullName as clientName',
                'user.email as email',
                'user.phone as phone',
                'user.currentDebt as debt',
            ])
            .where('user.currentDebt > :minDebt', { minDebt })
            .orderBy('user.currentDebt', 'DESC')
            .getRawMany();

        const totalDebt = data.reduce((sum, row) => sum + parseFloat(row.debt), 0);

        return {
            clients: data.map(row => ({
                id: row.clientId,
                name: row.clientName,
                email: row.email,
                phone: row.phone,
                debt: parseFloat(row.debt),
            })),
            totalDebt,
            count: data.length,
        };
    }

    // Статус инвентаря
    async getInventoryStatus(warehouseId?: string) {
        const query = this.warehouseRepo.createQueryBuilder('warehouse')
            .leftJoin('warehouse.stock', 'stock')
            .leftJoin('stock.product', 'product')
            .select([
                'warehouse.id as warehouseId',
                'warehouse.name as warehouseName',
                'product.id as productId',
                'product.name as productName',
                'product.sku as sku',
                'SUM(stock.quantity) as quantity',
            ])
            .groupBy('warehouse.id, warehouse.name, product.id, product.name, product.sku');

        if (warehouseId) {
            query.where('warehouse.id = :warehouseId', { warehouseId });
        }

        const data = await query.getRawMany();

        return data.map(row => ({
            warehouseId: row.warehouseId,
            warehouseName: row.warehouseName,
            productId: row.productId,
            productName: row.productName,
            sku: row.sku,
            quantity: parseFloat(row.quantity || 0),
        }));
    }

    // ABC-анализ
    async getABCAnalysis(range: DateRange) {
        const { start, end } = this.getDateRange(range);

        const products = await this.orderRepo.createQueryBuilder('order')
            .innerJoin('order.items', 'item')
            .innerJoin('item.product', 'product')
            .select([
                'product.id as productId',
                'product.name as productName',
                'SUM(item.total) as revenue',
            ])
            .where('order.createdAt BETWEEN :start AND :end', { start, end })
            .andWhere('order.status NOT IN (:...excluded)', { excluded: [OrderStatus.CANCELLED, OrderStatus.RETURNED] })
            .groupBy('product.id, product.name')
            .orderBy('revenue', 'DESC')
            .getRawMany();

        const totalRevenue = products.reduce((sum, p) => sum + parseFloat(p.revenue), 0);
        let cumulativeRevenue = 0;

        const withABC = products.map(p => {
            const revenue = parseFloat(p.revenue);
            cumulativeRevenue += revenue;
            const cumulativeShare = (cumulativeRevenue / totalRevenue) * 100;
            
            let category: 'A' | 'B' | 'C';
            if (cumulativeShare <= 80) category = 'A';
            else if (cumulativeShare <= 95) category = 'B';
            else category = 'C';

            return {
                id: p.productId,
                name: p.productName,
                revenue,
                share: (revenue / totalRevenue) * 100,
                cumulativeShare,
                category,
            };
        });

        return {
            products: withABC,
            summary: {
                totalProducts: products.length,
                categoryA: withABC.filter(p => p.category === 'A').length,
                categoryB: withABC.filter(p => p.category === 'B').length,
                categoryC: withABC.filter(p => p.category === 'C').length,
                totalRevenue,
            },
        };
    }
}
