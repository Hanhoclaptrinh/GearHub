export interface CategoryMock {
    name: string;
    slug: string;
    description: string;
    iconUrl: string;
    parentSlug: string | null;
}

const categories: CategoryMock[] = [
    {
        "name": "Laptop",
        "slug": "laptop",
        "description": "Máy tính xách tay các loại",
        "iconUrl": "https://placehold.co/400x400/343a40/FFFFFF?text=Laptop",
        "parentSlug": null
    },
    {
        "name": "Linh kiện PC",
        "slug": "linh-kien-pc",
        "description": "Phần cứng máy tính",
        "iconUrl": "https://placehold.co/400x400/fd7e14/FFFFFF?text=Parts",
        "parentSlug": null
    },
    {
        "name": "Gaming Gear",
        "slug": "gaming-gear",
        "description": "Phụ kiện chơi game chuyên nghiệp",
        "iconUrl": "https://placehold.co/400x400/6610f2/FFFFFF?text=Gear",
        "parentSlug": null
    },

    {
        "name": "Laptop Gaming",
        "slug": "laptop-gaming",
        "description": "Cấu hình cao cho game thủ",
        "iconUrl": "https://placehold.co/400x400/dc3545/FFFFFF?text=Gaming+Lap",
        "parentSlug": "laptop"
    },
    {
        "name": "Laptop Văn Phòng",
        "slug": "laptop-van-phong",
        "description": "Mỏng nhẹ, pin bền",
        "iconUrl": "https://placehold.co/400x400/20c997/FFFFFF?text=Office+Lap",
        "parentSlug": "laptop"
    },

    {
        "name": "VGA - Card màn hình",
        "slug": "vga",
        "description": "Xử lý đồ họa mạnh mẽ",
        "iconUrl": "https://placehold.co/400x400/007bff/FFFFFF?text=VGA",
        "parentSlug": "linh-kien-pc"
    },
    {
        "name": "CPU - Bộ vi xử lý",
        "slug": "cpu",
        "description": "Bộ não của máy tính",
        "iconUrl": "https://placehold.co/400x400/e83e8c/FFFFFF?text=CPU",
        "parentSlug": "linh-kien-pc"
    },

    {
        "name": "Bàn phím cơ",
        "slug": "ban-phim-co",
        "description": "Trải nghiệm gõ phím đỉnh cao",
        "iconUrl": "https://placehold.co/400x400/6f42c1/FFFFFF?text=Keyboard",
        "parentSlug": "gaming-gear"
    },
    {
        "name": "Chuột Gaming",
        "slug": "chuot-gaming",
        "description": "Độ nhạy cực cao",
        "iconUrl": "https://placehold.co/400x400/28a745/FFFFFF?text=Mouse",
        "parentSlug": "gaming-gear"
    }
];

export default categories;