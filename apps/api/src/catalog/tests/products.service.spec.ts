import { Test, TestingModule } from '@nestjs/testing';
import { ProductsService } from '../products.service';
import { getRepositoryToken } from '@nestjs/typeorm';
import { Repository, DataSource } from 'typeorm';
import { Product } from '../product.entity';
import { Category } from '../category.entity';
import { ProductAIService } from '../product-ai.service';
import { NotFoundException } from '@nestjs/common';

describe('ProductsService', () => {
    let service: ProductsService;
    let productsRepository: jest.Mocked<Repository<Product>>;
    let categoryRepository: jest.Mocked<Repository<Category>>;
    let dataSource: jest.Mocked<DataSource>;
    let aiService: jest.Mocked<ProductAIService>;

    const mockCategory: Category = {
        id: 'category-1',
        name: 'Напитки',
        description: null,
    };

    const mockProduct: Product = {
        id: 'product-1',
        name: 'Test Product',
        sku: 'BEV-TEST-0001',
        description: 'Test description',
        categoryId: 'category-1',
        basePrice: 100,
        productType: 'GOODS',
        unit: 'PCS',
        attributes: {
            shelfLifeDays: 365,
            weightKg: 1.5,
            barcodes: { ean13: '1234567890123' },
        },
        isActive: true,
        aiConfidence: 0.9,
        aiKeywords: ['test', 'product'],
        isVerified: true,
        createdAt: new Date(),
        updatedAt: new Date(),
    };

    beforeEach(async () => {
        productsRepository = {
            find: jest.fn(),
            findOne: jest.fn(),
            create: jest.fn(),
            save: jest.fn(),
            update: jest.fn(),
        } as any;

        categoryRepository = {
            findOne: jest.fn(),
            save: jest.fn(),
        } as any;

        dataSource = {
            query: jest.fn(),
        } as any;

        aiService = {
            analyzeProduct: jest.fn(),
            suggestPricing: jest.fn(),
            validateForUzbekistan: jest.fn(),
        } as any;

        const module: TestingModule = await Test.createTestingModule({
            providers: [
                ProductsService,
                {
                    provide: getRepositoryToken(Product),
                    useValue: productsRepository,
                },
                {
                    provide: getRepositoryToken(Category),
                    useValue: categoryRepository,
                },
                {
                    provide: DataSource,
                    useValue: dataSource,
                },
                {
                    provide: ProductAIService,
                    useValue: aiService,
                },
            ],
        }).compile();

        service = module.get<ProductsService>(ProductsService);
    });

    describe('findAll', () => {
        it('should return all active products with categories', async () => {
            const products = [mockProduct];
            productsRepository.find.mockResolvedValue(products);

            const result = await service.findAll();

            expect(result).toEqual(products);
            expect(productsRepository.find).toHaveBeenCalledWith({
                relations: ['category'],
                where: { isActive: true },
                order: { name: 'ASC' },
            });
        });
    });

    describe('findByCategory', () => {
        it('should return products by category', async () => {
            const products = [mockProduct];
            productsRepository.find.mockResolvedValue(products);

            const result = await service.findByCategory('category-1');

            expect(result).toEqual(products);
            expect(productsRepository.find).toHaveBeenCalledWith({
                where: { categoryId: 'category-1', isActive: true },
                relations: ['category'],
            });
        });
    });

    describe('findOne', () => {
        it('should return product by id', async () => {
            productsRepository.findOne.mockResolvedValue(mockProduct);

            const result = await service.findOne('product-1');

            expect(result).toEqual(mockProduct);
            expect(productsRepository.findOne).toHaveBeenCalledWith({
                where: { id: 'product-1' },
                relations: ['category'],
            });
        });

        it('should throw NotFoundException when product not found', async () => {
            productsRepository.findOne.mockResolvedValue(null);

            await expect(service.findOne('non-existent')).rejects.toThrow(NotFoundException);
        });
    });

    describe('findByBarcode', () => {
        it('should find product by barcode', async () => {
            productsRepository.findOne.mockResolvedValue(mockProduct);

            const result = await service.findByBarcode('1234567890123');

            expect(result).toEqual(mockProduct);
        });

        it('should return null when barcode not found', async () => {
            productsRepository.findOne.mockResolvedValue(null);

            const result = await service.findByBarcode('9999999999999');

            expect(result).toBeNull();
        });
    });

    describe('create', () => {
        it('should create product with provided SKU', async () => {
            const createDto = {
                name: 'New Product',
                sku: 'CUSTOM-SKU-001',
                categoryId: 'category-1',
                basePrice: 150,
            };

            productsRepository.create.mockReturnValue({ ...createDto, id: 'new-id' } as any);
            productsRepository.save.mockResolvedValue({ ...createDto, id: 'new-id' } as any);

            const result = await service.create(createDto as any);

            expect(result).toBeDefined();
            expect(result.sku).toBe('CUSTOM-SKU-001');
        });

        it('should generate SKU when not provided', async () => {
            const createDto = {
                name: 'Новый Продукт',
                categoryId: 'category-1',
                basePrice: 150,
            };

            categoryRepository.findOne.mockResolvedValue(mockCategory);
            dataSource.query.mockResolvedValue([{ count: '5' }]);
            productsRepository.create.mockReturnValue({ ...createDto, id: 'new-id', sku: 'BEV-NOV-0006' } as any);
            productsRepository.save.mockResolvedValue({ ...createDto, id: 'new-id', sku: 'BEV-NOV-0006' } as any);

            const result = await service.create(createDto as any);

            expect(result).toBeDefined();
            expect(result.sku).toContain('BEV-');
        });
    });

    describe('createWithAI', () => {
        it('should create product with AI analysis', async () => {
            const aiAnalysis = {
                suggestedName: 'AI Generated Product',
                suggestedCategory: 'Напитки',
                description: 'AI generated description',
                suggestedType: 'GOODS',
                suggestedUnit: 'PCS',
                estimatedShelfLifeDays: 365,
                estimatedWeightKg: 1.0,
                barcodes: { ean13: '1234567890123' },
                confidence: 0.85,
                keywords: ['drink', 'beverage'],
            };

            aiService.analyzeProduct.mockResolvedValue(aiAnalysis);
            categoryRepository.findOne.mockResolvedValue(mockCategory);
            dataSource.query.mockResolvedValue([{ count: '0' }]);
            productsRepository.save.mockImplementation(async (data) => ({ ...data, id: 'ai-product-id' } as any));
            productsRepository.findOne.mockResolvedValue({ ...mockProduct, id: 'ai-product-id' });
            aiService.suggestPricing.mockReturnValue({
                retailPrice: 120,
                wholesalePrice: 100,
                margin: 20,
            });
            aiService.validateForUzbekistan.mockReturnValue({
                isValid: true,
                warnings: [],
            });

            const result = await service.createWithAI({
                text: 'Some drink product',
                basePrice: 80,
            });

            expect(result).toBeDefined();
            expect(result.product).toBeDefined();
            expect(result.aiAnalysis).toBeDefined();
            expect(aiService.analyzeProduct).toHaveBeenCalled();
        });

        it('should create new category if not exists', async () => {
            const aiAnalysis = {
                suggestedName: 'New Category Product',
                suggestedCategory: 'New Category',
                description: 'Description',
                suggestedType: 'GOODS',
                suggestedUnit: 'PCS',
                estimatedShelfLifeDays: 30,
                estimatedWeightKg: 0.5,
                barcodes: {},
                confidence: 0.75,
                keywords: [],
            };

            aiService.analyzeProduct.mockResolvedValue(aiAnalysis);
            categoryRepository.findOne.mockResolvedValue(null);
            categoryRepository.save.mockResolvedValue({ id: 'new-cat-id', name: 'New Category' });
            dataSource.query.mockResolvedValue([{ count: '0' }]);
            productsRepository.save.mockImplementation(async (data) => ({ ...data, id: 'new-product' } as any));
            productsRepository.findOne.mockResolvedValue({ ...mockProduct, id: 'new-product' });

            const result = await service.createWithAI({ text: 'New product' });

            expect(categoryRepository.save).toHaveBeenCalledWith({ name: 'New Category' });
            expect(result).toBeDefined();
        });
    });

    describe('previewAIAnalysis', () => {
        it('should return AI analysis preview without creating product', async () => {
            const aiAnalysis = {
                suggestedName: 'Preview Product',
                suggestedCategory: 'Напитки',
                description: 'Preview description',
                suggestedType: 'GOODS',
                suggestedUnit: 'PCS',
                estimatedShelfLifeDays: 180,
                estimatedWeightKg: 1.0,
                barcodes: {},
                confidence: 0.8,
                keywords: [],
            };

            aiService.analyzeProduct.mockResolvedValue(aiAnalysis);
            categoryRepository.findOne.mockResolvedValue(mockCategory);
            dataSource.query.mockResolvedValue([{ count: '10' }]);
            aiService.validateForUzbekistan.mockReturnValue({
                isValid: true,
                warnings: [],
            });

            const result = await service.previewAIAnalysis({ text: 'Preview' });

            expect(result).toBeDefined();
            expect(result.generatedSku).toBeDefined();
            expect(productsRepository.save).not.toHaveBeenCalled();
        });
    });

    describe('bulkCreate', () => {
        it('should create multiple products', async () => {
            const products = [
                { name: 'Product 1', categoryId: 'cat-1', basePrice: 100 },
                { name: 'Product 2', categoryId: 'cat-1', basePrice: 200 },
            ];

            productsRepository.create.mockImplementation((data) => data as any);
            productsRepository.save.mockImplementation(async (data) => ({ ...data, id: `id-${Math.random()}` } as any));

            const result = await service.bulkCreate(products as any);

            expect(result.created.length).toBe(2);
            expect(result.errors.length).toBe(0);
        });

        it('should collect errors for failed products', async () => {
            const products = [
                { name: 'Product 1', categoryId: 'cat-1', basePrice: 100 },
                { name: 'Product 2', categoryId: 'cat-1', basePrice: -50 }, // Invalid price
            ];

            productsRepository.create.mockImplementation((data) => data as any);
            productsRepository.save
                .mockResolvedValueOnce({ id: 'id-1' } as any)
                .mockRejectedValueOnce(new Error('Invalid price'));

            const result = await service.bulkCreate(products as any);

            expect(result.created.length).toBe(1);
            expect(result.errors.length).toBe(1);
            expect(result.errors[0].row).toBe(2);
        });
    });

    describe('update', () => {
        it('should update product', async () => {
            productsRepository.findOne.mockResolvedValue(mockProduct);
            productsRepository.save.mockResolvedValue({ ...mockProduct, name: 'Updated Name' });

            const result = await service.update('product-1', { name: 'Updated Name' } as any);

            expect(result.name).toBe('Updated Name');
        });
    });

    describe('deactivate', () => {
        it('should deactivate product', async () => {
            productsRepository.update.mockResolvedValue({ affected: 1 } as any);

            await service.deactivate('product-1');

            expect(productsRepository.update).toHaveBeenCalledWith('product-1', { isActive: false });
        });
    });
});
