import { Entity, PrimaryColumn, Column } from 'typeorm';

@Entity('system_settings')
export class SystemSetting {
    @PrimaryColumn()
    key: string;

    @Column()
    value: string;

    @Column({ nullable: true })
    description: string;
}
