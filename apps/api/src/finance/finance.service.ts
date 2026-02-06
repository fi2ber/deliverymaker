import { Inject, Injectable, BadRequestException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository, DataSource } from 'typeorm';
import { CashHandover, HandoverStatus } from './cash-handover.entity';
import { Order, OrderStatus, PaymentStatus, PaymentMethod } from '../sales/order.entity';
import { TENANT_CONNECTION } from '../database/database.module';

@Injectable()
export class FinanceService {
    constructor(
        @Inject(TENANT_CONNECTION) private dataSource: DataSource,
    ) { }

    private get handoverRepo() { return this.dataSource.getRepository(CashHandover); }
    private get orderRepo() { return this.dataSource.getRepository(Order); }

    async getDriverBalance(driverId: string): Promise<number> {
        // 1. Total Cash Collected from Orders
        const result = await this.orderRepo
            .createQueryBuilder('order')
            .select('SUM(order.paidAmount)', 'totalCollected')
            .where('order.driver.id = :driverId', { driverId })
            .andWhere('order.status = :status', { status: OrderStatus.DELIVERED })
            .andWhere('order.paymentMethod = :method', { method: PaymentMethod.CASH })
            .getRawOne();

        const totalCollected = Number(result?.totalCollected || 0);

        // 2. Total Handed Over (Confirmed)
        const handoverResult = await this.handoverRepo
            .createQueryBuilder('handover')
            .select('SUM(handover.amount)', 'totalHandedOver')
            .where('handover.driver.id = :driverId', { driverId })
            .andWhere('handover.status = :status', { status: HandoverStatus.CONFIRMED })
            .getRawOne();

        const totalHandedOver = Number(handoverResult?.totalHandedOver || 0);

        return totalCollected - totalHandedOver;
    }

    async requestHandover(driverId: string, amount: number) {
        if (amount <= 0) throw new BadRequestException('Amount must be positive');

        const currentBalance = await this.getDriverBalance(driverId);
        if (amount > currentBalance) throw new BadRequestException(`Insufficient balance. You have ${currentBalance}`);

        const handover = this.handoverRepo.create({
            driver: { id: driverId },
            amount,
            status: HandoverStatus.PENDING
        });

        return this.handoverRepo.save(handover);
    }

    // Admin Action
    async confirmHandover(handoverId: string, cashierId: string) {
        const handover = await this.handoverRepo.findOneBy({ id: handoverId });
        if (!handover) throw new BadRequestException('Handover not found');
        if (handover.status !== HandoverStatus.PENDING) throw new BadRequestException('Already processed');

        handover.status = HandoverStatus.CONFIRMED;
        handover.cashier = { id: cashierId } as any;

        return this.handoverRepo.save(handover);
    }
}
