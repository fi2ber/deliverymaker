import { ApiProperty } from '@nestjs/swagger';
import { IsEmail, IsString, MinLength, IsNotEmpty } from 'class-validator';

export class LoginDto {
    @ApiProperty({ example: 'user@example.com', description: 'User email address' })
    @IsEmail({}, { message: 'Please provide a valid email address' })
    @IsNotEmpty()
    email: string;

    @ApiProperty({ example: 'password123', description: 'User password (min 6 chars)' })
    @IsString()
    @MinLength(6, { message: 'Password must be at least 6 characters' })
    @IsNotEmpty()
    password: string;
}
