import { Controller, Post, Body, HttpCode, HttpStatus, UnauthorizedException } from '@nestjs/common';
import { ApiTags, ApiOperation, ApiResponse } from '@nestjs/swagger';
import { AuthService } from './auth.service';
import { LoginDto } from './dto/login.dto';

@ApiTags('Auth')
@Controller('auth')
export class AuthController {
    constructor(private authService: AuthService) { }

    @HttpCode(HttpStatus.OK)
    @Post('login')
    @ApiOperation({ summary: 'User login', description: 'Authenticate user and return JWT token' })
    @ApiResponse({ status: 200, description: 'Login successful', schema: {
        example: { access_token: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...' }
    }})
    @ApiResponse({ status: 401, description: 'Invalid credentials' })
    async signIn(@Body() signInDto: LoginDto) {
        const user = await this.authService.validateUser(signInDto.email, signInDto.password);
        if (!user) {
            throw new UnauthorizedException('Invalid credentials');
        }
        return this.authService.login(user);
    }
}
