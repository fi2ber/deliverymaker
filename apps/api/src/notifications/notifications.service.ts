import { Inject, Injectable } from '@nestjs/common';
import { DataSource } from 'typeorm';
import { TENANT_CONNECTION } from '../database/database.module';
import { Notification } from './notification.entity';
import { User } from '../users/user.entity';

@Injectable()
export class NotificationsService {
    constructor(
        @Inject(TENANT_CONNECTION) private dataSource: DataSource,
    ) { }

    private get notificationRepo() { return this.dataSource.getRepository(Notification); }

    async create(data: { userId?: string, title: string, message: string, type?: 'INFO' | 'WARNING' | 'ALERT', metadata?: any }) {
        const notification = this.notificationRepo.create({
            title: data.title,
            message: data.message,
            type: data.type || 'INFO',
            metadata: data.metadata ? JSON.stringify(data.metadata) : null,
            user: data.userId ? { id: data.userId } : null
        });

        return this.notificationRepo.save(notification);
    }

    async getForUser(userId: string) {
        return this.notificationRepo.find({
            where: { user: { id: userId } },
            order: { createdAt: 'DESC' },
            take: 50
        });
    }

    async markAsRead(id: string) {
        return this.notificationRepo.update(id, { isRead: true });
    }
}
