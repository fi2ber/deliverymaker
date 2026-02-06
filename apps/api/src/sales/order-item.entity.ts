import { Entity, PrimaryGeneratedColumn, Column, ManyToOne, OneToMany } from 'typeorm';
import { Order } from './order.entity';
import { Product } from '../catalog/product.entity';
import { OrderItemAllocation } from './order-item-allocation.entity';

@Entity('order_items')
export class OrderItem {
    @PrimaryGeneratedColumn('uuid')
    id: string;

    @ManyToOne(() => Order, (order) => order.items, { onDelete: 'CASCADE' })
    order: Order;

    @ManyToOne(() => Product)
    product: Product;

    @OneToMany(() => OrderItemAllocation, (alloc) => alloc.orderItem, { cascade: true })
    allocations: OrderItemAllocation[];

    // Old direct relation removed in favor of strict allocations
    // @ManyToOne(() => Batch, { nullable: true })
    // batch: Batch;

    @Column({ type: 'decimal', precision: 10, scale: 2 })
    quantity: number;

    @Column({ type: 'decimal', precision: 10, scale: 2 })
    price: number; // Snapshot of price at moment of sale

    @Column({ type: 'decimal', precision: 10, scale: 2 })
    total: number;
}
