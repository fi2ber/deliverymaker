import { IsString, IsOptional, IsNumber, IsEnum, IsObject } from 'class-validator';
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { SubscriptionStatus, PaymentProvider, PaymentStatus } from '../subscription.entity';

export class CreateSubscriptionDto {
    @ApiProperty({ description: 'Customer ID' })
    @IsString()
    customerId: string;

    @ApiPropertyOptional({ description: 'Client ID (legacy user relation)' })
    @IsString()
    @IsOptional()
    clientId?: string;

    @ApiProperty({ description: 'Combo product ID' })
    @IsString()
    comboProductId: string;

    @ApiPropertyOptional({ description: 'Subscription status', enum: SubscriptionStatus })
    @IsEnum(SubscriptionStatus)
    @IsOptional()
    status?: SubscriptionStatus;

    @ApiPropertyOptional({ description: 'Payment status', enum: PaymentStatus })
    @IsEnum(PaymentStatus)
    @IsOptional()
    paymentStatus?: PaymentStatus;

    @ApiProperty({ description: 'Total amount' })
    @IsNumber()
    totalAmount: number;

    @ApiPropertyOptional({ description: 'Price per delivery' })
    @IsNumber()
    @IsOptional()
    pricePerDelivery?: number;

    @ApiPropertyOptional({ description: 'Delivery address' })
    @IsObject()
    @IsOptional()
    deliveryAddress?: {
        lat?: number;
        lng?: number;
        address: string;
        phone: string;
        comment?: string;
    };

    @ApiPropertyOptional({ description: 'Payment provider', enum: PaymentProvider })
    @IsEnum(PaymentProvider)
    @IsOptional()
    paymentProvider?: PaymentProvider;

    @ApiPropertyOptional({ description: 'Tenant ID' })
    @IsString()
    @IsOptional()
    tenantId?: string;
}
