import { ValidationPipe } from "@nestjs/common";
import type { INestApplication } from "@nestjs/common";

export function applyAppConfig(app: INestApplication) {
  app.useGlobalPipes(
    new ValidationPipe({
      whitelist: true,
      forbidNonWhitelisted: true,
      transform: true,
    }),
  );

  app.setGlobalPrefix("api");

  // 如你需要 CORS，本地+Lambda一致也建议在这开
  app.enableCors();
}
