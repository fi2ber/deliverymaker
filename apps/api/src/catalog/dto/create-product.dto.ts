import { IsString, IsNumber, IsOptional, IsEnum, ValidateNested, IsObject, Min, Max } from 'class-validator';
import { Type } from 'class-transformer';
import { ProductType, UnitOfMeasure } from '../product-types';

class DimensionsDto {
    @IsNumber()
    @Min(0)
    length: number;

    @IsNumber()
    @Min(0)
    width: number;

    @IsNumber()
    @Min(0)
    height: number;
}

class TemperatureControlDto {
    @IsNumber()
    min: number;

    @IsNumber()
    max: number;

    @IsOptional()
    required?: boolean;
}

class BarcodesDto {
    @IsString()
    @IsOptional()
    ean13?: string;

    @IsString()
    @IsOptional()
    ean8?: string;

    @IsString()
    @IsOptional()
    upc?: string;
}

class CertificationDto {
    @IsOptional()
    halal?: boolean;

    @IsOptional()
    organic?: boolean;

    @IsString()
    @IsOptional()
    gost?: string;

    @IsString()
    @IsOptional()
    ozbekiston?: string;
}

class PackagingDto {
    @IsEnum(['plastic', 'glass', 'paper', 'metal', 'mixed'])
    type: 'plastic' | 'glass' | 'paper' | 'metal' | 'mixed';

    @IsOptional()
    recyclable?: boolean;

    @IsOptional()
    depositScheme?: boolean;
}

export class ProductAttributesDto {
    @IsNumber()
    @IsOptional()
    @Min(0)
    weightKg?: number;

    @IsNumber()
    @IsOptional()
    @Min(0)
    volumeLiters?: number;

    @ValidateNested()
    @Type(() => DimensionsDto)
    @IsOptional()
    dimensions?: DimensionsDto;

    @ValidateNested()
    @Type(() => TemperatureControlDto)
    @IsOptional()
    temperatureControl?: TemperatureControlDto;

    @IsNumber()
    @Min(1)
    shelfLifeDays: number;

    @IsNumber()
    @IsOptional()
    shelfLifeAfterOpen?: number;

    @ValidateNested()
    @Type(() => BarcodesDto)
    @IsOptional()
    barcodes?: BarcodesDto;

    @ValidateNested()
    @Type(() => CertificationDto)
    @IsOptional()
    certification?: CertificationDto;

    @ValidateNested()
    @Type(() => PackagingDto)
    @IsOptional()
    packaging?: PackagingDto;
}

export class CreateProductDto {
    @IsString()
    name: string;

    @IsString()
    @IsOptional()
    sku?: string;

    @IsString()
    @IsOptional()
    description?: string;

    @IsString()
    @IsOptional()
    image?: string;

    @IsString({ each: true })
    @IsOptional()
    images?: string[];

    @IsString()
    categoryId: string;

    @IsNumber()
    @Min(0)
    basePrice: number;

    @IsEnum(ProductType)
    productType: ProductType;

    @IsEnum(UnitOfMeasure)
    unit: UnitOfMeasure;

    @ValidateNested()
    @Type(() => ProductAttributesDto)
    attributes: ProductAttributesDto;

    @IsNumber()
    @IsOptional()
    aiConfidence?: number;

    @IsString({ each: true })
    @IsOptional()
    aiKeywords?: string[];
}

export class AIProductCreateDto {
    @IsString()
    @IsOptional()
    text?: string;

    @IsString()
    @IsOptional()
    imageUrl?: string;

    @IsString()
    @IsOptional()
    barcode?: string;

    @IsObject()
    @IsOptional()
    supplierData?: {
        name: string;
        description?: string;
        price?: number;
        category?: string;
    };
}
