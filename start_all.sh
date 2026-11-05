#!/usr/bin/env bash
# ========================================================
# Kakaotalk 공통 인프라 통합 기동 스크립트
# ========================================================
set -e

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$DIR"

echo "=================================================="
echo "🚀 [Kakaotalk-Infra] 공통 인프라 기동 (PostgreSQL, Registry, Jenkins)"
echo "=================================================="

# 필요 시 최신 이미지 체크
if [ "$1" == "--pull" ]; then
    echo "📦 최신 도커 이미지 Pull 진행 중..."
    docker compose pull
fi

docker compose up -d

echo ""
echo "✅ 현재 실행 중인 인프라 컨테이너 상태:"
docker compose ps
echo "=================================================="
