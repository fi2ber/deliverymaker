import { Injectable, Logger } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository, Between } from 'typeorm';
import { Order, OrderStatus } from '../sales/order.entity';
import { Product } from '../catalog/product.entity';
import { Stock } from '../warehouse/stock.entity';

export interface DemandForecast {
    productId: string;
    productName: string;
    currentStock: number;
    avgDailySales: number;
    forecastNext7Days: number;
    forecastNext30Days: number;
    recommendedOrder: number;
    stockStatus: 'ok' | 'low' | 'critical' | 'overstock';
    confidence: number;
}

export interface StockAlert {
    type: 'low_stock' | 'overstock' | 'expiring';
    productId: string;
    productName: string;
    message: string;
    severity: 'info' | 'warning' | 'critical';
    action: string;
}

@Injectable()
export class ForecastingService {
    private readonly logger = new Logger(ForecastingService.name);

    constructor(
        @InjectRepository(Order)
        private orderRepo: Repository<Order>,
        @InjectRepository(Product)
        private productRepo: Repository<Product>,
        @InjectRepository(Stock)
        private stockRepo: Repository<Stock>,
    ) {}

    // Прогноз спроса на основе исторических данных
    async generateDemandForecast(warehouseId?: string): Promise<DemandForecast[]> {
        // Получаем все активные продукты
        const products = await this.productRepo.find({
            where: { isActive: true },
            relations: ['category'],
        });

        const forecasts: DemandForecast[] = [];

        for (const product of products) {
            try {
                // Получаем историю продаж за последние 90 дней
                const salesHistory = await this.getSalesHistory(product.id, 90);
                
                // Получаем текущий остаток
                const currentStock = await this.getCurrentStock(product.id, warehouseId);

                // Рассчитываем средние продажи
                const avgDailySales = this.calculateAverageDailySales(salesHistory);
                
                // Прогноз на 7 и 30 дней
                const forecast7Days = Math.round(avgDailySales * 7);
                const forecast30Days = Math.round(avgDailySales * 30);

                // Рекомендуемый заказ
                const safetyStock = Math.max(avgDailySales * 7, 10); // Минимум недельный запас
                const recommendedOrder = Math.max(0, forecast30Days + safetyStock - currentStock);

                // Определяем статус запаса
                const daysOfStock = avgDailySales > 0 ? currentStock / avgDailySales : 999;
                let stockStatus: DemandForecast['stockStatus'];
                if (daysOfStock < 3) stockStatus = 'critical';
                else if (daysOfStock < 7) stockStatus = 'low';
                else if (daysOfStock > 60) stockStatus = 'overstock';
                else stockStatus = 'ok';

                // Уверенность прогноза (на основе количества исторических данных)
                const confidence = Math.min(salesHistory.length / 30, 1) * 100;

                forecasts.push({
                    productId: product.id,
                    productName: product.name,
                    currentStock,
                    avgDailySales: Math.round(avgDailySales * 100) / 100,
                    forecastNext7Days: forecast7Days,
                    forecastNext30Days: forecast30Days,
                    recommendedOrder: Math.round(recommendedOrder),
                    stockStatus,
                    confidence: Math.round(confidence),
                });
            } catch (error) {
                this.logger.error(`Failed to forecast for product ${product.id}`, error);
            }
        }

        return forecasts.sort((a, b) => {
            // Сначала критические, потом по рекомендуемому заказу
            if (a.stockStatus === 'critical' && b.stockStatus !== 'critical') return -1;
            if (b.stockStatus === 'critical' && a.stockStatus !== 'critical') return 1;
            return b.recommendedOrder - a.recommendedOrder;
        });
    }

    // Умные алерты о запасах
    async generateStockAlerts(warehouseId?: string): Promise<StockAlert[]> {
        const alerts: StockAlert[] = [];
        const forecasts = await this.generateDemandForecast(warehouseId);

        for (const forecast of forecasts) {
            // Низкий запас
            if (forecast.stockStatus === 'critical') {
                alerts.push({
                    type: 'low_stock',
                    productId: forecast.productId,
                    productName: forecast.productName,
                    message: `Критический остаток: ${forecast.currentStock} ед. Рекомендуется заказать ${forecast.recommendedOrder} ед.`,
                    severity: 'critical',
                    action: 'Срочно заказать',
                });
            } else if (forecast.stockStatus === 'low') {
                alerts.push({
                    type: 'low_stock',
                    productId: forecast.productId,
                    productName: forecast.productName,
                    message: `Низкий остаток: ${forecast.currentStock} ед. Закажите ${forecast.recommendedOrder} ед.`,
                    severity: 'warning',
                    action: 'Заказать',
                });
            }

            // Избыточный запас
            if (forecast.stockStatus === 'overstock') {
                alerts.push({
                    type: 'overstock',
                    productId: forecast.productId,
                    productName: forecast.productName,
                    message: `Избыточный запас: ${forecast.currentStock} ед. (${Math.round(forecast.currentStock / forecast.avgDailySales)} дней). Рассмотрите акцию.`,
                    severity: 'info',
                    action: 'Провести акцию',
                });
            }
        }

        // Сортируем по важности
        const severityOrder = { critical: 0, warning: 1, info: 2 };
        return alerts.sort((a, b) => severityOrder[a.severity] - severityOrder[b.severity]);
    }

