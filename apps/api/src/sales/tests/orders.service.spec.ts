import { Test, TestingModule } from '@nestjs/testing';
import { OrdersService } from '../orders.service';
import { DataSource, Repository } from 'typeorm';
import { Order, OrderStatus, PaymentMethod } from '../order.entity';
import { WarehouseService } from '../../warehouse/warehouse.service';
import { TENANT_CONNECTION } from '../../database/database.module';
import { ForbiddenException, BadRequestException } from '@nestjs/common';

describe('OrdersService', () => {
    let service: OrdersService;
    let dataSource: jest.Mocked<DataSource>;
    let warehouseService: jest.Mocked<WarehouseService>;
    let mockOrderRepo: jest.Mocked<Repository<Order>>;
    let mockManager: any;

    const mockWarehouse = {
        id: 'warehouse-1',
        name: 'Main Warehouse',
    };

    const mockUser = {
        id: 'user-1',
        fullName: 'Test User',
        currentDebt: 0,
    };

    const mockOrder = {
        id: 'order-1',
        status: OrderStatus.CONFIRMED,
        client: mockUser,
        warehouse: mockWarehouse,
        items: [],
        totalAmount: 1000,
        paidAmount: 0,
        paymentMethod: PaymentMethod.CASH,
    };

    beforeEach(async () => {
        mockOrderRepo = {
            find: jest.fn(),
            findOne: jest.fn(),
            createQueryBuilder: jest.fn(() => ({
                select: jest.fn().mockReturnThis(),
                where: jest.fn().mockReturnThis(),
                andWhere: jest.fn().mockReturnThis(),
                getRawOne: jest.fn(),
            })),
            save: jest.fn(),
            create: jest.fn(),
        } as any;

        mockManager = {
            create: jest.fn((entity, data) => ({ ...data, id: 'new-id' })),
            save: jest.fn(async (entity, data) => ({ ...data, id: 'saved-id' })),
            findOne: jest.fn(),
            increment: jest.fn(),
            getRepository: jest.fn(() => mockOrderRepo),
        };

        dataSource = {
            getRepository: jest.fn(() => mockOrderRepo),
            transaction: jest.fn(async (callback) => callback(mockManager)),
        } as any;

        warehouseService = {
            deductStock: jest.fn(),
            getDriverWarehouse: jest.fn(),
        } as any;

        const module: TestingModule = await Test.createTestingModule({
            providers: [
                OrdersService,
                {
                    provide: TENANT_CONNECTION,
                    useValue: dataSource,
                },
                {
                    provide: WarehouseService,
                    useValue: warehouseService,
                },
            ],
        }).compile();

        service = module.get<OrdersService>(OrdersService);
    });

    describe('getDebt', () => {
        it('should calculate client debt correctly', async () => {
            const mockQueryBuilder = {
                select: jest.fn().mockReturnThis(),
                where: jest.fn().mockReturnThis(),
                andWhere: jest.fn().mockReturnThis(),
                getRawOne: jest.fn().mockResolvedValue({ debt: '1500.50' }),
            };
            mockOrderRepo.createQueryBuilder.mockReturnValue(mockQueryBuilder as any);

            const result = await service.getDebt('user-1');

            expect(result).toBe(1500.5);
        });

        it('should return 0 when client has no debt', async () => {
            const mockQueryBuilder = {
                select: jest.fn().mockReturnThis(),
                where: jest.fn().mockReturnThis(),
                andWhere: jest.fn().mockReturnThis(),
                getRawOne: jest.fn().mockResolvedValue({ debt: null }),
            };
            mockOrderRepo.createQueryBuilder.mockReturnValue(mockQueryBuilder as any);

            const result = await service.getDebt('user-1');

            expect(result).toBe(0);
        });
    });

    describe('create', () => {
        const createOrderData = {
            clientId: 'user-1',
            warehouseId: 'warehouse-1',
            paymentMethod: PaymentMethod.CASH,
            items: [
                { productId: 'product-1', quantity: 2, price: 100 },
                { productId: 'product-2', quantity: 1, price: 200 },
            ],
        };

        it('should create order successfully with cash payment', async () => {
            warehouseService.deductStock.mockResolvedValue([
                { batchId: 'batch-1', quantity: 2 },
                { batchId: 'batch-2', quantity: 1 },
            ]);

            const result = await service.create(createOrderData);

            expect(result).toBeDefined();
            expect(mockManager.increment).toHaveBeenCalledWith(
                expect.anything(),
                { id: 'user-1' },
                'currentDebt',
                400 // Total amount
            );
        });

        it('should throw ForbiddenException when client has debt and tries credit payment', async () => {
            const mockQueryBuilder = {
                select: jest.fn().mockReturnThis(),
                where: jest.fn().mockReturnThis(),
                andWhere: jest.fn().mockReturnThis(),
                getRawOne: jest.fn().mockResolvedValue({ debt: '500' }),
            };
            mockOrderRepo.createQueryBuilder.mockReturnValue(mockQueryBuilder as any);

            await expect(
                service.create({
                    ...createOrderData,
                    paymentMethod: PaymentMethod.CREDIT,
                })
            ).rejects.toThrow(ForbiddenException);
        });

        it('should throw BadRequestException when stock is insufficient', async () => {
            warehouseService.deductStock.mockRejectedValue(
                new Error('INSUFFICIENT_STOCK:Req=2,Avail=0')
            );

            await expect(service.create(createOrderData)).rejects.toThrow(BadRequestException);
        });

        it('should create order with credit payment when no debt', async () => {
            const mockQueryBuilder = {
                select: jest.fn().mockReturnThis(),
                where: jest.fn().mockReturnThis(),
                andWhere: jest.fn().mockReturnThis(),
                getRawOne: jest.fn().mockResolvedValue({ debt: '0' }),
            };
            mockOrderRepo.createQueryBuilder.mockReturnValue(mockQueryBuilder as any);

            warehouseService.deductStock.mockResolvedValue([
                { batchId: 'batch-1', quantity: 2 },
            ]);

            const result = await service.create({
                ...createOrderData,
                items: [{ productId: 'product-1', quantity: 2, price: 100 }],
                paymentMethod: PaymentMethod.CREDIT,
            });

            expect(result).toBeDefined();
        });
    });

    describe('createVanSale', () => {
        it('should create van sale order successfully', async () => {
            warehouseService.getDriverWarehouse.mockResolvedValue(mockWarehouse as any);
            warehouseService.deductStock.mockResolvedValue([
                { batchId: 'batch-1', quantity: 5 },
            ]);

            const result = await service.createVanSale('driver-1', {
                clientId: 'client-1',
                items: [{ productId: 'product-1', quantity: 5, price: 100 }],
            });

            expect(result).toBeDefined();
            expect(result.status).toBe(OrderStatus.DELIVERED);
        });

        it('should throw BadRequestException when driver has no truck assigned', async () => {
            warehouseService.getDriverWarehouse.mockResolvedValue(null);

            await expect(
                service.createVanSale('driver-without-truck', {
                    clientId: 'client-1',
                    items: [{ productId: 'product-1', quantity: 1, price: 100 }],
                })
            ).rejects.toThrow(BadRequestException);
        });

        it('should allow overdraft in van sale', async () => {
            warehouseService.getDriverWarehouse.mockResolvedValue(mockWarehouse as any);
            warehouseService.deductStock.mockResolvedValue([
                { batchId: 'batch-1', quantity: 10 },
            ]);

            const result = await service.createVanSale('driver-1', {
                clientId: 'client-1',
                items: [
                    { productId: 'product-1', quantity: 5, price: 100 },
                    { productId: 'product-2', quantity: 3, price: 150 },
                ],
            });

            expect(result).toBeDefined();
            expect(warehouseService.deductStock).toHaveBeenCalledWith(
                'warehouse-1',
                expect.any(String),
                expect.any(Number),
                mockManager,
                true // allow overdraft
            );
        });
    });

    describe('findAll', () => {
        it('should return all orders with relations', async () => {
            const orders = [mockOrder];
            mockOrderRepo.find.mockResolvedValue(orders as any);

            const result = await service.findAll();

            expect(result).toEqual(orders);
            expect(mockOrderRepo.find).toHaveBeenCalledWith({
                relations: ['items', 'items.allocations', 'items.allocations.batch', 'client'],
            });
        });
    });
});
