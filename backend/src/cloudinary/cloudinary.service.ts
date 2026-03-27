import { Injectable, BadRequestException } from '@nestjs/common';
import { v2 as cloudinary, UploadApiResponse, UploadApiErrorResponse } from 'cloudinary';
import * as streamifier from 'streamifier';

@Injectable()
export class CloudinaryService {
    // upload file tu buffer len cld
    async uploadFile(file: Express.Multer.File): Promise<UploadApiResponse | UploadApiErrorResponse> {
        return new Promise((resolve, reject) => {
            const upload = cloudinary.uploader.upload_stream(
                {
                    folder: 'gearhub/media',
                    resource_type: 'auto',
                },
                (error, result) => {
                    if (error) return reject(error);

                    if (!result) {
                        return reject(new BadRequestException('Lỗi tải file lên Cloudinary'));
                    }

                    resolve(result);
                },
            );

            // chuyen doi buffer
            streamifier.createReadStream(file.buffer).pipe(upload);
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