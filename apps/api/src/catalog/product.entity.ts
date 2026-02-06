import { Entity, PrimaryGeneratedColumn, Column, CreateDateColumn, UpdateDateColumn, ManyToOne, JoinColumn } from 'typeorm';
import { Category } from './category.entity';
import { ProductType, UnitOfMeasure } from './product-types';

@Entity('products')
export class Product {
    @PrimaryGeneratedColumn('uuid')
    id: string;

    @Column()
    name: string;

    @Column({ unique: true })
    sku: string;

    @Column({ type: 'text', nullable: true })
    description: string;

    @Column({ nullable: true })
    image: string; // Главное фото

    @Column({ type: 'text', array: true, default: [] })
    images: string[]; // Дополнительные фото

    @ManyToOne(() => Category, (category) => category.children)
    @JoinColumn({ name: 'categoryId' })
    category: Category;

    @Column()
    categoryId: string;

    @Column({ type: 'decimal', precision: 10, scale: 2 })
    basePrice: number;

    @Column({
        type: 'enum',
        enum: ProductType,
        default: ProductType.PIECES,
    })
    productType: ProductType;

    @Column({
        type: 'enum',
        enum: UnitOfMeasure,
        default: UnitOfMeasure.PCS,
    })
    unit: UnitOfMeasure;

    // Расширенные атрибуты (JSONB для гибкости)
    @Column({ type: 'jsonb', nullable: true })
    attributes: {
        weightKg?: number;
        volumeLiters?: number;
        dimensions?: { length: number; width: number; height: number };
        temperatureControl?: { min: number; max: number; required: boolean };
        shelfLifeDays: number;
        shelfLifeAfterOpen?: number;
        barcodes?: { ean13?: string; ean8?: string; upc?: string };
        certification?: { halal?: boolean; organic?: boolean; gost?: string; ozbekiston?: string };
        packaging?: { type: 'plastic' | 'glass' | 'paper' | 'metal' | 'mixed'; recyclable?: boolean; depositScheme?: boolean };
    };

    // AI-метаданные
    @Column({ type: 'float', nullable: true })
    aiConfidence: number;

    @Column({ type: 'text', array: true, nullable: true })
    aiKeywords: string[];

    // Статус
    @Column({ default: true })
    isActive: boolean;

    @Column({ default: false })
    isVerified: boolean; // Проверено модератором

    @CreateDateColumn()
    createdAt: Date;

    @UpdateDateColumn()
    updatedAt: Date;
}
