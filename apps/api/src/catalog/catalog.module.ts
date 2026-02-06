import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { ConfigModule } from '@nestjs/config';
import { Product } from './product.entity';
import { Category } from './category.entity';
import { ProductsController } from './products.controller';
import { ProductsService } from './products.service';
import { ProductAIService } from './product-ai.service';
import { FileUploadService } from '../common/services/file-upload.service';

@Module({
    imports: [
        TypeOrmModule.forFeature([Product, Category]),
        ConfigModule,
    ],
    controllers: [ProductsController],
    providers: [ProductsService, ProductAIService, FileUploadService],
    exports: [ProductsService],
})
export class CatalogModule { }
