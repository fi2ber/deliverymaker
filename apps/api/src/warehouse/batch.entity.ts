import { Entity, PrimaryGeneratedColumn, Column, CreateDateColumn, UpdateDateColumn, ManyToOne, Index } from 'typeorm';
import { Product } from '../catalog/product.entity';

@Entity('batches')
export class Batch {
    @PrimaryGeneratedColumn('uuid')
    id: string;

    // Manual batch identifier (e.g. "LOT-2023-01")
    @Column({ nullable: true })
    batchCode: string;

    @ManyToOne(() => Product)
    product: Product;

    @Column({ type: 'decimal', precision: 10, scale: 2 })
    purchasePrice: number;

    @Column({ type: 'date', nullable: true })
    @Index() // Optimized for FEFO sorting
    expirationDate: Date; // Critical for FEFO

    @Column({ type: 'date' })
    arrivalDate: Date; // Critical for FIFO

    @CreateDateColumn()
    createdAt: Date;
}
