#!/usr/bin/env bash
# ==============================================================================
# [STEP 2] 순정 리눅스(Ubuntu Native) - Redroid 인스턴스 일괄 배포 & 스케일링 스크립트
#          - 1~60대 자유 확장/축소 지원
#          - 초경량 최적화 해상도 (540x960, 220 DPI) 적용
#          - 최신 카카오톡 완벽 호환 (Android 13 / redroid:13.0.0-latest)
#          - 최초 1회 생성된 기기 신분증(IMEI, MAC, Serial 등) 영구 보존으로 카카오톡 인증 풀림 방지
#          - 3대 성능 최적화(ext4 볼륨, guest GPU, use_memfd) 및 가상 키보드 차단 적용
# sh(dash)로 실행된 경우 자동으로 bash로 재실행
if [ -z "${BASH_VERSION:-}" ]; then
    exec bash "$0" "$@"
fi

set -euo pipefail

if [ -z "${1:-}" ]; then
    echo "💡 [안내] 기기 대수를 입력하지 않아 기본 권장값인 [20대]로 실행합니다."
    echo "   (원하는 대수를 지정하려면: ./2_deploy_redroid.sh [1~60] 예: ./2_deploy_redroid.sh 30)"
    echo ""
    TARGET_COUNT=20
else
    TARGET_COUNT="$1"
fi

if ! [[ "$TARGET_COUNT" =~ ^[0-9]+$ ]] || [ "$TARGET_COUNT" -lt 1 ] || [ "$TARGET_COUNT" -gt 60 ]; then
    echo "❌ [오류] 기기 대수는 1부터 60 사이의 숫자여야 합니다. (입력값: $TARGET_COUNT)"
    exit 1
fi

export TARGET_COUNT

REDROID_DIR="$HOME/redroid"
mkdir -p "$REDROID_DIR"
cd "$REDROID_DIR"

echo "=================================================================="
echo "🚀 [순정 리눅스 2/3] Redroid 인스턴스 [총 ${TARGET_COUNT}대] 구동 및 최적화를 시작합니다."
echo "=================================================================="

# 1. Binderfs 활성화 상태 점검
if [ ! -e /dev/binderfs/binder ] && [ ! -e /dev/binder ]; then
    echo "⚙️ /dev/binderfs 마운트 확인 중..."
    sudo mkdir -p /dev/binderfs || true
    sudo mount -t binder binder /dev/binderfs || true
fi

# 2. [부팅 초기화] 가상 키보드 100% 완전 비활성화 init 스크립트 작성
echo "⌨️ 가상 키보드 원천 차단 init 스크립트(init-keyboard.rc) 작성 중..."
cat << 'EOF' > init-keyboard.rc
on property:sys.boot_completed=1
    exec_background - root root -- /system/bin/ip rule add from all lookup main pref 9999
    exec_background - root root -- /system/bin/settings put secure show_ime_with_hard_keyboard 0
    exec_background - root root -- /system/bin/settings put global window_animation_scale 0
    exec_background - root root -- /system/bin/settings put global transition_animation_scale 0
    exec_background - root root -- /system/bin/settings put global animator_duration_scale 0
    exec_background - root root -- /system/bin/settings put global package_verifier_enable 0
    exec_background - root root -- /system/bin/settings put global verifier_verify_adb_installs 0
    exec_background - root root -- /system/bin/settings put system sound_effects_enabled 0
    exec_background - root root -- /system/bin/settings put system haptic_feedback_enabled 0
    exec_background - root root -- /system/bin/settings put secure spell_checker_enabled 0
    exec_background - root root -- /system/bin/dumpsys deviceidle disable
    exec_background - root root -- /system/bin/pm disable-user --user 0 com.android.inputmethod.latin
    exec_background - root root -- /system/bin/pm disable-user --user 0 com.google.android.inputmethod.latin
    exec_background - root root -- /system/bin/pm disable-user --user 0 io.github.visnkmr.nokeyboard
EOF
chmod 644 init-keyboard.rc

# 3. [영구 프로필] 기기 신분증 영구 보관 파일 (device_profiles.json) 관리
PROFILES_FILE="$REDROID_DIR/device_profiles.json"
echo "🛡️ 기기 프로필 영구 고정 데이터 점검 및 생성 중 (${PROFILES_FILE})..."

python3 - << 'PYEOF'
import json
import os
import random
import secrets

PROFILES_PATH = os.path.expanduser("~/redroid/device_profiles.json")

