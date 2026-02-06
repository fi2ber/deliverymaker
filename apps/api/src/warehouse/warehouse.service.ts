import { Injectable, BadRequestException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository, DataSource, LessThan, MoreThan, EntityManager } from 'typeorm';
import { Warehouse } from './warehouse.entity';
import { Product } from '../catalog/product.entity';
import { Batch } from './batch.entity';
import { Stock } from './stock.entity';
import { TENANT_CONNECTION } from '../database/database.module'; // Import injection token
import { Inject } from '@nestjs/common';

@Injectable()
export class WarehouseService {
    constructor(
        @Inject(TENANT_CONNECTION) private dataSource: DataSource,
    ) { }

    private get warehouseRepo() { return this.dataSource.getRepository(Warehouse); }
    private get batchRepo() { return this.dataSource.getRepository(Batch); }
    private get stockRepo() { return this.dataSource.getRepository(Stock); }
    private get productRepo() { return this.dataSource.getRepository(Product); }

    async findAll() {
        return this.warehouseRepo.find();
    }

    async receiveGoods(
        warehouseId: string,
        productId: string,
        quantity: number,
        purchasePrice: number,
        expirationDate?: Date
    ) {
        if (quantity <= 0) throw new BadRequestException('Quantity must be positive');

        // 1. Validate Warehouse & Product
        const warehouse = await this.warehouseRepo.findOneBy({ id: warehouseId });
        if (!warehouse) throw new BadRequestException('Warehouse not found');

        const product = await this.productRepo.findOneBy({ id: productId });
        if (!product) throw new BadRequestException('Product not found');

        return this.dataSource.transaction(async (manager) => {
            // 2. Create Batch
            const batch = manager.create(Batch, {
                product,
                purchasePrice,
                expirationDate,
                arrivalDate: new Date(),
                batchCode: `BATCH-${Date.now()}` // Simple generation
            });
            await manager.save(batch);

            // 3. Update Stock
            let stock = await manager.findOne(Stock, {
                where: { warehouse: { id: warehouseId }, product: { id: productId }, batch: { id: batch.id } }
            });

            if (!stock) {
                stock = manager.create(Stock, {
                    warehouse,
                    product,
                    batch,
                    quantity: 0
                });
            }

            stock.quantity = Number(stock.quantity) + Number(quantity);
            await manager.save(stock);

            return { batch, stock };
        });
    }

    async getStock(warehouseId: string) {
        return this.stockRepo.find({
            where: { warehouse: { id: warehouseId } },
            relations: ['product', 'batch']
        });
    }

    async getDriverWarehouse(driverId: string) {
        return this.warehouseRepo.findOne({
            where: { driver: { id: driverId } },
            relations: ['driver']
        });
    }

