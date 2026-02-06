import { NestFactory } from '@nestjs/core';
import { NestExpressApplication } from '@nestjs/platform-express';
import { ValidationPipe, VersioningType } from '@nestjs/common';
import { SwaggerModule, DocumentBuilder } from '@nestjs/swagger';
import { join } from 'path';
import { AppModule } from './app.module';

async function bootstrap() {
    const app = await NestFactory.create<NestExpressApplication>(AppModule);
    
    // API Versioning
    app.enableVersioning({
        type: VersioningType.URI,
        defaultVersion: '1',
    });
    
    // Enable CORS
    app.enableCors({
        origin: process.env.CORS_ORIGIN || '*',
        credentials: true,
    });
    
    // Global validation pipe
    app.useGlobalPipes(new ValidationPipe({
        whitelist: true,
        forbidNonWhitelisted: true,
        transform: true,
        transformOptions: {
            enableImplicitConversion: true,
        },
    }));
    
    // Swagger Documentation
    const config = new DocumentBuilder()
        .setTitle('DeliveryMaker API')
        .setDescription('SaaS Distribution Platform API for Uzbekistan')
        .setVersion('1.0.0')
        .addBearerAuth(
            {
                type: 'http',
                scheme: 'bearer',
                bearerFormat: 'JWT',
                name: 'JWT',
                description: 'Enter JWT token',
                in: 'header',
            },
            'JWT-auth',
        )
        .addTag('Auth', 'Authentication endpoints')
        .addTag('Users', 'User management')
        .addTag('Products', 'Product catalog management')
        .addTag('Orders', 'Sales order management')
        .addTag('Warehouse', 'Warehouse operations & inventory')
        .addTag('Logistics', 'Routes & delivery management')
        .addTag('Finance', 'Payments & handovers')
        .addTag('Analytics', 'Reports & analytics')
        .addTag('AI', 'AI forecasting & recommendations')
        .addTag('Notifications', 'Push notifications & real-time updates')
        .build();
    
    const document = SwaggerModule.createDocument(app, config);
    SwaggerModule.setup('api/docs', app, document, {
        swaggerOptions: {
            persistAuthorization: true,
            docExpansion: 'list',
            filter: true,
            showRequestDuration: true,
        },
        customSiteTitle: 'DeliveryMaker API Docs',
    });
    
    // Serve static files from uploads directory
    app.useStaticAssets(join(__dirname, '..', 'uploads'), {
        prefix: '/uploads',
    });
    
    const port = process.env.PORT || 3001;
    await app.listen(port);
    
    console.log(`=================================`);
    console.log(`🚀 Application is running on: ${await app.getUrl()}`);
    console.log(`📚 API Documentation: http://localhost:${port}/api/docs`);
    console.log(`=================================`);
}
bootstrap();
