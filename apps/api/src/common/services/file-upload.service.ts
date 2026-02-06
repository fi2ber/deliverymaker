import { Injectable, Logger, BadRequestException } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import * as fs from 'fs';
import * as path from 'path';
import { v4 as uuidv4 } from 'uuid';

export interface UploadedFile {
    url: string;
    filename: string;
    originalName: string;
    size: number;
    mimetype: string;
}

@Injectable()
export class FileUploadService {
    private readonly logger = new Logger(FileUploadService.name);
    private readonly uploadDir: string;
    private readonly baseUrl: string;

    constructor(private configService: ConfigService) {
        this.uploadDir = this.configService.get<string>('UPLOAD_DIR') || './uploads';
        this.baseUrl = this.configService.get<string>('BASE_URL') || 'http://localhost:3001';
        
        this.ensureDirectories();
    }

    private ensureDirectories() {
        const dirs = ['products', 'temp'];
        for (const dir of dirs) {
            const fullPath = path.join(this.uploadDir, dir);
            if (!fs.existsSync(fullPath)) {
                fs.mkdirSync(fullPath, { recursive: true });
            }
        }
    }

    async uploadProductImage(
        file: Express.Multer.File,
        productId: string
    ): Promise<UploadedFile> {
        this.validateImage(file);

        const ext = path.extname(file.originalname);
        const filename = `${productId}_${uuidv4()}${ext}`;
        const filepath = path.join(this.uploadDir, 'products', filename);

        fs.writeFileSync(filepath, file.buffer);

        const url = `${this.baseUrl}/uploads/products/${filename}`;

        this.logger.log(`Uploaded image: ${filename} for product ${productId}`);

        return {
            url,
            filename,
            originalName: file.originalname,
            size: file.size,
            mimetype: file.mimetype,
        };
    }

    async uploadMultipleProductImages(
        files: Express.Multer.File[],
        productId: string
    ): Promise<UploadedFile[]> {
        const uploads: UploadedFile[] = [];
        
        for (const file of files) {
            try {
                const uploaded = await this.uploadProductImage(file, productId);
                uploads.push(uploaded);
            } catch (error) {
                this.logger.error(`Failed to upload file ${file.originalname}`, error);
            }
        }

        return uploads;
    }

    async deleteImage(filename: string): Promise<boolean> {
        try {
            const filepath = path.join(this.uploadDir, 'products', filename);
            if (fs.existsSync(filepath)) {
                fs.unlinkSync(filepath);
                this.logger.log(`Deleted image: ${filename}`);
                return true;
            }
            return false;
        } catch (error) {
            this.logger.error(`Failed to delete image ${filename}`, error);
            return false;
        }
    }

    private validateImage(file: Express.Multer.File) {
        const maxSize = 10 * 1024 * 1024;
        if (file.size > maxSize) {
            throw new BadRequestException('File size exceeds 10MB limit');
        }

        const allowedTypes = ['image/jpeg', 'image/png', 'image/webp', 'image/gif'];
        if (!allowedTypes.includes(file.mimetype)) {
            throw new BadRequestException('Invalid file type. Allowed: JPEG, PNG, WebP, GIF');
        }

        const magicNumbers = {
            'image/jpeg': [0xFF, 0xD8, 0xFF],
            'image/png': [0x89, 0x50, 0x4E, 0x47],
            'image/webp': [0x52, 0x49, 0x46, 0x46],
            'image/gif': [0x47, 0x49, 0x46, 0x38],
        };

        const signature = magicNumbers[file.mimetype];
        if (signature) {
            const buffer = file.buffer.slice(0, signature.length);
            const isValid = signature.every((byte, i) => buffer[i] === byte);
            if (!isValid) {
                throw new BadRequestException('Invalid file signature');
            }
        }
    }

    getImagePath(filename: string): string {
        return path.join(this.uploadDir, 'products', filename);
    }
}
