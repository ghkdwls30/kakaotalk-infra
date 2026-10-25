#!/usr/bin/env bash
# ==============================================================================
# [STRESS TEST] 순정 리눅스(Ubuntu Native) - 전체 Redroid 인스턴스 동시 Monkey 부하 테스트
#
# 사용법:
#   ./stress_test_all.sh                   (기본: 설정 앱, 이벤트 500회, 간격 100ms)
#   ./stress_test_all.sh 1000 50           (이벤트 1000회, 간격 50ms 극한 부하)
#   ./stress_test_all.sh 500 100 com.kakao.talk  (카카오톡 앱에 부하 인가)
#   ./stress_test_all.sh stop              (진행 중인 monkey 부하 즉시 전면 중단)
# ==============================================================================
set -euo pipefail

CMD="${1:-start}"

if [ "$CMD" = "stop" ]; then
    echo "🛑 전체 기기에서 실행 중인 Monkey 부하 프로세스를 중지합니다..."
    containers=$(docker ps --filter "name=redroid" --format "{{.Names}}")
    for c in $containers; do
        docker exec "$c" pkill -f monkey >/dev/null 2>&1 || true
    done
    echo "✅ 모든 Monkey 프로세스가 강제 종료되었습니다."
    exit 0
fi

COUNT="${1:-500}"
THROTTLE="${2:-100}"
PACKAGE="${3:-com.android.settings}"

echo "=================================================================="
echo "⚡ [순정 리눅스] Redroid 전체 동시 스트레스 부하 테스트"
echo "=================================================================="
echo "🎯 대상 패키지 : $PACKAGE"
echo "🔢 이벤트 횟수 : $COUNT 회"
echo "⏱️ 이벤트 간격 : ${THROTTLE} ms"
echo "=================================================================="

containers=$(docker ps --filter "name=redroid" --format "{{.Names}}" | sort -V)
total=$(echo "$containers" | grep -c "redroid" || true)

if [ "$total" -eq 0 ]; then
    echo "❌ 실행 중인 Redroid 컨테이너가 없습니다!"
    exit 1
fi

echo "🚀 총 ${total}대 기기에 동시 부하를 병렬로 인가합니다..."
echo ""

for c in $containers; do
    echo "  ▶ [$c] Monkey 부하 시작..."
    docker exec -d "$c" monkey \
        -p "$PACKAGE" \
        --throttle "$THROTTLE" \
        --pct-syskeys 0 \
        --pct-appswitch 0 \
        --ignore-crashes \
        --ignore-timeouts \
        "$COUNT" >/dev/null 2>&1 &
done

echo ""
echo "=================================================================="
echo "🔥 전체 [${total}대] 기기에 부하가 동시에 실행되었습니다!"
echo "   - 웹 뷰어: http://localhost:8000"
echo "   - 실시간 자원 확인: htop 또는 docker stats"
echo "   - 강제 중단: ./stress_test_all.sh stop"
echo "=================================================================="
