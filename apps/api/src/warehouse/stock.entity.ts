import { Entity, PrimaryGeneratedColumn, Column, CreateDateColumn, UpdateDateColumn, ManyToOne, Unique } from 'typeorm';
import { Warehouse } from './warehouse.entity';
import { Product } from '../catalog/product.entity';
import { Batch } from './batch.entity';

@Entity('stocks')
@Unique(['warehouse', 'product', 'batch']) // Unique constraint for specific batch in specific warehouse
export class Stock {
    @PrimaryGeneratedColumn('uuid')
    id: string;

    @ManyToOne(() => Warehouse)
    warehouse: Warehouse;

    @ManyToOne(() => Product)
    product: Product;

    @ManyToOne(() => Batch, { nullable: true }) // Nullable if strict batch tracking provided? No, should be strict.
    batch: Batch;

    @Column({ type: 'decimal', precision: 10, scale: 2, default: 0 })
    quantity: number;

    @CreateDateColumn()
    createdAt: Date;

    @UpdateDateColumn()
    updatedAt: Date;
}
