import { Injectable, Logger } from '@nestjs/common';
import { CommentPostDto } from './dtos/comment-post.dto';
import { User } from 'src/user/entity/user.entity';
import { CommentRepository } from './comment.repository';
import {
  CommentGetDto,
  CommentGetResponseDto,
  CommentGetResponseDtoElement,
} from './dtos/comment-get.dto';
import { CommonResponseDto } from 'src/common/dtos/common.dto';

@Injectable()
export class CommentService {
  constructor(private repository: CommentRepository) {}

  async getComment(dto: CommentGetDto): Promise<CommentGetResponseDto> {
    try {
      const comments = await this.repository.getComment(dto);
      return { elements: comments.map(CommentGetResponseDtoElement.from) };
    } catch (e) {
      Logger.error(e);

      throw e;
    }
  }

  async postComment(
    user: User,
    dto: CommentPostDto,
  ): Promise<CommonResponseDto> {
    try {
      await this.repository.createComment(user, dto);

      return { ok: true };
    } catch (e) {
      Logger.error(e);

      return { ok: false, error: e };
    }
  }
}
