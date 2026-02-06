import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { Warehouse } from './warehouse.entity';
import { Batch } from './batch.entity';
import { Stock } from './stock.entity';
import { InventoryCount, InventoryCountItem } from './entities/inventory-count.entity';
import { WarehouseService } from './warehouse.service';
import { InventoryCountService } from './inventory-count.service';
import { WarehouseController } from './warehouse.controller';

@Module({
    imports: [TypeOrmModule.forFeature([
        Warehouse, 
        Batch, 
        Stock, 
        InventoryCount, 
        InventoryCountItem
    ])],
    controllers: [WarehouseController],
    providers: [WarehouseService, InventoryCountService],
    exports: [WarehouseService, InventoryCountService],
})
export class WarehouseModule { }
