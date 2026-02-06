import { Injectable, Logger, NotFoundException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository, DataSource } from 'typeorm';
import { Product } from './product.entity';
import { Category } from './category.entity';
import { CreateProductDto } from './dto/create-product.dto';
import { ProductAIService } from './product-ai.service';
import { ProductType, UnitOfMeasure, PRODUCT_CATEGORIES } from './product-types';

@Injectable()
export class ProductsService {
    private readonly logger = new Logger(ProductsService.name);

    constructor(
        @InjectRepository(Product)
        private productsRepository: Repository<Product>,
        @InjectRepository(Category)
        private categoryRepository: Repository<Category>,
        private dataSource: DataSource,
        private aiService: ProductAIService,
    ) { }

    async findAll(): Promise<Product[]> {
        return this.productsRepository.find({ 
            relations: ['category'],
            where: { isActive: true },
            order: { name: 'ASC' }
        });
    }

    async findByCategory(categoryId: string): Promise<Product[]> {
        return this.productsRepository.find({
            where: { categoryId, isActive: true },
            relations: ['category'],
        });
    }

    async findOne(id: string): Promise<Product> {
        const product = await this.productsRepository.findOne({
            where: { id },
            relations: ['category'],
        });
        if (!product) {
            throw new NotFoundException('Product not found');
        }
        return product;
    }

    async findByBarcode(barcode: string): Promise<Product | null> {
        return this.productsRepository.findOne({
            where: {
                attributes: {
                    barcodes: {
                        ean13: barcode
                    }
                }
            },
        });
    }

    async create(dto: CreateProductDto): Promise<Product> {
        // Генерируем SKU если не указан
        if (!dto.sku) {
            const category = await this.categoryRepository.findOne({ 
                where: { id: dto.categoryId } 
            });
            const categoryCode = this.getCategoryCode(category?.name || 'GEN');
            const sequence = await this.getNextSequence(categoryCode);
            dto.sku = this.generateSKU(categoryCode, dto.name, sequence);
        }

        const product = this.productsRepository.create({
            ...dto,
            attributes: dto.attributes as any,
        });

        return this.productsRepository.save(product);
    }

    // AI-создание продукта
    async createWithAI(input: {
        text?: string;
        imageUrl?: string;
        barcode?: string;
        supplierData?: any;
        basePrice?: number;
    }): Promise<{ product: Product; aiAnalysis: any }> {
        // Анализируем через AI
        const analysis = await this.aiService.analyzeProduct({
            text: input.text,
            imageUrl: input.imageUrl,
            barcode: input.barcode,
            supplierData: input.supplierData,
        });

        // Находим или создаем категорию
        let category = await this.categoryRepository.findOne({
            where: { name: analysis.suggestedCategory }
        });

        if (!category) {
            category = await this.categoryRepository.save({
                name: analysis.suggestedCategory,
            });
        }

        // Генерируем SKU
        const sequence = await this.getNextSequence(analysis.suggestedCategory);
        const sku = this.generateSKU(
            analysis.suggestedCategory,
            analysis.suggestedName,
            sequence
        );

        // Рассчитываем цены если не указана
        const pricing = input.basePrice 
            ? this.aiService.suggestPricing(input.basePrice, analysis.suggestedCategory)
            : { retailPrice: 0, wholesalePrice: 0, margin: 0 };

        // Создаем продукт
        const productData: Partial<Product> = {
            name: analysis.suggestedName,
            sku,
            description: analysis.description,
            categoryId: category.id,
            basePrice: input.basePrice || pricing.retailPrice,
            productType: analysis.suggestedType,
            unit: analysis.suggestedUnit,
            attributes: {
                shelfLifeDays: analysis.estimatedShelfLifeDays,
                weightKg: analysis.estimatedWeightKg,
                barcodes: analysis.barcodes,
            },
            aiConfidence: analysis.confidence,
            aiKeywords: analysis.keywords,
            isVerified: analysis.confidence > 0.8, // Авто-подтверждение если уверенность высокая
        };

        const product = await this.productsRepository.save(productData);

        return {
            product: await this.findOne(product.id),
            aiAnalysis: {
                ...analysis,
                generatedSku: sku,
                suggestedPrice: pricing,
                validation: this.aiService.validateForUzbekistan(productData.attributes as any),
            }
        };
    }

