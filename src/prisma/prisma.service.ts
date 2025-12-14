import { Injectable, type OnModuleDestroy } from '@nestjs/common';
import { PrismaPg } from '@prisma/adapter-pg';
import { PrismaClient } from '@prisma/client';

@Injectable()
export class PrismaService extends PrismaClient implements OnModuleDestroy {
  constructor() {
    // Prisma v7: 必须提供 adapter 或 accelerateUrl
    // 这里用 Postgres driver adapter（直连 Aurora）

    const connectionString = process.env.DATABASE_URL;
    if (!connectionString) {
      throw new Error('DATABASE_URL is not set');
    }

    const adapter = new PrismaPg({ connectionString });

    super({ adapter });
  }

  async onModuleDestroy() {
    await this.$disconnect();
  }
}
