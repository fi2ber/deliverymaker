import { Module, Global, Scope, OnModuleDestroy } from '@nestjs/common';
import { DataSource } from 'typeorm';
import { REQUEST } from '@nestjs/core';
import { Request } from 'express';

export const TENANT_CONNECTION = 'TENANT_CONNECTION';

// Connection pool to avoid creating new connections per request
const connectionPool = new Map<string, DataSource>();

async function getOrCreateConnection(tenantId: string): Promise<DataSource> {
    if (connectionPool.has(tenantId)) {
        const existing = connectionPool.get(tenantId)!;
        if (existing.isInitialized) {
            return existing;
        }
        // Connection was closed, remove from pool
        connectionPool.delete(tenantId);
    }

    const dataSource = new DataSource({
        type: 'postgres',
        host: process.env.DB_HOST || 'localhost',
        port: parseInt(process.env.DB_PORT || '5432'),
        username: process.env.DB_USER || 'postgres',
        password: process.env.DB_PASSWORD || 'postgres',
        database: process.env.DB_NAME || 'delivery_maker',
        schema: tenantId,
        entities: [__dirname + '/../**/*.entity{.ts,.js}'],
        synchronize: process.env.NODE_ENV !== 'production',
        logging: process.env.NODE_ENV === 'development',
        // Connection pool settings
        extra: {
            max: 10, // Maximum pool size per tenant
            idleTimeoutMillis: 30000,
            connectionTimeoutMillis: 2000,
        },
    });

    await dataSource.initialize();
    connectionPool.set(tenantId, dataSource);
    return dataSource;
}

@Global()
@Module({
    providers: [
        {
            provide: TENANT_CONNECTION,
            inject: [REQUEST],
            scope: Scope.REQUEST,
            useFactory: async (req: Request) => {
                const tenantId = (req as any).tenantId || 'public';
                
                // Validate tenantId format (prevent injection)
                if (!/^[a-zA-Z0-9_-]+$/.test(tenantId)) {
                    throw new Error('Invalid tenant ID format');
                }

                return getOrCreateConnection(tenantId);
            },
        },
    ],
    exports: [TENANT_CONNECTION],
})
export class DatabaseModule implements OnModuleDestroy {
    async onModuleDestroy() {
        // Close all connections on shutdown
        for (const [tenantId, dataSource] of connectionPool.entries()) {
            if (dataSource.isInitialized) {
                await dataSource.destroy();
            }
        }
        connectionPool.clear();
    }
}
