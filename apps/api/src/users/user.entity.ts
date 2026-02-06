import { Entity, PrimaryGeneratedColumn, Column, CreateDateColumn, UpdateDateColumn, OneToMany, Index } from 'typeorm';
import { Notification } from '../notifications/notification.entity';

export enum UserRole {
    SUPER_ADMIN = 'SUPER_ADMIN', // Can access all tenants (special handling needed)
    OWNER = 'OWNER',
    DIRECTOR = 'DIRECTOR',
    WAREHOUSE_MANAGER = 'WAREHOUSE_MANAGER',
    ACCOUNTANT = 'ACCOUNTANT',
    SALES_REP = 'SALES_REP',
    DRIVER = 'DRIVER',
}

@Entity('users')
@Index(['email', 'tenantId'], { unique: true })
export class User {
    @PrimaryGeneratedColumn('uuid')
    id: string;

    @Column()
    tenantId: string;

    @Column()
    email: string; // Or username/phone

    @Column({ select: false })
    passwordHash: string;

    @Column({ type: 'enum', enum: UserRole, default: UserRole.SALES_REP })
    role: UserRole;

    @Column()
    fullName: string;

    @Column({ nullable: true })
    phone: string;

    @Column({ nullable: true })
    @Index() // Optimized for webhook lookups
    telegramChatId: string;

    @Column({ type: 'decimal', precision: 12, scale: 2, default: 0 })
    currentDebt: number; // Denormalized field for performance

    @CreateDateColumn()
    createdAt: Date;

    @UpdateDateColumn()
    updatedAt: Date;

    @OneToMany(() => Notification, (notification) => notification.user)
    notifications: Notification[];
}
