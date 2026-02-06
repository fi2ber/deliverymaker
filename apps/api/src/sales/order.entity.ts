import { Entity, PrimaryGeneratedColumn, Column, CreateDateColumn, UpdateDateColumn, ManyToOne, OneToMany, Index } from 'typeorm';
import { User } from '../users/user.entity';
import { Warehouse } from '../warehouse/warehouse.entity';
import { OrderItem } from './order-item.entity';

export enum OrderStatus {
    DRAFT = 'DRAFT',
    CONFIRMED = 'CONFIRMED',
    PROCESSING = 'PROCESSING',
    SHIPPED = 'SHIPPED',
    DELIVERED = 'DELIVERED',
    CANCELLED = 'CANCELLED',
    RETURNED = 'RETURNED',
}

export enum PaymentStatus {
    PENDING = 'PENDING',
    PARTIAL = 'PARTIAL',
    PAID = 'PAID',
}

export enum PaymentMethod {
    CASH = 'CASH',
    CREDIT = 'CREDIT', // Post-payment
    CARD = 'CARD',
}

@Entity('orders')
export class Order {
    @PrimaryGeneratedColumn('uuid')
    id: string;

    // Manual sequential ID for humans (e.g. ORD-1001)
    @Column({ generated: 'increment' })
    humanId: number;

    @ManyToOne(() => User) // The client/shop owner
    @Index() // Optimized for filtering by client
    client: User;

    @ManyToOne(() => User, { nullable: true }) // The sales rep who created it
    salesRep: User;

    @ManyToOne(() => User, { nullable: true }) // The driver assigned
    driver: User;

    @ManyToOne(() => Warehouse, { nullable: true }) // Origin warehouse
    warehouse: Warehouse;

    @Column({ type: 'enum', enum: OrderStatus, default: OrderStatus.DRAFT })
    @Index() // Optimized for debt calculation (NOT IN status) and analytics
    status: OrderStatus;

    @Column({ type: 'enum', enum: PaymentMethod, default: PaymentMethod.CASH })
    paymentMethod: PaymentMethod;

    @Column({ type: 'enum', enum: PaymentStatus, default: PaymentStatus.PENDING })
    paymentStatus: PaymentStatus;

    @Column({ type: 'decimal', precision: 12, scale: 2, default: 0 })
    totalAmount: number;

    @Column({ type: 'decimal', precision: 12, scale: 2, default: 0 })
    paidAmount: number;

    @OneToMany(() => OrderItem, (item) => item.order, { cascade: true })
    items: OrderItem[];

    @Column({ type: 'date', nullable: true })
    deliveryDate: Date;

    @Column({ type: 'jsonb', nullable: true })
    location: { lat: number; lng: number; address: string };

    @CreateDateColumn()
    @Index() // Optimized for date range queries (AI analytics)
    createdAt: Date;

    @UpdateDateColumn()
    updatedAt: Date;
}
