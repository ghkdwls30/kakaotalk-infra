#!/usr/bin/env bash
# ==============================================================================
# [STEP 1] WSL2 Ubuntu - Docker Engine (Native) 설치 및 시스템 환경 구성
# ==============================================================================
set -euo pipefail

echo "=================================================================="
echo "🚀 [1/4] Docker Engine 및 WSL2 시스템 환경 구성을 시작합니다."
echo "=================================================================="

# 1. systemd 활성화 확인 및 /etc/wsl.conf 설정
if ! grep -q "systemd=true" /etc/wsl.conf 2>/dev/null; then
    echo "⚙️ /etc/wsl.conf에 systemd 설정을 추가합니다..."
    sudo bash -c 'cat <<EOF > /etc/wsl.conf
[boot]
systemd=true
[network]
generateResolvConf=true
EOF'
    echo "💡 systemd 설정이 완료되었습니다. (추후 wsl --shutdown 시 적용)"
fi

# 2. 필수 유틸리티 및 의존 패키지 설치
echo "📦 필수 패키지 설치 중..."
sudo apt-get update -y
sudo apt-get install -y ca-certificates curl gnupg lsb-release

# 3. Docker 공식 GPG 키 및 공식 레포지토리 등록
echo "🔑 Docker GPG 키 및 공식 레포지토리 등록 중..."
sudo mkdir -p /etc/apt/keyrings
if [ ! -f /etc/apt/keyrings/docker.gpg ]; then
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
fi

echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# 4. Docker Engine 및 Docker Compose 플러그인 설치
echo "🐳 Docker Engine & Compose 플러그인 설치 중..."
sudo apt-get update -y
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# 5. 현재 사용자 docker 그룹 추가
sudo usermod -aG docker "$USER"

# 6. WSL2 iptables 호환성 설정 (legacy 모드 지정)
echo "🌐 iptables 레거시 모드 지정 (WSL2 네트워크 필수 호환)..."
sudo update-alternatives --set iptables /usr/sbin/iptables-legacy || true
sudo update-alternatives --set ip6tables /usr/sbin/ip6tables-legacy || true

# 6-1. WSL2 도커 필수 네트워크 모듈 자동 로드 등록
sudo bash -c 'cat <<EOF > /etc/modules-load.d/docker.conf
bridge
br_netfilter
llc
stp
ip_tables
iptable_filter
iptable_nat
iptable_mangle
iptable_raw
ip6_tables
ip6table_filter
ip6table_nat
xt_nat
xt_tcpudp
xt_addrtype
xt_conntrack
xt_MASQUERADE
EOF'
sudo modprobe iptable_nat 2>/dev/null || true
sudo modprobe xt_addrtype 2>/dev/null || true
sudo modprobe br_netfilter 2>/dev/null || true

# 7. Docker 데몬 override 설정 (unix socket 안정화)
sudo mkdir -p /etc/systemd/system/docker.service.d
sudo bash -c 'cat <<EOF > /etc/systemd/system/docker.service.d/override.conf
[Service]
ExecStart=
ExecStart=/usr/bin/dockerd -H unix:///var/run/docker.sock --containerd=/run/containerd/containerd.sock
EOF'

sudo systemctl daemon-reload || true
sudo systemctl enable docker || true
sudo service docker start || true

echo "=================================================================="
echo "✅ Docker Engine 설치 및 환경 설정 완료!"
echo "   - Docker 버전: $(docker --version 2>/dev/null || echo '설치됨')"
echo "   - Compose 버전: $(docker compose version 2>/dev/null || echo '설치됨')"
echo "👉 다음 단계: ./2_build_binder_kernel.sh 를 실행하세요."
echo "=================================================================="
