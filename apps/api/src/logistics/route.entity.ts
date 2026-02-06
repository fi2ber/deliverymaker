import { Entity, PrimaryGeneratedColumn, Column, ManyToOne, OneToMany, CreateDateColumn, UpdateDateColumn } from 'typeorm';
import { User } from '../users/user.entity';
import { RouteStop } from './route-stop.entity';

export enum RouteStatus {
    DRAFT = 'DRAFT',
    ASSIGNED = 'ASSIGNED',
    IN_PROGRESS = 'IN_PROGRESS',
    COMPLETED = 'COMPLETED',
    CANCELLED = 'CANCELLED',
}

@Entity('routes')
export class Route {
    @PrimaryGeneratedColumn('uuid')
    id: string;

    @Column({ generated: 'increment' })
    humanId: number;

    @ManyToOne(() => User, (user) => user.id) // Driver
    driver: User;

    @Column({ type: 'date' })
    date: Date;

    @Column({ type: 'enum', enum: RouteStatus, default: RouteStatus.DRAFT })
    status: RouteStatus;

    // Total efficiency metrics
    @Column({ type: 'decimal', precision: 10, scale: 2, default: 0 })
    totalDistanceKm: number;

    @OneToMany(() => RouteStop, (stop) => stop.route, { cascade: true })
    stops: RouteStop[];

    @CreateDateColumn()
    createdAt: Date;

    @UpdateDateColumn()
    updatedAt: Date;
}
