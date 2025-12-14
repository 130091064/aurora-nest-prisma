```bash
# 本地开发用：migrate dev
npx prisma migrate dev --name init_items
# 在 prisma/migrations/ 生成迁移文件
# 把迁移应用到数据库
# 自动 prisma generate

# 验收（会唤醒 DB，一次即可）：
npx prisma studio

# 云上部署用：migrate deploy
npx prisma migrate deploy


# 原型期临时同步（不需要迁移历史）
# 你明确不关心迁移文件
npx prisma db push

```