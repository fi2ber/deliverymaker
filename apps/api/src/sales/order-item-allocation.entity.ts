import { Entity, PrimaryGeneratedColumn, Column, ManyToOne } from 'typeorm';
import { OrderItem } from './order-item.entity';
import { Batch } from '../warehouse/batch.entity';

@Entity('order_item_allocations')
export class OrderItemAllocation {
    @PrimaryGeneratedColumn('uuid')
    id: string;

    @ManyToOne(() => OrderItem, (item) => item.allocations, { onDelete: 'CASCADE' })
    orderItem: OrderItem;

    @ManyToOne(() => Batch)
    batch: Batch;

    @Column({ type: 'decimal', precision: 10, scale: 2 })
    quantity: number;
}
