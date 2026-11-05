# 🐧 리눅스(Ubuntu Native) 인프라 & Redroid 구축 가이드

순정 Ubuntu 22.04 LTS / 24.04 LTS 환경에서 Docker 환경 구축 및 Redroid 10~60대 대량 최적화 구동을 위한 스크립트 모음입니다.

---

## 🛠️ 제공 스크립트 목록

| 구분 | 파일명 | 설명 | 비고 |
| :--- | :--- | :--- | :--- |
| **순수 도커 설치** | `install_docker.sh` | Docker Engine & Docker Compose 공식 최신판 설치, log-rotation 및 docker 그룹 권한 설정 | 일반 서버용 (최초 1회) |
| **Redroid 올인원** | `0_setup_native_system.sh` | Binder 커널 모듈, binderfs 마운트, ulimit 104만개/sysctl 확장, Docker & ADB 올인원 설치 | Redroid 호스트용 (최초 1회) |
| **웹 뷰어** | `1_build_ws_scrcpy.sh` | 웹 브라우저 60fps 한글 지원 원격 제어 뷰어(ws-scrcpy) 소스 패치 및 이미지 빌드 | 최초 1회 |
| **인스턴스 배포** | `2_deploy_redroid.sh` | 안드로이드 13 가상 기기 일괄 배포 & 스케일링 | 수시 사용 |
| **카카오톡 배포** | `3_install_kakaotalk_all.sh`| 전체 기기 카카오톡 APK 일괄 설치 및 자동 기동 | 앱 배포 시 |
| **기기 제어기** | `redroid_ctl.sh` | 기기 상태 확인, 시작, 중지, 대수 변경, ADB 쉘 접속 툴 | 일상 관리용 |

---

## 🚀 빠른 시작 가이드

### 상황 A. DB, Jenkins, 백엔드 서버 등 순수 도커만 필요할 때
```bash
# 순수 Docker Engine 및 Compose 최신 버전만 설치
bash install_docker.sh
newgrp docker
```

---

### 상황 B. Redroid 안드로이드 가상화 호스트를 구축할 때
```bash
# [1단계] 시스템 최적화, 커널 Binder 모듈 활성화, 도커 최신 엔진 설치 (기존 올인원 스크립트)
bash 0_setup_native_system.sh

# [2단계] 웹 브라우저 60 FPS 제어 뷰어(ws-scrcpy) 소스 패치 및 빌드 (최초 1회)
bash 1_build_ws_scrcpy.sh

# [3단계] Redroid 인스턴스 일괄 배포 (원하는 대수 입력, 기본 20대)
bash 2_deploy_redroid.sh 20

# [4단계] 카카오톡 분할 패키지 4종 일괄 설치
bash 3_install_kakaotalk_all.sh 1 20
```

---

## 📊 Redroid 일상 관리 명령어 (`redroid_ctl.sh`)

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
