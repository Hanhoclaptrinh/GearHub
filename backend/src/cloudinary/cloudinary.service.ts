import { Injectable, BadRequestException } from '@nestjs/common';
import { v2 as cloudinary, UploadApiResponse, UploadApiErrorResponse } from 'cloudinary';
import * as streamifier from 'streamifier';
import sharp from 'sharp';

@Injectable()
export class CloudinaryService {
    private readonly MAX_FILE_SIZE = 10 * 1024 * 1024; // 10MB Cloudinary Free Limit

    // upload file tu buffer len cld
    async uploadFile(file: Express.Multer.File): Promise<UploadApiResponse | UploadApiErrorResponse> {
        // kiem tra kich thuoc file truoc khi gui
        if (file.size > this.MAX_FILE_SIZE) {
            throw new BadRequestException(
                `Kích thước file (${(file.size / 1024 / 1024).toFixed(2)}MB) vượt quá giới hạn cho phép (10MB). ` +
                `Vui lòng tối ưu hóa file trước khi tải lên.`
            );
        }

        let buffer = file.buffer;

        // nen anh neu la file hinh anh va kich thuoc > 2MB
        if (file.mimetype.startsWith('image/') && file.size > 2 * 1024 * 1024) {
            try {
                // nen anh bang sharp (giu nguyen dinh dang nhung giam chat luong hoac resize neu qua lon)
                const image = sharp(file.buffer);
                const metadata = await image.metadata();

                let pipeline = image;
                // neu anh qua lon (> 2000px), thuc hien resize de giam dung luong
                if (metadata.width && metadata.width > 2000) {
                    pipeline = pipeline.resize(2000);
                }

                // nen chat luong xuong ~80%
                if (file.mimetype === 'image/jpeg' || file.mimetype === 'image/jpg') {
                    buffer = await pipeline.jpeg({ quality: 80 }).toBuffer();
                } else if (file.mimetype === 'image/png') {
                    buffer = await pipeline.png({ quality: 80, compressionLevel: 8 }).toBuffer();
                } else if (file.mimetype === 'image/webp') {
                    buffer = await pipeline.webp({ quality: 80 }).toBuffer();
                }
            } catch (err) {
                console.error('Lỗi khi nén ảnh bằng Sharp:', err);
                // neu loi thi tiep tuc voi buffer goc neu no van < 10MB
            }
        }

        return new Promise((resolve, reject) => {
            const upload = cloudinary.uploader.upload_stream(
                {
                    folder: 'gearhub/media',
                    resource_type: 'auto',
                    format: file.mimetype === 'image/svg+xml' ? 'svg' : undefined,
                },
                (error, result) => {
                    if (error) {
                        return reject(error);
                    }

                    if (!result) {
                        return reject(new BadRequestException('Lỗi tải file lên Cloudinary'));
                    }

                    resolve(result);
                },
            );

            // chuyen doi buffer
            streamifier.createReadStream(buffer).pipe(upload);
        });
    }

    async deleteFile(publicId: string): Promise<any> {
        try {
            return await cloudinary.uploader.destroy(publicId);
        } catch (error) {
            throw new BadRequestException(`Lỗi khi xóa file khỏi cloud: ${error.message}`);
        }
    }
}