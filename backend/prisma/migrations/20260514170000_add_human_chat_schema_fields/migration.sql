ALTER TABLE `chat_rooms`
  ADD COLUMN `customer_unread_count` INTEGER NOT NULL DEFAULT 0,
  ADD COLUMN `staff_unread_count` INTEGER NOT NULL DEFAULT 0;

ALTER TABLE `messages`
  ADD COLUMN `type` ENUM('TEXT', 'IMAGE', 'SYSTEM') NOT NULL DEFAULT 'TEXT',
  ADD COLUMN `status` ENUM('SENT', 'DELIVERED', 'READ') NOT NULL DEFAULT 'SENT',
  ADD COLUMN `read_at` DATETIME(3) NULL;

CREATE INDEX `chat_rooms_user_id_idx` ON `chat_rooms`(`user_id`);
CREATE INDEX `chat_rooms_staff_id_idx` ON `chat_rooms`(`staff_id`);
CREATE INDEX `chat_rooms_status_idx` ON `chat_rooms`(`status`);
CREATE INDEX `chat_rooms_last_message_at_idx` ON `chat_rooms`(`last_message_at`);
CREATE INDEX `messages_sender_id_idx` ON `messages`(`sender_id`);
