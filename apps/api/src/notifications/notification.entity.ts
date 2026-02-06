import { Entity, PrimaryGeneratedColumn, Column, CreateDateColumn, ManyToOne } from 'typeorm';
import { User } from '../users/user.entity';
import { Order } from '../sales/order.entity';

@Entity('notifications')
export class Notification {
    @PrimaryGeneratedColumn('uuid')
    id: string;

    @Column()
    title: string;

    @Column({ type: 'text' })
    message: string;

    @Column({ default: false })
    isRead: boolean;

    @Column({ type: 'enum', enum: ['INFO', 'WARNING', 'ALERT'], default: 'INFO' })
    type: 'INFO' | 'WARNING' | 'ALERT';

    @ManyToOne(() => User, (user) => user.notifications, { nullable: true })
    user: User;

    @Column({ nullable: true })
    metadata: string; // JSON string for extra data (e.g. orderId: 123)

    @CreateDateColumn()
    createdAt: Date;
}
