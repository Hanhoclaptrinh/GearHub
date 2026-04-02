/*
  Warnings:

  - You are about to drop the column `product_id` on the `cart_items` table. All the data in the column will be lost.
  - You are about to drop the column `product_id` on the `order_items` table. All the data in the column will be lost.
  - The values [SHIPPED] on the enum `orders_status` will be removed. If these variants are still used in the database, this will fail.
  - The values [ONLINE] on the enum `transactions_payment_method` will be removed. If these variants are still used in the database, this will fail.
  - You are about to drop the column `price` on the `products` table. All the data in the column will be lost.
  - You are about to drop the column `stock` on the `products` table. All the data in the column will be lost.
  - A unique constraint covering the columns `[cart_id,product_variant_id]` on the table `cart_items` will be added. If there are existing duplicate values, this will fail.
  - Added the required column `product_variant_id` to the `cart_items` table without a default value. This is not possible if the table is not empty.
  - Added the required column `product_name` to the `order_items` table without a default value. This is not possible if the table is not empty.
  - Added the required column `product_variant_id` to the `order_items` table without a default value. This is not possible if the table is not empty.
  - Added the required column `variant_name` to the `order_items` table without a default value. This is not possible if the table is not empty.
  - Added the required column `updated_at` to the `product_assets` table without a default value. This is not possible if the table is not empty.
  - Added the required column `updated_at` to the `reviews` table without a default value. This is not possible if the table is not empty.
  - Added the required column `payment_method` to the `transactions` table without a default value. This is not possible if the table is not empty.

*/
-- DropForeignKey
ALTER TABLE `cart_items` DROP FOREIGN KEY `cart_items_product_id_fkey`;

-- DropForeignKey
ALTER TABLE `order_items` DROP FOREIGN KEY `order_items_product_id_fkey`;

-- DropForeignKey
ALTER TABLE `reviews` DROP FOREIGN KEY `reviews_product_id_fkey`;

-- DropForeignKey
ALTER TABLE `reviews` DROP FOREIGN KEY `reviews_user_id_fkey`;

-- DropIndex
DROP INDEX `products_price_idx` ON `products`;

-- AlterTable
ALTER TABLE `cart_items` DROP COLUMN `product_id`,
    ADD COLUMN `created_at` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    ADD COLUMN `product_variant_id` VARCHAR(36) NOT NULL,
    ADD COLUMN `updated_at` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3);

-- AlterTable
ALTER TABLE `order_items` DROP COLUMN `product_id`,
    ADD COLUMN `product_name` VARCHAR(255) NOT NULL,
    ADD COLUMN `product_variant_id` VARCHAR(36) NOT NULL,
    ADD COLUMN `variant_name` VARCHAR(255) NOT NULL;

-- AlterTable
ALTER TABLE `order_tracking` ADD COLUMN `created_at` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3);

-- AlterTable
ALTER TABLE `orders` ADD COLUMN `payment_status` ENUM('PENDING', 'PROCESSING', 'PAID', 'FAILED', 'REFUNDED') NOT NULL DEFAULT 'PENDING',
    MODIFY `status` ENUM('PENDING', 'CONFIRMED', 'PROCESSING', 'SHIPPING', 'DELIVERED', 'CANCELLED', 'RETURNED', 'FAILED') NOT NULL DEFAULT 'PENDING',
    MODIFY `payment_method` ENUM('COD', 'E_WALLET', 'PAYMENT_GATEWAY', 'BANK_TRANSFER') NOT NULL DEFAULT 'COD';

-- AlterTable
ALTER TABLE `product_assets` ADD COLUMN `created_at` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    ADD COLUMN `updated_at` DATETIME(3) NOT NULL;

-- AlterTable
ALTER TABLE `products` DROP COLUMN `price`,
    DROP COLUMN `stock`;

-- AlterTable
ALTER TABLE `reviews` ADD COLUMN `is_verified_purchase` BOOLEAN NOT NULL DEFAULT false,
    ADD COLUMN `order_id` VARCHAR(36) NULL,
    ADD COLUMN `reply` TEXT NULL,
    ADD COLUMN `updated_at` DATETIME(3) NOT NULL;

-- AlterTable
ALTER TABLE `transactions` ADD COLUMN `created_at` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    ADD COLUMN `description` VARCHAR(255) NULL,
    ADD COLUMN `payment_method` ENUM('COD', 'E_WALLET', 'PAYMENT_GATEWAY', 'BANK_TRANSFER') NOT NULL,
    ADD COLUMN `providerTransactionId` VARCHAR(191) NULL,
    ADD COLUMN `raw_response` TEXT NULL,
    ADD COLUMN `updated_at` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3);

-- AlterTable
ALTER TABLE `users` ADD COLUMN `status` ENUM('ACTIVE', 'BANNED', 'INACTIVE') NOT NULL DEFAULT 'ACTIVE';

-- CreateTable
CREATE TABLE `product_variants` (
    `id` VARCHAR(36) NOT NULL,
    `product_id` VARCHAR(36) NOT NULL,
    `sku` VARCHAR(100) NOT NULL,
    `name` VARCHAR(255) NOT NULL,
    `price` DECIMAL(15, 2) NOT NULL,
    `stock` INTEGER NOT NULL DEFAULT 0,
    `attributes` JSON NULL,

    UNIQUE INDEX `product_variants_sku_key`(`sku`),
    INDEX `product_variants_price_idx`(`price`),
    PRIMARY KEY (`id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- CreateTable
CREATE TABLE `review_assets` (
    `id` VARCHAR(36) NOT NULL,
    `review_id` VARCHAR(36) NOT NULL,
    `url` VARCHAR(255) NOT NULL,
    `type` VARCHAR(191) NOT NULL DEFAULT 'IMAGE',

    PRIMARY KEY (`id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- CreateIndex
CREATE INDEX `cart_items_product_variant_id_idx` ON `cart_items`(`product_variant_id`);

-- CreateIndex
CREATE UNIQUE INDEX `cart_items_cart_id_product_variant_id_key` ON `cart_items`(`cart_id`, `product_variant_id`);

-- CreateIndex
CREATE INDEX `order_items_product_variant_id_idx` ON `order_items`(`product_variant_id`);

-- AddForeignKey
ALTER TABLE `product_variants` ADD CONSTRAINT `product_variants_product_id_fkey` FOREIGN KEY (`product_id`) REFERENCES `products`(`id`) ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `cart_items` ADD CONSTRAINT `cart_items_product_variant_id_fkey` FOREIGN KEY (`product_variant_id`) REFERENCES `product_variants`(`id`) ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `order_items` ADD CONSTRAINT `order_items_product_variant_id_fkey` FOREIGN KEY (`product_variant_id`) REFERENCES `product_variants`(`id`) ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `reviews` ADD CONSTRAINT `reviews_user_id_fkey` FOREIGN KEY (`user_id`) REFERENCES `users`(`id`) ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `reviews` ADD CONSTRAINT `reviews_product_id_fkey` FOREIGN KEY (`product_id`) REFERENCES `products`(`id`) ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `review_assets` ADD CONSTRAINT `review_assets_review_id_fkey` FOREIGN KEY (`review_id`) REFERENCES `reviews`(`id`) ON DELETE CASCADE ON UPDATE CASCADE;
