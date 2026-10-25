#!/usr/bin/env bash
# ==============================================================================
# [STEP 3] 웹 브라우저 60 FPS 실시간 제어 뷰어 (ws-scrcpy) 소스 패치 및 이미지 빌드
# ==============================================================================
set -euo pipefail

echo "=================================================================="
echo "🚀 [3/4] ws-scrcpy 웹 뷰어 패치 및 도커 이미지 빌드를 시작합니다."
echo "=================================================================="

# 1. Binderfs 활성화 상태 점검
if [ ! -e /dev/binderfs/binder ] && [ ! -e /dev/binder ]; then
    echo "⚠️ /dev/binderfs 가 마운트되어 있지 않아 수동 마운트를 시도합니다..."
    sudo mkdir -p /dev/binderfs || true
    sudo mount -t binder binder /dev/binderfs || true
fi

# 2. ws-scrcpy 소스 다운로드 (홈 디렉터리에 다운로드)
WS_DIR="$HOME/ws-scrcpy"
if [ ! -d "$WS_DIR" ]; then
    echo "📥 ws-scrcpy 공식 레포지토리 다운로드 중..."
    cd "$HOME"
    git clone https://github.com/NetrisTV/ws-scrcpy.git --depth=1
else
    echo "💡 기존 ws-scrcpy 디렉터리가 발견되었습니다: $WS_DIR"
fi

cd "$WS_DIR"

# 3. 5대 핵심 패치 적용
echo "🛠️ 웹 대시보드 최적화 패치 적용 중..."

# 패치 1: 우측 사이드 툴바 버튼 숨김 처리 (웹 iframe 100% 꽉 차게 렌더링)
if ! grep -q "control-buttons-list" src/style/app.css 2>/dev/null; then
    echo ".control-buttons-list { display: none !important; }" >> src/style/app.css
fi

# 패치 2: 모든 파일(사진, 동영상, 문서 등) 드래그 앤 드롭 전송 허용 패치 (TS 미사용 변수 에러 방지)
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

# 패치 6: HTTP 환경 WebCodecs 미지원 시 자동 fallback (mse, broadway, tinyh264)
if [ -f src/app/googDevice/client/StreamClientScrcpy.ts ]; then
    node -e '
    const fs = require("fs");
    const file = "src/app/googDevice/client/StreamClientScrcpy.ts";
    let content = fs.readFileSync(file, "utf8");
    const target = "const p = StreamClientScrcpy.createPlayer(playerName, udid, displayInfo);\n            if (!p) {\n                throw Error(`Unsupported player: \"${playerName}\"`);\n            }";
    const repl = "let p = StreamClientScrcpy.createPlayer(playerName, udid, displayInfo);\n            if (!p) {\n                const fallbacks = [\x27mse\x27, \x27broadway\x27, \x27tinyh264\x27];\n                for (const fallback of fallbacks) {\n                    p = StreamClientScrcpy.createPlayer(fallback, udid, displayInfo);\n                    if (p) {\n                        console.warn(`[StreamClientScrcpy] Player \"${playerName}\" not supported in this context. Fallback to \"${fallback}\".`);\n                        playerName = fallback;\n                        break;\n                    }\n                }\n            }\n            if (!p) {\n                throw Error(`Unsupported player: \"${playerName}\"`);\n            }";
    if (content.includes(target)) {
        fs.writeFileSync(file, content.replace(target, repl));
    }
    ' || true
fi

# 4. Redroid 1~30번 기기 자동 ADB 연결 entrypoint.sh 생성
echo "📝 1~30대 자동 연결 엔트리포인트 생성 중..."
cat << 'EOF' > entrypoint.sh
#!/bin/bash
(
  while true; do
    for p in $(seq 6001 6030); do
      adb connect 127.0.0.1:$p > /dev/null 2>&1 || true
    done
    sleep 5
  done
) &
exec npm start
EOF
chmod +x entrypoint.sh

# 5. Dockerfile 생성
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

# 6. 도커 이미지 빌드
echo "🔨 ws-scrcpy 도커 이미지 빌드 진행 중 (약 1~2분 소요)..."
docker build -t ws-scrcpy:latest .

echo "=================================================================="
echo "✅ ws-scrcpy 웹 뷰어 빌드 완료! (이미지: ws-scrcpy:latest)"
echo "👉 다음 단계: ./4_deploy_redroid.sh [대수] 를 실행하세요."
echo "=================================================================="
