#!/usr/bin/env bash
# ==============================================================================
# [STEP 1] 웹 브라우저 실시간 제어 뷰어 (ws-scrcpy) 소스 패치 및 이미지 빌드
#          - 패치 1: iframe 꽉 찬 화면 렌더링 (사이드바 숨김)
#          - 패치 2: 모든 파일 드래그 앤 드롭 전송 허용
#          - 패치 3: 고품질 60 FPS / 8 Mbps 설정
#          - 패치 4: 불필요한 가상 터치 키 이벤트 방지
#          - 패치 5: 한글 UTF-8 3바이트 인코딩 깨짐 방지
# ==============================================================================
set -euo pipefail

echo "=================================================================="
echo "🚀 [순정 리눅스 1/3] ws-scrcpy 웹 뷰어 패치 및 도커 이미지 빌드를 시작합니다."
echo "=================================================================="

WS_DIR="$HOME/ws-scrcpy"
if [ ! -d "$WS_DIR" ]; then
    echo "📥 ws-scrcpy 공식 레포지토리 다운로드 중..."
    cd "$HOME"
    git clone https://github.com/NetrisTV/ws-scrcpy.git --depth=1
else
    echo "💡 기존 ws-scrcpy 디렉터리가 발견되었습니다: $WS_DIR"
fi

cd "$WS_DIR"

# 1. 최적화 패치 적용
echo "🛠️ 웹 대시보드 최적화 패치 적용 중..."

# 패치 1: 우측 사이드 툴바 버튼 및 설정 패널 숨김 (웹 iframe 100% 꽉 차게 렌더링)
if ! grep -q "display: none !important" src/style/app.css 2>/dev/null; then
    echo ".control-buttons-list, .control-wrapper, .more-box { display: none !important; width: 0 !important; max-width: 0 !important; }" >> src/style/app.css
fi

# 패치 2: 모든 파일(사진, 동영상, 문서 등) 드래그 앤 드롭 전송 허용 패치
if [ -f src/app/googDevice/filePush/ScrcpyFilePushStream.ts ]; then
    sed -i 's/return (type && ALLOWED_TYPES.includes(type)) || (!type && ALLOWED_NAME_RE.test(name));/return Boolean(file) || Boolean(ALLOWED_TYPES) || Boolean(ALLOWED_NAME_RE);/g' src/app/googDevice/filePush/ScrcpyFilePushStream.ts || true
fi

# 패치 2-1: TypeScript 미사용 변수 strict 검사 비활성화 (빌드 에러 원천 차단)
if [ -f tsconfig.json ]; then
    sed -i 's/"noUnusedLocals": true/"noUnusedLocals": false/g' tsconfig.json || true
    sed -i 's/"noUnusedParameters": true/"noUnusedParameters": false/g' tsconfig.json || true
fi

# 패치 3: 60 FPS & 8 Mbps 고화질/고프레임 기본값 패치
for file in src/app/googDevice/client/*.ts; do
    if [ -f "$file" ]; then
        sed -i 's/maxFps: 30/maxFps: 60/g' "$file" 2>/dev/null || true
        sed -i 's/bitrate: 4000000/bitrate: 8000000/g' "$file" 2>/dev/null || true
    fi
done

# 패치 4: Ctrl/Shift 키 입력 시 초록색 원(멀티터치 시뮬레이션) 방지 패치
if [ -f src/app/googDevice/interactionHandler/FeaturedInteractionHandler.ts ]; then
    sed -i 's/public static readonly keyEventsNames: string\[\] = \[.*\];/public static readonly keyEventsNames: string[] = [];/g' src/app/googDevice/interactionHandler/FeaturedInteractionHandler.ts || true
fi

# 패치 5: 한글 UTF-8 3바이트 글자수 잘림 및 클립보드 붙여넣기 에러 방지 패치
if [ -f src/app/googDevice/controlMessage/TextControlMessage.ts ]; then
    sed -i "s/Buffer.from(this.text, 'ascii')/Buffer.from(this.text, 'utf8')/g" src/app/googDevice/controlMessage/TextControlMessage.ts || true
    sed -i "s/this.text.length/Buffer.byteLength(this.text, 'utf8')/g" src/app/googDevice/controlMessage/TextControlMessage.ts || true
fi

# 2. Redroid 기기 스마트 자동 ADB 연결 entrypoint.sh 생성
echo "📝 스마트 자동 연결 엔트리포인트 생성 중..."
cat << 'EOF' > entrypoint.sh
#!/bin/bash
(
  sleep 5
  while true; do
    devices=$(adb devices 2>/dev/null)
    
    # 1. 오프라인으로 꼬인 기기 연결 자동 초기화
    echo "$devices" | grep "offline" | while read -r line; do
      dev=$(echo "$line" | awk '{print $1}')
      if [ -n "$dev" ]; then
        adb disconnect "$dev" >/dev/null 2>&1 || true
      fi
    done

    # 2. 실제로 포트가 열려있는 가상 기기만 선별 연결 (최대 60대 범위 내)
    for p in $(seq 6001 6060); do
      if ! echo "$devices" | grep -q "127.0.0.1:$p[[:space:]]*device"; then
        if (exec 3<>/dev/tcp/127.0.0.1/"$p") 2>/dev/null; then
          exec 3>&-
          adb disconnect 127.0.0.1:$p >/dev/null 2>&1 || true
          adb connect 127.0.0.1:$p >/dev/null 2>&1 || true
        fi
      fi
    done
    sleep 30
  done
) &
exec npm start
EOF
chmod +x entrypoint.sh

# 3. Dockerfile 생성
echo "🐳 ws-scrcpy Dockerfile 생성 중..."
cat << 'EOF' > Dockerfile
FROM node:20-bookworm-slim
RUN apt-get update && apt-get install -y adb git python3 make g++ curl && rm -rf /var/lib/apt/lists/*
WORKDIR /app
COPY . .
RUN chmod +x entrypoint.sh
RUN npm install
RUN npm run dist
EXPOSE 8000
CMD ["./entrypoint.sh"]
EOF

# 4. 도커 이미지 빌드
echo "🔨 ws-scrcpy 도커 이미지 빌드 진행 중 (약 1~2분 소요)..."
docker build -t ws-scrcpy:latest .

echo ""
echo "=================================================================="
echo "✅ ws-scrcpy 웹 뷰어 빌드 완료! (이미지: ws-scrcpy:latest)"
echo "👉 다음 단계: ./2_deploy_redroid.sh [대수] 를 실행하세요."
echo "=================================================================="
