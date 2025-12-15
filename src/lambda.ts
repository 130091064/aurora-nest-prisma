import { NestFactory } from "@nestjs/core";
import { ExpressAdapter } from "@nestjs/platform-express";
import type { Handler } from "aws-lambda";
import express from "express";
import serverlessExpress from "@codegenie/serverless-express";
import { applyAppConfig } from "./bootstrap";

import { AppModule } from "./app.module";

let cached: any;

async function bootstrap() {
  const app = express();

  const nestApp = await NestFactory.create(AppModule, new ExpressAdapter(app), {
    logger: ["log", "error", "warn"],
  });

  applyAppConfig(nestApp);

  await nestApp.init();

  // 不让 TS 推断返回类型：直接当作 any
  return serverlessExpress({ app }) as any;
}

export const handler: Handler = async (
  event: any,
  context: any,
  callback: any,
) => {
  if (!cached) {
    cached = await bootstrap();
  }
  // 统一把 callback 也传进去，避免“缺 callback”
  return cached(event, context, callback);
};
