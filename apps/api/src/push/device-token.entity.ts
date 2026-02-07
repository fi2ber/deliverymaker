import { Entity, PrimaryGeneratedColumn, Column, CreateDateColumn, UpdateDateColumn, Index } from 'typeorm';

export enum DevicePlatform {
    IOS = 'ios',
    ANDROID = 'android',
    WEB = 'web',
}

export enum UserRole {
    DRIVER = 'driver',
    SALES = 'sales',
    MANAGER = 'manager',
    ADMIN = 'admin',
}

@Entity('device_tokens')
export class DeviceToken {
    @PrimaryGeneratedColumn('uuid')
    id: string;

    @Index()
    @Column({ name: 'user_id' })
    userId: string;

    @Column({
        type: 'enum',
        enum: UserRole,
    })
    role: UserRole;

    @Column()
    @Index()
    token: string;

    @Column({
        type: 'enum',
        enum: DevicePlatform,
    })
    platform: DevicePlatform;

    @Column({ name: 'device_name', nullable: true })
    deviceName?: string;

    @Column({ name: 'app_version', nullable: true })
    appVersion?: string;

    @Column({ name: 'tenant_id', nullable: true })
    tenantId?: string;

    @Column({ type: 'boolean', default: true })
    isActive: boolean;

    @Column({ type: 'timestamp', nullable: true })
    lastUsedAt?: Date;

    @CreateDateColumn({ name: 'created_at' })
    createdAt: Date;

    @UpdateDateColumn({ name: 'updated_at' })
    updatedAt: Date;
}
