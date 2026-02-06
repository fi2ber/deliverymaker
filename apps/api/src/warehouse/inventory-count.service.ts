import { Injectable, NotFoundException, BadRequestException } from '@nestjs/common';
import { Inject } from '@nestjs/common';
import { DataSource, In } from 'typeorm';
import { TENANT_CONNECTION } from '../database/database.module';
import { 
    InventoryCount, 
    InventoryCountItem, 
    InventoryCountStatus 
} from './entities/inventory-count.entity';
import { Stock } from './stock.entity';

export interface CreateInventoryCountDto {
    name: string;
    warehouseId: string;
    productIds?: string[]; // If empty, all products
    notes?: string;
}

export interface CountItemDto {
    itemId: string;
    actualQuantity: number;
    notes?: string;
}

@Injectable()
export class InventoryCountService {
    constructor(
        @Inject(TENANT_CONNECTION) private dataSource: DataSource,
    ) { }

    private get countRepo() { 
        return this.dataSource.getRepository(InventoryCount); 
    }

    private get countItemRepo() { 
        return this.dataSource.getRepository(InventoryCountItem); 
    }

    private get stockRepo() {
        return this.dataSource.getRepository(Stock);
    }

    /**
     * Create new inventory count
     */
    async createCount(
        dto: CreateInventoryCountDto, 
        userId: string
    ): Promise<InventoryCount> {
        const queryRunner = this.dataSource.createQueryRunner();
        await queryRunner.connect();
        await queryRunner.startTransaction();

        try {
            // Create count header
            const count = this.countRepo.create({
                name: dto.name,
                warehouse: { id: dto.warehouseId },
                status: InventoryCountStatus.DRAFT,
                createdBy: { id: userId },
                notes: dto.notes,
            });

            const savedCount = await queryRunner.manager.save(count);

            // Get products to count
            let stocks: Stock[];
            if (dto.productIds && dto.productIds.length > 0) {
                stocks = await queryRunner.manager.find(Stock, {
                    where: { warehouse: { id: dto.warehouseId }, product: { id: In(dto.productIds) } },
                    relations: ['product'],
                });
            } else {
                stocks = await queryRunner.manager.find(Stock, {
                    where: { warehouse: { id: dto.warehouseId } },
                    relations: ['product'],
                });
            }

            // Create count items
            const countItems = stocks.map(stock => {
                return this.countItemRepo.create({
                    inventoryCount: savedCount,
                    productId: stock.product.id,
                    productName: stock.product.name,
                    expectedQuantity: stock.quantity,
                    actualQuantity: null,
                    difference: null,
                });
            });

            await queryRunner.manager.save(countItems);
            await queryRunner.commitTransaction();

            return this.countRepo.findOne({
                where: { id: savedCount.id },
                relations: ['items', 'warehouse', 'createdBy'],
            });
        } catch (error) {
            await queryRunner.rollbackTransaction();
            throw error;
        } finally {
            await queryRunner.release();
        }
    }

    /**
     * Start inventory count
     */
    async startCount(countId: string): Promise<InventoryCount> {
        const count = await this.countRepo.findOne({
            where: { id: countId },
            relations: ['items'],
        });

        if (!count) {
            throw new NotFoundException('Inventory count not found');
        }

        if (count.status !== InventoryCountStatus.DRAFT) {
            throw new BadRequestException('Count can only be started from DRAFT status');
        }

        count.status = InventoryCountStatus.IN_PROGRESS;
        count.startedAt = new Date();

        return this.countRepo.save(count);
    }

    /**
     * Submit count for items
     */
    async submitCounts(
        countId: string, 
        items: CountItemDto[], 
        userId: string
    ): Promise<InventoryCount> {
        const count = await this.countRepo.findOne({
            where: { id: countId },
            relations: ['items'],
        });

        if (!count) {
            throw new NotFoundException('Inventory count not found');
        }

        if (count.status !== InventoryCountStatus.IN_PROGRESS) {
            throw new BadRequestException('Count is not in progress');
        }

        // Update each item
        for (const itemDto of items) {
            const item = count.items.find(i => i.id === itemDto.itemId);
            if (!item) continue;

            item.actualQuantity = itemDto.actualQuantity;
            item.difference = itemDto.actualQuantity - Number(item.expectedQuantity);
            item.countedBy = { id: userId } as any;
            item.countedAt = new Date();
            item.notes = itemDto.notes;
        }

        await this.countItemRepo.save(count.items);

        return this.countRepo.findOne({
            where: { id: countId },
            relations: ['items', 'warehouse', 'createdBy'],
        });
    }

