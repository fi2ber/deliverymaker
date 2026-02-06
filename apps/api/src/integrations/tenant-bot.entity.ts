import { Entity, PrimaryColumn, Column, CreateDateColumn, UpdateDateColumn } from 'typeorm';

export enum BotStatus {
    ACTIVE = 'ACTIVE',
    INACTIVE = 'INACTIVE',
    SUSPENDED = 'SUSPENDED',
}

@Entity('tenant_bots')
export class TenantBot {
    @PrimaryColumn()
    tenantId: string; // ID тенанта (schema name)

    @Column()
    botToken: string; // Токен от @BotFather (encrypted)

    @Column()
    botUsername: string; // @username бота

    @Column({ nullable: true })
    botName: string; // Отображаемое имя бота

    @Column({ type: 'enum', enum: BotStatus, default: BotStatus.ACTIVE })
    status: BotStatus;

    @Column({ nullable: true })
    webhookUrl: string; // URL для вебхуков

    @Column({ type: 'simple-json', nullable: true })
    settings: {
        welcomeMessage?: string;
        supportUsername?: string;
        paymentProviderToken?: string; // Для Telegram Payments
        webAppUrl?: string;
    };

    @Column({ type: 'bigint', default: 0 })
    messageCount: number; // Счетчик отправленных сообщений

    @Column({ type: 'bigint', default: 0 })
    errorCount: number; // Счетчик ошибок

    @Column({ type: 'timestamp', nullable: true })
    lastErrorAt: Date;

    @Column({ type: 'text', nullable: true })
    lastErrorMessage: string;

    @CreateDateColumn()
    createdAt: Date;

    @UpdateDateColumn()
    updatedAt: Date;
}
