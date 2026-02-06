import { 
    Controller, 
    Get, 
    Post, 
    Put, 
    Delete, 
    Body, 
    Param, 
    Query,
    UseInterceptors,
    UploadedFile,
    UploadedFiles,
    ParseUUIDPipe,
    Res,
    UseGuards,
} from '@nestjs/common';
import { ApiTags, ApiBearerAuth, ApiOperation, ApiResponse, ApiConsumes, ApiBody } from '@nestjs/swagger';
import { FileInterceptor, FilesInterceptor } from '@nestjs/platform-express';
import { Response } from 'express';
import { ProductsService } from './products.service';
import { FileUploadService } from '../common/services/file-upload.service';
import { CreateProductDto, AIProductCreateDto } from './dto/create-product.dto';
import * as fs from 'fs';
import { JwtAuthGuard } from '../auth/jwt.guard';
import { RolesGuard } from '../common/guards/roles.guard';
import { Roles } from '../common/decorators/roles.decorator';
import { UserRole } from '../users/user.entity';

@ApiTags('Products')
@ApiBearerAuth('JWT-auth')
@Controller('products')
@UseGuards(JwtAuthGuard)
export class ProductsController {
    constructor(
        private readonly productsService: ProductsService,
        private readonly fileUploadService: FileUploadService,
    ) { }

    @Get()
    @ApiOperation({ summary: 'Get all products', description: 'Retrieve list of all products or filter by category' })
    @ApiResponse({ status: 200, description: 'List of products' })
    async findAll(@Query('category') categoryId?: string) {
        if (categoryId) {
            return this.productsService.findByCategory(categoryId);
        }
        return this.productsService.findAll();
    }

    @Get(':id')
    async findOne(@Param('id', ParseUUIDPipe) id: string) {
        return this.productsService.findOne(id);
    }

    @Get('barcode/:barcode')
    async findByBarcode(@Param('barcode') barcode: string) {
        const product = await this.productsService.findByBarcode(barcode);
        if (!product) {
            return { found: false, barcode };
        }
        return { found: true, product };
    }

    @Post()
    @UseGuards(RolesGuard)
    @Roles(UserRole.SUPER_ADMIN, UserRole.OWNER, UserRole.DIRECTOR, UserRole.WAREHOUSE_MANAGER)
    async create(@Body() dto: CreateProductDto) {
        return this.productsService.create(dto);
    }

    // AI-assisted product creation
    @Post('ai-create')
    @UseGuards(RolesGuard)
    @Roles(UserRole.SUPER_ADMIN, UserRole.OWNER, UserRole.DIRECTOR, UserRole.WAREHOUSE_MANAGER)
    async createWithAI(@Body() input: AIProductCreateDto) {
        return this.productsService.createWithAI({
            text: input.text,
            imageUrl: input.imageUrl,
            barcode: input.barcode,
            supplierData: input.supplierData,
            basePrice: input.supplierData?.price,
        });
    }

    // Preview AI analysis without creating
    @Post('ai-preview')
    @UseGuards(RolesGuard)
    @Roles(UserRole.SUPER_ADMIN, UserRole.OWNER, UserRole.DIRECTOR, UserRole.WAREHOUSE_MANAGER)
    async previewAI(@Body() input: AIProductCreateDto) {
        return this.productsService.previewAIAnalysis({
            text: input.text,
            imageUrl: input.imageUrl,
            barcode: input.barcode,
            supplierData: input.supplierData,
            basePrice: input.supplierData?.price,
        });
    }

    // Upload single image
    @Post(':id/image')
    @UseGuards(RolesGuard)
    @Roles(UserRole.SUPER_ADMIN, UserRole.OWNER, UserRole.DIRECTOR, UserRole.WAREHOUSE_MANAGER)
    @UseInterceptors(FileInterceptor('image'))
    async uploadImage(
        @Param('id', ParseUUIDPipe) id: string,
        @UploadedFile() file: Express.Multer.File,
    ) {
        const uploaded = await this.fileUploadService.uploadProductImage(file, id);
        
        // Обновляем продукт, устанавливая главное фото
        await this.productsService.update(id, { image: uploaded.url });

        return {
            message: 'Image uploaded successfully',
            image: uploaded,
        };
    }

