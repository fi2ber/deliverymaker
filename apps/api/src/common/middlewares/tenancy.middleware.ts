import { Injectable, NestMiddleware, UnauthorizedException } from '@nestjs/common';
import { Request, Response, NextFunction } from 'express';
import { JwtService } from '@nestjs/jwt';

const TENANT_HEADER = 'x-tenant-id';
const PUBLIC_PATHS = ['/auth/login', '/auth/register', '/health'];

@Injectable()
export class TenancyMiddleware implements NestMiddleware {
    constructor(private readonly jwtService: JwtService) {}

    use(req: Request, res: Response, next: NextFunction) {
        // Allow public paths without tenant check
        if (PUBLIC_PATHS.some(path => req.path.startsWith(path))) {
            (req as any).tenantId = 'public';
            return next();
        }

        // Try to extract tenant from JWT token
        const authHeader = req.headers.authorization;
        if (authHeader?.startsWith('Bearer ')) {
            const token = authHeader.substring(7);
            try {
                const payload = this.jwtService.decode(token) as any;
                if (payload?.tenantId) {
                    (req as any).tenantId = payload.tenantId;
                    (req as any).user = payload;
                    return next();
                }
            } catch (e) {
                // Invalid token, will check header fallback
            }
        }

        // Fallback to header (for legacy or specific use cases)
        const tenantId = req.headers[TENANT_HEADER] as string;
        if (tenantId) {
            // Validate tenantId format
            if (!/^[a-zA-Z0-9_-]+$/.test(tenantId)) {
                throw new UnauthorizedException('Invalid tenant ID format');
            }
            (req as any).tenantId = tenantId;
            return next();
        }

        // No tenant identified
        throw new UnauthorizedException('Tenant identification required');
    }
}
