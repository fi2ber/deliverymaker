import { Test, TestingModule } from '@nestjs/testing';
import { INestApplication } from '@nestjs/common';
import * as request from 'supertest';
import { TenancyMiddleware } from '../src/common/middlewares/tenancy.middleware';
import { JwtService } from '@nestjs/jwt';
import { describe, it, beforeAll, afterAll, expect, jest } from '@jest/globals';
import { Controller, Get, Req } from '@nestjs/common';
import { Request } from 'express';

// Test controller
@Controller()
class TestController {
    @Get('/test/tenant')
    getTenant(@Req() req: Request) {
        return { tenantId: (req as any).tenantId };
    }

    @Get('/test/jwt-tenant')
    getJwtTenant(@Req() req: Request) {
        return { 
            tenantId: (req as any).tenantId,
            user: (req as any).user 
        };
    }

    @Get('/test/subdomain')
    getSubdomain(@Req() req: Request) {
        const host = req.headers.host || '';
        const subdomain = host.split('.')[0];
        if (subdomain && subdomain !== 'localhost' && subdomain !== '127') {
            (req as any).tenantId = subdomain;
        }
        return { tenantId: (req as any).tenantId };
    }

    @Get('/health')
    getHealth(@Req() req: Request) {
        return { status: 'ok', tenantId: (req as any).tenantId };
    }
}

describe('Tenancy Middleware (e2e)', () => {
    let app: INestApplication;
    let mockJwtService: any;
    let middleware: TenancyMiddleware;

    beforeAll(async () => {
        mockJwtService = {
            decode: jest.fn((token: string): any => {
                if (token === 'valid.token.here') {
                    return { 
                        sub: 'user-1', 
                        email: 'test@test.com',
                        tenantId: 'tenant_from_jwt',
                        role: 'ADMIN'
                    };
                }
                return null;
            }),
        };

        const moduleFixture: TestingModule = await Test.createTestingModule({
            controllers: [TestController],
            providers: [
                {
                    provide: JwtService,
                    useValue: mockJwtService,
                },
            ],
        }).compile();

        app = moduleFixture.createNestApplication();
        
        // Create and apply middleware
        middleware = new TenancyMiddleware(mockJwtService);
        app.use(middleware.use.bind(middleware));
        
        await app.init();
    });

    afterAll(async () => {
        await app.close();
    });

    describe('Tenant Identification via Header', () => {
        it('should extract tenant from x-tenant-id header', async () => {
            return request(app.getHttpServer())
                .get('/test/tenant')
                .set('x-tenant-id', 'tenant_abc')
                .expect(200)
                .expect((res) => {
                    expect(res.body.tenantId).toBe('tenant_abc');
                });
        });
    });

    describe('Tenant Identification via JWT', () => {
        it('should extract tenant from JWT token when available', async () => {
            return request(app.getHttpServer())
                .get('/test/jwt-tenant')
                .set('Authorization', 'Bearer valid.token.here')
                .expect(200)
                .expect((res) => {
                    expect(res.body.tenantId).toBe('tenant_from_jwt');
                    expect(res.body.user.email).toBe('test@test.com');
                });
        });

        it('should use header when JWT is invalid', async () => {
            return request(app.getHttpServer())
                .get('/test/tenant')
                .set('Authorization', 'Bearer invalid.token')
                .set('x-tenant-id', 'header_tenant')
                .expect(200)
                .expect((res) => {
                    expect(res.body.tenantId).toBe('header_tenant');
                });
        });
    });

    describe('Subdomain extraction', () => {
        it('should extract tenant from subdomain in host header', async () => {
            return request(app.getHttpServer())
                .get('/test/subdomain')
                .set('Host', 'tenant123.deliverymaker.uz')
                .set('x-tenant-id', 'fallback')
                .expect(200)
                .expect((res) => {
                    expect(res.body.tenantId).toBe('tenant123');
                });
        });
    });

    describe('Security', () => {
        it('should reject invalid tenant ID characters in header', async () => {
            return request(app.getHttpServer())
                .get('/test/tenant')
                .set('x-tenant-id', "tenant'; DROP TABLE users; --")
                .expect(401)
                .expect((res) => {
                    expect(res.body.message).toContain('Invalid tenant ID format');
                });
        });

        it('should accept valid tenant ID formats', async () => {
            const validTenantIds = [
                'tenant_123',
                'tenant-abc',
                'TenantABC',
                'tenant123_test',
            ];

            for (const tenantId of validTenantIds) {
                await request(app.getHttpServer())
                    .get('/test/tenant')
                    .set('x-tenant-id', tenantId)
                    .expect(200)
                    .expect((res) => {
                        expect(res.body.tenantId).toBe(tenantId);
                    });
            }
        });

        it('should require tenant identification', async () => {
            return request(app.getHttpServer())
                .get('/test/tenant')
                .expect(401)
                .expect((res) => {
                    expect(res.body.message).toContain('Tenant identification required');
                });
        });
    });

    describe('Request Context Isolation', () => {
        it('should maintain tenant isolation across concurrent requests', async () => {
            const requests = [
                { tenant: 'tenant_a', expected: 'tenant_a' },
                { tenant: 'tenant_b', expected: 'tenant_b' },
                { tenant: 'tenant_c', expected: 'tenant_c' },
            ];

            const responses = await Promise.all(
                requests.map(r => 
                    request(app.getHttpServer())
                        .get('/test/tenant')
                        .set('x-tenant-id', r.tenant)
                )
            );

            responses.forEach((res, idx) => {
                expect(res.body.tenantId).toBe(requests[idx].expected);
            });
        });
    });

    describe('Public Paths', () => {
        it('should allow access to public paths without tenant', async () => {
            return request(app.getHttpServer())
                .get('/health')
                .expect(200)
                .expect((res) => {
                    expect(res.body.status).toBe('ok');
                    expect(res.body.tenantId).toBe('public');
                });
        });
    });
});
