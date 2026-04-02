import { IsString, IsNotEmpty, Length } from 'class-validator';

export class ReplyReviewDto {
    @IsString()
    @IsNotEmpty()
    @Length(2, 2000)
    reply: string;
}