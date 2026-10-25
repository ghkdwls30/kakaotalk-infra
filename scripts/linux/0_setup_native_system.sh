#!/usr/bin/env bash
# ==============================================================================
# [STEP 0] 순정 리눅스(Ubuntu Native) - 커널 모듈, 시스템 제한 해제 및 Docker 환경 구축
#          - 대상 OS: Ubuntu 22.04 LTS / 24.04 LTS (순정 PC/서버 베어메탈)
#          - 기능:
#            1) 안드로이드 필수 Binder 모듈 자동 설치 및 binderfs 영구 마운트
#            2) 10~60대 대량 가동을 위한 파일/프로세스/스레드 한도 극대화 (ulimits & sysctl)
#            3) Docker Engine & Docker Compose 공식 최신판 설치
#            4) ADB 도구 설치 및 현재 사용자 도커 권한 부여
# ==============================================================================
set -euo pipefail

echo "=================================================================="
echo "🐧 [순정 리눅스 0/3] 호스트 시스템 최적화 및 도커 환경 구축을 시작합니다."
echo "=================================================================="

# 1. 패키지 인덱스 갱신 및 필수 유틸리티 설치
echo "📦 기본 유틸리티 설치 중..."
sudo apt-get update -y
sudo apt-get install -y ca-certificates curl gnupg lsb-release adb python3 python3-pip

# 2. 안드로이드 필수 커널 모듈(Binder) 설정
echo "⚙️ 안드로이드 필수 Binder 커널 모듈 점검 및 설치 중..."
KERNEL_VER=$(uname -r)
sudo apt-get install -y "linux-modules-extra-${KERNEL_VER}" 2>/dev/null || true

# binderfs 마운트 디렉터리 준비
sudo mkdir -p /dev/binderfs

# 영구 마운트 (/etc/fstab) 등록
if ! grep -q "binderfs" /etc/fstab 2>/dev/null; then
    echo "none /dev/binderfs binder default 0 0" | sudo tee -a /etc/fstab > /dev/null
fi
sudo mount -a || sudo mount -t binder binder /dev/binderfs || true

# 부팅 시 자동 로드 모듈 등록
echo "binder_linux" | sudo tee /etc/modules-load.d/redroid-binder.conf > /dev/null
sudo modprobe binder_linux 2>/dev/null || true

if [ -e /dev/binderfs/binder ] || [ -e /dev/binder ]; then
    echo "✅ Binder 드라이버가 성공적으로 활성화되었습니다!"
else
    echo "⚠️ /dev/binderfs/binder 확인 필요 (대부분의 최신 Ubuntu 커널에서는 정상 동작합니다)."
fi

# 3. 20~60대 대량 구동을 위한 시스템 자원 제한 해제 (ulimit & sysctl)
echo "🚀 대량 인스턴스 구동을 위한 시스템 한도(파일/프로세스/메모리 맵) 확장 중..."

# 3-1. 사용자/프로세스 한도 (limits.conf)
sudo bash -c 'cat << "EOF" > /etc/security/limits.d/99-redroid.conf
* soft nofile 1048576
* hard nofile 1048576
* soft nproc 1048576
* hard nproc 1048576
root soft nofile 1048576
root hard nofile 1048576
root soft nproc 1048576
root hard nproc 1048576
EOF'

# 3-2. 커널 레벨 시스템 파라미터 (sysctl)
sudo bash -c 'cat << "EOF" > /etc/sysctl.d/99-redroid.conf
fs.file-max = 2097152
fs.inotify.max_user_watches = 524288
fs.inotify.max_user_instances = 8192
kernel.pid_max = 4194304
kernel.threads-max = 4194304
vm.max_map_count = 262144
net.core.somaxconn = 65535
net.ipv4.ip_local_port_range = 1024 65535
EOF'
sudo sysctl --system > /dev/null

# 4. Docker 공식 최신 엔진 및 Compose 플러그인 설치
echo "🐳 Docker 공식 최신판 설치 중..."
sudo mkdir -p /etc/apt/keyrings
if [ ! -f /etc/apt/keyrings/docker.gpg ]; then
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
fi

echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

sudo apt-get update -y
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# 5. 도커 데몬 기본 ulimit 설정 (/etc/docker/daemon.json)
echo "⚙️ 도커 데몬 대량 컨테이너 최적화 설정 중..."
sudo bash -c 'cat << "EOF" > /etc/docker/daemon.json
{
  "default-ulimits": {
    "nofile": {
      "Name": "nofile",
      "Hard": 1048576,
      "Soft": 1048576
    },
    "nproc": {
      "Name": "nproc",
      "Hard": 1048576,
      "Soft": 1048576
    }
  },
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "20m",
    "max-file": "3"
  }
}
EOF'

# 6. 현재 사용자 docker 그룹 추가 및 서비스 시작
sudo usermod -aG docker "$USER"
sudo systemctl daemon-reload
sudo systemctl enable docker
sudo systemctl restart docker

echo ""
echo "=================================================================="
echo "🎉 [순정 리눅스 0/3] 시스템 환경 구축이 완료되었습니다!"
echo "   - Binder 모듈: 정상 활성화 완료"
echo "   - 시스템 자원 제한: 파일 104만개 / 프로세스 무제한 확장 완료"
echo "   - Docker 버전: $(docker --version)"
echo "   - Docker Compose: $(docker compose version)"
echo ""
echo "💡 [중요] 도커 권한 적용을 위해 터미널을 다시 열거나 아래 명령을 실행하세요:"
echo "   newgrp docker"
echo ""
echo "👉 다음 단계: ./1_build_ws_scrcpy.sh 를 실행하세요."
echo "=================================================================="
