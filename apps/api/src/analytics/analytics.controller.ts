import { Controller, Get, Query, UseGuards } from '@nestjs/common';
import { ApiTags, ApiBearerAuth, ApiOperation, ApiResponse } from '@nestjs/swagger';
import { AnalyticsService, DateRange } from './analytics.service';
import { JwtAuthGuard } from '../auth/jwt.guard';
import { RolesGuard } from '../common/guards/roles.guard';
import { Roles } from '../common/decorators/roles.decorator';
import { UserRole } from '../users/user.entity';

@ApiTags('Analytics')
@ApiBearerAuth('JWT-auth')
@Controller('analytics')
@UseGuards(JwtAuthGuard, RolesGuard)
@Roles(UserRole.SUPER_ADMIN, UserRole.OWNER, UserRole.DIRECTOR, UserRole.ACCOUNTANT)
export class AnalyticsController {
    constructor(private readonly analyticsService: AnalyticsService) {}

    @Get('dashboard')
    async getDashboard(@Query() query: DateRange) {
        const [
            kpi,
            salesTrend,
            topProducts,
            topCustomers,
            driverPerformance,
        ] = await Promise.all([
            this.analyticsService.getKPI(query),
            this.analyticsService.getSalesTrend(query),
            this.analyticsService.getTopProducts(query, 10),
            this.analyticsService.getTopCustomers(query, 10),
            this.analyticsService.getDriverPerformance(query),
        ]);

        return {
            kpi,
            salesTrend,
            topProducts,
            topCustomers,
            driverPerformance,
        };
    }

    @Get('kpi')
    async getKPI(@Query() query: DateRange) {
        return this.analyticsService.getKPI(query);
    }

    @Get('sales-trend')
    async getSalesTrend(@Query() query: DateRange) {
        return this.analyticsService.getSalesTrend(query);
    }

    @Get('top-products')
    async getTopProducts(@Query() query: DateRange & { limit?: string }) {
        return this.analyticsService.getTopProducts(
            query,
            parseInt(query.limit || '10', 10)
        );
    }

    @Get('top-customers')
    async getTopCustomers(@Query() query: DateRange & { limit?: string }) {
        return this.analyticsService.getTopCustomers(
            query,
            parseInt(query.limit || '10', 10)
        );
    }

    @Get('driver-performance')
    async getDriverPerformance(@Query() query: DateRange) {
        return this.analyticsService.getDriverPerformance(query);
    }

    @Get('debt-report')
    async getDebtReport(@Query() query: DateRange & { minDebt?: string }) {
        return this.analyticsService.getDebtReport({
            ...query,
            minDebt: parseFloat(query.minDebt || '0'),
        });
    }

    @Get('inventory-status')
    async getInventoryStatus(@Query('warehouseId') warehouseId?: string) {
        return this.analyticsService.getInventoryStatus(warehouseId);
    }

    @Get('abc-analysis')
    async getABCAnalysis(@Query() query: DateRange) {
        return this.analyticsService.getABCAnalysis(query);
    }
}
