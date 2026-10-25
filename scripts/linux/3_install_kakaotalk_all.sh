#!/usr/bin/env bash
# ==============================================================================
# [STEP 3] 순정 리눅스(Ubuntu Native) - 카카오톡 분할 패키지 4종 일괄 자동 설치기
#          - 대상 APK: apks/kakaotalk/*.apk
#          - 다중 설치(install-multiple) 지원 및 자동 초기 실행
# ==============================================================================

# sh(dash)로 실행된 경우 자동으로 bash로 재실행
if [ -z "${BASH_VERSION:-}" ]; then
    exec bash "$0" "$@"
fi

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
APK_DIR="$SCRIPT_DIR/../apks/kakaotalk"
AURORA_APK="$SCRIPT_DIR/../apks/aurora_store.apk"

if [ ! -f "$APK_DIR/base.apk" ]; then
    echo "❌ [오류] 카카오톡 APK 패키지 경로를 찾을 수 없습니다: $APK_DIR"
    exit 1
fi

# 인자 처리: 1개만 입력 시 1번부터 해당 번호까지, 2개 입력 시 시작~끝 번호
if [ $# -eq 1 ]; then
    START_NUM=1
    END_NUM="$1"
elif [ $# -ge 2 ]; then
    START_NUM="$1"
    END_NUM="$2"
else
    START_NUM=1
    END_NUM=20
fi

echo "=================================================================="
echo "💬 [순정 리눅스 3/3] 카카오톡 + 오로라 스토어 일괄 배포기 (${START_NUM}번 ~ ${END_NUM}번 기기)"
echo "=================================================================="

APK_LIST=()
for f in "$APK_DIR"/*.apk; do
    [ -f "$f" ] && APK_LIST+=("$f")
done

echo "📦 설치 대상 패키지 (${#APK_LIST[@]}개 파일):"
for f in "${APK_LIST[@]}"; do
    echo "   - $(basename "$f")"
done
if [ -f "$AURORA_APK" ]; then
    echo "   - $(basename "$AURORA_APK") (오로라 스토어)"
fi
echo ""

for i in $(seq "$START_NUM" "$END_NUM"); do
    port=$((6000 + i))
    target="127.0.0.1:$port"
    echo -n "🚀 [기기 $i] $target 연결 및 설치 중... "
    
    connect_out=$(adb connect "$target" 2>&1 || true)
    
    # 1. 분할 패키지 일괄 설치
    install_err=$(adb -s "$target" install-multiple -r "${APK_LIST[@]}" 2>&1)
    if [ $? -eq 0 ]; then
        # 2. 오로라 스토어 추가 설치 (존재 시)
        if [ -f "$AURORA_APK" ]; then
            adb -s "$target" install -r "$AURORA_APK" >/dev/null 2>&1 || true
        fi
        # 3. 카카오톡 자동 기동
        adb -s "$target" shell "am start -n com.kakao.talk/.activity.SplashActivity" >/dev/null 2>&1 || true
        echo "✅ [성공] 카카오톡 + 오로라 스토어 설치 완료 및 실행!"
    else
        echo "❌ [실패]"
        echo "      └─ 사유: $install_err"
    fi
done

echo ""
echo "=================================================================="
echo "🎉 전체 기기에 카카오톡 배포가 완료되었습니다!"
echo "   - 웹 뷰어: http://localhost:8000 접속 후 화면을 확인하세요."
echo "=================================================================="