    /**
     * Complete inventory count and apply adjustments
     */
    async completeCount(countId: string, userId: string): Promise<InventoryCount> {
        const count = await this.countRepo.findOne({
            where: { id: countId },
            relations: ['items', 'warehouse'],
        });

        if (!count) {
            throw new NotFoundException('Inventory count not found');
        }

        if (count.status !== InventoryCountStatus.IN_PROGRESS) {
            throw new BadRequestException('Count must be in progress to complete');
        }

        // Check if all items are counted
        const uncountedItems = count.items.filter(i => i.actualQuantity === null);
        if (uncountedItems.length > 0) {
            throw new BadRequestException(
                `${uncountedItems.length} items still need to be counted`
            );
        }

        const queryRunner = this.dataSource.createQueryRunner();
        await queryRunner.connect();
        await queryRunner.startTransaction();

        try {
            // Apply stock adjustments
            for (const item of count.items) {
                if (item.difference !== 0) {
                    // Get current stock
                    const stock = await queryRunner.manager.findOne(Stock, {
                        where: { 
                            warehouse: { id: count.warehouse.id },
                            product: { id: item.productId }
                        },
                    });

                    if (stock) {
                        stock.quantity = item.actualQuantity;
                        await queryRunner.manager.save(stock);
                    }
                }
            }

            // Mark count as completed
            count.status = InventoryCountStatus.COMPLETED;
            count.completedBy = { id: userId } as any;
            count.completedAt = new Date();

            await queryRunner.manager.save(count);
            await queryRunner.commitTransaction();

            return this.countRepo.findOne({
                where: { id: countId },
                relations: ['items', 'warehouse', 'createdBy', 'completedBy'],
            });
        } catch (error) {
            await queryRunner.rollbackTransaction();
            throw error;
        } finally {
            await queryRunner.release();
        }
    }

    /**
     * Get count summary with discrepancies
     */
    async getCountSummary(countId: string) {
        const count = await this.countRepo.findOne({
            where: { id: countId },
            relations: ['items', 'warehouse'],
        });

        if (!count) {
            throw new NotFoundException('Inventory count not found');
        }

        const totalItems = count.items.length;
        const countedItems = count.items.filter(i => i.actualQuantity !== null).length;
        const discrepancies = count.items.filter(i => i.difference !== 0);
        const totalDiscrepancyValue = discrepancies.reduce(
            (sum, item) => sum + (Number(item.difference) || 0), 
            0
        );

        return {
            id: count.id,
            name: count.name,
            status: count.status,
            warehouse: count.warehouse,
            summary: {
                totalItems,
                countedItems,
                remainingItems: totalItems - countedItems,
                discrepanciesCount: discrepancies.length,
                totalDiscrepancyValue,
            },
            itemsWithDiscrepancies: discrepancies.map(i => ({
                productId: i.productId,
                productName: i.productName,
                expected: i.expectedQuantity,
                actual: i.actualQuantity,
                difference: i.difference,
            })),
        };
    }

    /**
     * Get all inventory counts
     */
    async findAll(warehouseId?: string): Promise<InventoryCount[]> {
        const where: any = {};
        if (warehouseId) {
            where.warehouse = { id: warehouseId };
        }

        return this.countRepo.find({
            where,
            relations: ['warehouse', 'createdBy', 'completedBy'],
            order: { createdAt: 'DESC' },
        });
    }

    /**
     * Get single count with items
     */
    async findOne(id: string): Promise<InventoryCount> {
        const count = await this.countRepo.findOne({
            where: { id },
            relations: ['items', 'warehouse', 'createdBy', 'completedBy'],
        });

        if (!count) {
            throw new NotFoundException('Inventory count not found');
        }

        return count;
    }

    /**
     * Cancel inventory count
     */
    async cancelCount(countId: string): Promise<InventoryCount> {
        const count = await this.countRepo.findOne({ where: { id: countId } });
        
        if (!count) {
            throw new NotFoundException('Inventory count not found');
        }

        if (count.status === InventoryCountStatus.COMPLETED) {
            throw new BadRequestException('Cannot cancel completed count');
        }

        count.status = InventoryCountStatus.CANCELLED;
        return this.countRepo.save(count);
    }

    /**
     * Mark items for recount
     */
    async markForRecount(countId: string, itemIds: string[]): Promise<void> {
        await this.countItemRepo.update(
            { id: In(itemIds), inventoryCount: { id: countId } },
            { isRecount: true, actualQuantity: null, difference: null }
        );
    }
}
