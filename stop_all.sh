#!/usr/bin/env bash
# ========================================================
# Kakaotalk 전체 인프라 통합 중지 스크립트
# ========================================================
set -e

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$DIR"

echo "🛑 [Kakaotalk] 전체 인프라 컨테이너 중지..."
docker compose down
echo "✅ 중지 완료"
