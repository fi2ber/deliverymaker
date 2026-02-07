import { IsString, IsOptional, IsBoolean, IsEnum } from 'class-validator';
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { CustomerSource, CustomerStatus } from '../entities/customer.entity';

export { CustomerSource, CustomerStatus };

export class CreateCustomerDto {
    @ApiProperty({ description: 'Telegram user ID' })
    @IsString()
    telegramId: string;

    @ApiPropertyOptional({ description: 'First name' })
    @IsString()
    @IsOptional()
    firstName?: string;

    @ApiPropertyOptional({ description: 'Last name' })
    @IsString()
    @IsOptional()
    lastName?: string;

    @ApiPropertyOptional({ description: 'Phone number' })
    @IsString()
    @IsOptional()
    phone?: string;

    @ApiPropertyOptional({ description: 'Telegram username' })
    @IsString()
    @IsOptional()
    telegramUsername?: string;

    @ApiPropertyOptional({ description: 'Telegram chat ID for notifications' })
    @IsString()
    @IsOptional()
    telegramChatId?: string;

    @ApiPropertyOptional({ description: 'Delivery address' })
    @IsString()
    @IsOptional()
    address?: string;

    @ApiPropertyOptional({ description: 'Customer source', enum: CustomerSource })
    @IsEnum(CustomerSource)
    @IsOptional()
    source?: CustomerSource;

    @ApiPropertyOptional({ description: 'Customer status', enum: CustomerStatus })
    @IsEnum(CustomerStatus)
    @IsOptional()
    status?: CustomerStatus;

    @ApiPropertyOptional({ description: 'Is phone verified' })
    @IsBoolean()
    @IsOptional()
    isPhoneVerified?: boolean;

    @ApiPropertyOptional({ description: 'Tenant ID for multi-tenancy' })
    @IsString()
    @IsOptional()
    tenantId?: string;
}
