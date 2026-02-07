import { Entity, PrimaryGeneratedColumn, Column, CreateDateColumn, UpdateDateColumn, ManyToOne, JoinColumn } from 'typeorm';
import { User } from '../users/user.entity';
import { ComboProduct } from './combo-product.entity';
import { Customer } from '../customers/entities/customer.entity';

export enum SubscriptionStatus {
    PENDING = 'PENDING',           // Ожидает первой оплаты
    ACTIVE = 'ACTIVE',             // Активна
    PAUSED = 'PAUSED',             // Приостановлена
    CANCELLED = 'CANCELLED',       // Отменена
    EXPIRED = 'EXPIRED',           // Истекла
}

export enum PaymentProvider {
    TELEGRAM = 'TELEGRAM',         // Telegram Payments
    CLICK = 'CLICK',               // Click Uzbekistan
    PAYME = 'PAYME',               // Payme
    CASH = 'CASH',                 // Наличные при доставке
    UZUM = 'UZUM',                 // Uzum Bank
}

export enum PaymentStatus {
    PENDING = 'pending',
    PAID = 'paid',
    FAILED = 'failed',
    REFUNDED = 'refunded',
}

@Entity('subscriptions')
export class Subscription {
    @PrimaryGeneratedColumn('uuid')
    id: string;

    @Column({ name: 'tenant_id' })
    tenantId: string;

    @Column({ unique: true, nullable: true })
    orderCode: string; // Для клиента (например, "SUB-1001")

    // Legacy: связь с User (для обратной совместимости)
    @ManyToOne(() => User, { nullable: true })
    @JoinColumn({ name: 'client_id' })
    client?: User;

    @Column({ name: 'client_id', nullable: true })
    clientId?: string;

    // New: связь с Customer (self-service)
    @ManyToOne(() => Customer, { nullable: true })
    @JoinColumn({ name: 'customer_id' })
    customer?: Customer;

    @Column({ name: 'customer_id', nullable: true })
    customerId?: string;

    @ManyToOne(() => ComboProduct)
    @JoinColumn({ name: 'combo_product_id' })
    comboProduct: ComboProduct;

    @Column({ name: 'combo_product_id' })
    comboProductId: string;

    @Column({ type: 'enum', enum: SubscriptionStatus, default: SubscriptionStatus.PENDING })
    status: SubscriptionStatus;

    @Column({ type: 'enum', enum: PaymentStatus, default: PaymentStatus.PENDING })
    paymentStatus: PaymentStatus;

    @Column({ type: 'decimal', precision: 10, scale: 2, nullable: true })
    paidAmount: number;

    @Column({ type: 'timestamp', nullable: true })
    paidAt: Date;

    @Column({ type: 'date', nullable: true })
    startDate: Date; // Дата начала подписки

    @Column({ type: 'date', nullable: true })
    endDate: Date; // Дата окончания подписки

    @Column({ type: 'date', nullable: true })
    nextDeliveryDate: Date; // Следующая доставка

    @Column({ type: 'int', default: 0 })
    deliveriesCompleted: number; // Количество выполненных доставок

    @Column({ type: 'int', default: 0 })
    totalDeliveries: number; // Всего доставок по подписке

    @Column({ type: 'decimal', precision: 10, scale: 2 })
    pricePerDelivery: number; // Цена за одну доставку

    @Column({ type: 'decimal', precision: 12, scale: 2 })
    totalAmount: number; // Общая сумма подписки

    @Column({ type: 'enum', enum: PaymentProvider, default: PaymentProvider.TELEGRAM })
    paymentProvider: PaymentProvider;

    @Column({ nullable: true })
    telegramPaymentChargeId: string; // ID платежа в Telegram

    @Column({ type: 'simple-json', nullable: true })
    deliveryAddress: {
        lat?: number;
        lng?: number;
        address: string;
        phone: string;
        comment?: string;
    };

    @Column({ type: 'simple-json', nullable: true })
    deliverySchedule: {
        preferredTimeStart?: string; // "09:00"
        preferredTimeEnd?: string;   // "18:00"
        weekdaysOnly?: boolean;
    };

    @Column({ type: 'simple-json', nullable: true })
    telegramData?: {
        chatId: string;
        username?: string;
        invoiceMessageId?: number;
    };

    @CreateDateColumn({ name: 'created_at' })
    createdAt: Date;

    @UpdateDateColumn({ name: 'updated_at' })
    updatedAt: Date;
}
