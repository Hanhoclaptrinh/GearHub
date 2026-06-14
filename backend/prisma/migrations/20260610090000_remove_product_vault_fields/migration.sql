-- Keep a narrow backup of the removed vault values before dropping the columns.
-- Product rows and related data are untouched.
CREATE TABLE IF NOT EXISTS `product_vault_backup_20260610` (
  `product_id` VARCHAR(36) NOT NULL,
  `is_vault` BOOLEAN NOT NULL,
  `vault_specs` JSON NULL,
  `backed_up_at` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  PRIMARY KEY (`product_id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

INSERT INTO `product_vault_backup_20260610` (`product_id`, `is_vault`, `vault_specs`)
SELECT `id`, `is_vault`, `vault_specs`
FROM `products`
WHERE `is_vault` = TRUE OR `vault_specs` IS NOT NULL
ON DUPLICATE KEY UPDATE
  `is_vault` = VALUES(`is_vault`),
  `vault_specs` = VALUES(`vault_specs`),
  `backed_up_at` = CURRENT_TIMESTAMP(3);

DROP INDEX `products_is_vault_idx` ON `products`;

ALTER TABLE `products`
  DROP COLUMN `is_vault`,
  DROP COLUMN `vault_specs`;
