import { Entity, PrimaryGeneratedColumn, Column, CreateDateColumn, UpdateDateColumn, Index } from 'typeorm';

export enum CustomerSource {
  TELEGRAM_BOT = 'telegram_bot',
  MANAGER = 'manager',
  QR_CODE = 'qr_code',
  REFERRAL = 'referral',
  WEBSITE = 'website',
}

export enum CustomerStatus {
  ACTIVE = 'active',
  INACTIVE = 'inactive',
  BLOCKED = 'blocked',
}

@Entity('customers')
export class Customer {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ name: 'tenant_id' })
  @Index()
  tenantId: string;

  @Column({ name: 'telegram_id', nullable: true, unique: true })
  @Index()
  telegramId?: string;

  @Column({ name: 'telegram_username', nullable: true })
  telegramUsername?: string;

  @Column({ name: 'telegram_chat_id', nullable: true })
  telegramChatId?: string;

  @Column({ nullable: true })
  firstName: string;

  @Column({ nullable: true })
  lastName: string;

  @Column({ nullable: true })
  @Index()
  phone: string;

  @Column({ nullable: true })
  email: string;

  @Column({ type: 'text', nullable: true })
  address: string;

  @Column({
    type: 'enum',
    enum: CustomerSource,
    default: CustomerSource.TELEGRAM_BOT,
  })
  source: CustomerSource;

  @Column({
    type: 'enum',
    enum: CustomerStatus,
    default: CustomerStatus.ACTIVE,
  })
  status: CustomerStatus;

  @Column({ type: 'boolean', default: false })
  @Index()
  isPhoneVerified: boolean;

  @Column({ type: 'timestamp', nullable: true })
  lastOrderAt: Date;

  @Column({ type: 'decimal', precision: 10, scale: 2, default: 0 })
  totalSpent: number;

  @Column({ type: 'int', default: 0 })
  totalOrders: number;

  @CreateDateColumn({ name: 'created_at' })
  createdAt: Date;

  @UpdateDateColumn({ name: 'updated_at' })
  updatedAt: Date;
}