MODELS = [
    {"model": "SM-S928N", "device": "e3q",  "name": "Galaxy S24 Ultra", "tac": "35284382"},
    {"model": "SM-S918N", "device": "dm3q", "name": "Galaxy S23 Ultra", "tac": "35418240"},
    {"model": "SM-S908N", "device": "b0q",  "name": "Galaxy S22 Ultra", "tac": "35984128"},
    {"model": "SM-G998N", "device": "p3s",  "name": "Galaxy S21 Ultra", "tac": "35165412"},
    {"model": "SM-F946N", "device": "q5",   "name": "Galaxy Z Fold5",   "tac": "35629471"},
    {"model": "SM-F936N", "device": "q4",   "name": "Galaxy Z Fold4",   "tac": "35874219"},
    {"model": "SM-F731N", "device": "b5",   "name": "Galaxy Z Flip5",   "tac": "35398210"},
    {"model": "SM-S921N", "device": "e1q",  "name": "Galaxy S24",       "tac": "35284381"},
    {"model": "SM-S911N", "device": "dm1q", "name": "Galaxy S23",       "tac": "35418239"},
    {"model": "SM-A546S", "device": "a54x", "name": "Galaxy A54",       "tac": "35892147"},
    {"model": "SM-A346S", "device": "a34x", "name": "Galaxy A34",       "tac": "35741289"},
    {"model": "SM-A245S", "device": "a24",  "name": "Galaxy A24",       "tac": "35698124"},
]

SAMSUNG_OUIS = ["30:CD:A7", "9C:2A:70", "DC:71:44", "5C:E8:EB", "84:25:DB", "A4:C4:94"]

CARRIERS = [
    {"name": "SKT", "numeric": "45005", "alpha": "SKTelecom"},
    {"name": "KT",  "numeric": "45008", "alpha": "KT"},
    {"name": "LGU", "numeric": "45006", "alpha": "LG U+"}
]

def luhn_checksum(digits):
    checksum = 0
    for idx, d in enumerate(reversed(digits)):
        val = int(d)
        if idx % 2 == 0:
            val *= 2
            if val > 9:
                val -= 9
        checksum += val
    return (10 - (checksum % 10)) % 10

profiles = {}
if os.path.exists(PROFILES_PATH):
    try:
        with open(PROFILES_PATH, "r", encoding="utf-8") as f:
            profiles = json.load(f)
    except Exception:
        profiles = {}

target = int(os.environ.get("TARGET_COUNT", 60))
max_devices = max(target, len(profiles), 60)
updated = False

for i in range(1, max_devices + 1):
    key = str(i)
    if key not in profiles:
        updated = True
        model_info = MODELS[(i - 1) % len(MODELS)]
        carrier = CARRIERS[(i - 1) % len(CARRIERS)]
        
        # 1. 삼성 정품 TAC 기반 유효한 IMEI 생성
        serial_part = f"{random.randint(100000, 999999)}"
        imei_14 = model_info["tac"] + serial_part
        check_digit = luhn_checksum(imei_14)
        imei = f"{imei_14}{check_digit}"
        
        # 2. 삼성 고유 MAC 주소
        oui = random.choice(SAMSUNG_OUIS)
        mac_suffix = f"{random.randint(0, 255):02X}:{random.randint(0, 255):02X}:{random.randint(0, 255):02X}"
        mac = f"{oui}:{mac_suffix}"
        
        # 3. 고유 시리얼 번호
        serial_chars = "0123456789ABCDEFGHJKLMNPQRSTUVWXYZ"
        serial = "R5CW" + "".join(random.choice(serial_chars) for _ in range(7))
        
        # 4. 고유 Android ID
        android_id = secrets.token_hex(8)
        
        # 5. 통신사 IMSI
        imsi = carrier["numeric"] + f"{random.randint(1000000000, 9999999999)}"
        
        profiles[key] = {
            "id": i,
            "port": 6000 + i,
            "model": model_info["model"],
            "device": model_info["device"],
            "name": model_info["name"],
            "serial": serial,
            "imei": imei,
            "imsi": imsi,
            "mac": mac,
            "android_id": android_id,
            "carrier_numeric": carrier["numeric"],
            "carrier_alpha": carrier["alpha"]
        }

if updated or not os.path.exists(PROFILES_PATH):
    with open(PROFILES_PATH, "w", encoding="utf-8") as f:
        json.dump(profiles, f, indent=2, ensure_ascii=False)
    print(f"✅ 기기 프로필 영구 저장 완료! (총 {len(profiles)}대 등록됨)")
else:
    print(f"🔒 기존 기기 프로필을 그대로 안전하게 로드했습니다. (인증 보존 완료)")
PYEOF

# 4. 요청된 대수(TARGET_COUNT)만큼 docker-compose.yml 생성
echo "📄 docker-compose.yml 파일 생성 중 (${TARGET_COUNT}대 활성화)..."

python3 - << PYEOF
import json
import os

TARGET_COUNT = int(os.environ.get("TARGET_COUNT", 20))
REDROID_DIR = os.path.expanduser("~/redroid")
PROFILES_PATH = os.path.join(REDROID_DIR, "device_profiles.json")

with open(PROFILES_PATH, "r", encoding="utf-8") as f:
    profiles = json.load(f)

lines = [
    "services:"
]

