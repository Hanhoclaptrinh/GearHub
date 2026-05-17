-- Phase 2.1 additive schema review only.
-- Do not execute against production until the SQL has been reviewed,
-- a database backup exists, and the change has been tested in staging.

CREATE TABLE `product_embeddings` (
  `id` VARCHAR(36) NOT NULL,
  `product_id` VARCHAR(36) NOT NULL,
  `text_hash` VARCHAR(64) NOT NULL,
  `source_text` TEXT NOT NULL,
  `embedding` JSON NOT NULL,
  `updated_at` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),
  PRIMARY KEY (`id`),
  UNIQUE KEY `product_embeddings_product_id_key` (`product_id`),
  KEY `product_embeddings_product_id_idx` (`product_id`),
  KEY `product_embeddings_updated_at_idx` (`updated_at`),
  CONSTRAINT `product_embeddings_product_id_fkey`
    FOREIGN KEY (`product_id`) REFERENCES `products`(`id`)
    ON DELETE CASCADE ON UPDATE CASCADE
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

