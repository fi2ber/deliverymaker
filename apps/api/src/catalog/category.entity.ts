import { Entity, PrimaryGeneratedColumn, Column, CreateDateColumn, UpdateDateColumn, Tree, TreeChildren, TreeParent } from 'typeorm';

@Entity('categories')
@Tree("materialized-path")
export class Category {
    @PrimaryGeneratedColumn('uuid')
    id: string;

    @Column()
    name: string;

    @Column({ nullable: true })
    image: string;

    @TreeChildren()
    children: Category[];

    @TreeParent()
    parent: Category;

    @CreateDateColumn()
    createdAt: Date;

    @UpdateDateColumn()
    updatedAt: Date;
}
