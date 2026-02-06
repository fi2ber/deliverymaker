import { 
    Entity, 
    PrimaryGeneratedColumn, 
    Column, 
    ManyToOne, 
    OneToMany, 
    CreateDateColumn, 
    UpdateDateColumn,
    JoinColumn,
} from 'typeorm';
import { Warehouse } from '../warehouse.entity';
import { User } from '../../users/user.entity';

export enum InventoryCountStatus {
    DRAFT = 'draft',
    IN_PROGRESS = 'in_progress',
    COMPLETED = 'completed',
    CANCELLED = 'cancelled',
}

@Entity('inventory_counts')
export class InventoryCount {
    @PrimaryGeneratedColumn('uuid')
    id: string;

    @Column()
    name: string; // e.g., "Monthly Stock Count March 2024"

    @ManyToOne(() => Warehouse)
    @JoinColumn()
    warehouse: Warehouse;

    @Column({
        type: 'enum',
        enum: InventoryCountStatus,
        default: InventoryCountStatus.DRAFT,
    })
    status: InventoryCountStatus;

    @ManyToOne(() => User)
    createdBy: User;

    @ManyToOne(() => User, { nullable: true })
    completedBy: User;

    @Column({ type: 'timestamp', nullable: true })
    startedAt: Date;

    @Column({ type: 'timestamp', nullable: true })
    completedAt: Date;

    @OneToMany(() => InventoryCountItem, item => item.inventoryCount, { cascade: true })
    items: InventoryCountItem[];

    @Column({ type: 'text', nullable: true })
    notes: string;

    @CreateDateColumn()
    createdAt: Date;

    @UpdateDateColumn()
    updatedAt: Date;
}

@Entity('inventory_count_items')
export class InventoryCountItem {
    @PrimaryGeneratedColumn('uuid')
    id: string;

    @ManyToOne(() => InventoryCount, count => count.items)
    inventoryCount: InventoryCount;

    @Column()
    productId: string;

    @Column()
    productName: string; // Snapshot of name at count time

    @Column({ type: 'decimal', precision: 10, scale: 2 })
    expectedQuantity: number;

    @Column({ type: 'decimal', precision: 10, scale: 2, nullable: true })
    actualQuantity: number;

    @Column({ type: 'decimal', precision: 10, scale: 2, nullable: true })
    difference: number;

    @ManyToOne(() => User, { nullable: true })
    countedBy: User;

    @Column({ type: 'timestamp', nullable: true })
    countedAt: Date;

    @Column({ nullable: true })
    notes: string; // e.g., "Damaged goods found"

    @Column({ default: false })
    isRecount: boolean; // Flag for items needing recount

    @CreateDateColumn()
    createdAt: Date;

    @UpdateDateColumn()
    updatedAt: Date;
}
