import { ConfigService } from '@nestjs/config';
import { v2 as cloudinary } from 'cloudinary';

export const CloudinaryProvider = {
    provide: 'CLOUDINARY',
    inject: [ConfigService],
    useFactory: (configService: ConfigService) => {
        return cloudinary.config({
            cloud_name: configService.get<string>('CLD_NAME'),
            api_key: configService.get<string>('CLD_API_KEY'),
            api_secret: configService.get<string>('CLD_API_SECRET'),
        });
    },
};
