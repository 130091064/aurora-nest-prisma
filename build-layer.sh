#!/usr/bin/env bash
set -euo pipefail

IMAGE="public.ecr.aws/lambda/nodejs:24-x86_64"
ROOT_DIR="$(cd "$(dirname "$0")" && pwd)"
LAYER_NODEJS_DIR="$ROOT_DIR/layer/nodejs"
APP_DIR="$ROOT_DIR"

mkdir -p "$LAYER_NODEJS_DIR"

echo "==> [0/3] Syncing package files into layer/nodejs ..."

test -f "$APP_DIR/package.json" || { echo "❌ Not found: $APP_DIR/package.json"; exit 1; }
test -f "$APP_DIR/pnpm-lock.yaml" || { echo "❌ Not found: $APP_DIR/pnpm-lock.yaml"; exit 1; }

cp "$APP_DIR/package.json" "$LAYER_NODEJS_DIR/package.json"
cp "$APP_DIR/pnpm-lock.yaml" "$LAYER_NODEJS_DIR/pnpm-lock.yaml"

# package-lock.json：如果存在就同步；不存在也没关系，容器里会自动生成
if [ -f "$APP_DIR/package-lock.json" ]; then
  cp "$APP_DIR/package-lock.json" "$LAYER_NODEJS_DIR/package-lock.json"
fi

# 清理旧产物（包括历史误写进去的 pnpm/npm 目录）
rm -rf \
  "$LAYER_NODEJS_DIR/node_modules" \
  "$LAYER_NODEJS_DIR/.pnpm" \
  "$LAYER_NODEJS_DIR/.pnpm-store" \
  "$LAYER_NODEJS_DIR/.npm" \
  "$LAYER_NODEJS_DIR/.cache"

USER_FLAG=()
if [[ "$(uname -s)" != "Darwin" ]]; then
  USER_FLAG=(--user "$(id -u):$(id -g)")
fi

echo "==> [1/3] Installing prod deps into Layer in Docker (Linux/x86_64) via npm ci..."

docker run --rm \
  --platform linux/amd64 \
  "${USER_FLAG[@]}" \
  -e HOME=/tmp \
  -v "$LAYER_NODEJS_DIR":/var/task:rw \
  -w /var/task \
  --entrypoint /bin/bash \
  "$IMAGE" -lc '
    set -euo pipefail
    node -v
    npm -v

    # ✅ 所有 npm cache 放 /tmp，避免写进 layer
    export npm_config_cache=/tmp/npm-cache
    export NPM_CONFIG_CACHE=/tmp/npm-cache

    # npm ci 必须要 package-lock.json
    # 如果没有或不匹配：在容器里用 npm 生成/修复，然后再 ci
    if [ ! -f package-lock.json ]; then
      echo "==> package-lock.json not found, generating..."
      npm i --package-lock-only --ignore-scripts --no-audit --no-fund
    else
      echo "==> package-lock.json exists, verifying with npm ci..."
      if ! npm ci --omit=dev --ignore-scripts --no-audit --no-fund; then
        echo "==> npm ci failed (likely lock mismatch). Re-generating lockfile then retrying..."
        rm -f package-lock.json
        npm i --package-lock-only --ignore-scripts --no-audit --no-fund
      fi
    fi

    # 再跑一次 ci，确保最终是干净可复现的依赖树
    npm ci --omit=dev --ignore-scripts --no-audit --no-fund

    echo "==> [1.5/3] Slimming node_modules (safe)..."

    # ✅ 只删真正的大头，但不动 typescript/prisma（否则会造成 .bin 残留入口缺失，引发 sam build hash 报错）
    rm -rf /var/task/node_modules/@prisma/studio-core 2>/dev/null || true

    # 可选：如果你确定运行时代码不 import effect
    rm -rf /var/task/node_modules/effect 2>/dev/null || true

    # 可选：纯后端 API 一般不需要 react/react-dom
    rm -rf /var/task/node_modules/react /var/task/node_modules/react-dom 2>/dev/null || true

    # ✅ 稳健瘦身：删 docs/tests/sourcemap/typescript 源码（不破坏 .bin）
    find /var/task/node_modules -type f \( -name "*.md" -o -name "*.map" \) -delete 2>/dev/null || true
    find /var/task/node_modules -type d \( -name "test" -o -name "__tests__" -o -name "docs" \) -prune -exec rm -rf {} + 2>/dev/null || true

    # ✅ 关键：修复 node_modules/.bin 里的坏链接（根治 sam build 的 FileNotFoundError）
    if [ -d /var/task/node_modules/.bin ]; then
      echo "==> Fixing broken links in node_modules/.bin ..."
      # 删除所有指向不存在目标的链接
      find -L /var/task/node_modules/.bin -type l -exec rm -f {} + 2>/dev/null || true
    fi


    # ✅ 保险：不要把 cache 写进 /var/task（layer）
    rm -rf /var/task/.npm /var/task/.cache 2>/dev/null || true
  '

# 保险：纠正属主（WSL/Linux 防 root 残留；Mac 上这句通常也不会坏）
chown -R "$(id -u):$(id -g)" "$LAYER_NODEJS_DIR/node_modules" 2>/dev/null || true

echo "==> [2/3] Copying Prisma generated client (.prisma) from App to Layer..."

if [ ! -d "$APP_DIR/node_modules/.prisma/client" ]; then
  echo "❌ Not found: $APP_DIR/node_modules/.prisma/client"
  echo "   请先在项目根目录执行：pnpm prisma:generate"
  echo "   并确保 schema.prisma generator binaryTargets 包含 linux-x64-openssl-3.0.x"
  exit 1
fi

rm -rf "$LAYER_NODEJS_DIR/node_modules/.prisma"
mkdir -p "$LAYER_NODEJS_DIR/node_modules"
cp -R "$APP_DIR/node_modules/.prisma" "$LAYER_NODEJS_DIR/node_modules/.prisma"

echo "==> [3/3] Sanity check for Prisma client files in Layer..."
test -f "$LAYER_NODEJS_DIR/node_modules/.prisma/client/default.js" || {
  echo "❌ Missing: layer/nodejs/node_modules/.prisma/client/default.js"
  exit 1
}

echo "✅ Layer build done!"
echo "   Layer node_modules: $LAYER_NODEJS_DIR/node_modules"
echo "   Prisma client:      $LAYER_NODEJS_DIR/node_modules/.prisma/client"
