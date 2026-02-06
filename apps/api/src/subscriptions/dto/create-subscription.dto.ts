import { IsEnum, IsUUID, IsDateString, IsObject, IsOptional, IsString, IsNumber } from 'class-validator';
import { PaymentProvider } from '../subscription.entity';

export class CreateSubscriptionDto {
    @IsUUID()
    comboProductId: string;

    @IsDateString()
    startDate: string;

    @IsEnum(PaymentProvider)
    @IsOptional()
    paymentProvider?: PaymentProvider = PaymentProvider.TELEGRAM;

    @IsObject()
    @IsOptional()
    deliveryAddress?: {
        lat?: number;
        lng?: number;
        address: string;
        phone: string;
        comment?: string;
    };

    @IsObject()
    @IsOptional()
    deliverySchedule?: {
        preferredTimeStart?: string;
        preferredTimeEnd?: string;
        weekdaysOnly?: boolean;
    };

    @IsObject()
    @IsOptional()
    telegramData?: {
        chatId: string;
        username?: string;
    };
}

export class CreateComboProductDto {
    @IsString()
    name: string;

    @IsString()
    @IsOptional()
    description?: string;

    @IsString()
    image: string;

    @IsObject({ each: true })
    items: {
        productId: string;
        name: string;
        quantity: number;
        unit: string;
        image?: string;
    }[];

    @IsString()
    period: string;

    @IsNumber()
    basePrice: number;

    @IsNumber()
    subscriptionPrice: number;

    @IsNumber()
    @IsOptional()
    discountPercent?: number;

    @IsNumber()
    @IsOptional()
    totalDeliveries?: number;

    @IsNumber()
    @IsOptional()
    deliveryFrequencyDays?: number;

    @IsObject()
    @IsOptional()
    telegramSettings?: {
        buttonText: string;
        descriptionShort: string;
        emoji: string;
    };
}
