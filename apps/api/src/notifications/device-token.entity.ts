import { Entity, PrimaryGeneratedColumn, Column, ManyToOne, CreateDateColumn, Index } from 'typeorm';
import { User } from '../users/user.entity';

export enum DevicePlatform {
    IOS = 'ios',
    ANDROID = 'android',
    WEB = 'web',
}

@Entity('device_tokens')
@Index(['token', 'platform'], { unique: true })
export class DeviceToken {
    @PrimaryGeneratedColumn('uuid')
    id: string;

    @Column()
    token: string; // FCM token or Web Push token

    @Column({ type: 'enum', enum: DevicePlatform })
    platform: DevicePlatform;

    @ManyToOne(() => User, { onDelete: 'CASCADE' })
    user: User;

    @Column({ default: true })
    isActive: boolean;

    @Column({ nullable: true })
    deviceInfo: string; // Device model, browser info, etc.

    @Column({ type: 'timestamp', nullable: true })
    lastUsedAt: Date;

    @CreateDateColumn()
    createdAt: Date;
}
