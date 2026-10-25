#!/usr/bin/env bash
# ==============================================================================
# [CONTROL] 순정 리눅스(Ubuntu Native) - Redroid 통합 제어 및 관리 툴
#           사용법:
#             ./redroid_ctl.sh status        : 전체 기기 상태 및 ADB 연결 확인
#             ./redroid_ctl.sh start         : 컨테이너 전체 시작
#             ./redroid_ctl.sh stop          : 컨테이너 전체 안전 중지
#             ./redroid_ctl.sh restart       : 컨테이너 전체 재시작
#             ./redroid_ctl.sh scale [대수]   : 기기 대수 동적 확장/축소 (예: ./redroid_ctl.sh scale 30)
#             ./redroid_ctl.sh adb           : ADB 전체 재연결
#             ./redroid_ctl.sh shell [번호]   : 특정 기기 ADB 쉘 접속 (예: ./redroid_ctl.sh shell 1)
# ==============================================================================
set -euo pipefail

REDROID_DIR="$HOME/redroid"
CMD="${1:-status}"

case "$CMD" in
    status)
        echo "=================================================================="
        echo "📊 [Redroid 도커 컨테이너 가동 현황]"
        echo "=================================================================="
        docker ps --filter "name=redroid" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
        echo ""
        echo "=================================================================="
        echo "🔌 [ADB 연결 기기 현황]"
        echo "=================================================================="
        adb devices
        ;;

    start)
        echo "🚀 Redroid 및 웹 뷰어를 시작합니다..."
        cd "$REDROID_DIR"
        docker compose start
        ;;

    stop)
        echo "🛑 Redroid 컨테이너를 안전하게 중지합니다..."
        cd "$REDROID_DIR"
        docker compose stop
        ;;

    restart)
        echo "🔄 Redroid 컨테이너를 재시작합니다..."
        cd "$REDROID_DIR"
        docker compose restart
        ;;

    scale)
        COUNT="${2:-20}"
        SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
        echo "📈 기기 대수를 [${COUNT}대]로 변경합니다..."
        "$SCRIPT_DIR/2_deploy_redroid.sh" "$COUNT"
        ;;

    adb)
        echo "🔌 ADB 일괄 재연결 중..."
        containers=$(docker ps --filter "name=redroid" --format "{{.Names}}")
        for c in $containers; do
            if [[ "$c" =~ redroid-([0-9]+) ]]; then
                num="${BASH_REMATCH[1]}"
                port=$((6000 + 10#$num))
                adb disconnect "127.0.0.1:$port" >/dev/null 2>&1 || true
                adb connect "127.0.0.1:$port" >/dev/null 2>&1 || true
            fi
        done
        adb devices
        ;;

    shell)
        DEV_NUM="${2:-1}"
        PORT=$((6000 + DEV_NUM))
        echo "📱 [기기 $DEV_NUM] (127.0.0.1:$PORT) 쉘에 접속합니다. (종료: exit)"
        adb -s "127.0.0.1:$PORT" shell
        ;;

    *)
        echo "📖 사용법: ./redroid_ctl.sh {status|start|stop|restart|scale [대수]|adb|shell [번호]}"
        exit 1
        ;;
esac
