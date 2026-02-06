import { Entity, PrimaryGeneratedColumn, Column, CreateDateColumn, UpdateDateColumn, ManyToOne, JoinColumn } from 'typeorm';

export enum SubscriptionPeriod {
    WEEKLY = 'WEEKLY',      // 1 неделя
    MONTHLY = 'MONTHLY',    // 1 месяц
    QUARTERLY = 'QUARTERLY', // 3 месяца
    YEARLY = 'YEARLY',      // 12 месяцев
}

export enum ComboStatus {
    ACTIVE = 'ACTIVE',
    INACTIVE = 'INACTIVE',
    ARCHIVED = 'ARCHIVED',
}

// Товар в составе комбо
export interface ComboItem {
    productId: string;
    name: string;
    quantity: number;
    unit: string;
    image?: string;
}

@Entity('combo_products')
export class ComboProduct {
    @PrimaryGeneratedColumn('uuid')
    id: string;

    @Column()
    name: string; // Название комбо (например, "Семейный набор", "Офисный ланч")

    @Column({ type: 'text', nullable: true })
    description: string;

    @Column()
    image: string; // URL изображения комбо

    @Column({ type: 'jsonb' })
    items: ComboItem[]; // Список товаров в комбо

    @Column({ type: 'enum', enum: SubscriptionPeriod, default: SubscriptionPeriod.MONTHLY })
    period: SubscriptionPeriod;

    @Column({ type: 'decimal', precision: 10, scale: 2 })
    basePrice: number; // Цена без скидки

    @Column({ type: 'decimal', precision: 10, scale: 2 })
    subscriptionPrice: number; // Цена по подписке (со скидкой)

    @Column({ type: 'decimal', precision: 5, scale: 2, default: 0 })
    discountPercent: number; // Процент скидки

    @Column({ type: 'enum', enum: ComboStatus, default: ComboStatus.ACTIVE })
    status: ComboStatus;

    @Column({ default: true })
    isAvailableForTMA: boolean; // Доступно в Telegram Mini App

    @Column({ type: 'int', default: 0 })
    totalDeliveries: number; // Количество доставок за период (например, 4 раза в месяц)

    @Column({ type: 'int', default: 1 })
    deliveryFrequencyDays: number; // Частота доставки в днях

    @Column({ type: 'simple-json', nullable: true })
    telegramSettings?: {
        buttonText: string;
        descriptionShort: string;
        emoji: string;
    };

    @CreateDateColumn()
    createdAt: Date;

    @UpdateDateColumn()
    updatedAt: Date;
}
