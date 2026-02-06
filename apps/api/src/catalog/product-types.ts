// Product Type Definitions for Uzbekistan Distribution Market

export enum ProductType {
    // Штучные товары (piece goods)
    PIECES = 'PIECES',           // Бутылки, банки, пачки
    
    // Весовые товары (weight-based)
    WEIGHT = 'WEIGHT',           // Мясо, овощи, фрукты на развес
    
    // Жидкости (liquids)
    LIQUID = 'LIQUID',           // Вода, масло, соки
    
    // Наборы/комплекты (bundles)
    BUNDLE = 'BUNDLE',           // Мультипаки, промо-наборы
    
    // Расфасованные (pre-packaged)
    PREPACKED = 'PREPACKED',     // Упаковка фиксированного веса
}

export enum UnitOfMeasure {
    // Штуки
    PCS = 'pcs',           // штуки
    BOX = 'box',           // коробки
    PACK = 'pack',         // пачки
    BOTTLE = 'bottle',     // бутылки
    CAN = 'can',           // банки
    JAR = 'jar',           // банки (стекло)
    
    // Вес
    KG = 'kg',             // килограммы
    GRAM = 'g',            // граммы
    TON = 'ton',           // тонны
    
    // Объем
    LITER = 'l',           // литры
    ML = 'ml',             // миллилитры
    
    // Упаковки
    CASE = 'case',         // ящики
    PALLET = 'pallet',     // паллеты
}

export interface ProductAttributes {
    // Физические характеристики
    weightKg?: number;           // Вес в кг (для доставки)
    volumeLiters?: number;       // Объем в литрах
    dimensions?: {
        length: number;          // см
        width: number;
        height: number;
    };
    
    // Температурный режим
    temperatureControl?: {
        min: number;             // °C
        max: number;
        required: boolean;
    };
    
    // Срок годности
    shelfLifeDays: number;
    shelfLifeAfterOpen?: number; // дней после вскрытия
    
    // Бар-коды
    barcodes: {
        ean13?: string;
        ean8?: string;
        upc?: string;
        qr?: string;
    };
    
    // Сертификация (для Узбекистана)
    certification?: {
        halal?: boolean;
        organic?: boolean;
        gost?: string;           // ГОСТ Р
        ozbekiston?: string;     // Стандарт Уз
    };
    
    // Упаковка
    packaging?: {
        type: 'plastic' | 'glass' | 'paper' | 'metal' | 'mixed';
        recyclable: boolean;
        depositScheme: boolean;  // Залоговая тара
    };
}

