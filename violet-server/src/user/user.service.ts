import {
  BadRequestException,
  Injectable,
  Logger,
  UnauthorizedException,
} from '@nestjs/common';
import { UserRepository } from './user.repository';
import { UserRegisterDTO } from './dtos/user-register.dto';
import { ListDiscordUserAppIdsResponseDto } from './dtos/list-discord.dto';
import { CommonResponseDto } from 'src/common/dtos/common.dto';

@Injectable()
export class UserService {
  constructor(private readonly userRepository: UserRepository) {}

  async registerUser(dto: UserRegisterDTO): Promise<CommonResponseDto> {
    try {
      if (await this.userRepository.isUserExists(dto.userAppId))
        throw new UnauthorizedException('user app id already exists');

      await this.userRepository.createUser(dto);

      return { ok: true };
    } catch (e) {
      Logger.error(e);

      return { ok: false, error: e };
    }
  }

  async listDiscordUserAppIds(
    discordId?: string,
  ): Promise<ListDiscordUserAppIdsResponseDto> {
    if (discordId == null) {
      throw new BadRequestException('discord login is required');
    }

    const users = await this.userRepository.find({
      select: {
        userAppId: true,
      },
      where: {
        discordId: discordId!,
      },
    });

    return { userAppIds: users.map(({ userAppId }) => userAppId) };
  }
}
