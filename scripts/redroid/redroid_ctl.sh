#!/usr/bin/env bash
# ==============================================================================
# Redroid 컨테?�너 ?�스?�스 간편 ?�어 �?모니?�링 CLI
# ==============================================================================
set -euo pipefail

REDROID_DIR="$HOME/redroid"
CMD="${1:-help}"
ARG="${2:-}"

cd "$REDROID_DIR" 2>/dev/null || {
    echo "??~/redroid ?�렉?�리가 존재?��? ?�습?�다. 먼�? 4_deploy_redroid.sh �??�행?�세??"
    exit 1
}

case "$CMD" in
    status)
        echo "=================================================================="
        echo "?�� [?�시�??�태] 가??중인 Redroid ?�스?�스 목록"
        echo "=================================================================="
        docker ps --filter "name=redroid" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
        echo ""
        echo "?�� [리소???�유??(CPU / RAM)]"
        docker stats --no-stream --format "table {{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.NetIO}}" $(docker ps -q --filter "name=redroid")
        ;;

    scale)
        if [ -z "$ARG" ]; then
            echo "?�용�? ./redroid_ctl.sh scale [?�??1~30)]"
            exit 1
        fi
        echo "?�� ?�스?�스�?${ARG}?��?변경합?�다..."
        # deploy ?�크립트 ?�치 ?�인 ???�행
        SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"; SCRIPT_PATH="$SCRIPT_DIR/4_deploy_redroid.sh"
        if [ ! -f "$SCRIPT_PATH" ]; then
            SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"; SCRIPT_PATH="$SCRIPT_DIR/4_deploy_redroid.sh"
        fi
        bash "$SCRIPT_PATH" "$ARG"
        ;;

    start)
        if [ -z "$ARG" ] || [ "$ARG" = "all" ]; then
            echo "?? ?�체 Redroid ?�스?�스�??�작?�니??.."
            docker compose start
        else
            NUM=$(printf "%02d" "$ARG")
            echo "?? redroid-${NUM} 기기�??�작?�니??.."
            docker start "redroid-${NUM}"
        fi
        ;;

    stop)
        if [ -z "$ARG" ] || [ "$ARG" = "all" ]; then
            echo "?�� ?�체 Redroid ?�스?�스�??�시 중�??�니??.."
            docker compose stop
        else
            NUM=$(printf "%02d" "$ARG")
            echo "?�� redroid-${NUM} 기기�??�시 중�??�니??.."
            docker stop "redroid-${NUM}"
        fi
        ;;

    restart)
        if [ -z "$ARG" ] || [ "$ARG" = "all" ]; then
            echo "?�� ?�체 Redroid ?�스?�스�??�시?�합?�다..."
            docker compose restart
        else
            NUM=$(printf "%02d" "$ARG")
            echo "?�� redroid-${NUM} 기기�??�시?�합?�다..."
            docker restart "redroid-${NUM}"
        fi
        ;;

    logs)
        if [ -z "$ARG" ]; then
            echo "?�용�? ./redroid_ctl.sh logs [기기번호]"
            exit 1
        fi
        NUM=$(printf "%02d" "$ARG")
        docker logs --tail 100 -f "redroid-${NUM}"
        ;;

    web)
        echo "?�� ??뷰어(ws-scrcpy) 컨테?�너 ?�시??�?.."
        docker restart ws-scrcpy
        echo "????뷰어 ?�시???�료: http://localhost:8000"
        ;;

    *)
        echo "=================================================================="
        echo "?�� Redroid 간편 관�?명령??가?�드"
        echo "=================================================================="
        echo "  ./redroid_ctl.sh status         : ?�재 기동 기기 �?CPU/RAM ?�유???�인"
        echo "  ./redroid_ctl.sh scale <N>      : N?��??�??조절 (?? scale 20, scale 10)"
        echo "  ./redroid_ctl.sh start <번호>   : ?�정 기기 켜기 (?? start 5, start all)"
        echo "  ./redroid_ctl.sh stop <번호>    : ?�정 기기 ?�기 (?? stop 16, stop all)"
        echo "  ./redroid_ctl.sh restart <번호> : ?�정 기기 ?��???(?? restart 3)"
        echo "  ./redroid_ctl.sh logs <번호>    : ?�정 기기 ?�시�?로그 보기"
        echo "  ./redroid_ctl.sh web            : ??뷰어(ws-scrcpy) ?�시??
        echo "=================================================================="
        ;;
esac