// Категории товаров для дистрибуции
export const PRODUCT_CATEGORIES = {
    // Вода и напитки
    WATER: {
        code: 'BEV-WATER',
        name: 'Вода',
        defaultUnit: UnitOfMeasure.LITER,
        defaultType: ProductType.LIQUID,
        subcategories: ['Минеральная', 'Питьевая', 'Газированная', 'Негазированная'],
    },
    SOFT_DRINKS: {
        code: 'BEV-SOFT',
        name: 'Безалкогольные напитки',
        defaultUnit: UnitOfMeasure.LITER,
        defaultType: ProductType.LIQUID,
        subcategories: ['Соки', 'Лимонады', 'Энергетики', 'Чай', 'Кофе'],
    },
    
    // Мясо и птица
    MEAT_FRESH: {
        code: 'MEAT-FRESH',
        name: 'Свежее мясо',
        defaultUnit: UnitOfMeasure.KG,
        defaultType: ProductType.WEIGHT,
        temperatureControl: { min: 0, max: 4, required: true },
        subcategories: ['Говядина', 'Баранина', 'Свинина', 'Телятина'],
    },
    MEAT_PROCESSED: {
        code: 'MEAT-PROC',
        name: 'Мясные изделия',
        defaultUnit: UnitOfMeasure.KG,
        defaultType: ProductType.WEIGHT,
        temperatureControl: { min: 0, max: 6, required: true },
        subcategories: ['Колбасы', 'Сосиски', 'Ветчина', 'Деликатесы'],
    },
    POULTRY: {
        code: 'MEAT-POULTRY',
        name: 'Птица',
        defaultUnit: UnitOfMeasure.KG,
        defaultType: ProductType.WEIGHT,
        temperatureControl: { min: -2, max: 4, required: true },
        subcategories: ['Курица', 'Индейка', 'Утка', 'Перепела'],
    },
    
    // Овощи и фрукты
    VEGETABLES: {
        code: 'PROD-VEG',
        name: 'Овощи',
        defaultUnit: UnitOfMeasure.KG,
        defaultType: ProductType.WEIGHT,
        subcategories: ['Картофель', 'Морковь', 'Лук', 'Капуста', 'Помидоры', 'Огурцы'],
    },
    FRUITS: {
        code: 'PROD-FRUIT',
        name: 'Фрукты',
        defaultUnit: UnitOfMeasure.KG,
        defaultType: ProductType.WEIGHT,
        subcategories: ['Яблоки', 'Груши', 'Виноград', 'Апельсины', 'Бананы'],
    },
    
    // Молочка
    DAIRY: {
        code: 'DAIRY',
        name: 'Молочная продукция',
        defaultUnit: UnitOfMeasure.LITER,
        defaultType: ProductType.LIQUID,
        temperatureControl: { min: 0, max: 6, required: true },
        subcategories: ['Молоко', 'Кефир', 'Йогурт', 'Сметана', 'Творог', 'Сыр'],
    },
    
    // Бакалея
    GROCERY: {
        code: 'GROC',
        name: 'Бакалея',
        defaultUnit: UnitOfMeasure.PCS,
        defaultType: ProductType.PIECES,
        subcategories: ['Крупы', 'Макароны', 'Мука', 'Сахар', 'Соль', 'Масло'],
    },
    
    // Консервы
    CANNED: {
        code: 'CANNED',
        name: 'Консервы',
        defaultUnit: UnitOfMeasure.CAN,
        defaultType: ProductType.PIECES,
        subcategories: ['Мясные', 'Рыбные', 'Овощные', 'Фруктовые'],
    },
    
    // Заморозка
    FROZEN: {
        code: 'FROZEN',
        name: 'Замороженные продукты',
        defaultUnit: UnitOfMeasure.KG,
        defaultType: ProductType.WEIGHT,
        temperatureControl: { min: -18, max: -12, required: true },
        subcategories: ['Овощи', 'Ягоды', 'Полуфабрикаты', 'Морепродукты'],
    },
    
    // Хлебобулочные
    BAKERY: {
        code: 'BAKERY',
        name: 'Хлебобулочные изделия',
        defaultUnit: UnitOfMeasure.PCS,
        defaultType: ProductType.PIECES,
        shelfLifeDays: 3,
        subcategories: ['Хлеб', 'Булочки', 'Выпечка', 'Хлебцы'],
    },
    
    // Алкоголь (если лицензия есть)
    ALCOHOL: {
        code: 'ALCOHOL',
        name: 'Алкогольные напитки',
        defaultUnit: UnitOfMeasure.LITER,
        defaultType: ProductType.LIQUID,
        requiresLicense: true,
        subcategories: ['Пиво', 'Вино', 'Водка', 'Коньяк'],
    },
};

// Конвертация единиц измерения
export const UNIT_CONVERSION = {
    // Вес
    'kg_to_g': 1000,
    'g_to_kg': 0.001,
    'ton_to_kg': 1000,
    
    // Объем
    'l_to_ml': 1000,
    'ml_to_l': 0.001,
    
    // Упаковки (условные)
    'box_to_pcs': 12,        // Стандартная коробка
    'case_to_box': 10,       // Ящик
    'pallet_to_case': 40,    // Паллета
};

// Правила округления для разных типов
export const ROUNDING_RULES = {
    [ProductType.WEIGHT]: 0.001,    // 3 знака после запятой (граммы)
    [ProductType.LIQUID]: 0.001,    // миллилитры
    [ProductType.PIECES]: 1,        // только целые числа
    [ProductType.BUNDLE]: 1,        // целые наборы
    [ProductType.PREPACKED]: 0.01,  // 2 знака
};
