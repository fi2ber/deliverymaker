import { Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import axios from 'axios';
import { ProductType, UnitOfMeasure, PRODUCT_CATEGORIES, ProductAttributes } from './product-types';

export interface AIProductAnalysis {
    suggestedName: string;
    suggestedCategory: string;
    suggestedType: ProductType;
    suggestedUnit: UnitOfMeasure;
    estimatedShelfLifeDays: number;
    estimatedWeightKg?: number;
    estimatedDimensions?: { length: number; width: number; height: number };
    barcodes?: { ean13?: string; ean8?: string };
    confidence: number; // 0-1
    keywords: string[];
    description: string;
}

export interface ProductCreationInput {
    text?: string;           // Описание товара
    imageUrl?: string;       // URL изображения
    barcode?: string;        // Штрих-код для поиска
    supplierData?: {         // Данные от поставщика
        name: string;
        description?: string;
        price?: number;
        category?: string;
    };
}

@Injectable()
export class ProductAIService {
    private readonly logger = new Logger(ProductAIService.name);
    private readonly openaiApiKey: string;

    constructor(private configService: ConfigService) {
        this.openaiApiKey = this.configService.get<string>('OPENAI_API_KEY') || '';
    }

    /**
     * Анализирует входные данные и предлагает параметры товара
     */
    async analyzeProduct(input: ProductCreationInput): Promise<AIProductAnalysis> {
        // Если есть штрих-код, пробуем найти в базе данных
        if (input.barcode) {
            const barcodeData = await this.lookupBarcode(input.barcode);
            if (barcodeData) {
                return this.enhanceWithAI(barcodeData, input);
            }
        }

        // Используем GPT для анализа текста/описания
        if (input.text || input.supplierData?.description) {
            return this.analyzeWithGPT(input);
        }

        // Если есть изображение - анализируем через Vision API
        if (input.imageUrl) {
            return this.analyzeImage(input.imageUrl);
        }

        throw new Error('Insufficient data for product analysis');
    }

    /**
     * Генерирует SKU на основе категории и названия
     */
    generateSKU(categoryCode: string, productName: string, sequence: number): string {
        const transliterated = this.transliterate(productName);
        const shortName = transliterated
            .split(' ')
            .map(w => w.substring(0, 3).toUpperCase())
            .join('');
        
        const category = categoryCode.substring(0, 3).toUpperCase();
        const seq = sequence.toString().padStart(4, '0');
        
        return `${category}-${shortName}-${seq}`;
    }

    /**
     * Предлагает цену на основе себестоимости и категории
     */
    suggestPricing(costPrice: number, category: string): {
        retailPrice: number;
        wholesalePrice: number;
        margin: number;
    } {
        // Маржинальность по категориям
        const margins: Record<string, number> = {
            'BEV-WATER': 0.25,      // Вода - низкая маржа
            'BEV-SOFT': 0.35,       // Напитки
            'MEAT-FRESH': 0.30,     // Мясо
            'MEAT-PROC': 0.40,      // Колбасы
            'PROD-VEG': 0.35,       // Овощи
            'DAIRY': 0.28,          // Молочка
            'GROC': 0.25,           // Бакалея
            'CANNED': 0.35,         // Консервы
            'BAKERY': 0.45,         // Выпечка
            'FROZEN': 0.32,         // Заморозка
        };

        const margin = margins[category] || 0.30;
        const retailPrice = costPrice * (1 + margin);
        const wholesalePrice = costPrice * (1 + margin * 0.6); // Опт на 40% дешевле

        return {
            retailPrice: Math.round(retailPrice * 100) / 100,
            wholesalePrice: Math.round(wholesalePrice * 100) / 100,
            margin,
        };
    }

    /**
     * Проверяет соответствие товара требованиям Узбекистана
     */
    validateForUzbekistan(productData: Partial<ProductAttributes>): {
        valid: boolean;
        issues: string[];
        requiredCertificates: string[];
    } {
        const issues: string[] = [];
        const requiredCertificates: string[] = [];

        // Температурный режим для скоропортящихся
        if (productData.temperatureControl?.required) {
            if (!productData.temperatureControl.min || !productData.temperatureControl.max) {
                issues.push('Укажите температурный режим хранения');
            }
            requiredCertificates.push('Санитарно-эпидемиологическое заключение');
        }

        // Срок годности
        if (!productData.shelfLifeDays || productData.shelfLifeDays < 1) {
            issues.push('Укажите корректный срок годности');
        }

        // Для мяса и молочки - обязательная сертификация
        if (productData.temperatureControl?.required) {
            requiredCertificates.push('Сертификат соответствия');
            requiredCertificates.push('Ветеринарное свидетельство');
        }

        // Для импорта
        if (!productData.barcodes?.ean13) {
            issues.push('Рекомендуется указать штрих-код EAN-13');
        }

        return {
            valid: issues.length === 0,
            issues,
            requiredCertificates,
        };
    }

    // ============ Private Methods ============

    private async lookupBarcode(barcode: string): Promise<Partial<AIProductAnalysis> | null> {
        // Интеграция с внешними API (OpenFoodFacts, EAN-Search и др.)
        try {
            // OpenFoodFacts API (бесплатный)
            const response = await axios.get(
                `https://world.openfoodfacts.org/api/v0/product/${barcode}.json`,
                { timeout: 5000 }
            );

            if (response.data?.product) {
                const product = response.data.product;
                return {
                    suggestedName: product.product_name_ru || product.product_name,
                    suggestedCategory: this.mapCategory(product.categories),
                    estimatedWeightKg: product.product_quantity 
                        ? product.product_quantity / 1000 
                        : undefined,
                    barcodes: { ean13: barcode },
                    confidence: 0.8,
                };
            }
        } catch (error) {
            this.logger.warn(`Barcode lookup failed for ${barcode}`);
        }
        return null;
    }

    private async analyzeWithGPT(input: ProductCreationInput): Promise<AIProductAnalysis> {
        const text = input.text || input.supplierData?.description || '';
        const name = input.supplierData?.name || '';

        const prompt = `
Проанализируй товар для системы дистрибуции в Узбекистане и предложи параметры:

Название: ${name}
Описание: ${text}

Ответь в формате JSON:
{
    "suggestedName": "оптимизированное название для каталога",
    "suggestedCategory": "код категории из списка",
    "suggestedType": "WEIGHT|LIQUID|PIECES|BUNDLE|PREPACKED",
    "suggestedUnit": "kg|l|pcs|box|etc",
    "estimatedShelfLifeDays": число,
    "estimatedWeightKg": число или null,
    "keywords": ["тег1", "тег2"],
    "description": "SEO-описание для каталога"
}

Доступные категории:
- BEV-WATER: Вода
- BEV-SOFT: Безалкогольные напитки
- MEAT-FRESH: Свежее мясо
- MEAT-PROC: Мясные изделия
- MEAT-POULTRY: Птица
- PROD-VEG: Овощи
- PROD-FRUIT: Фрукты
- DAIRY: Молочка
- GROC: Бакалея
- CANNED: Консервы
- FROZEN: Заморозка
- BAKERY: Выпечка
`;

        try {
            const response = await axios.post(
                'https://api.openai.com/v1/chat/completions',
                {
                    model: 'gpt-4o-mini',
                    messages: [
                        { role: 'system', content: 'Ты помощник для создания карточек товаров в дистрибьюторской системе.' },
                        { role: 'user', content: prompt }
                    ],
                    response_format: { type: 'json_object' }
                },
                {
                    headers: { 'Authorization': `Bearer ${this.openaiApiKey}` },
                    timeout: 15000
                }
            );

            const result = JSON.parse(response.data.choices[0].message.content);
            
            return {
                ...result,
                confidence: 0.75,
                barcodes: input.barcode ? { ean13: input.barcode } : undefined,
            };
        } catch (error) {
            this.logger.error('GPT analysis failed', error);
            // Fallback к базовому анализу
            return this.fallbackAnalysis(name, text);
        }
    }

    private async analyzeImage(imageUrl: string): Promise<AIProductAnalysis> {
        // GPT-4 Vision для анализа изображения
        try {
            const response = await axios.post(
                'https://api.openai.com/v1/chat/completions',
                {
                    model: 'gpt-4o',
                    messages: [
                        {
                            role: 'user',
                            content: [
                                { 
                                    type: 'text', 
                                    text: 'Определи что это за товар. Ответь в JSON: {name, category, type, estimatedWeightKg, volumeLiters}' 
                                },
                                { type: 'image_url', image_url: { url: imageUrl } }
                            ]
                        }
                    ],
                    response_format: { type: 'json_object' }
                },
                {
                    headers: { 'Authorization': `Bearer ${this.openaiApiKey}` },
                    timeout: 20000
                }
            );

            const result = JSON.parse(response.data.choices[0].message.content);
            
            return {
                suggestedName: result.name,
                suggestedCategory: result.category,
                suggestedType: result.type as ProductType,
                suggestedUnit: this.inferUnitFromType(result.type),
                estimatedWeightKg: result.estimatedWeightKg,
                estimatedShelfLifeDays: 30, // Default
                confidence: 0.7,
                keywords: [],
                description: `Товар: ${result.name}`,
            };
        } catch (error) {
            this.logger.error('Image analysis failed', error);
            throw new Error('Failed to analyze image');
        }
    }

    private enhanceWithAI(
        barcodeData: Partial<AIProductAnalysis>,
        input: ProductCreationInput
    ): AIProductAnalysis {
        // Дополняем данные из barcode AI-анализом
        return {
            ...barcodeData,
            suggestedName: barcodeData.suggestedName || input.supplierData?.name || 'Unknown',
            suggestedType: ProductType.PIECES,
            suggestedUnit: UnitOfMeasure.PCS,
            estimatedShelfLifeDays: barcodeData.estimatedShelfLifeDays || 365,
            confidence: (barcodeData.confidence || 0.5) + 0.1,
            keywords: [],
            description: barcodeData.suggestedName || '',
        } as AIProductAnalysis;
    }

    private fallbackAnalysis(name: string, description: string): AIProductAnalysis {
        // Базовый анализ если GPT недоступен
        const lowerText = (name + ' ' + description).toLowerCase();
        
        // Правила классификации
        if (lowerText.includes('вода') || lowerText.includes('suv') || lowerText.includes('water')) {
            return {
                suggestedName: name,
                suggestedCategory: 'BEV-WATER',
                suggestedType: ProductType.LIQUID,
                suggestedUnit: UnitOfMeasure.LITER,
                estimatedShelfLifeDays: 365,
                confidence: 0.6,
                keywords: ['вода', 'напитки'],
                description: description,
            };
        }

        if (lowerText.includes('мясо') || lowerText.includes('go\'sht') || lowerText.includes('meat')) {
            return {
                suggestedName: name,
                suggestedCategory: 'MEAT-FRESH',
                suggestedType: ProductType.WEIGHT,
                suggestedUnit: UnitOfMeasure.KG,
                estimatedShelfLifeDays: 7,
                confidence: 0.6,
                keywords: ['мясо', 'продукты'],
                description: description,
            };
        }

        // Default
        return {
            suggestedName: name,
            suggestedCategory: 'GROC',
            suggestedType: ProductType.PIECES,
            suggestedUnit: UnitOfMeasure.PCS,
            estimatedShelfLifeDays: 180,
            confidence: 0.4,
            keywords: [],
            description: description,
        };
    }

    private mapCategory(categories: string): string {
        if (!categories) return 'GROC';
        
        const cat = categories.toLowerCase();
        if (cat.includes('water')) return 'BEV-WATER';
        if (cat.includes('meat') || cat.includes('beef') || cat.includes('chicken')) return 'MEAT-FRESH';
        if (cat.includes('dairy') || cat.includes('milk')) return 'DAIRY';
        if (cat.includes('vegetable')) return 'PROD-VEG';
        if (cat.includes('fruit')) return 'PROD-FRUIT';
        
        return 'GROC';
    }

    private inferUnitFromType(type: string): UnitOfMeasure {
        const map: Record<string, UnitOfMeasure> = {
            'WEIGHT': UnitOfMeasure.KG,
            'LIQUID': UnitOfMeasure.LITER,
            'PIECES': UnitOfMeasure.PCS,
        };
        return map[type] || UnitOfMeasure.PCS;
    }

    private transliterate(text: string): string {
        const ru = 'абвгдеёжзийклмнопрстуфхцчшщъыьэюя';
        const en = 'abvgdeejzijklmnoprstufhzcss_y_eua';
        
        return text.toLowerCase()
            .split('')
            .map(char => {
                const idx = ru.indexOf(char);
                return idx >= 0 ? en[idx] : char;
            })
            .join('');
    }
}
