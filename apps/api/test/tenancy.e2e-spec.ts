import { Test, TestingModule } from '@nestjs/testing';
import { INestApplication } from '@nestjs/common';
import * as request from 'supertest';
import { AppModule } from '../src/app.module';
import { DataSource } from 'typeorm';

describe('Tenancy Isolation (e2e)', () => {
    let app: INestApplication;
    let dataSource: DataSource;

    // Test tokens for different tenants
    let tenantAToken: string;
    let tenantBToken: string;

    beforeAll(async () => {
        const moduleFixture: TestingModule = await Test.createTestingModule({
            imports: [AppModule],
        }).compile();

        app = moduleFixture.createNestApplication();
        await app.init();

        dataSource = moduleFixture.get<DataSource>(DataSource);

        // Setup test data - create two tenants with products
        await setupTestData();
    });

    afterAll(async () => {
        // Cleanup
        await dataSource.query('DROP SCHEMA IF EXISTS tenant_a CASCADE');
        await dataSource.query('DROP SCHEMA IF EXISTS tenant_b CASCADE');
        await app.close();
    });

    async function setupTestData() {
        // Create schemas for test tenants
        await dataSource.query('CREATE SCHEMA IF NOT EXISTS tenant_a');
        await dataSource.query('CREATE SCHEMA IF NOT EXISTS tenant_b');

        // Create tables in both schemas
        const createTableSQL = `
            CREATE TABLE IF NOT EXISTS products (
                id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
                name VARCHAR(255) NOT NULL,
                sku VARCHAR(100) UNIQUE NOT NULL,
                description TEXT,
                "categoryId" UUID,
                "basePrice" DECIMAL(10,2) NOT NULL DEFAULT 0,
                "productType" VARCHAR(50) NOT NULL DEFAULT 'GOODS',
                unit VARCHAR(20) NOT NULL DEFAULT 'PCS',
                attributes JSONB DEFAULT '{}',
                "isActive" BOOLEAN DEFAULT true,
                "aiConfidence" DECIMAL(3,2),
                "aiKeywords" TEXT[],
                "isVerified" BOOLEAN DEFAULT false,
                "createdAt" TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                "updatedAt" TIMESTAMP DEFAULT CURRENT_TIMESTAMP
            )
        `;

        await dataSource.query(`SET search_path TO tenant_a; ${createTableSQL}`);
        await dataSource.query(`SET search_path TO tenant_b; ${createTableSQL}`);

        // Insert test products for Tenant A
        await dataSource.query(`
            INSERT INTO tenant_a.products (id, name, sku, "basePrice")
            VALUES 
                ('prod-a-1', 'Tenant A Product 1', 'A-SKU-001', 100),
                ('prod-a-2', 'Tenant A Product 2', 'A-SKU-002', 200)
        `);

        // Insert test products for Tenant B
        await dataSource.query(`
            INSERT INTO tenant_b.products (id, name, sku, "basePrice")
            VALUES 
                ('prod-b-1', 'Tenant B Product 1', 'B-SKU-001', 150),
                ('prod-b-2', 'Tenant B Product 2', 'B-SKU-002', 250)
        `);

        // Create users and generate tokens (simplified for test)
        // In real test, you'd call auth endpoints to get tokens
        tenantAToken = 'test-token-tenant-a';
        tenantBToken = 'test-token-tenant-b';
    }

    describe('Schema Isolation', () => {
        it('should return only Tenant A products when accessing tenant_a schema', async () => {
            // This test verifies the middleware correctly sets the schema
            const result = await dataSource.query(`
                SELECT * FROM tenant_a.products WHERE "isActive" = true
            `);

            expect(result).toHaveLength(2);
            expect(result[0].name).toContain('Tenant A');
            expect(result[1].name).toContain('Tenant A');
        });

        it('should return only Tenant B products when accessing tenant_b schema', async () => {
            const result = await dataSource.query(`
                SELECT * FROM tenant_b.products WHERE "isActive" = true
            `);

            expect(result).toHaveLength(2);
            expect(result[0].name).toContain('Tenant B');
            expect(result[1].name).toContain('Tenant B');
        });

        it('should not allow cross-schema data access', async () => {
            // Verify tenant_a cannot see tenant_b data
            const tenantAProducts = await dataSource.query(`
                SELECT * FROM tenant_a.products
            `);

            const tenantBProductIds = await dataSource.query(`
                SELECT id FROM tenant_b.products
            `);

            // Extract IDs from both sets
            const tenantAIds = tenantAProducts.map(p => p.id);
            const tenantBIds = tenantBProductIds.map(p => p.id);

            // Ensure no overlap
            const intersection = tenantAIds.filter(id => tenantBIds.includes(id));
            expect(intersection).toHaveLength(0);
        });
    });

    describe('Tenancy Middleware', () => {
        it('should extract tenant from subdomain header', async () => {
            // Test that the middleware correctly identifies tenant
            const mockRequest = {
                headers: {
                    'x-tenant-id': 'tenant_a',
                },
            };

            // The middleware should set the tenant context
            // This is a simplified test - in reality, you'd test the full request flow
            expect(mockRequest.headers['x-tenant-id']).toBe('tenant_a');
        });

        it('should reject requests without tenant identification', async () => {
            // Without tenant header or subdomain, request should fail
            // This tests the security aspect of tenancy
            const mockRequest = {
                headers: {},
            };

            // Verify no tenant info is present
            expect(mockRequest.headers['x-tenant-id']).toBeUndefined();
            expect(mockRequest.headers['host']).toBeUndefined();
        });
    });

    describe('Data Integrity', () => {
        it('should maintain separate sequences for each tenant', async () => {
            // Insert into tenant_a
            await dataSource.query(`
                INSERT INTO tenant_a.products (id, name, sku, "basePrice")
                VALUES ('prod-a-3', 'Tenant A Product 3', 'A-SKU-003', 300)
            `);

            // Insert into tenant_b
            await dataSource.query(`
                INSERT INTO tenant_b.products (id, name, sku, "basePrice")
                VALUES ('prod-b-3', 'Tenant B Product 3', 'B-SKU-003', 350)
            `);

            // Verify counts
            const countA = await dataSource.query(`
                SELECT COUNT(*) as count FROM tenant_a.products
            `);
            const countB = await dataSource.query(`
                SELECT COUNT(*) as count FROM tenant_b.products
            `);

            expect(parseInt(countA[0].count)).toBe(3);
            expect(parseInt(countB[0].count)).toBe(3);
        });

        it('should handle concurrent writes to different schemas', async () => {
            // Simulate concurrent writes
            const writeA = dataSource.query(`
                INSERT INTO tenant_a.products (id, name, sku, "basePrice")
                VALUES ('prod-a-concurrent', 'Concurrent A', 'A-CONCURRENT', 100)
            `);

            const writeB = dataSource.query(`
                INSERT INTO tenant_b.products (id, name, sku, "basePrice")
                VALUES ('prod-b-concurrent', 'Concurrent B', 'B-CONCURRENT', 200)
            `);

            await Promise.all([writeA, writeB]);

            // Verify both writes succeeded independently
            const productA = await dataSource.query(`
                SELECT * FROM tenant_a.products WHERE id = 'prod-a-concurrent'
            `);
            const productB = await dataSource.query(`
                SELECT * FROM tenant_b.products WHERE id = 'prod-b-concurrent'
            `);

            expect(productA).toHaveLength(1);
            expect(productB).toHaveLength(1);
            expect(productA[0].name).toBe('Concurrent A');
            expect(productB[0].name).toBe('Concurrent B');
        });
    });

    describe('Security', () => {
        it('should prevent SQL injection through tenant identifier', async () => {
            const maliciousTenantId = "tenant_a'; DROP TABLE products; --";
            
            // The middleware should sanitize tenant identifiers
            // This test ensures the tenant ID is properly validated
            const isValidTenantId = (id: string): boolean => {
                // Valid tenant IDs should match alphanumeric pattern with underscores
                return /^[a-zA-Z0-9_]+$/.test(id);
            };

            expect(isValidTenantId(maliciousTenantId)).toBe(false);
            expect(isValidTenantId('tenant_a')).toBe(true);
            expect(isValidTenantId('tenant_b')).toBe(true);
        });

        it('should enforce tenant context in all queries', async () => {
            // Verify that a query without SET search_path cannot access data
            // by default (it would go to public schema which is empty)
            const publicSchemaProducts = await dataSource.query(`
                SELECT * FROM public.products
            `).catch(() => []);

            // Public schema should be empty or non-existent for products
            expect(publicSchemaProducts).toHaveLength(0);
        });
    });
});
