/*
  Warnings:

  - A unique constraint covering the columns `[phone]` on the table `profiles` will be added. If there are existing duplicate values, this will fail.
  - Made the column `phone` on table `profiles` required. This step will fail if there are existing NULL values in that column.

*/
-- AlterTable
ALTER TABLE `profiles` MODIFY `phone` VARCHAR(20) NOT NULL;

-- CreateIndex
CREATE UNIQUE INDEX `profiles_phone_key` ON `profiles`(`phone`);