    // Точка заказа (Reorder Point) для товара
    async calculateReorderPoint(productId: string, leadTimeDays: number = 7): Promise<{
        reorderPoint: number;
        safetyStock: number;
        currentStock: number;
        shouldOrder: boolean;
    }> {
        const salesHistory = await this.getSalesHistory(productId, 60);
        const avgDailySales = this.calculateAverageDailySales(salesHistory);
        
        // Страховой запас (на 1.5 стандартных отклонения)
        const variance = this.calculateVariance(salesHistory.map(h => h.quantity));
        const safetyStock = Math.round(1.5 * Math.sqrt(variance) * Math.sqrt(leadTimeDays));
        
        // Точка заказа
        const reorderPoint = Math.round((avgDailySales * leadTimeDays) + safetyStock);
        
        const currentStock = await this.getCurrentStock(productId);
        
        return {
            reorderPoint,
            safetyStock,
            currentStock,
            shouldOrder: currentStock <= reorderPoint,
        };
    }

    // Сезонный анализ
    async getSeasonalTrends(productId: string): Promise<{
        dayOfWeek: { day: string; avgSales: number }[];
        monthly: { month: string; avgSales: number }[];
    }> {
        const sales = await this.orderRepo.createQueryBuilder('order')
            .innerJoin('order.items', 'item')
            .select([
                'EXTRACT(DOW FROM order.createdAt) as dayOfWeek',
                'EXTRACT(MONTH FROM order.createdAt) as month',
                'SUM(item.quantity) as quantity',
            ])
            .where('item.product.id = :productId', { productId })
            .andWhere('order.createdAt > :date', { date: new Date(Date.now() - 365 * 24 * 60 * 60 * 1000) })
            .andWhere('order.status NOT IN (:...excluded)', { excluded: [OrderStatus.CANCELLED, OrderStatus.RETURNED] })
            .groupBy('dayOfWeek, month')
            .getRawMany();

        const dayNames = ['Вс', 'Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб'];
        const monthNames = ['Янв', 'Фев', 'Мар', 'Апр', 'Май', 'Июн', 'Июл', 'Авг', 'Сен', 'Окт', 'Ноя', 'Дек'];

        const dayOfWeekMap = new Map<number, number[]>();
        const monthMap = new Map<number, number[]>();

        for (const row of sales) {
            const dow = parseInt(row.dayOfWeek);
            const month = parseInt(row.month);
            const qty = parseFloat(row.quantity);

            if (!dayOfWeekMap.has(dow)) dayOfWeekMap.set(dow, []);
            if (!monthMap.has(month)) monthMap.set(month, []);

            dayOfWeekMap.get(dow)!.push(qty);
            monthMap.get(month)!.push(qty);
        }

        return {
            dayOfWeek: Array.from(dayOfWeekMap.entries())
                .map(([day, quantities]) => ({
                    day: dayNames[day],
                    avgSales: quantities.reduce((a, b) => a + b, 0) / quantities.length,
                }))
                .sort((a, b) => dayNames.indexOf(a.day) - dayNames.indexOf(b.day)),
            monthly: Array.from(monthMap.entries())
                .map(([month, quantities]) => ({
                    month: monthNames[month - 1],
                    avgSales: quantities.reduce((a, b) => a + b, 0) / quantities.length,
                }))
                .sort((a, b) => monthNames.indexOf(a.month) - monthNames.indexOf(b.month)),
        };
    }

    // ============ Private Methods ============

    private async getSalesHistory(productId: string, days: number): Promise<{ date: Date; quantity: number }[]> {
        const startDate = new Date();
        startDate.setDate(startDate.getDate() - days);

        const result = await this.orderRepo.createQueryBuilder('order')
            .innerJoin('order.items', 'item')
            .select([
                'DATE(order.createdAt) as date',
                'SUM(item.quantity) as quantity',
            ])
            .where('item.product.id = :productId', { productId })
            .andWhere('order.createdAt >= :startDate', { startDate })
            .andWhere('order.status NOT IN (:...excluded)', { excluded: [OrderStatus.CANCELLED, OrderStatus.RETURNED] })
            .groupBy('DATE(order.createdAt)')
            .orderBy('date', 'ASC')
            .getRawMany();

        return result.map(row => ({
            date: new Date(row.date),
            quantity: parseFloat(row.quantity) || 0,
        }));
    }

    private async getCurrentStock(productId: string, warehouseId?: string): Promise<number> {
        const query = this.stockRepo.createQueryBuilder('stock')
            .select('SUM(stock.quantity)', 'total')
            .where('stock.product.id = :productId', { productId });

        if (warehouseId) {
            query.andWhere('stock.warehouse.id = :warehouseId', { warehouseId });
        }

        const result = await query.getRawOne();
        return parseFloat(result?.total || 0);
    }

    private calculateAverageDailySales(history: { date: Date; quantity: number }[]): number {
        if (history.length === 0) return 0;
        const total = history.reduce((sum, h) => sum + h.quantity, 0);
        return total / 90; // Среднее за 90 дней
    }

    private calculateVariance(values: number[]): number {
        if (values.length === 0) return 0;
        const mean = values.reduce((a, b) => a + b, 0) / values.length;
        const squaredDiffs = values.map(v => Math.pow(v - mean, 2));
        return squaredDiffs.reduce((a, b) => a + b, 0) / values.length;
    }
}
