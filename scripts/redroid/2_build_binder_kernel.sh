#!/usr/bin/env bash
# ==============================================================================
# [STEP 2] Redroid 구동 필수 Binder/Ashmem 커널 멀티스레드 고속 빌드 및 배포
# ==============================================================================
set -euo pipefail

echo "=================================================================="
echo "🚀 [2/4] Redroid 커널(Binder/Ashmem) 빌드를 시작합니다."
echo "   (24스레드 CPU 활용으로 약 2~3분 소요됩니다)"
echo "=================================================================="

# 1. 빌드 필수 패키지 설치
echo "📦 커널 빌드 도구 패키지 설치 중..."
sudo apt-get update -y
sudo apt-get install -y build-essential flex bison libssl-dev libelf-dev bc dwarves git

# 2. 공식 WSL2 커널 소스 다운로드 (홈 디렉터리에 다운로드)
KERNEL_DIR="$HOME/WSL2-Linux-Kernel"
if [ ! -d "$KERNEL_DIR" ]; then
    echo "📥 공식 Microsoft WSL2 커널 소스 다운로드 중..."
    cd "$HOME"
    git clone https://github.com/microsoft/WSL2-Linux-Kernel.git --depth=1
else
    echo "💡 기존 커널 소스 디렉터리가 발견되었습니다: $KERNEL_DIR"
fi

cd "$KERNEL_DIR"

# 3. 기본 설정 복사 및 Redroid Binder/Ashmem 옵션 활성화
echo "⚙️ Binder & Ashmem 커널 옵션 적용 중..."
cp Microsoft/config-wsl .config
cat <<EOF >> .config
CONFIG_ASHMEM=y
CONFIG_ANDROID=y
CONFIG_ANDROID_BINDER_IPC=y
CONFIG_ANDROID_BINDERFS=y
CONFIG_ANDROID_BINDER_DEVICES="binder,hwbinder,vndbinder"
CONFIG_DMABUF_HEAPS=y
CONFIG_DMABUF_HEAPS_SYSTEM=y
EOF

# 4. 멀티스레드 고속 빌드
NPROC=$(nproc)
echo "🔨 커널 컴파일 진행 중... (사용 스레드 수: ${NPROC})"
make -j"${NPROC}" KCONFIG_CONFIG=.config
sudo make modules_install

# 5. 빌드 완료된 커널을 Windows C:\WSL 폴더로 자동 복사
echo "📂 빌드된 커널 이미지를 Windows C:\\WSL 로 복사 중..."
sudo mkdir -p /mnt/c/WSL
sudo cp arch/x86_64/boot/bzImage /mnt/c/WSL/bzImage-redroid
sudo chmod 777 /mnt/c/WSL/bzImage-redroid

# 6. 부팅 시 도커 및 Redroid 필수 네트워크 모듈 자동 로드 등록
echo "🌐 도커 네트워크 모듈 자동 로드 등록 중..."
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

# 7. binderfs 영구 자동 마운트 systemd 서비스 등록
echo "🔗 /dev/binderfs 자동 마운트 systemd 서비스 등록 중..."
sudo bash -c 'cat <<EOF > /etc/systemd/system/binderfs.service
[Unit]
Description=Mount BinderFS for Redroid
Before=docker.service

[Service]
Type=oneshot
RemainAfterExit=yes
ExecStartPre=/sbin/modprobe -a ip_tables iptable_filter iptable_nat iptable_mangle iptable_raw ip6_tables ip6table_filter ip6table_nat xt_nat xt_tcpudp xt_addrtype xt_conntrack xt_MASQUERADE br_netfilter
ExecStartPre=/bin/mkdir -p /dev/binderfs
ExecStart=/bin/mount -t binder binder /dev/binderfs
ExecStartPost=/bin/chmod 777 /dev/binderfs /dev/binderfs/binder /dev/binderfs/binder-control /dev/binderfs/hwbinder /dev/binderfs/vndbinder

[Install]
WantedBy=multi-user.target
EOF'

sudo systemctl daemon-reload
sudo systemctl enable binderfs.service

echo "=================================================================="
echo "✅ Redroid 커널 빌드 및 배포 완료!"
echo "   - 생성된 커널: C:\\WSL\\bzImage-redroid"
echo ""
echo "👉 중요: 이제 Windows에서 [scripts/win/1_setup_wslconfig.bat] 파일을"
echo "   더블클릭하여 새 커널을 적용하고 WSL을 재시작해 주세요!"
echo "   (재시작 후 WSL로 다시 들어와 3_build_ws_scrcpy.sh 실행)"
echo "=================================================================="
