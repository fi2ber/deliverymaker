import { Entity, PrimaryGeneratedColumn, Column, ManyToOne } from 'typeorm';
import { Route } from './route.entity';
import { Order } from '../sales/order.entity';

@Entity('route_stops')
export class RouteStop {
    @PrimaryGeneratedColumn('uuid')
    id: string;

    @ManyToOne(() => Route, (route) => route.stops, { onDelete: 'CASCADE' })
    route: Route;

    @ManyToOne(() => Order)
    order: Order;

    @Column({ type: 'int' })
    sequence: number;

    @Column({ nullable: true })
    estimatedArrivalTime: Date;

    @Column({ nullable: true })
    actualArrivalTime: Date;

    @Column({ nullable: true })
    completionTime: Date;

    @Column({ type: 'boolean', default: false })
    isCompleted: boolean;
}
