-- CreateTable
CREATE TABLE `product_image_embeddings` (
    `id` VARCHAR(36) NOT NULL,
    `product_id` VARCHAR(36) NOT NULL,
    `variant_id` VARCHAR(36) NULL,
    `asset_id` VARCHAR(36) NULL,
    `image_url` VARCHAR(255) NOT NULL,
    `image_hash` VARCHAR(64) NOT NULL,
    `embedding` JSON NOT NULL,
    `source_type` ENUM('PRODUCT_THUMBNAIL', 'PRODUCT_ASSET', 'VARIANT_IMAGE') NOT NULL,
    `created_at` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    `updated_at` DATETIME(3) NOT NULL,

    UNIQUE INDEX `product_image_embeddings_image_hash_key`(`image_hash`),
    INDEX `product_image_embeddings_product_id_idx`(`product_id`),
    INDEX `product_image_embeddings_variant_id_idx`(`variant_id`),
    INDEX `product_image_embeddings_asset_id_idx`(`asset_id`),
    INDEX `product_image_embeddings_updated_at_idx`(`updated_at`),
    PRIMARY KEY (`id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- AddForeignKey
ALTER TABLE `product_image_embeddings` ADD CONSTRAINT `product_image_embeddings_product_id_fkey` FOREIGN KEY (`product_id`) REFERENCES `products`(`id`) ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `product_image_embeddings` ADD CONSTRAINT `product_image_embeddings_variant_id_fkey` FOREIGN KEY (`variant_id`) REFERENCES `product_variants`(`id`) ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `product_image_embeddings` ADD CONSTRAINT `product_image_embeddings_asset_id_fkey` FOREIGN KEY (`asset_id`) REFERENCES `product_assets`(`id`) ON DELETE CASCADE ON UPDATE CASCADE;
