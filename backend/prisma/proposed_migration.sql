-- proposed_migration.sql
-- Manual DB updates for GearHub Promotion Module
-- Database: MySQL

-- 1. Alter users table to add reward points fields
ALTER TABLE `users` 
ADD COLUMN `reward_points` INT NOT NULL DEFAULT 0,
ADD COLUMN `total_spent` DECIMAL(15, 2) NOT NULL DEFAULT 0.00;

-- 2. Alter orders table to add discount tracking fields
ALTER TABLE `orders`
ADD COLUMN `voucher_discount` DECIMAL(10, 2) NOT NULL DEFAULT 0.00,
ADD COLUMN `points_discount` DECIMAL(10, 2) NOT NULL DEFAULT 0.00,
ADD COLUMN `points_used` INT NOT NULL DEFAULT 0;

-- 3. Create vouchers table
CREATE TABLE `vouchers` (
  `id` VARCHAR(36) NOT NULL,
  `code` VARCHAR(50) NOT NULL,
  `name` VARCHAR(255) NOT NULL,
  `description` TEXT NULL,
  `type` ENUM('PERCENT', 'FIXED_AMOUNT') NOT NULL,
  `value` DECIMAL(10, 2) NOT NULL,
  `min_order_amount` DECIMAL(10, 2) NOT NULL DEFAULT 0.00,
  `max_discount_amount` DECIMAL(10, 2) NULL,
  `quantity` INT NOT NULL,
  `claimed_count` INT NOT NULL DEFAULT 0,
  `used_count` INT NOT NULL DEFAULT 0,
  `starts_at` DATETIME(3) NULL,
  `expires_at` DATETIME(3) NULL,
  `is_active` TINYINT(1) NOT NULL DEFAULT 1,
  `created_at` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  `updated_at` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),
  PRIMARY KEY (`id`),
  UNIQUE KEY `vouchers_code_key` (`code`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 4. Create user_vouchers table
CREATE TABLE `user_vouchers` (
  `id` VARCHAR(36) NOT NULL,
  `user_id` VARCHAR(36) NOT NULL,
  `voucher_id` VARCHAR(36) NOT NULL,
  `claimed_at` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  `used_at` DATETIME(3) NULL,
  `order_id` VARCHAR(36) NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `user_vouchers_order_id_key` (`order_id`),
  UNIQUE KEY `user_vouchers_user_id_voucher_id_key` (`user_id`, `voucher_id`),
  CONSTRAINT `user_vouchers_user_id_fkey` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `user_vouchers_voucher_id_fkey` FOREIGN KEY (`voucher_id`) REFERENCES `vouchers` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `user_vouchers_order_id_fkey` FOREIGN KEY (`order_id`) REFERENCES `orders` (`id`) ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 5. Create point_transactions table
CREATE TABLE `point_transactions` (
  `id` VARCHAR(36) NOT NULL,
  `user_id` VARCHAR(36) NOT NULL,
  `order_id` VARCHAR(36) NULL,
  `type` ENUM('EARN', 'REDEEM', 'REFUND', 'ADJUST') NOT NULL,
  `points` INT NOT NULL,
  `balance_after` INT NOT NULL,
  `description` VARCHAR(255) NULL,
  `created_at` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  PRIMARY KEY (`id`),
  CONSTRAINT `point_transactions_user_id_fkey` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `point_transactions_order_id_fkey` FOREIGN KEY (`order_id`) REFERENCES `orders` (`id`) ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
