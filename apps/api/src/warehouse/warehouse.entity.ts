import { Entity, PrimaryGeneratedColumn, Column, CreateDateColumn, UpdateDateColumn, OneToOne, JoinColumn } from 'typeorm';
import { User } from '../users/user.entity';

@Entity('warehouses')
export class Warehouse {
    @PrimaryGeneratedColumn('uuid')
    id: string;

    @Column()
    name: string;

    @Column({ type: 'enum', enum: ['MAIN', 'TRUCK'], default: 'MAIN' })
    type: 'MAIN' | 'TRUCK';

    @Column({ nullable: true })

    @Column({ nullable: true })
    address: string;

    @Column({ type: 'decimal', precision: 10, scale: 6, nullable: true })
    latitude: number;

    @Column({ type: 'decimal', precision: 10, scale: 6, nullable: true })
    longitude: number;

    @Column({ default: true })
    isActive: boolean;

    @CreateDateColumn()
    createdAt: Date;

    @UpdateDateColumn()
    updatedAt: Date;

    @OneToOne(() => User, { nullable: true })
    @JoinColumn()
    driver: User;
}
