#!/usr/bin/env bash
# ========================================================
# Kakaotalk 전체 인프라 통합 재기동 스크립트
# ========================================================
set -e

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$DIR"

echo "🔄 [Kakaotalk] 전체 인프라 재기동..."
docker compose restart
echo ""
echo "✅ 현재 실행 중인 컨테이너 상태:"
docker compose ps
