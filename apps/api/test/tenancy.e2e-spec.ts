import { Test, TestingModule } from '@nestjs/testing';
import { INestApplication } from '@nestjs/common';
import * as request from 'supertest';
import { AppModule } from '../src/app.module';

describe('Tenancy Isolation (e2e)', () => {
    let app: INestApplication;
    let tenantAToken: string;
    let tenantBToken: string;

    beforeAll(async () => {
        const moduleFixture: TestingModule = await Test.createTestingModule({
            imports: [AppModule],
        }).compile();

        app = moduleFixture.createNestApplication();
        await app.init();

        // Login as tenant A user
        const loginAResponse = await request(app.getHttpServer())
            .post('/auth/login')
            .send({ email: 'tenant-a@example.com', password: 'password123' });
        tenantAToken = loginAResponse.body.access_token;

        // Login as tenant B user
        const loginBResponse = await request(app.getHttpServer())
            .post('/auth/login')
            .send({ email: 'tenant-b@example.com', password: 'password123' });
        tenantBToken = loginBResponse.body.access_token;
    });

    afterAll(async () => {
        await app.close();
    });

    describe('Data Isolation', () => {
        let createdProductId: string;

        it('should create product in tenant A', async () => {
            const response = await request(app.getHttpServer())
                .post('/products')
                .set('Authorization', `Bearer ${tenantAToken}`)
                .send({
                    name: 'Tenant A Product',
                    sku: 'TENT-A-001',
                    price: 100,
                })
                .expect(201);

            createdProductId = response.body.id;
            expect(response.body.name).toBe('Tenant A Product');
        });

        it('should NOT see tenant A product from tenant B', async () => {
            const response = await request(app.getHttpServer())
                .get('/products')
                .set('Authorization', `Bearer ${tenantBToken}`)
                .expect(200);

            const products = response.body;
            const tenantAProduct = products.find((p: any) => p.id === createdProductId);
            expect(tenantAProduct).toBeUndefined();
        });

        it('should see product in tenant A', async () => {
            const response = await request(app.getHttpServer())
                .get('/products')
                .set('Authorization', `Bearer ${tenantAToken}`)
                .expect(200);

            const products = response.body;
            const tenantAProduct = products.find((p: any) => p.id === createdProductId);
            expect(tenantAProduct).toBeDefined();
            expect(tenantAProduct.name).toBe('Tenant A Product');
        });

        it('should return 404 when tenant B tries to access tenant A product', async () => {
            await request(app.getHttpServer())
                .get(`/products/${createdProductId}`)
                .set('Authorization', `Bearer ${tenantBToken}`)
                .expect(404);
        });
    });

    describe('JWT Tenant Enforcement', () => {
        it('should reject requests without valid JWT token', async () => {
            await request(app.getHttpServer())
                .get('/products')
                .expect(401);
        });

        it('should reject requests with invalid JWT token', async () => {
            await request(app.getHttpServer())
                .get('/products')
                .set('Authorization', 'Bearer invalid-token')
                .expect(401);
        });
    });

    describe('Role-based Access Control', () => {
        it('should allow driver to create van-sale', async () => {
            const driverLogin = await request(app.getHttpServer())
                .post('/auth/login')
                .send({ email: 'driver@example.com', password: 'password123' });
            const driverToken = driverLogin.body.access_token;

            await request(app.getHttpServer())
                .post('/orders/van-sale')
                .set('Authorization', `Bearer ${driverToken}`)
                .send({
                    clientId: 'client-uuid',
                    items: [{ productId: 'product-uuid', quantity: 1, price: 100 }],
                })
                .expect(201);
        });

        it('should reject driver from accessing analytics', async () => {
            const driverLogin = await request(app.getHttpServer())
                .post('/auth/login')
                .send({ email: 'driver@example.com', password: 'password123' });
            const driverToken = driverLogin.body.access_token;

            await request(app.getHttpServer())
                .get('/analytics/dashboard')
                .set('Authorization', `Bearer ${driverToken}`)
                .expect(403);
        });
    });
});