    // Предварительный анализ без создания
    async previewAIAnalysis(input: {
        text?: string;
        imageUrl?: string;
        barcode?: string;
        supplierData?: any;
        basePrice?: number;
    }) {
        const analysis = await this.aiService.analyzeProduct({
            text: input.text,
            imageUrl: input.imageUrl,
            barcode: input.barcode,
            supplierData: input.supplierData,
        });

        const category = await this.categoryRepository.findOne({
            where: { name: analysis.suggestedCategory }
        });

        const sequence = await this.getNextSequence(analysis.suggestedCategory);
        const sku = this.generateSKU(
            analysis.suggestedCategory,
            analysis.suggestedName,
            sequence
        );

        const pricing = input.basePrice 
            ? this.aiService.suggestPricing(input.basePrice, analysis.suggestedCategory)
            : null;

        const validation = this.aiService.validateForUzbekistan({
            shelfLifeDays: analysis.estimatedShelfLifeDays,
            barcodes: analysis.barcodes,
        });

        return {
            ...analysis,
            generatedSku: sku,
            suggestedPrice: pricing,
            validation,
            categoryExists: !!category,
        };
    }

    // Массовое создание из Excel/CSV
    async bulkCreate(products: CreateProductDto[]): Promise<{
        created: Product[];
        errors: { row: number; error: string }[];
    }> {
        const created: Product[] = [];
        const errors: { row: number; error: string }[] = [];

        for (let i = 0; i < products.length; i++) {
            try {
                const product = await this.create(products[i]);
                created.push(product);
            } catch (error) {
                errors.push({
                    row: i + 1,
                    error: error.message,
                });
            }
        }

        return { created, errors };
    }

    async update(id: string, data: Partial<CreateProductDto>): Promise<Product> {
        const product = await this.findOne(id);
        
        Object.assign(product, {
            ...data,
            attributes: data.attributes ? data.attributes as any : product.attributes,
        });

        return this.productsRepository.save(product);
    }

    async deactivate(id: string): Promise<void> {
        await this.productsRepository.update(id, { isActive: false });
    }

    // ============ Private Methods ============

    private generateSKU(categoryCode: string, productName: string, sequence: number): string {
        const transliterated = this.transliterate(productName);
        const shortName = transliterated
            .split(' ')
            .map(w => w.substring(0, 3).toUpperCase())
            .join('');
        
        const category = categoryCode.substring(0, 3).toUpperCase();
        const seq = sequence.toString().padStart(4, '0');
        
        return `${category}-${shortName}-${seq}`;
    }

    private async getNextSequence(categoryCode: string): Promise<number> {
        const result = await this.dataSource.query(
            `SELECT COUNT(*) as count FROM products WHERE sku LIKE $1`,
            [`${categoryCode}%`]
        );
        return parseInt(result[0].count, 10) + 1;
    }

    private getCategoryCode(categoryName: string): string {
        const codes: Record<string, string> = {
            'Вода': 'WTR',
            'Напитки': 'BEV',
            'Мясо': 'MT',
            'Овощи': 'VEG',
            'Фрукты': 'FRT',
            'Молочка': 'DAIRY',
            'Бакалея': 'GROC',
        };
        return codes[categoryName] || 'GEN';
    }

    private transliterate(text: string): string {
        const ru = 'абвгдеёжзийклмнопрстуфхцчшщъыьэюя';
        const en = 'abvgdeejzijklmnoprstufhzcss_y_eua';
        
        return text.toLowerCase()
            .split('')
            .map(char => {
                const idx = ru.indexOf(char);
                return idx >= 0 ? en[idx] : char;
            })
            .join('');
    }
}
