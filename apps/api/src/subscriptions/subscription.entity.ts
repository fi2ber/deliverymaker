import { Entity, PrimaryGeneratedColumn, Column, CreateDateColumn, UpdateDateColumn, ManyToOne, JoinColumn } from 'typeorm';
import { User } from '../users/user.entity';
import { ComboProduct } from './combo-product.entity';

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
}

@Entity('subscriptions')
export class Subscription {
    @PrimaryGeneratedColumn('uuid')
    id: string;

    @Column({ unique: true })
    orderCode: string; // Для клиента (например, "SUB-1001")

    @ManyToOne(() => User)
    @JoinColumn({ name: 'clientId' })
    client: User;

    @Column()
    clientId: string;

    @ManyToOne(() => ComboProduct)
    @JoinColumn({ name: 'comboProductId' })
    comboProduct: ComboProduct;

    @Column()
    comboProductId: string;

    @Column({ type: 'enum', enum: SubscriptionStatus, default: SubscriptionStatus.PENDING })
    status: SubscriptionStatus;

    @Column({ type: 'date' })
    startDate: Date; // Дата начала подписки

    @Column({ type: 'date' })
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

    @CreateDateColumn()
    createdAt: Date;

    @UpdateDateColumn()
    updatedAt: Date;
}
