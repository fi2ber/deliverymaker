import { Test, TestingModule } from '@nestjs/testing';
import { Reflector } from '@nestjs/core';
import { ExecutionContext, ForbiddenException } from '@nestjs/common';
import { RolesGuard } from './roles.guard';
import { UserRole } from '../../users/user.entity';

describe('RolesGuard', () => {
    let guard: RolesGuard;
    let reflectorMock: { getAllAndOverride: jest.Mock };

    const mockContext = (user: any): ExecutionContext =>
        ({
            switchToHttp: () => ({
                getRequest: () => ({ user }),
            }),
            getHandler: () => jest.fn(),
            getClass: () => jest.fn(),
        }) as any;

    beforeEach(async () => {
        reflectorMock = { getAllAndOverride: jest.fn() };

        const module: TestingModule = await Test.createTestingModule({
            providers: [
                RolesGuard,
                {
                    provide: Reflector,
                    useValue: reflectorMock,
                },
            ],
        }).compile();

        guard = module.get<RolesGuard>(RolesGuard);
    });

    it('should allow access when no roles are required', () => {
        reflectorMock.getAllAndOverride.mockReturnValue(null);

        const context = mockContext({ role: UserRole.DRIVER });
        const result = guard.canActivate(context);

        expect(result).toBe(true);
    });

    it('should allow access when user has required role', () => {
        reflectorMock.getAllAndOverride.mockReturnValue([UserRole.OWNER, UserRole.DIRECTOR]);

        const context = mockContext({ role: UserRole.DIRECTOR });
        const result = guard.canActivate(context);

        expect(result).toBe(true);
    });

    it('should allow access for SUPER_ADMIN to any role', () => {
        reflectorMock.getAllAndOverride.mockReturnValue([UserRole.OWNER]);

        const context = mockContext({ role: UserRole.SUPER_ADMIN });
        const result = guard.canActivate(context);

        expect(result).toBe(true);
    });

    it('should deny access when user does not have required role', () => {
        reflectorMock.getAllAndOverride.mockReturnValue([UserRole.OWNER]);

        const context = mockContext({ role: UserRole.DRIVER });
        
        expect(() => guard.canActivate(context)).toThrow(ForbiddenException);
    });

    it('should throw when user is not authenticated', () => {
        reflectorMock.getAllAndOverride.mockReturnValue([UserRole.OWNER]);

        const context = mockContext(null);
        
        expect(() => guard.canActivate(context)).toThrow(ForbiddenException);
    });
});
