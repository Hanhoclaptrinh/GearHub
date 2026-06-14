export type FilterType = 'multi_select' | 'range';

export type FilterKey =
    // System filters
    | 'brandId'
    | 'price'
    | 'subcategory'

    // Common specs
    | 'ram'
    | 'storage'
    | 'chip'
    | 'cpu'
    | 'gpu'
    | 'screenSize'
    | 'refreshRate'
    | 'battery'
    | 'batteryLife'
    | 'connection'
    | 'rgb'
    | 'weight'
    | 'resolution'

    // Phone / tablet / smartwatch
    | 'camera'
    | 'frontCamera'
    | 'rearCamera'
    | 'screenType'
    | 'os'
    | 'sim'
    | 'waterResistance'

    // Laptop
    | 'laptopCpu'
    | 'laptopGpu'
    | 'touchScreen'

    // Keyboard
    | 'layout'
    | 'switchType'
    | 'hotSwap'
    | 'keycapMaterial'

    // Mouse
    | 'dpi'
    | 'sensor'
    | 'pollingRate'

    // Headphone / speaker
    | 'noiseCancelling'
    | 'microphone'
    | 'driverSize'
    | 'speakerPower'

    // Monitor / VR
    | 'panelType'
    | 'responseTime'
    | 'fieldOfView'
    | 'trackingType'

    // GPU
    | 'gpuChipset'
    | 'vram'
    | 'memoryType'
    | 'busWidth'
    | 'powerRequirement'

    // CPU
    | 'socket'
    | 'coreCount'
    | 'threadCount'
    | 'baseClock'
    | 'boostClock'
    | 'tdp'

    // RAM component
    | 'capacity'
    | 'busSpeed'
    | 'kitType'

    // SSD
    | 'formFactor'
    | 'storageInterface'
    | 'readSpeed'
    | 'writeSpeed'

    // Mainboard
    | 'chipset'
    | 'mainboardFormFactor'
    | 'ramSlot'
    | 'pcieSlot'

    // PSU
    | 'wattage'
    | 'efficiency'
    | 'modular'

    // PC case / cooling
    | 'caseSize'
    | 'fanSupport'
    | 'radiatorSupport'
    | 'coolingType';

export interface FilterDefinition {
    key: FilterKey;
    label: string;
    type: FilterType;

    /**
     * Key dùng để đọc dữ liệu trong:
     * - Product.attributeConfig
     * - ProductVariant.attributes
     *
     * Các filter hệ thống như brandId, price, subcategory không cần specKey.
     */
    specKey?: string;
}

export type FilterProfileId =
    | 'GENERIC_GROUP'
    | 'PHONE'
    | 'LAPTOP'
    | 'TABLET'
    | 'SMARTWATCH'
    | 'KEYBOARD'
    | 'MOUSE'
    | 'HEADPHONE'
    | 'SPEAKER'
    | 'MONITOR'
    | 'VR_HEADSET'
    | 'GPU'
    | 'CPU'
    | 'RAM_COMPONENT'
    | 'SSD'
    | 'MAINBOARD'
    | 'PSU'
    | 'PC_CASE'
    | 'COOLING';

export interface FilterProfile {
    id: FilterProfileId;
    name: string;
    filters: FilterDefinition[];
}

const DEFAULT_FILTERS: FilterDefinition[] = [
    { key: 'brandId', label: 'Thương hiệu', type: 'multi_select' },
    { key: 'price', label: 'Khoảng giá', type: 'range' },
];

const SUBCATEGORY_FILTER: FilterDefinition = {
    key: 'subcategory',
    label: 'Loại sản phẩm',
    type: 'multi_select',
};

