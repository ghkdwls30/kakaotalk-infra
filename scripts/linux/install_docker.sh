#!/usr/bin/env bash
# ==============================================================================
# [DOCKER] Ubuntu 순정 Docker Engine & Docker Compose 최신판 설치 스크립트
#          - 대상 OS: Ubuntu 20.04 / 22.04 / 24.04 LTS
#          - 기능:
#            1) 필수 기본 패키지(curl, ca-certificates, gnupg) 설치
#            2) Docker 공식 최신 APT 저장소 및 GPG 키 등록
#            3) Docker Engine, CLI, containerd, Docker Compose Plugin 설치
#            4) 컨테이너 로그 무한 증식 방지(Log Rotation) 데몬 설정
#            5) 현재 사용자에게 docker 그룹 권한 자동 부여 및 서비스 활성화
# ==============================================================================
set -euo pipefail

echo "=================================================================="
echo "🐳 [Docker Setup] 순수 Docker Engine & Docker Compose 설치를 시작합니다."
echo "=================================================================="

# 1. 패키지 인덱스 갱신 및 기본 유틸리티 설치
echo "📦 1/5 기본 유틸리티 및 인증서 패키지 확인 중..."
sudo apt-get update -y
sudo apt-get install -y ca-certificates curl gnupg lsb-release

# 2. Docker 공식 GPG 키 등록
echo "🔑 2/5 Docker 공식 GPG 키 등록 중..."
sudo mkdir -p /etc/apt/keyrings
if [ ! -f /etc/apt/keyrings/docker.gpg ]; then
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
    sudo chmod a+r /etc/apt/keyrings/docker.gpg
fi

# 3. Docker APT 공식 레포지토리 추가
echo "🌐 3/5 Docker APT 레포지토리 등록 중..."
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

sudo apt-get update -y

# 4. Docker Engine & Docker Compose 플러그인 설치
echo "📦 4/5 Docker 최신 패키지 설치 중..."
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# 5. 도커 데몬 로그 로테이션 기본 설정 (디스크 풀 방지)
echo "⚙️ 5/5 도커 데몬 기본 로깅(Log Rotation) 설정 중..."
if [ ! -f /etc/docker/daemon.json ]; then
    sudo mkdir -p /etc/docker
    sudo bash -c 'cat << "EOF" > /etc/docker/daemon.json
{
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "20m",
    "max-file": "3"
  }
}
EOF'
fi

# 6. 현재 사용자 docker 그룹 추가 및 서비스 시작
sudo usermod -aG docker "$USER"
sudo systemctl daemon-reload
sudo systemctl enable docker
sudo systemctl restart docker

echo ""
echo "=================================================================="
echo "🎉 Docker 환경 설치가 완료되었습니다!"
echo "   - Docker 버전: $(docker --version)"
echo "   - Docker Compose 버전: $(docker compose version)"
echo ""
echo "💡 [중요] 'sudo' 없이 docker 명령어를 사용하려면 현재 세션에서 아래 명령을 실행하거나"
echo "   터미널을 재접속(또는 재로그인)하세요:"
echo "   newgrp docker"
echo "=================================================================="