    // Upload multiple images
    @Post(':id/images')
    @UseGuards(RolesGuard)
    @Roles(UserRole.SUPER_ADMIN, UserRole.OWNER, UserRole.DIRECTOR, UserRole.WAREHOUSE_MANAGER)
    @UseInterceptors(FilesInterceptor('images', 10)) // макс 10 файлов
    async uploadMultipleImages(
        @Param('id', ParseUUIDPipe) id: string,
        @UploadedFiles() files: Express.Multer.File[],
    ) {
        const uploaded = await this.fileUploadService.uploadMultipleProductImages(files, id);
        
        // Получаем текущий продукт
        const product = await this.productsService.findOne(id);
        
        // Добавляем новые URL к существующим
        const currentImages = product.images || [];
        const newImages = uploaded.map(u => u.url);
        
        await this.productsService.update(id, {
            images: [...currentImages, ...newImages],
        });

        return {
            message: `${uploaded.length} images uploaded successfully`,
            images: uploaded,
        };
    }

    // Delete image
    @Delete(':id/images')
    @UseGuards(RolesGuard)
    @Roles(UserRole.SUPER_ADMIN, UserRole.OWNER, UserRole.DIRECTOR, UserRole.WAREHOUSE_MANAGER)
    async deleteImage(
        @Param('id', ParseUUIDPipe) id: string,
        @Body('url') imageUrl: string,
    ) {
        // Извлекаем filename из URL
        const filename = imageUrl.split('/').pop();
        
        if (filename) {
            await this.fileUploadService.deleteImage(filename);
        }

        // Удаляем URL из продукта
        const product = await this.productsService.findOne(id);
        const updatedImages = (product.images || []).filter(url => url !== imageUrl);
        
        // Если удаляем главное фото, очищаем image поле
        const updates: any = { images: updatedImages };
        if (product.image === imageUrl) {
            updates.image = null;
        }
        
        await this.productsService.update(id, updates);

        return { message: 'Image deleted successfully' };
    }

    // Set main image
    @Put(':id/main-image')
    @UseGuards(RolesGuard)
    @Roles(UserRole.SUPER_ADMIN, UserRole.OWNER, UserRole.DIRECTOR, UserRole.WAREHOUSE_MANAGER)
    async setMainImage(
        @Param('id', ParseUUIDPipe) id: string,
        @Body('url') imageUrl: string,
    ) {
        const product = await this.productsService.findOne(id);
        
        // Проверяем что URL существует в images
        if (!product.images?.includes(imageUrl)) {
            return { error: 'Image not found in product gallery' };
        }

        await this.productsService.update(id, { image: imageUrl });

        return { message: 'Main image updated successfully' };
    }

    // Serve uploaded files
    @Get('uploads/products/:filename')
    async serveImage(@Param('filename') filename: string, @Res() res: Response) {
        const filepath = this.fileUploadService.getImagePath(filename);
        
        if (!fs.existsSync(filepath)) {
            return res.status(404).json({ error: 'Image not found' });
        }

        return res.sendFile(filepath);
    }

    // Bulk creation
    @Post('bulk')
    @UseGuards(RolesGuard)
    @Roles(UserRole.SUPER_ADMIN, UserRole.OWNER, UserRole.DIRECTOR, UserRole.WAREHOUSE_MANAGER)
    async bulkCreate(@Body() products: CreateProductDto[]) {
        return this.productsService.bulkCreate(products);
    }

    @Put(':id')
    @UseGuards(RolesGuard)
    @Roles(UserRole.SUPER_ADMIN, UserRole.OWNER, UserRole.DIRECTOR, UserRole.WAREHOUSE_MANAGER)
    async update(
        @Param('id', ParseUUIDPipe) id: string,
        @Body() dto: Partial<CreateProductDto>,
    ) {
        return this.productsService.update(id, dto);
    }

    @Delete(':id')
    @UseGuards(RolesGuard)
    @Roles(UserRole.SUPER_ADMIN, UserRole.OWNER, UserRole.DIRECTOR)
    async deactivate(@Param('id', ParseUUIDPipe) id: string) {
        await this.productsService.deactivate(id);
        return { message: 'Product deactivated' };
    }
}
