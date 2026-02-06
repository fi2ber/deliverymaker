import { Controller, Get, Post, Query, Body, Param, UseGuards } from '@nestjs/common';
import { ApiTags, ApiBearerAuth, ApiOperation, ApiResponse } from '@nestjs/swagger';
import { ForecastingService, DemandForecast, StockAlert } from './forecasting.service';
import { ProductAIService } from '../catalog/product-ai.service';
import { JwtAuthGuard } from '../auth/jwt.guard';
import { RolesGuard } from '../common/guards/roles.guard';
import { Roles } from '../common/decorators/roles.decorator';
import { UserRole } from '../users/user.entity';

@ApiTags('AI')
@ApiBearerAuth('JWT-auth')
@Controller('ai')
@UseGuards(JwtAuthGuard, RolesGuard)
@Roles(UserRole.SUPER_ADMIN, UserRole.OWNER, UserRole.DIRECTOR, UserRole.WAREHOUSE_MANAGER)
export class AiController {
    constructor(
        private readonly forecastingService: ForecastingService,
        private readonly productAIService: ProductAIService,
    ) {}

    // Прогноз спроса
    @Get('forecast/demand')
    async getDemandForecast(
        @Query('warehouseId') warehouseId?: string,
        @Query('days') days?: string,
    ): Promise<DemandForecast[]> {
        return this.forecastingService.generateDemandForecast(warehouseId);
    }

    // Прогноз спроса для конкретного товара
    @Get('forecast/demand/:productId')
    async getProductForecast(
        @Param('productId') productId: string,
        @Query('days') days?: string,
    ): Promise<DemandForecast | null> {
        const forecasts = await this.forecastingService.generateDemandForecast();
        const forecast = forecasts.find(f => f.productId === productId);
        return forecast || null;
    }

    // Алерты о запасах
    @Get('alerts/stock')
    async getStockAlerts(@Query('warehouseId') warehouseId?: string): Promise<StockAlert[]> {
        return this.forecastingService.generateStockAlerts(warehouseId);
    }

    // Точка заказа для конкретного товара
    @Get('reorder-point/:productId')
    async getReorderPoint(
        @Query('productId') productId: string,
        @Query('leadTime') leadTimeDays?: string,
    ) {
        return this.forecastingService.calculateReorderPoint(
            productId,
            parseInt(leadTimeDays || '7', 10)
        );
    }

    // Сезонные тренды
    @Get('seasonal/:productId')
    async getSeasonalTrends(@Query('productId') productId: string) {
        return this.forecastingService.getSeasonalTrends(productId);
    }

    // Умные рекомендации (комбинированные)
    @Get('recommendations')
    async getRecommendations(@Query('warehouseId') warehouseId?: string) {
        return this.getPurchasesRecommendations(warehouseId);
    }

    // Рекомендации по закупкам
    @Get('recommendations/purchases')
    async getPurchasesRecommendations(@Query('warehouseId') warehouseId?: string) {
        const [forecast, alerts] = await Promise.all([
            this.forecastingService.generateDemandForecast(warehouseId),
            this.forecastingService.generateStockAlerts(warehouseId),
        ]);

        // Критичные товары для заказа
        const criticalToOrder = forecast
            .filter(f => f.stockStatus === 'critical' || f.stockStatus === 'low')
            .slice(0, 10);

        // Неликвидные товары
        const overstock = forecast
            .filter(f => f.stockStatus === 'overstock')
            .slice(0, 10);

        // Высокая уверенность прогноза
        const highConfidence = forecast
            .filter(f => f.confidence > 80)
            .sort((a, b) => b.forecastNext30Days - a.forecastNext30Days)
            .slice(0, 10);

        // Товары для заказа (с низким запасом)
        const shouldOrder = forecast
            .filter(f => f.stockStatus === 'low' && f.recommendedOrder > 0)
            .map(f => ({
                productId: f.productId,
                productName: f.productName,
                currentStock: f.currentStock,
                forecastNext7Days: f.forecastNext7Days,
                recommendedOrder: f.recommendedOrder,
                confidence: f.confidence,
            }));

        // Формат неликвидов для фронтенда
        const overstockItems = overstock.map(f => ({
            productId: f.productId,
            productName: f.productName,
            currentStock: f.currentStock,
            avgDailySales: f.avgDailySales,
            daysUntilStockout: f.avgDailySales > 0 ? Math.round(f.currentStock / f.avgDailySales) : 999,
            excessAmount: f.currentStock - (f.forecastNext30Days * 2), // Избыток сверх 2-месячной нормы
        }));

        return {
            criticalToOrder: criticalToOrder.map(f => ({
                productId: f.productId,
                productName: f.productName,
                currentStock: f.currentStock,
                forecastNext7Days: f.forecastNext7Days,
                recommendedOrder: f.recommendedOrder,
                confidence: f.confidence,
            })),
            shouldOrder,
            overstock: overstockItems,
            highConfidence,
            alerts: alerts.slice(0, 20),
            summary: {
                totalProducts: forecast.length,
                criticalCount: forecast.filter(f => f.stockStatus === 'critical').length,
                lowCount: forecast.filter(f => f.stockStatus === 'low').length,
                okCount: forecast.filter(f => f.stockStatus === 'ok').length,
                overstockCount: forecast.filter(f => f.stockStatus === 'overstock').length,
                totalRecommendedOrderValue: criticalToOrder.reduce((sum, f) => sum + (f.recommendedOrder * 1000), 0), // Условная цена
            },
            generatedAt: new Date().toISOString(),
        };
    }
}
