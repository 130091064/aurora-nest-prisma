#!/usr/bin/env bash
set -euo pipefail

rm -rf dist .aws-sam

pnpm install --frozen-lockfile
pnpm nest build

sam build --use-container
