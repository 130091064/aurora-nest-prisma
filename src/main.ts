import { NestFactory } from "@nestjs/core";
import { AppModule } from "./app.module";
import { applyAppConfig } from "./bootstrap";

async function bootstrap() {
  const app = await NestFactory.create(AppModule);

  applyAppConfig(app);
  const port = process.env.PORT ? Number(process.env.PORT) : 3000;
  await app.listen(port);
}
bootstrap();
