import { Entity, PrimaryGeneratedColumn, Column, CreateDateColumn, UpdateDateColumn, ManyToOne, JoinColumn, Index } from 'typeorm';
import { Customer } from '../customers/entities/customer.entity';

export enum OrderStatus {
    PENDING = 'PENDING',           // Ожидает обработки складом
    CONFIRMED = 'CONFIRMED',       // Подтвержден, готовится
    PACKING = 'PACKING',           // Комплектуется
    READY = 'READY',               // Готов к выдаче
    ASSIGNED = 'ASSIGNED',         // Назначен доставщику
    IN_TRANSIT = 'IN_TRANSIT',     // В пути
    DELIVERED = 'DELIVERED',       // Доставлен
    CANCELLED = 'CANCELLED',       // Отменен
    RETURNED = 'RETURNED',         // Возвращен
}

export enum OrderSource {
    SUBSCRIPTION = 'SUBSCRIPTION', // Из подписки
    MANUAL = 'MANUAL',             // Создан вручную
    TMA = 'TMA',                   // Из Telegram Mini App
    WEB = 'WEB',                   // С веб-сайта
}

export enum PaymentStatus {
    PENDING = 'pending',
    PAID = 'paid',
    PARTIAL = 'partial',
    FAILED = 'failed',
}

export enum PaymentMethod {
    CASH = 'cash',
    CARD = 'card',
    TRANSFER = 'transfer',
    TELEGRAM = 'telegram',
    CREDIT = 'credit',
}

export interface OrderItem {
    productId: string;
    productName?: string;
    quantity: number;
    unit?: string;
    price?: number;
    total?: number;
}

@Entity('orders')
export class Order {
    @PrimaryGeneratedColumn('uuid')
    id: string;

    @Column({ unique: true })
    orderCode: string;

    @Index()
    @Column({ name: 'tenant_id' })
    tenantId: string;

    @Column({ name: 'subscription_id', nullable: true })
    subscriptionId?: string;

    @Index()
    @Column({ name: 'customer_id' })
    customerId: string;

    @ManyToOne(() => Customer)
    @JoinColumn({ name: 'customer_id' })
    customer: Customer;

    @Column({
        type: 'enum',
        enum: OrderStatus,
        default: OrderStatus.PENDING,
    })
    status: OrderStatus;

    @Column({
        type: 'enum',
        enum: OrderSource,
        default: OrderSource.MANUAL,
    })
    source: OrderSource;

    @Column({ type: 'simple-json' })
    items: OrderItem[];

    @Column({ type: 'decimal', precision: 12, scale: 2 })
    totalAmount: number;

    @Column({ type: 'date' })
    deliveryDate: Date;

    @Column({ type: 'simple-json', nullable: true })
    deliveryAddress: {
        lat?: number;
        lng?: number;
        address: string;
        phone: string;
        comment?: string;
    };

    @Column({ type: 'simple-json', nullable: true })
    deliverySchedule?: {
        preferredTimeStart?: string;
        preferredTimeEnd?: string;
    };

    @Column({ name: 'driver_id', nullable: true })
    driverId?: string;

    @Column({ nullable: true })
    driverName?: string;

    @Column({ nullable: true })
    driverPhone?: string;

    @Column({ type: 'timestamp', nullable: true })
    assignedAt?: Date;

    @Column({ type: 'timestamp', nullable: true })
    pickedUpAt?: Date;

    @Column({ type: 'timestamp', nullable: true })
    deliveredAt?: Date;

    @Column({ type: 'simple-json', nullable: true })
    deliveryProof?: {
        photoUrl?: string;
        signatureUrl?: string;
        notes?: string;
        deliveredAt: Date;
    };

    @Column({ type: 'text', nullable: true })
    notes?: string;

    @Column({ type: 'simple-json', nullable: true })
    metadata?: {
        packedBy?: string;
        checkedBy?: string;
        warehouseNotes?: string;
        pickupNotes?: string;
        deliveryFailedReason?: string;
        deliveryFailedAt?: Date;
    };

    // Legacy fields for backward compatibility
    @Column({ nullable: true })
    warehouse?: string;

    @Column({ type: 'simple-json', nullable: true })
    location?: {
        lat: number;
        lng: number;
        address: string;
    };

    @Column({ type: 'enum', enum: PaymentStatus, default: PaymentStatus.PENDING, nullable: true })
    paymentStatus?: PaymentStatus;

    @Column({ type: 'decimal', precision: 12, scale: 2, default: 0, nullable: true })
    paidAmount?: number;

    @Column({ type: 'enum', enum: PaymentMethod, nullable: true })
    paymentMethod?: PaymentMethod;

    @CreateDateColumn({ name: 'created_at' })
    createdAt: Date;

    @UpdateDateColumn({ name: 'updated_at' })
    updatedAt: Date;
}
