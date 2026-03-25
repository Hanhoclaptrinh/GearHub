/*
  Warnings:

  - A unique constraint covering the columns `[slug]` on the table `brands` will be added. If there are existing duplicate values, this will fail.
  - Added the required column `slug` to the `brands` table without a default value. This is not possible if the table is not empty.

*/
-- AlterTable
ALTER TABLE `brands` ADD COLUMN `slug` VARCHAR(100) NOT NULL;

-- CreateIndex
CREATE UNIQUE INDEX `brands_slug_key` ON `brands`(`slug`);

-- CreateIndex
CREATE INDEX `brands_slug_idx` ON `brands`(`slug`);