export const FILTER_PROFILES: Record<FilterProfileId, FilterProfile> = {
    GENERIC_GROUP: {
        id: 'GENERIC_GROUP',
        name: 'Bộ lọc cơ bản',
        filters: [...DEFAULT_FILTERS, SUBCATEGORY_FILTER],
    },

    PHONE: {
        id: 'PHONE',
        name: 'Điện thoại',
        filters: [
            ...DEFAULT_FILTERS,
            SUBCATEGORY_FILTER,
            { key: 'ram', label: 'RAM', type: 'multi_select', specKey: 'ram' },
            { key: 'storage', label: 'Bộ nhớ trong', type: 'multi_select', specKey: 'storage' },
            { key: 'chip', label: 'Chip xử lý', type: 'multi_select', specKey: 'chip' },
            { key: 'screenSize', label: 'Kích thước màn hình', type: 'multi_select', specKey: 'screenSize' },
            { key: 'refreshRate', label: 'Tần số quét', type: 'multi_select', specKey: 'refreshRate' },
            { key: 'battery', label: 'Dung lượng pin', type: 'multi_select', specKey: 'battery' },
            { key: 'camera', label: 'Camera', type: 'multi_select', specKey: 'camera' },
        ],
    },

    LAPTOP: {
        id: 'LAPTOP',
        name: 'Laptop',
        filters: [
            ...DEFAULT_FILTERS,
            SUBCATEGORY_FILTER,
            { key: 'cpu', label: 'CPU', type: 'multi_select', specKey: 'cpu' },
            { key: 'gpu', label: 'Card đồ họa', type: 'multi_select', specKey: 'gpu' },
            { key: 'ram', label: 'RAM', type: 'multi_select', specKey: 'ram' },
            { key: 'storage', label: 'Ổ cứng', type: 'multi_select', specKey: 'storage' },
            { key: 'screenSize', label: 'Kích thước màn hình', type: 'multi_select', specKey: 'screenSize' },
            { key: 'refreshRate', label: 'Tần số quét', type: 'multi_select', specKey: 'refreshRate' },
            { key: 'touchScreen', label: 'Màn hình cảm ứng', type: 'multi_select', specKey: 'touchScreen' },
        ],
    },

    TABLET: {
        id: 'TABLET',
        name: 'Máy tính bảng',
        filters: [
            ...DEFAULT_FILTERS,
            SUBCATEGORY_FILTER,
            { key: 'ram', label: 'RAM', type: 'multi_select', specKey: 'ram' },
            { key: 'storage', label: 'Bộ nhớ trong', type: 'multi_select', specKey: 'storage' },
            { key: 'chip', label: 'Chip xử lý', type: 'multi_select', specKey: 'chip' },
            { key: 'screenSize', label: 'Kích thước màn hình', type: 'multi_select', specKey: 'screenSize' },
            { key: 'battery', label: 'Dung lượng pin', type: 'multi_select', specKey: 'battery' },
            { key: 'connection', label: 'Kết nối', type: 'multi_select', specKey: 'connection' },
        ],
    },

    SMARTWATCH: {
        id: 'SMARTWATCH',
        name: 'Đồng hồ thông minh',
        filters: [
            ...DEFAULT_FILTERS,
            { key: 'screenSize', label: 'Kích thước màn hình', type: 'multi_select', specKey: 'screenSize' },
            { key: 'batteryLife', label: 'Thời lượng pin', type: 'multi_select', specKey: 'batteryLife' },
            { key: 'os', label: 'Hệ điều hành', type: 'multi_select', specKey: 'os' },
            { key: 'waterResistance', label: 'Kháng nước', type: 'multi_select', specKey: 'waterResistance' },
            { key: 'connection', label: 'Kết nối', type: 'multi_select', specKey: 'connection' },
        ],
    },

    KEYBOARD: {
        id: 'KEYBOARD',
        name: 'Bàn phím',
        filters: [
            ...DEFAULT_FILTERS,
            { key: 'layout', label: 'Layout bàn phím', type: 'multi_select', specKey: 'layout' },
            { key: 'switchType', label: 'Loại switch', type: 'multi_select', specKey: 'switchType' },
            { key: 'connection', label: 'Kết nối', type: 'multi_select', specKey: 'connection' },
            { key: 'hotSwap', label: 'Hỗ trợ hot-swap', type: 'multi_select', specKey: 'hotSwap' },
            { key: 'keycapMaterial', label: 'Chất liệu keycap', type: 'multi_select', specKey: 'keycapMaterial' },
            { key: 'rgb', label: 'Đèn LED', type: 'multi_select', specKey: 'rgb' },
        ],
    },

    MOUSE: {
        id: 'MOUSE',
        name: 'Chuột',
        filters: [
            ...DEFAULT_FILTERS,
            { key: 'dpi', label: 'DPI tối đa', type: 'multi_select', specKey: 'dpi' },
            { key: 'sensor', label: 'Cảm biến', type: 'multi_select', specKey: 'sensor' },
            { key: 'weight', label: 'Trọng lượng', type: 'multi_select', specKey: 'weight' },
            { key: 'pollingRate', label: 'Tần số phản hồi', type: 'multi_select', specKey: 'pollingRate' },
            { key: 'connection', label: 'Kết nối', type: 'multi_select', specKey: 'connection' },
            { key: 'rgb', label: 'Đèn LED', type: 'multi_select', specKey: 'rgb' },
        ],
    },

    HEADPHONE: {
        id: 'HEADPHONE',
        name: 'Tai nghe',
        filters: [
            ...DEFAULT_FILTERS,
            SUBCATEGORY_FILTER,
            { key: 'connection', label: 'Kết nối', type: 'multi_select', specKey: 'connection' },
            { key: 'noiseCancelling', label: 'Chống ồn ANC', type: 'multi_select', specKey: 'noiseCancelling' },
            { key: 'batteryLife', label: 'Thời lượng pin', type: 'multi_select', specKey: 'batteryLife' },
            { key: 'microphone', label: 'Microphone', type: 'multi_select', specKey: 'microphone' },
            { key: 'driverSize', label: 'Kích thước driver', type: 'multi_select', specKey: 'driverSize' },
        ],
    },

    SPEAKER: {
        id: 'SPEAKER',
        name: 'Loa',
        filters: [
            ...DEFAULT_FILTERS,
            { key: 'connection', label: 'Kết nối', type: 'multi_select', specKey: 'connection' },
            { key: 'batteryLife', label: 'Thời lượng pin', type: 'multi_select', specKey: 'batteryLife' },
            { key: 'speakerPower', label: 'Công suất loa', type: 'multi_select', specKey: 'speakerPower' },
            { key: 'waterResistance', label: 'Kháng nước', type: 'multi_select', specKey: 'waterResistance' },
        ],
    },

    MONITOR: {
        id: 'MONITOR',
        name: 'Màn hình',
        filters: [
            ...DEFAULT_FILTERS,
            { key: 'screenSize', label: 'Kích thước màn hình', type: 'multi_select', specKey: 'screenSize' },
            { key: 'resolution', label: 'Độ phân giải', type: 'multi_select', specKey: 'resolution' },
            { key: 'refreshRate', label: 'Tần số quét', type: 'multi_select', specKey: 'refreshRate' },
            { key: 'panelType', label: 'Loại tấm nền', type: 'multi_select', specKey: 'panelType' },
            { key: 'responseTime', label: 'Thời gian phản hồi', type: 'multi_select', specKey: 'responseTime' },
        ],
    },

    VR_HEADSET: {
        id: 'VR_HEADSET',
        name: 'Kính thực tế ảo',
        filters: [
            ...DEFAULT_FILTERS,
            { key: 'resolution', label: 'Độ phân giải', type: 'multi_select', specKey: 'resolution' },
            { key: 'refreshRate', label: 'Tần số quét', type: 'multi_select', specKey: 'refreshRate' },
            { key: 'fieldOfView', label: 'Góc nhìn', type: 'multi_select', specKey: 'fieldOfView' },
            { key: 'trackingType', label: 'Theo dõi chuyển động', type: 'multi_select', specKey: 'trackingType' },
            { key: 'connection', label: 'Kết nối', type: 'multi_select', specKey: 'connection' },
            { key: 'storage', label: 'Bộ nhớ', type: 'multi_select', specKey: 'storage' },
        ],
    },

    GPU: {
        id: 'GPU',
        name: 'Card màn hình',
        filters: [
            ...DEFAULT_FILTERS,
            { key: 'gpuChipset', label: 'Chip GPU', type: 'multi_select', specKey: 'gpuChipset' },
            { key: 'vram', label: 'VRAM', type: 'multi_select', specKey: 'vram' },
            { key: 'memoryType', label: 'Loại bộ nhớ', type: 'multi_select', specKey: 'memoryType' },
            { key: 'busWidth', label: 'Bus bộ nhớ', type: 'multi_select', specKey: 'busWidth' },
            { key: 'powerRequirement', label: 'Nguồn đề xuất', type: 'multi_select', specKey: 'powerRequirement' },
        ],
    },

    CPU: {
        id: 'CPU',
        name: 'CPU',
        filters: [
            ...DEFAULT_FILTERS,
            { key: 'socket', label: 'Socket', type: 'multi_select', specKey: 'socket' },
            { key: 'coreCount', label: 'Số nhân', type: 'multi_select', specKey: 'coreCount' },
            { key: 'threadCount', label: 'Số luồng', type: 'multi_select', specKey: 'threadCount' },
            { key: 'baseClock', label: 'Xung cơ bản', type: 'multi_select', specKey: 'baseClock' },
            { key: 'boostClock', label: 'Xung tối đa', type: 'multi_select', specKey: 'boostClock' },
            { key: 'tdp', label: 'TDP', type: 'multi_select', specKey: 'tdp' },
        ],
    },

    RAM_COMPONENT: {
        id: 'RAM_COMPONENT',
        name: 'RAM máy tính',
        filters: [
            ...DEFAULT_FILTERS,
            { key: 'capacity', label: 'Dung lượng', type: 'multi_select', specKey: 'capacity' },
            { key: 'memoryType', label: 'Chuẩn RAM', type: 'multi_select', specKey: 'memoryType' },
            { key: 'busSpeed', label: 'Bus RAM', type: 'multi_select', specKey: 'busSpeed' },
            { key: 'kitType', label: 'Số thanh', type: 'multi_select', specKey: 'kitType' },
            { key: 'rgb', label: 'Đèn LED', type: 'multi_select', specKey: 'rgb' },
        ],
    },

    SSD: {
        id: 'SSD',
        name: 'SSD',
        filters: [
            ...DEFAULT_FILTERS,
            { key: 'capacity', label: 'Dung lượng', type: 'multi_select', specKey: 'capacity' },
            { key: 'formFactor', label: 'Chuẩn kích thước', type: 'multi_select', specKey: 'formFactor' },
            { key: 'storageInterface', label: 'Giao tiếp', type: 'multi_select', specKey: 'storageInterface' },
            { key: 'readSpeed', label: 'Tốc độ đọc', type: 'multi_select', specKey: 'readSpeed' },
            { key: 'writeSpeed', label: 'Tốc độ ghi', type: 'multi_select', specKey: 'writeSpeed' },
        ],
    },

    MAINBOARD: {
        id: 'MAINBOARD',
        name: 'Mainboard',
        filters: [
            ...DEFAULT_FILTERS,
            { key: 'socket', label: 'Socket', type: 'multi_select', specKey: 'socket' },
            { key: 'chipset', label: 'Chipset', type: 'multi_select', specKey: 'chipset' },
            { key: 'mainboardFormFactor', label: 'Kích thước mainboard', type: 'multi_select', specKey: 'mainboardFormFactor' },
            { key: 'memoryType', label: 'Chuẩn RAM hỗ trợ', type: 'multi_select', specKey: 'memoryType' },
            { key: 'ramSlot', label: 'Số khe RAM', type: 'multi_select', specKey: 'ramSlot' },
            { key: 'pcieSlot', label: 'Khe PCIe', type: 'multi_select', specKey: 'pcieSlot' },
        ],
    },

    PSU: {
        id: 'PSU',
        name: 'Nguồn máy tính',
        filters: [
            ...DEFAULT_FILTERS,
            { key: 'wattage', label: 'Công suất', type: 'multi_select', specKey: 'wattage' },
            { key: 'efficiency', label: 'Chuẩn hiệu suất', type: 'multi_select', specKey: 'efficiency' },
            { key: 'modular', label: 'Dây nguồn tháo rời', type: 'multi_select', specKey: 'modular' },
        ],
    },

    PC_CASE: {
        id: 'PC_CASE',
        name: 'Vỏ case',
        filters: [
            ...DEFAULT_FILTERS,
            { key: 'caseSize', label: 'Kích thước case', type: 'multi_select', specKey: 'caseSize' },
            { key: 'mainboardFormFactor', label: 'Hỗ trợ mainboard', type: 'multi_select', specKey: 'mainboardFormFactor' },
            { key: 'fanSupport', label: 'Hỗ trợ quạt', type: 'multi_select', specKey: 'fanSupport' },
            { key: 'radiatorSupport', label: 'Hỗ trợ radiator', type: 'multi_select', specKey: 'radiatorSupport' },
            { key: 'rgb', label: 'Đèn LED', type: 'multi_select', specKey: 'rgb' },
        ],
    },

    COOLING: {
        id: 'COOLING',
        name: 'Tản nhiệt',
        filters: [
            ...DEFAULT_FILTERS,
            { key: 'coolingType', label: 'Loại tản nhiệt', type: 'multi_select', specKey: 'coolingType' },
            { key: 'socket', label: 'Socket hỗ trợ', type: 'multi_select', specKey: 'socket' },
            { key: 'fanSupport', label: 'Kích thước quạt', type: 'multi_select', specKey: 'fanSupport' },
            { key: 'radiatorSupport', label: 'Kích thước radiator', type: 'multi_select', specKey: 'radiatorSupport' },
            { key: 'rgb', label: 'Đèn LED', type: 'multi_select', specKey: 'rgb' },
        ],
    },
};

