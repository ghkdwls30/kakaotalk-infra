# KakaoTalk Shared Infrastructure (`kakaotalk-infra`)

카카오톡 자동화 시스템의 공통 기반 인프라(DB, CI/CD, Registry) 및 호스트 최적화 환경 구축 레포지토리입니다.

---

## 📁 디렉터리 구조

```text
kakaotalk-infra/
├── docker-compose.yml          # 공통 인프라 통합 실행 compose (Postgres, Registry, Jenkins)
├── start_all.sh                # 전체 인프라 통합 기동 스크립트
├── stop_all.sh                 # 전체 인프라 중지 스크립트
├── restart_all.sh              # 전체 인프라 재기동 스크립트
│
├── postgres/                   # [데이터베이스] PostgreSQL 16 (호스트 모드, 64GB 튜닝)
│   ├── docker-compose.yml      # DB 단독 실행 compose
│   ├── .env                    # DB 관리자 계정(admin/zeus890!), 270대 트래픽 튜닝
│   └── data/                   # DB 영구 데이터 볼륨 (자동 생성, .gitignore 등록)
│
├── docker-registry/            # [사설 레지스트리] Docker Registry 2 (포트 5000)
│   ├── docker-compose.yml      # 레지스트리 단독 실행 compose
│   ├── .env                    # 레지스트리 포트 설정
│   └── data/                   # 이미지 영구 저장 볼륨
│
├── jenkins/                    # [CI/CD] Jenkins LTS (포트 9090, 50000)
│   ├── docker-compose.yml      # Jenkins 컨테이너 compose (호스트 Docker 직결 마운트)
│   ├── .env                    # 포트 및 JVM 옵션, 권한 설정
│   └── jenkins_home/           # Jenkins 빌드 작업, 설정 영구 데이터
│
└── scripts/                    # 호스트 시스템 설치 및 Redroid 단말 관리 스크립트
    ├── apks/                   # 카카오톡 및 필수 APK 파일
    └── linux/
        ├── install_docker.sh   # [공통] 순수 Docker Engine & Compose 최신판 단독 설치
        ├── 0_setup_native_system.sh # [Redroid] Binder 모듈, 시스템 최적화 & Docker 올인원 설치
        ├── 1_build_ws_scrcpy.sh     # [Redroid] 웹 브라우저 60fps 뷰어 빌드
        ├── 2_deploy_redroid.sh      # [Redroid] 인스턴스 일괄 배포 & 스케일링
        ├── 3_install_kakaotalk_all.sh # [Redroid] 카톡 APK 일괄 설치
        └── redroid_ctl.sh      # [Redroid] 일상 운영 제어기
```

---

## 🚀 인프라 실행 가이드

### 1. 인프라 전체 통합 실행 (DB + Registry + Jenkins 한 번에)

```bash
# 전체 인프라 기동
./start_all.sh
# 또는 직접 실행
docker compose up -d

# 상태 확인
docker compose ps

# 전체 중지
./stop_all.sh
```

---

### 2. 개별 인프라 독립 실행

각 디렉터리로 이동하여 필요한 인프라만 독립적으로 기동/중지할 수 있습니다.

#### ① PostgreSQL 데이터베이스 (`postgres`)
```bash
cd postgres
docker compose up -d
docker compose logs -f
```

#### ② 사설 도커 레지스트리 (`docker-registry`)
```bash
cd docker-registry
docker compose up -d
docker compose logs -f
```

#### ③ Jenkins CI/CD (`jenkins`)
```bash
cd jenkins
docker compose up -d
docker compose logs -f
```

---

## ⚙️ 네트워크 및 포트 안내

- **PostgreSQL**: `localhost:5432` (`network_mode: host`, `admin` / `zeus890!`)
- **Docker Registry**: `5000` (Registry API / Push / Pull)
- **Jenkins**: `9090` (Web UI 대시보드) / `50000` (JNLP 빌드 에이전트)
