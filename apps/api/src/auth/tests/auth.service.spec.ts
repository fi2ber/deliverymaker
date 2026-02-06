import { Test, TestingModule } from '@nestjs/testing';
import { JwtService } from '@nestjs/jwt';
import * as bcrypt from 'bcrypt';
import { AuthService } from '../auth.service';
import { UsersService } from '../../users/users.service';
import { User, UserRole } from '../../users/user.entity';

describe('AuthService', () => {
    let service: AuthService;
    let usersService: jest.Mocked<UsersService>;
    let jwtService: jest.Mocked<JwtService>;

    const mockUser: User = {
        id: 'user-uuid',
        tenantId: 'tenant-1',
        email: 'test@example.com',
        passwordHash: 'hashed_password',
        role: UserRole.SALES_REP,
        fullName: 'Test User',
        phone: null,
        telegramChatId: null,
        currentDebt: 0,
        createdAt: new Date(),
        updatedAt: new Date(),
        notifications: [],
    };

    beforeEach(async () => {
        const module: TestingModule = await Test.createTestingModule({
            providers: [
                AuthService,
                {
                    provide: UsersService,
                    useValue: {
                        findOneByEmail: jest.fn(),
                    },
                },
                {
                    provide: JwtService,
                    useValue: {
                        sign: jest.fn().mockReturnValue('test_token'),
                    },
                },
            ],
        }).compile();

        service = module.get<AuthService>(AuthService);
        usersService = module.get(UsersService);
        jwtService = module.get(JwtService);
    });

    describe('validateUser', () => {
        it('should return user without password when credentials are valid', async () => {
            const password = 'password123';
            const hashedPassword = await bcrypt.hash(password, 10);
            const userWithHash = { ...mockUser, passwordHash: hashedPassword };

            usersService.findOneByEmail.mockResolvedValue(userWithHash);

            const result = await service.validateUser('test@example.com', password);

            expect(result).toBeDefined();
            expect(result.passwordHash).toBeUndefined();
            expect(result.email).toBe('test@example.com');
        });

        it('should return null when user not found', async () => {
            usersService.findOneByEmail.mockResolvedValue(null);

            const result = await service.validateUser('nonexistent@example.com', 'password');

            expect(result).toBeNull();
        });

        it('should return null when password is invalid', async () => {
            const hashedPassword = await bcrypt.hash('correct_password', 10);
            const userWithHash = { ...mockUser, passwordHash: hashedPassword };

            usersService.findOneByEmail.mockResolvedValue(userWithHash);

            const result = await service.validateUser('test@example.com', 'wrong_password');

            expect(result).toBeNull();
        });
    });

    describe('login', () => {
        it('should return JWT token with correct payload', async () => {
            const user = { ...mockUser };
            delete user.passwordHash;

            const result = await service.login(user);

            expect(result.access_token).toBe('test_token');
            expect(jwtService.sign).toHaveBeenCalledWith({
                email: user.email,
                sub: user.id,
                role: user.role,
                tenantId: user.tenantId,
            });
        });
    });
});
