import { Injectable, NestMiddleware, UnauthorizedException } from '@nestjs/common';
import { Request, Response, NextFunction } from 'express';
import { JwtService } from '@nestjs/jwt';
import { createHmac } from 'crypto';

const TENANT_HEADER = 'x-tenant-id';
const TELEGRAM_INIT_DATA_HEADER = 'x-telegram-init-data';
const PUBLIC_PATHS = ['/auth/login', '/auth/register', '/health', '/subscriptions/combos/tma'];

@Injectable()
export class TenancyMiddleware implements NestMiddleware {
    constructor(private readonly jwtService: JwtService) {}

    use(req: Request, res: Response, next: NextFunction) {
        // Allow public paths without tenant check
        if (PUBLIC_PATHS.some(path => req.path.startsWith(path))) {
            // Extract tenant from header if provided, otherwise use 'public'
            const tenantId = req.headers[TENANT_HEADER] as string;
            (req as any).tenantId = tenantId && /^[a-zA-Z0-9_-]+$/.test(tenantId) ? tenantId : 'public';
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

        // Check for Telegram WebApp initData
        const initData = req.headers[TELEGRAM_INIT_DATA_HEADER] as string;
        if (initData) {
            // Parse initData to extract user info
            const parsed = this.parseInitData(initData);
            if (parsed?.user) {
                (req as any).telegramUser = JSON.parse(parsed.user);
                (req as any).initData = initData;
                // Tenant should be provided via header when using Telegram auth
                const tenantId = req.headers[TENANT_HEADER] as string;
                if (tenantId && /^[a-zA-Z0-9_-]+$/.test(tenantId)) {
                    (req as any).tenantId = tenantId;
                    return next();
                }
            }
        }

        // Fallback to header
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

    private parseInitData(initData: string): Record<string, string> | null {
        try {
            const params = new URLSearchParams(initData);
            const result: Record<string, string> = {};
            for (const [key, value] of params) {
                result[key] = value;
            }
            return result;
        } catch {
            return null;
        }
    }
}

// Helper to verify Telegram WebApp initData
export function verifyTelegramInitData(initData: string, botToken: string): boolean {
    try {
        const params = new URLSearchParams(initData);
        const hash = params.get('hash');
        params.delete('hash');
        
        // Sort params alphabetically
        const sortedParams = Array.from(params.entries())
            .sort(([a], [b]) => a.localeCompare(b))
            .map(([key, value]) => `${key}=${value}`)
            .join('\n');
        
        // Create secret key from bot token
        const secretKey = createHmac('sha256', 'WebAppData')
            .update(botToken)
            .digest();
        
        // Calculate hash
        const calculatedHash = createHmac('sha256', secretKey)
            .update(sortedParams)
            .digest('hex');
        
        return calculatedHash === hash;
    } catch {
        return false;
    }
}
