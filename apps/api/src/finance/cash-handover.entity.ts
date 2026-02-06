import { Entity, PrimaryGeneratedColumn, Column, CreateDateColumn, ManyToOne } from 'typeorm';
import { User } from '../users/user.entity';

export enum HandoverStatus {
    PENDING = 'PENDING',
    CONFIRMED = 'CONFIRMED',
    REJECTED = 'REJECTED',
}

@Entity('cash_handovers')
export class CashHandover {
    @PrimaryGeneratedColumn('uuid')
    id: string;

    @ManyToOne(() => User)
    driver: User;

    @ManyToOne(() => User, { nullable: true })
    cashier: User; // Who accepted it

    @Column({ type: 'decimal', precision: 12, scale: 2 })
    amount: number;

    @Column({ type: 'enum', enum: HandoverStatus, default: HandoverStatus.PENDING })
    status: HandoverStatus;

    @CreateDateColumn()
    createdAt: Date;
}
