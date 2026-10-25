# 🐧 순정 리눅스(Ubuntu Native) Redroid 구축 완벽 가이드

순정 Ubuntu 22.04 LTS / 24.04 LTS PC(또는 서버)에서 WSL 없이 네이티브로 Redroid 10~60대를 최적화 구동하는 가이드입니다.

---

## 🚀 빠른 시작 (3단계 실행)

순정 리눅스 터미널을 열고, 스크립트 폴더로 이동한 뒤 순서대로 실행하시면 됩니다:

```bash
cd /경로/to/kakaotalk-data/scripts/linux

# [1단계] 시스템 최적화, 커널 Binder 모듈 활성화, 도커 최신 엔진 설치 (최초 1회)
bash 0_setup_native_system.sh

# [2단계] 웹 브라우저 60 FPS 제어 뷰어(ws-scrcpy) 소스 패치 및 빌드 (최초 1회)
bash 1_build_ws_scrcpy.sh

# [3단계] Redroid 인스턴스 일괄 배포 (원하는 대수 입력, 기본 20대)
bash 2_deploy_redroid.sh 20

# [4단계] 카카오톡 분할 패키지 4종 일괄 설치
bash 3_install_kakaotalk_all.sh 1 20
```

---

## 🛠️ 제공 스크립트 목록

| 파일명 | 설명 | 비고 |
| :--- | :--- | :--- |
| `0_setup_native_system.sh` | Binder 모듈, sysctl 최적화, ulimits 104만개 해제, Docker 설치 | 최초 1회 |
| `1_build_ws_scrcpy.sh` | 웹 뷰어 고화질/60fps/한글 패치 및 도커 이미지 빌드 | 최초 1회 |
| `2_deploy_redroid.sh` | 540x960 220DPI 안드로이드 13 인스턴스 일괄 배포 & 스케일링 | 수시 사용 |
| `3_install_kakaotalk_all.sh`| 전체 기기 카카오톡 일괄 설치 및 자동 기동 | 앱 배포 시 |
| `redroid_ctl.sh` | 기기 상태 확인, 시작, 중지, 대수 변경, ADB 쉘 접속 툴 | 일상 관리용 |

---

## 📊 일상 관리 명령어 (`redroid_ctl.sh`)

```bash
# 전체 상태 및 ADB 연결 기기 확인
./redroid_ctl.sh status

# 대수를 30대로 확장 기동
./redroid_ctl.sh scale 30

# 컨테이너 일괄 중지 / 시작 / 재시작
./redroid_ctl.sh stop
./redroid_ctl.sh start
./redroid_ctl.sh restart

# ADB 전체 재연결
./redroid_ctl.sh adb

# 특정 기기(예: 1번 기기) 내부 쉘 접속
./redroid_ctl.sh shell 1
```

---

## 🌟 순정 리눅스의 장점 (WSL 대비)

1. **커널 컴파일 불필요**: 복잡한 WSL 커널 빌드(`bzImage`) 없이 `apt` 명령으로 Binder 모듈이 즉시 활성화됩니다.
2. **포트프록시 문제 완전 제거**: WSL-Windows 간 네트워크 릴레이 끊김, `netsh` 설정 없이 로컬 포트(`127.0.0.1:6001~6020`)로 바로 직결됩니다.
3. **자원 100% 네이티브 활용**: `.wslconfig`로 CPU/RAM을 쪼갤 필요 없이 PC 전체 사양을 그대로 쓰며, 오버헤드가 없어 **약 15~20% 더 빠른 속도와 프레임**을 보여줍니다.
4. **안정적인 장기 구동**: 윈도우 절전모드나 세션 종료로 인한 중단 없이 24시간 무중단 가동이 가능합니다.
