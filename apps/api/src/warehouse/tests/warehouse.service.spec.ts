import { Test, TestingModule } from '@nestjs/testing';
import { WarehouseService } from '../warehouse.service';
import { DataSource, Repository, EntityManager } from 'typeorm';
import { Warehouse } from '../warehouse.entity';
import { Batch } from '../batch.entity';
import { Stock } from '../stock.entity';
import { Product } from '../../catalog/product.entity';
import { TENANT_CONNECTION } from '../../database/database.module';
import { BadRequestException } from '@nestjs/common';

describe('WarehouseService', () => {
    let service: WarehouseService;
    let dataSource: jest.Mocked<DataSource>;
    let mockWarehouseRepo: jest.Mocked<Repository<Warehouse>>;
    let mockBatchRepo: jest.Mocked<Repository<Batch>>;
    let mockStockRepo: jest.Mocked<Repository<Stock>>;
    let mockProductRepo: jest.Mocked<Repository<Product>>;
    let mockManager: jest.Mocked<EntityManager>;

    const mockWarehouse: Warehouse = {
        id: 'warehouse-1',
        name: 'Main Warehouse',
        type: 'MAIN',
        driver: null,
        address: null,
        isActive: true,
        createdAt: new Date(),
        updatedAt: new Date(),
    };

    const mockProduct: Product = {
        id: 'product-1',
        name: 'Test Product',
        sku: 'TEST-001',
        description: null,
        categoryId: 'category-1',
        basePrice: 100,
        productType: 'GOODS',
        unit: 'PCS',
        attributes: {},
        isActive: true,
        aiConfidence: null,
        aiKeywords: null,
        isVerified: true,
        createdAt: new Date(),
        updatedAt: new Date(),
    };

    const mockBatch: Batch = {
        id: 'batch-1',
        batchCode: 'BATCH-123',
        product: mockProduct,
        purchasePrice: 50,
        arrivalDate: new Date(),
        expirationDate: new Date(Date.now() + 30 * 24 * 60 * 60 * 1000), // 30 days from now
    };

    const mockStock: Stock = {
        id: 'stock-1',
        warehouse: mockWarehouse,
        product: mockProduct,
        batch: mockBatch,
        quantity: 100,
    };

    beforeEach(async () => {
        mockWarehouseRepo = {
            find: jest.fn(),
            findOne: jest.fn(),
            findOneBy: jest.fn(),
            save: jest.fn(),
            create: jest.fn(),
        } as any;

        mockBatchRepo = {
            findOne: jest.fn(),
            save: jest.fn(),
            create: jest.fn(),
        } as any;

        mockStockRepo = {
            find: jest.fn(),
            findOne: jest.fn(),
            save: jest.fn(),
            create: jest.fn(),
        } as any;

        mockProductRepo = {
            findOneBy: jest.fn(),
        } as any;

        mockManager = {
            findOne: jest.fn(),
            save: jest.fn(),
            create: jest.fn(),
            getRepository: jest.fn(),
            query: jest.fn(),
            increment: jest.fn(),
        } as any;

        dataSource = {
            getRepository: jest.fn((entity) => {
                if (entity === Warehouse) return mockWarehouseRepo;
                if (entity === Batch) return mockBatchRepo;
                if (entity === Stock) return mockStockRepo;
                if (entity === Product) return mockProductRepo;
                return {} as any;
            }),
            transaction: jest.fn(async (callback) => {
                return callback(mockManager);
            }),
        } as any;

        const module: TestingModule = await Test.createTestingModule({
            providers: [
                WarehouseService,
                {
                    provide: TENANT_CONNECTION,
                    useValue: dataSource,
                },
            ],
        }).compile();

        service = module.get<WarehouseService>(WarehouseService);
    });

    describe('findAll', () => {
        it('should return all warehouses', async () => {
            const warehouses = [mockWarehouse];
            mockWarehouseRepo.find.mockResolvedValue(warehouses);

            const result = await service.findAll();

            expect(result).toEqual(warehouses);
            expect(mockWarehouseRepo.find).toHaveBeenCalled();
        });
    });

    describe('receiveGoods', () => {
        it('should receive goods successfully', async () => {
            mockWarehouseRepo.findOneBy.mockResolvedValue(mockWarehouse);
            mockProductRepo.findOneBy.mockResolvedValue(mockProduct);
            mockManager.create.mockImplementation((entity, data) => data as any);
            mockManager.save.mockImplementation(async (entity, data) => ({
                id: 'new-batch-id',
                ...data,
            }));
            mockManager.findOne.mockResolvedValue(null); // No existing stock
            mockManager.query.mockResolvedValue([{ value: '3' }]);

            const result = await service.receiveGoods(
                'warehouse-1',
                'product-1',
                50,
                45,
                new Date(Date.now() + 60 * 24 * 60 * 60 * 1000)
            );

            expect(result).toBeDefined();
            expect(result.batch).toBeDefined();
            expect(result.stock).toBeDefined();
        });

        it('should throw BadRequestException when warehouse not found', async () => {
            mockWarehouseRepo.findOneBy.mockResolvedValue(null);

            await expect(
                service.receiveGoods('invalid-warehouse', 'product-1', 50, 45)
            ).rejects.toThrow(BadRequestException);
        });

        it('should throw BadRequestException when product not found', async () => {
            mockWarehouseRepo.findOneBy.mockResolvedValue(mockWarehouse);
            mockProductRepo.findOneBy.mockResolvedValue(null);

            await expect(
                service.receiveGoods('warehouse-1', 'invalid-product', 50, 45)
            ).rejects.toThrow(BadRequestException);
        });

        it('should throw BadRequestException when quantity is not positive', async () => {
            await expect(
                service.receiveGoods('warehouse-1', 'product-1', -10, 45)
            ).rejects.toThrow(BadRequestException);
        });

        it('should update existing stock quantity', async () => {
            mockWarehouseRepo.findOneBy.mockResolvedValue(mockWarehouse);
            mockProductRepo.findOneBy.mockResolvedValue(mockProduct);
            mockManager.create.mockImplementation((entity, data) => data as any);
            mockManager.save.mockImplementation(async (entity, data) => ({
                id: 'new-batch-id',
                ...data,
            }));
            mockManager.findOne.mockResolvedValue(mockStock); // Existing stock

            const result = await service.receiveGoods(
                'warehouse-1',
                'product-1',
                50,
                45
            );

            expect(result).toBeDefined();
            expect(result.stock.quantity).toBe(150); // 100 + 50
        });
    });

    describe('getStock', () => {
        it('should return stock for warehouse', async () => {
            mockStockRepo.find.mockResolvedValue([mockStock]);

            const result = await service.getStock('warehouse-1');

            expect(result).toEqual([mockStock]);
            expect(mockStockRepo.find).toHaveBeenCalledWith({
                where: { warehouse: { id: 'warehouse-1' } },
                relations: ['product', 'batch'],
            });
        });
    });

    describe('getDriverWarehouse', () => {
        it('should return warehouse for driver', async () => {
            mockWarehouseRepo.findOne.mockResolvedValue(mockWarehouse);

            const result = await service.getDriverWarehouse('driver-1');

            expect(result).toEqual(mockWarehouse);
        });

        it('should return null when driver has no warehouse', async () => {
            mockWarehouseRepo.findOne.mockResolvedValue(null);

            const result = await service.getDriverWarehouse('driver-without-warehouse');

            expect(result).toBeNull();
        });
    });

    describe('deductStock', () => {
        beforeEach(() => {
            mockManager.query.mockResolvedValue([{ value: '3' }]);
        });

        it('should deduct stock successfully with FEFO', async () => {
            const batch1 = { ...mockBatch, id: 'batch-1', expirationDate: new Date(Date.now() + 10 * 24 * 60 * 60 * 1000) };
            const batch2 = { ...mockBatch, id: 'batch-2', expirationDate: new Date(Date.now() + 20 * 24 * 60 * 60 * 1000) };
            
            mockManager.getRepository.mockReturnValue({
                find: jest.fn().mockResolvedValue([
                    { ...mockStock, batch: batch1, quantity: 30 },
                    { ...mockStock, batch: batch2, quantity: 50 },
                ]),
            } as any);
            mockManager.save.mockResolvedValue({});

            const result = await service.deductStock('warehouse-1', 'product-1', 40, mockManager);

            expect(result).toBeDefined();
            expect(result.length).toBeGreaterThan(0);
        });

        it('should throw error when insufficient stock', async () => {
            mockManager.getRepository.mockReturnValue({
                find: jest.fn().mockResolvedValue([
                    { ...mockStock, quantity: 10 },
                ]),
            } as any);

            await expect(
                service.deductStock('warehouse-1', 'product-1', 50, mockManager)
            ).rejects.toThrow('INSUFFICIENT_STOCK');
        });

        it('should allow overdraft when specified', async () => {
            mockManager.getRepository.mockReturnValue({
                find: jest.fn().mockResolvedValue([
                    { ...mockStock, quantity: 10 },
                ]),
            } as any);
            mockManager.save.mockResolvedValue({});

            const result = await service.deductStock(
                'warehouse-1',
                'product-1',
                50,
                mockManager,
                true // allow overdraft
            );

            expect(result).toBeDefined();
        });

        it('should throw BadRequestException when quantity is not positive', async () => {
            await expect(
                service.deductStock('warehouse-1', 'product-1', -10, mockManager)
            ).rejects.toThrow(BadRequestException);
        });
    });

    describe('transferStock', () => {
        it('should transfer stock between warehouses', async () => {
            const targetWarehouse = { ...mockWarehouse, id: 'warehouse-2' };
            
            mockManager.query.mockResolvedValue([{ value: '3' }]);
            mockManager.getRepository.mockReturnValue({
                find: jest.fn().mockResolvedValue([mockStock]),
            } as any);
            mockManager.findOne.mockImplementation(async (entity, options: any) => {
                if (options.where.id === 'warehouse-2') return targetWarehouse;
                if (options.where.id === 'product-1') return mockProduct;
                if (options.where.id === 'batch-1') return mockBatch;
                return null;
            });
            mockManager.save.mockResolvedValue({});

            await service.transferStock('warehouse-1', 'warehouse-2', [
                { productId: 'product-1', quantity: 20 },
            ]);

            expect(dataSource.transaction).toHaveBeenCalled();
        });
    });
});
