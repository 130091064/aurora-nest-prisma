#!/usr/bin/env bash
set -euo pipefail

rm -rf dist .aws-sam

# 1) 本机安装依赖 + 生成 Prisma Client + 编译 Nest（产出 dist）
pnpm install --frozen-lockfile
pnpm prisma:generate
pnpm nest build

./build-layer.sh

# 2) SAM 构建：只会进容器执行 Makefile 的拷贝动作（不会 npm install）
sam build --use-container --cached
