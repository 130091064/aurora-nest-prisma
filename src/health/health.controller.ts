import { Controller, Get, Query } from "@nestjs/common";
import { PrismaService } from "../prisma/prisma.service";

@Controller("health")
export class HealthController {
  // 注意：不要在 constructor 注入 Prisma，避免启动/探针误触库
  constructor(private readonly prisma: PrismaService) {}

  @Get()
  live() {
    return {
      ok: true,
      service: "aurora-nest-prisma",
      ts: new Date().toISOString(),
    };
  }

  @Get("ready")
  async ready(@Query("deep") deep?: string) {
    // 默认不查 DB，避免唤醒 ACU=0
    if (deep !== "1") {
      return {
        ok: true,
        ready: true,
        dbChecked: false,
        ts: new Date().toISOString(),
      };
    }

    // deep=1 才查 DB（手动排障用）
    await this.prisma.$queryRaw`SELECT 1`;
    return {
      ok: true,
      ready: true,
      dbChecked: true,
      ts: new Date().toISOString(),
    };
  }
}
