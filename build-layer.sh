#!/usr/bin/env bash
set -euo pipefail

# 你 template.yaml 里是 x86_64，所以这里用 x86_64 镜像
IMAGE="public.ecr.aws/lambda/nodejs:24-x86_64"

# 项目根目录
ROOT_DIR="$(cd "$(dirname "$0")" && pwd)"

# layer 目录：要求结构是 layer/nodejs/...
LAYER_NODEJS_DIR="$ROOT_DIR/layer/nodejs"

# 主工程根目录（这里就是 ROOT_DIR）
APP_DIR="$ROOT_DIR"

mkdir -p "$LAYER_NODEJS_DIR"

echo "==> [0/3] Syncing lockfile & package.json into layer/nodejs ..."

# 必须存在
if [ ! -f "$APP_DIR/package.json" ]; then
  echo "❌ Not found: $APP_DIR/package.json"
  exit 1
fi
if [ ! -f "$APP_DIR/pnpm-lock.yaml" ]; then
  echo "❌ Not found: $APP_DIR/pnpm-lock.yaml"
  exit 1
fi

# 自动复制（覆盖）
cp "$APP_DIR/package.json" "$LAYER_NODEJS_DIR/package.json"
cp "$APP_DIR/pnpm-lock.yaml" "$LAYER_NODEJS_DIR/pnpm-lock.yaml"

# 1) 清理旧的 layer node_modules
rm -rf "$LAYER_NODEJS_DIR/node_modules"

echo "==> [1/3] Installing prod deps into Layer in Docker (Linux/x86_64)..."
docker run --rm \
  --platform linux/amd64 \
  -v "$LAYER_NODEJS_DIR":/var/task \
  -w /var/task \
  --entrypoint /bin/bash \
  "$IMAGE" -lc "
    set -euo pipefail
    node -v
    npm -v

    corepack enable || true
    corepack prepare pnpm@10.20.0 --activate || true
    pnpm -v

    # 装 prod 依赖（允许 scripts，避免某些包需要 postinstall）
    pnpm install --prod --frozen-lockfile --ignore-scripts=false
  "

echo "==> [2/3] Copying Prisma generated client (.prisma) from App to Layer..."

# 主工程必须先成功执行过 pnpm prisma:generate
if [ ! -d "$APP_DIR/node_modules/.prisma/client" ]; then
  echo "❌ Not found: $APP_DIR/node_modules/.prisma/client"
  echo "   请先在项目根目录执行：pnpm prisma:generate"
  exit 1
fi

rm -rf "$LAYER_NODEJS_DIR/node_modules/.prisma"
mkdir -p "$LAYER_NODEJS_DIR/node_modules"
cp -R "$APP_DIR/node_modules/.prisma" "$LAYER_NODEJS_DIR/node_modules/.prisma"

echo "==> [3/3] Sanity check for Prisma client files in Layer..."
if [ ! -f "$LAYER_NODEJS_DIR/node_modules/.prisma/client/default.js" ]; then
  echo "❌ Missing: layer/nodejs/node_modules/.prisma/client/default.js"
  exit 1
fi

echo "✅ Layer build done!"
echo "   Layer node_modules: $LAYER_NODEJS_DIR/node_modules"
echo "   Prisma client:      $LAYER_NODEJS_DIR/node_modules/.prisma/client"
