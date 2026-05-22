-- Drop reward point ledger before removing related columns.
DROP TABLE IF EXISTS `point_transactions`;

-- Remove reward point balance fields from users.
ALTER TABLE `users`
    DROP COLUMN `reward_points`,
    DROP COLUMN `total_spent`;

-- Remove point redemption / earning fields from orders.
ALTER TABLE `orders`
    DROP COLUMN `points_discount`,
    DROP COLUMN `points_used`,
    DROP COLUMN `reward_points_earned`,
    DROP COLUMN `reward_points_earned_at`;

-- Keep normal vouchers, but remove point-redemption metadata.
ALTER TABLE `vouchers`
    DROP COLUMN `points_cost`,
    DROP COLUMN `required_tier`,
    DROP COLUMN `source`;