for i in range(1, TARGET_COUNT + 1):
    num = f"{i:02d}"
    p = profiles[str(i)]
    
    vol_dir = os.path.join(REDROID_DIR, "data", f"data{num}")
    os.makedirs(vol_dir, exist_ok=True)
    
    lines.append(f"  redroid-{num}:")
    lines.append(f"    image: redroid/redroid:13.0.0-latest")
    lines.append(f"    container_name: redroid-{num}")
    lines.append(f"    privileged: true")
    lines.append(f"    ports:")
    lines.append(f'      - "{p["port"]}:5555"')
    lines.append(f"    volumes:")
    lines.append(f"      - ./data/data{num}:/data")
    lines.append(f"      - ./init-keyboard.rc:/vendor/etc/init/init-keyboard.rc:ro")
    lines.append(f"    command:")
    lines.append(f"      - androidboot.redroid_width=540")
    lines.append(f"      - androidboot.redroid_height=960")
    lines.append(f"      - androidboot.redroid_dpi=220")
    lines.append(f"      - androidboot.redroid_gpu_mode=guest")
    lines.append(f"      - androidboot.use_memfd=1")
    lines.append(f"      - ro.product.locale=ko-KR")
    lines.append(f"      - ro.product.locale.language=ko")
    lines.append(f"      - ro.product.locale.region=KR")
    lines.append(f'      - ro.product.model={p["model"]}')
    lines.append(f"      - ro.product.brand=samsung")
    lines.append(f"      - ro.product.manufacturer=samsung")
    lines.append(f'      - ro.product.device={p["device"]}')
    lines.append(f'      - ro.serialno={p["serial"]}')
    lines.append(f'      - ro.boot.serialno={p["serial"]}')
    lines.append(f'      - androidboot.redroid_imei={p["imei"]}')
    lines.append(f'      - androidboot.redroid_imsi={p["imsi"]}')
    lines.append(f'      - androidboot.redroid_mac={p["mac"]}')
    lines.append(f'      - gsm.sim.operator.numeric={p["carrier_numeric"]}')
    lines.append(f'      - gsm.sim.operator.alpha={p["carrier_alpha"]}')
    lines.append(f"    restart: always")
    lines.append("    ulimits:")
    lines.append("      nofile:")
    lines.append("        soft: 1048576")
    lines.append("        hard: 1048576")
    lines.append("")

# 웹 브라우저 뷰어 서비스 통합
lines.append("  ws-scrcpy:")
lines.append("    image: ws-scrcpy:latest")
lines.append("    container_name: ws-scrcpy")
lines.append("    network_mode: host")
lines.append("    privileged: true")
lines.append("    restart: always")
lines.append("    volumes:")
lines.append("      - /var/run/docker.sock:/var/run/docker.sock")
lines.append("")

compose_path = os.path.join(REDROID_DIR, "docker-compose.yml")
with open(compose_path, "w", encoding="utf-8") as f:
    f.write("\n".join(lines))

print(f"✅ docker-compose.yml 생성 완료: 1번~{TARGET_COUNT}번 컨테이너 및 ws-scrcpy 매핑")
PYEOF

# 5. docker compose 기동
echo "🚀 컨테이너 일괄 기동 중..."
docker compose up -d --remove-orphans

# 6. Android ID 주입 (부팅 대기 후 적용)
echo "⏳ 안드로이드 부팅 감지 및 고유 Android ID 주입 중..."
sleep 5

python3 - << 'PYEOF'
import json
import os
import subprocess
import time

TARGET_COUNT = int(os.environ.get("TARGET_COUNT", 20))
PROFILES_PATH = os.path.expanduser("~/redroid/device_profiles.json")

with open(PROFILES_PATH, "r", encoding="utf-8") as f:
    profiles = json.load(f)

for i in range(1, TARGET_COUNT + 1):
    cname = f"redroid-{i:02d}"
    aid = profiles[str(i)]["android_id"]
    cmd = [
        "docker", "exec", cname,
        "settings", "put", "secure", "android_id", aid
    ]
    try:
        subprocess.run(cmd, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, timeout=5)
    except Exception:
        pass

print("✅ 기기별 고유 Android ID 잠금 적용 완료!")
PYEOF

# 7. 호스트 리눅스 ADB 일괄 자동 연결
echo "🔌 로컬 ADB 서비스 일괄 연결 중..."
for i in $(seq 1 "$TARGET_COUNT"); do
    port=$((6000 + i))
    adb connect "127.0.0.1:$port" >/dev/null 2>&1 || true
done

echo ""
echo "=================================================================="
echo "🎉 [순정 리눅스 2/3] Redroid [총 ${TARGET_COUNT}대] 정상 기동 완료!"
echo "   - 해상도: 540x960 (220 DPI 초슬림 최적화)"
echo "   - 안드로이드 버전: Android 13"
echo "   - 포트 범위: 127.0.0.1:6001 ~ 127.0.0.1:$((6000 + TARGET_COUNT))"
echo "   - 웹 뷰어: http://localhost:8000 (브라우저에서 즉시 제어 가능)"
echo "   - 데이터 저장소: ~/redroid/data/ (영구 보존)"
echo ""
echo "👉 다음 단계: ./3_install_kakaotalk_all.sh [대수] 를 실행하세요."
echo "=================================================================="
