import { Controller, Post, Get, Body, Param, Query, UseGuards, ParseUUIDPipe } from '@nestjs/common';
import { ApiTags, ApiBearerAuth, ApiOperation, ApiResponse } from '@nestjs/swagger';
import { WarehouseService } from './warehouse.service';
import { InventoryCountService } from './inventory-count.service';
import { CurrentUser } from '../common/decorators/current-user.decorator';
import { RolesGuard } from '../common/guards/roles.guard';
import { JwtAuthGuard } from '../auth/jwt.guard';
import { Roles } from '../common/decorators/roles.decorator';
import { UserRole } from '../users/user.entity';

@ApiTags('Warehouse')
@ApiBearerAuth('JWT-auth')
@Controller('warehouse')
@UseGuards(JwtAuthGuard)
export class WarehouseController {
    constructor(
        private readonly warehouseService: WarehouseService,
        private readonly inventoryCountService: InventoryCountService,
    ) { }

    @Post(':id/receive')
    @UseGuards(RolesGuard)
    @Roles(UserRole.SUPER_ADMIN, UserRole.OWNER, UserRole.WAREHOUSE_MANAGER)
    async receiveGoods(
        @Param('id') warehouseId: string,
        @Body() body: { productId: string; quantity: number; purchasePrice: number; expirationDate?: Date }
    ) {
        return this.warehouseService.receiveGoods(
            warehouseId,
            body.productId,
            body.quantity,
            body.purchasePrice,
            body.expirationDate
        );
    }

    @Get(':id/stock')
    @UseGuards(RolesGuard)
    @Roles(UserRole.SUPER_ADMIN, UserRole.OWNER, UserRole.WAREHOUSE_MANAGER, UserRole.DIRECTOR, UserRole.SALES_REP)
    async getStock(@Param('id') warehouseId: string) {
        return this.warehouseService.getStock(warehouseId);
    }

    @Get('my')
    async getMyWarehouse(@CurrentUser() user: any) {
        // Return the warehouse assigned to this driver (Truck)
        return this.warehouseService.getDriverWarehouse(user.id);
    }

    @Get()
    @UseGuards(RolesGuard)
    @Roles(UserRole.SUPER_ADMIN, UserRole.OWNER, UserRole.DIRECTOR, UserRole.WAREHOUSE_MANAGER)
    async findAll() {
        return this.warehouseService.findAll();
    }

    @Get('batch/:batchId/print')
    @UseGuards(RolesGuard)
    @Roles(UserRole.SUPER_ADMIN, UserRole.OWNER, UserRole.WAREHOUSE_MANAGER)
    async printBatchLabel(@Param('batchId') batchId: string) {
        // In real app, this generates ZPL/PDF or sends to a printer queue
        return {
            command: 'PRINT',
            format: 'ZPL',
            data: `^XA^FO50,50^ADN,36,20^FD Batch: ${batchId}^FS^XZ`
        };
    }

    @Post('transfer')
    @UseGuards(RolesGuard)
    @Roles(UserRole.SUPER_ADMIN, UserRole.OWNER, UserRole.WAREHOUSE_MANAGER)
    async transferStock(@Body() body: { sourceId: string, targetId: string, items: { productId: string, quantity: number }[] }) {
        return this.warehouseService.transferStock(body.sourceId, body.targetId, body.items);
    }

    // ============ Inventory Count ============

    @Post('inventory-counts')
    @UseGuards(RolesGuard)
    @Roles(UserRole.SUPER_ADMIN, UserRole.OWNER, UserRole.WAREHOUSE_MANAGER)
    async createInventoryCount(
        @Body() body: { name: string; warehouseId: string; productIds?: string[]; notes?: string },
        @CurrentUser() user: any,
    ) {
        return this.inventoryCountService.createCount(body, user.userId);
    }

    @Get('inventory-counts')
    @UseGuards(RolesGuard)
    @Roles(UserRole.SUPER_ADMIN, UserRole.OWNER, UserRole.WAREHOUSE_MANAGER, UserRole.DIRECTOR)
    async getInventoryCounts(@Query('warehouseId') warehouseId?: string) {
        return this.inventoryCountService.findAll(warehouseId);
    }

    @Get('inventory-counts/:id')
    @UseGuards(RolesGuard)
    @Roles(UserRole.SUPER_ADMIN, UserRole.OWNER, UserRole.WAREHOUSE_MANAGER, UserRole.DIRECTOR)
    async getInventoryCount(@Param('id', ParseUUIDPipe) id: string) {
        return this.inventoryCountService.findOne(id);
    }

    @Post('inventory-counts/:id/start')
    @UseGuards(RolesGuard)
    @Roles(UserRole.SUPER_ADMIN, UserRole.OWNER, UserRole.WAREHOUSE_MANAGER)
    async startInventoryCount(@Param('id', ParseUUIDPipe) id: string) {
        return this.inventoryCountService.startCount(id);
    }

    @Post('inventory-counts/:id/submit')
    @UseGuards(RolesGuard)
    @Roles(UserRole.SUPER_ADMIN, UserRole.OWNER, UserRole.WAREHOUSE_MANAGER)
    async submitCounts(
        @Param('id', ParseUUIDPipe) id: string,
        @Body() body: { items: { itemId: string; actualQuantity: number; notes?: string }[] },
        @CurrentUser() user: any,
    ) {
        return this.inventoryCountService.submitCounts(id, body.items, user.userId);
    }

    @Post('inventory-counts/:id/complete')
    @UseGuards(RolesGuard)
    @Roles(UserRole.SUPER_ADMIN, UserRole.OWNER, UserRole.WAREHOUSE_MANAGER)
    async completeInventoryCount(
        @Param('id', ParseUUIDPipe) id: string,
        @CurrentUser() user: any,
    ) {
        return this.inventoryCountService.completeCount(id, user.userId);
    }

    @Get('inventory-counts/:id/summary')
    @UseGuards(RolesGuard)
    @Roles(UserRole.SUPER_ADMIN, UserRole.OWNER, UserRole.WAREHOUSE_MANAGER, UserRole.DIRECTOR)
    async getInventoryCountSummary(@Param('id', ParseUUIDPipe) id: string) {
        return this.inventoryCountService.getCountSummary(id);
    }

    @Post('inventory-counts/:id/cancel')
    @UseGuards(RolesGuard)
    @Roles(UserRole.SUPER_ADMIN, UserRole.OWNER, UserRole.WAREHOUSE_MANAGER)
    async cancelInventoryCount(@Param('id', ParseUUIDPipe) id: string) {
        return this.inventoryCountService.cancelCount(id);
    }
}
