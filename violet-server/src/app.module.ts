import { Module } from '@nestjs/common';
import { AppController } from './app.controller';
import { AppService } from './app.service';
import { MySQLConfigModule } from './config/config.module';
import { TypeOrmModule } from '@nestjs/typeorm';
import { MySQLConfigService } from './config/config.service';
import { ConfigModule } from '@nestjs/config';
import { CommonModule } from './common/common.module';
import { CommentModule } from './comment/comment.module';
import { UserModule } from './user/user.module';
import { AuthModule } from './auth/auth.module';
import { ViewModule } from './view/view.module';
import { RedisModule } from './redis/redis.module';
import * as Joi from 'joi';
import { AWSModule } from './aws/aws.module';

export const envValidationSchema = Joi.object({
  NODE_ENV: Joi.string().valid('dev', 'prod', 'test').required(),
  DB_HOST: Joi.string().required(),
  DB_PORT: Joi.string().required(),
  DB_USER: Joi.string().required(),
  DB_PASSWORD: Joi.string().required(),
  DB_DB: Joi.string().required(),
  ACCESS_TOKEN_SECRET_KEY: Joi.string().required(),
  REFRESH_TOKEN_SECRET_KEY: Joi.string().required(),
  SALT: Joi.string().required(),
  REDIS_HOST: Joi.string().required(),
  REDIS_PORT: Joi.string().required(),
  IS_MASTER_NODE: Joi.bool().required(),
  DISCORD_CLIENT_ID: Joi.string().required(),
  DISCORD_CLIENT_SECRET: Joi.string().required(),
  DISCORD_REDIRECT_URI: Joi.string().required(),
  AWS_ACCESS_KEY: Joi.string().required(),
  AWS_SECRET_ACCESS_KEY: Joi.string().required(),
  DEFAULT_REGION_NAME: Joi.string().required(),
});

@Module({
  imports: [
    ConfigModule.forRoot({
      isGlobal: true,
      envFilePath:
        process.env.NODE_ENV === 'dev'
          ? '.dev.env'
          : process.env.NODE_ENV === 'prod'
            ? '.prod.env'
            : '.test.env',
      validationSchema: envValidationSchema,
    }),

    TypeOrmModule.forRootAsync({
      imports: [MySQLConfigModule],
      useClass: MySQLConfigService,
      inject: [MySQLConfigService],
    }),

    ConfigModule,
    CommonModule,
    CommentModule,
    UserModule,
    AuthModule,
    ViewModule,
    RedisModule,
    AWSModule,
  ],
  controllers: [AppController],
  providers: [AppService],
})
export class AppModule {}