    /**
     * Deducts stock using FEFO (First Expired First Out) or FIFO logic.
     */
    /**
     * Deducts stock using FEFO (First Expired First Out) or FIFO logic.
     * @param allowOverdraft If true, allows stock to go negative (useful for Van Sales where goods are physically gone)
     */
    async deductStock(warehouseId: string, productId: string, quantity: number, transactionManager: EntityManager, allowOverdraft = false) {
        if (quantity <= 0) throw new BadRequestException('Quantity must be positive');

        const executeLogic = async (manager: EntityManager) => {
            // 0. Fetch Settings (Min Expiration Buffer)
            // In a real high-perf scenario, this should be cached or injected
            const settingRepo = manager.getRepository('SystemSetting');
            // We use string string table name or entity if imported. Let's assume table name 'system_settings' or better, dynamic query
            const bufferSetting = await manager.query(`SELECT value FROM system_settings WHERE key = 'expiration_buffer_days' LIMIT 1`);
            const bufferDays = bufferSetting.length > 0 ? parseInt(bufferSetting[0].value) : 3;

            // 1. Find all stocks for product type, sorted by Expiration (FEFO) then Arrival (FIFO)
            const minExpirationDate = new Date();
            minExpirationDate.setDate(minExpirationDate.getDate() + bufferDays);

            const stockRepo = manager.getRepository(Stock);
            const stocks = await stockRepo.find({
                where: {
                    warehouse: { id: warehouseId },
                    product: { id: productId },
                    quantity: MoreThan(0), // We only look at positive stock for deduction usually
                },
                relations: ['batch'],
                order: {
                    batch: {
                        expirationDate: 'ASC',
                        arrivalDate: 'ASC'
                    }
                },
                lock: { mode: 'pessimistic_write' } // CRITICAL: Prevent Race Conditions
            });

            // Filter Valid Batches (Not Expired & sufficient shelf life)
            const validStocks = stocks.filter(stock => {
                if (!stock.batch.expirationDate) return true; // Non-perishable
                return new Date(stock.batch.expirationDate) > minExpirationDate;
            });

            // Check total available
            const totalAvailable = validStocks.reduce((sum, s) => sum + Number(s.quantity), 0);

            if (totalAvailable < quantity) {
                if (allowOverdraft) {
                    // OVERDRAFT LOGIC:
                    // 1. Consume all valid stocks
                    // 2. If still needed, consume invalid/expired stocks? Or just create a negative entry?
                    // Simplified: We consume what we have, and then we need to record the deficit.
                    // However, 'deductedBatches' needs to return *something* for the order allocations.
                    // If we don't have a batch, we can't allocate a batch.
                    // Strategy: We will create a "Phantom Batch" or "Overdraft Stock" if real stock is missing.
                    // Or simpler: We deduct from the *last available batch* making it negative. 
                    // Or if NO stocks exist, we find ANY batch for this product (even 0 qty) and make it negative.

                    // Fallback: If no stocks found at all, we can't do much without creating a batch.
                    // Let's assume for Van Sales stock *should* be there, but maybe slightly off.
                    // If totalAvailable < quantity, we take all validStocks to 0.
                    // Then for the remainder, we try to take from invalidStocks?
                    // If absolutely nothing, we throw. Overdraft usually implies "we thought we had 5 but we have 4, take 5 anyway -> -1".

                    // Let's stick to: Take all valid stocks to 0. 
                    // AND if we still need more, pick the LAST valid stock (or first) and drive it negative.
                    // If no valid stocks exist, we can't support overdraft easily without creating a dummy batch.
                    if (validStocks.length === 0) {
                        throw new Error(`OVERDRAFT_FAILED: No batches available to drive negative.`);
                    }
                } else {
                    throw new Error(`INSUFFICIENT_STOCK:Req=${quantity},Avail=${totalAvailable}`);
                }
            }

            let remainingToDeduct = quantity;
            const deductedBatches = [];

            // Pass 1: Deduct from available positive stock
            for (const stock of validStocks) {
                if (remainingToDeduct <= 0) break;

                const currentStockQty = Number(stock.quantity);

                if (currentStockQty >= remainingToDeduct) {
                    // Enough in this batch
                    stock.quantity = currentStockQty - remainingToDeduct;
                    deductedBatches.push({ batchId: stock.batch.id, quantity: remainingToDeduct });
                    remainingToDeduct = 0;
                } else {
                    // Take all
                    stock.quantity = 0;
                    deductedBatches.push({ batchId: stock.batch.id, quantity: currentStockQty });
                    remainingToDeduct -= currentStockQty;
                }
                await manager.save(stock);
            }

            // Pass 2: Overdraft (if enabled and still remaining)
            if (allowOverdraft && remainingToDeduct > 0) {
                // Drive the LAST used stock negative
                // We know validStocks.length > 0 from check above
                const lastStock = validStocks[validStocks.length - 1];

                // We need to re-fetch or use the object? Use object.
                // It is already saved as 0 (probably) from Pass 1.
                // We subtract remaining. 0 - remaining = -remaining.
                lastStock.quantity = Number(lastStock.quantity) - remainingToDeduct;

                // Update the deduction record for this batch
                const lastDeduction = deductedBatches.find(d => d.batchId === lastStock.batch.id);
                if (lastDeduction) {
                    lastDeduction.quantity += remainingToDeduct;
                } else {
                    deductedBatches.push({ batchId: lastStock.batch.id, quantity: remainingToDeduct });
                }

                await manager.save(lastStock);
                remainingToDeduct = 0;
            }

            return deductedBatches;
        };

        if (transactionManager) {
            return executeLogic(transactionManager);
        } else {
            return this.dataSource.transaction(async (manager) => executeLogic(manager));
        }
    }

    /**
     * Transfers stock from one warehouse to another (e.g. Main -> Truck).
     */
    async transferStock(sourceId: string, targetId: string, items: { productId: string, quantity: number }[]) {
        return this.dataSource.transaction(async (manager) => {
            for (const item of items) {
                const deductedBatches = await this.deductStock(sourceId, item.productId, item.quantity, manager);

                const targetWarehouse = await manager.findOne(Warehouse, { where: { id: targetId } });
                const product = await manager.findOne(Product, { where: { id: item.productId } });

                if (!targetWarehouse || !product) throw new BadRequestException('Invalid target or product');

                for (const deduction of deductedBatches) {
                    const batch = await manager.findOne(Batch, { where: { id: deduction.batchId } });

                    let targetStock = await manager.findOne(Stock, {
                        where: { warehouse: { id: targetId }, product: { id: item.productId }, batch: { id: batch.id } }
                    });

                    if (!targetStock) {
                        targetStock = manager.create(Stock, {
                            warehouse: targetWarehouse,
                            product: product,
                            batch: batch,
                            quantity: 0
                        });
                    }

                    targetStock.quantity = Number(targetStock.quantity) + Number(deduction.quantity);
                    await manager.save(targetStock);
                }
            }
        });
    }
}