export const CATEGORY_FILTER_PROFILE_MAP: Record<string, FilterProfileId> = {
    // Nhóm chung / marketing
    'gaming-gear': 'GENERIC_GROUP',
    gear: 'GENERIC_GROUP',
    'linh-kien-may-tinh': 'GENERIC_GROUP',
    'pc-components': 'GENERIC_GROUP',
    'phu-kien-cong-nghe': 'GENERIC_GROUP',

    // Điện thoại
    phone: 'PHONE',
    'dien-thoai': 'PHONE',
    smartphone: 'PHONE',
    'gaming-phone': 'PHONE',
    'dien-thoai-gaming': 'PHONE',
    'flagship-phone': 'PHONE',
    'dien-thoai-flagship': 'PHONE',
    'business-phone': 'PHONE',
    'dien-thoai-doanh-nhan': 'PHONE',

    // Laptop
    laptop: 'LAPTOP',
    'gaming-laptop': 'LAPTOP',
    'laptop-gaming': 'LAPTOP',
    'office-laptop': 'LAPTOP',
    'laptop-van-phong': 'LAPTOP',
    'workstation-laptop': 'LAPTOP',
    'laptop-tram': 'LAPTOP',
    ultrabook: 'LAPTOP',

    // Tablet
    tablet: 'TABLET',
    'may-tinh-bang': 'TABLET',
    ipad: 'TABLET',

    // Smartwatch
    smartwatch: 'SMARTWATCH',
    'dong-ho-thong-minh': 'SMARTWATCH',
    'apple-watch': 'SMARTWATCH',

    // Bàn phím
    keyboard: 'KEYBOARD',
    'ban-phim': 'KEYBOARD',
    'mechanical-keyboard': 'KEYBOARD',
    'ban-phim-co': 'KEYBOARD',
    'gaming-keyboard': 'KEYBOARD',
    'ban-phim-gaming': 'KEYBOARD',
    'wireless-keyboard': 'KEYBOARD',
    'ban-phim-khong-day': 'KEYBOARD',
    'wired-keyboard': 'KEYBOARD',
    'ban-phim-co-day': 'KEYBOARD',

    // Chuột
    mouse: 'MOUSE',
    chuot: 'MOUSE',
    'gaming-mouse': 'MOUSE',
    'chuot-gaming': 'MOUSE',
    'wireless-mouse': 'MOUSE',
    'chuot-khong-day': 'MOUSE',
    'wired-mouse': 'MOUSE',
    'chuot-co-day': 'MOUSE',

    // Tai nghe
    headphone: 'HEADPHONE',
    headphones: 'HEADPHONE',
    'tai-nghe': 'HEADPHONE',
    headset: 'HEADPHONE',
    'gaming-headset': 'HEADPHONE',
    'tai-nghe-gaming': 'HEADPHONE',
    'wireless-headphone': 'HEADPHONE',
    'tai-nghe-khong-day': 'HEADPHONE',
    'wired-headphone': 'HEADPHONE',
    'tai-nghe-co-day': 'HEADPHONE',
    earphone: 'HEADPHONE',
    earbuds: 'HEADPHONE',

    // Loa
    speaker: 'SPEAKER',
    loa: 'SPEAKER',
    'bluetooth-speaker': 'SPEAKER',
    'loa-bluetooth': 'SPEAKER',

    // Màn hình
    monitor: 'MONITOR',
    'man-hinh': 'MONITOR',
    'gaming-monitor': 'MONITOR',
    'man-hinh-gaming': 'MONITOR',

    // VR / AR
    'vr-headset': 'VR_HEADSET',
    'ar-headset': 'VR_HEADSET',
    'mixed-reality-headset': 'VR_HEADSET',
    'kinh-thuc-te-ao': 'VR_HEADSET',
    'kinh-vr': 'VR_HEADSET',
    'kinh-ar': 'VR_HEADSET',

    // GPU
    gpu: 'GPU',
    'card-man-hinh': 'GPU',
    'vga': 'GPU',
    'graphics-card': 'GPU',

    // CPU
    cpu: 'CPU',
    processor: 'CPU',
    'bo-vi-xu-ly': 'CPU',

    // RAM
    ram: 'RAM_COMPONENT',
    'ram-pc': 'RAM_COMPONENT',
    'ram-may-tinh': 'RAM_COMPONENT',
    memory: 'RAM_COMPONENT',

    // SSD
    ssd: 'SSD',
    'o-cung-ssd': 'SSD',
    storage: 'SSD',

    // Mainboard
    mainboard: 'MAINBOARD',
    motherboard: 'MAINBOARD',
    'bo-mach-chu': 'MAINBOARD',

    // PSU
    psu: 'PSU',
    'nguon-may-tinh': 'PSU',
    'power-supply': 'PSU',

    // PC case
    case: 'PC_CASE',
    'pc-case': 'PC_CASE',
    'case-pc': 'PC_CASE',
    'vo-case': 'PC_CASE',

    // Cooling
    cooling: 'COOLING',
    'tan-nhiet': 'COOLING',
    'cpu-cooler': 'COOLING',
    'air-cooler': 'COOLING',
    'liquid-cooler': 'COOLING',
    'tan-nhiet-khi': 'COOLING',
    'tan-nhiet-nuoc': 'COOLING',
};

export function normalizeCategorySlug(categorySlug: string): string {
    return categorySlug.toLowerCase().trim();
}

export function resolveFilterProfile(categorySlug?: string | null): FilterProfile {
    if (!categorySlug) {
        return FILTER_PROFILES.GENERIC_GROUP;
    }

    const normalizedSlug = normalizeCategorySlug(categorySlug);
    const profileId = CATEGORY_FILTER_PROFILE_MAP[normalizedSlug];

    if (!profileId) {
        return FILTER_PROFILES.GENERIC_GROUP;
    }

    return FILTER_PROFILES[profileId] ?? FILTER_PROFILES.GENERIC_GROUP;
}

export function getFilterDefinitionsByCategorySlug(
    categorySlug?: string | null,
): FilterDefinition[] {
    return resolveFilterProfile(categorySlug).filters;
}

export function isSpecFilter(filter: FilterDefinition): boolean {
    return Boolean(filter.specKey);
}

export function isSystemFilter(filter: FilterDefinition): boolean {
    return !filter.specKey;
}