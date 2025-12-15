import { NestFactory } from "@nestjs/core";
import { ExpressAdapter } from "@nestjs/platform-express";
import express from "express";
import serverlessExpress from "@codegenie/serverless-express";
import type {
  APIGatewayProxyEventV2,
  Context,
  APIGatewayProxyResultV2,
} from "aws-lambda";

import { AppModule } from "./app.module";
import { applyAppConfig } from "./bootstrap";

/**
 * ✅ Node.js 18+/24 官方推荐的「纯 Promise Handler」
 * ❌ 不包含 callback
 */
type LambdaHandlerV2 = (
  event: APIGatewayProxyEventV2,
  context: Context,
) => Promise<APIGatewayProxyResultV2>;

let cachedHandler: LambdaHandlerV2 | undefined;

async function bootstrap(): Promise<LambdaHandlerV2> {
  const app = express();

  const nestApp = await NestFactory.create(
    AppModule,
    new ExpressAdapter(app),
    {
      logger: ["log", "error", "warn"],
    },
  );

  applyAppConfig(nestApp);
  await nestApp.init();

  /**
   * @codegenie/serverless-express 在 Node 18+ 返回的就是 Promise handler
   */
  return serverlessExpress({ app }) as unknown as LambdaHandlerV2;
}

export const handler: LambdaHandlerV2 = async (event, context) => {
  // Lambda + Prisma 必备
  context.callbackWaitsForEmptyEventLoop = false;

  if (!cachedHandler) {
    cachedHandler = await bootstrap();
  }

  return cachedHandler(event, context);
};
