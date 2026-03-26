import { PrismaClient } from '@prisma/client';
import brands from './data/brands';
import categories from './data/categories';

const prisma = new PrismaClient();

async function seedBrands() {
    // console.log('📦 Đang seed Brands...');
    for (const b of brands) {
        await prisma.brand.upsert({
            where: { slug: b.slug },
            update: { name: b.name, logoUrl: b.logoUrl },
            create: b,
        });
    }
    // console.log(`✅ Đã xong ${brands.length} Brands.`);
}

async function seedCategories() {
    // console.log('📂 Đang seed Categories...');
    for (const cat of categories) {
        await prisma.category.upsert({
            where: { slug: cat.slug },
            update: {
                name: cat.name,
                description: cat.description,
                iconUrl: cat.iconUrl
            },
            create: {
                name: cat.name,
                slug: cat.slug,
                description: cat.description,
                iconUrl: cat.iconUrl,
            },
        });
    }

    for (const cat of categories) {
        if (cat.parentSlug) {
            const parent = await prisma.category.findUnique({
                where: { slug: cat.parentSlug }
            });

            if (parent) {
                await prisma.category.update({
                    where: { slug: cat.slug },
                    data: { parentId: parent.id },
                });
            }
        }
    }
    // console.log(`✅ Đã xong ${categories.length} Categories (bao gồm Sub-categories).`);
}

async function main() {
    // console.log('🚀 Bắt đầu quá trình nạp dữ liệu mẫu...');

    await seedBrands();
    await seedCategories();

    // console.log('✨ TẤT CẢ DỮ LIỆU ĐÃ SẴN SÀNG!');
}

main()
    .catch((e) => {
        // console.error('❌ Lỗi Seed:', e);
        process.exit(1);
    })
    .finally(async () => {
        await prisma.$disconnect();
    });