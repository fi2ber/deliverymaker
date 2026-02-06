import { Controller, Get, Post, Body, UseGuards } from '@nestjs/common';
import { ApiTags, ApiBearerAuth, ApiOperation, ApiResponse } from '@nestjs/swagger';
import { UsersService } from './users.service';
import { User, UserRole } from './user.entity';
import { JwtAuthGuard } from '../auth/jwt.guard';
import { RolesGuard } from '../common/guards/roles.guard';
import { Roles } from '../common/decorators/roles.decorator';

@ApiTags('Users')
@ApiBearerAuth('JWT-auth')
@Controller('users')
@UseGuards(JwtAuthGuard, RolesGuard)
@Roles(UserRole.SUPER_ADMIN, UserRole.OWNER, UserRole.DIRECTOR)
export class UsersController {
    constructor(private readonly usersService: UsersService) {}

    @Get('clients')
    @Roles(UserRole.SUPER_ADMIN, UserRole.OWNER, UserRole.DIRECTOR, UserRole.SALES_REP)
    async findClients(): Promise<User[]> {
        // Return users with CLIENT-appropriate roles (excluding internal staff)
        return this.usersService.findByRoles([
            UserRole.OWNER,
            UserRole.DIRECTOR,
            UserRole.SALES_REP,
        ]);
    }

    @Get('drivers')
    @Roles(UserRole.SUPER_ADMIN, UserRole.OWNER, UserRole.DIRECTOR, UserRole.SALES_REP, UserRole.DRIVER)
    async findDrivers(): Promise<User[]> {
        return this.usersService.findByRoles([UserRole.DRIVER]);
    }

    @Get()
    async findAll(): Promise<User[]> {
        return this.usersService.findAll();
    }

    @Post('clients')
    @Roles(UserRole.SUPER_ADMIN, UserRole.OWNER, UserRole.DIRECTOR, UserRole.SALES_REP)
    async createClient(@Body() data: {
        email: string;
        fullName: string;
        phone?: string;
        password: string;
        tenantId: string;
    }): Promise<User> {
        return this.usersService.create({
            ...data,
            role: UserRole.SALES_REP, // Default role for clients
            passwordHash: data.password, // Will be hashed in service
        });
    }
}
