# KakaoTalk Automation Infrastructure (`kakaotalk-infra`)

카카오톡 자동화 시스템의 배포, 컨테이너 오케스트레이션 및 인프라 운영 레포지토리입니다.

---

## 📁 디렉터리 구조

```text
kakaotalk-infra/
├── docker-compose.yml          # 앱 서비스 통합 실행 compose (Server, Web, Agent)
├── start_all.sh                # 전체 서비스 통합 기동 스크립트 (옵션: --pull)
├── stop_all.sh                 # 전체 서비스 중지 스크립트
├── restart_all.sh              # 전체 서비스 재기동 스크립트
│
├── kakaotalk-server/           # [백엔드] Spring Boot (포트 8080)
│   ├── docker-compose.yml      # 단독 실행 compose
│   ├── .env                    # 서버 환경변수 (포트, JVM 옵션, 프로파일 등)
│   ├── data/                   # H2/MySQL 영구 데이터베이스 볼륨
│   ├── uploads/                # 첨부파일/이미지 영구 볼륨
│   └── logs/                   # 애플리케이션 로그
│
├── kakaotalk-web/              # [프론트엔드] React / Nginx (포트 80, 443 SSL)
│   ├── docker-compose.yml      # 단독 실행 compose
│   ├── .env                    # 웹 환경변수
│   └── ssl/                    # HTTPS SSL 인증서 (fullchain.pem, privkey.pem)
│
├── kakaotalk-agent/            # [에이전트] Python ADB 자동화 워커
│   ├── docker-compose.yml      # 단독 실행 compose
│   ├── .env                    # WS 서버 주소, Redroid 타깃 IP/대수 설정
│   └── logs/                   # 에이전트 실행 및 실패 저널 로그
│
├── postgres/                   # [데이터베이스] PostgreSQL 16 (포트 5432)
│   ├── docker-compose.yml      # DB 실행 compose
│   ├── .env                    # DB 접속 계정, 암호, 포트 설정
│   └── data/                   # PostgreSQL 영구 데이터 볼륨
│
├── docker-registry/            # [사설 레지스트리] Docker Registry (포트 5000)
│   ├── docker-compose.yml      # Registry 단독 실행 compose
│   ├── .env                    # 레지스트리 포트 설정
│   └── data/                   # 레지스트리 이미지 영구 저장 볼륨
│
├── jenkins/                    # [CI/CD] Jenkins LTS (포트 9090, 50000)
│   ├── docker-compose.yml      # Jenkins 컨테이너 compose (Docker 소켓 연동)
│   ├── .env                    # 포트 및 JVM 옵션, 권한 설정
│   └── jenkins_home/           # Jenkins 빌드 및 플러그인 영구 데이터
│
└── scripts/                    # Redroid 단말 배포 및 ADB 관리 스크립트
    ├── apks/                   # 카카오톡 및 필수 APK 파일
    └── linux/                  # 커널 바인더, ws-scrcpy, redroid 런타임 제어 스크립트
```

---

## 🚀 실행 가이드

### 1. 애플리케이션 통합 실행 (Server, Web, Agent)

```bash
# 전체 서비스 한 번에 기동
./start_all.sh
# 또는 최신 도커 이미지 pull 후 기동
./start_all.sh --pull

# 또는 도커 컴포즈 직접 실행
docker compose up -d

# 상태 확인
docker compose ps

# 전체 중지
docker compose down
```

---

### 2. 인프라 및 개별 컴포넌트 실행

각 디렉터리로 이동하여 독립적으로 기동/중지할 수 있습니다.

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
# 브라우저 접속: http://localhost:9090
```

#### ④ 백엔드 서버 (`kakaotalk-server`)
```bash
cd kakaotalk-server
docker compose up -d
docker compose logs -f
```

#### ⑤ 웹 대시보드 (`kakaotalk-web`)
```bash
cd kakaotalk-web
docker compose up -d
docker compose logs -f
```

#### ⑥ 단말 제어 에이전트 (`kakaotalk-agent`)
```bash
cd kakaotalk-agent
docker compose up -d
docker compose logs -f
```

---

## ⚙️ 네트워크 및 포트 안내

- **PostgreSQL**: `5432` (PostgreSQL Database)
- **Docker Registry**: `5000` (Registry API / Push / Pull)
- **Jenkins**: `9090` (Web 대시보드) / `50000` (JNLP 빌드 에이전트)
- **Server**: `8080` (REST API & `/ws/agent` WebSocket)
- **Web**: `80` (HTTP), `443` (HTTPS SSL)
- **Agent**: `host` 모드 동작 (호스트의 Redroid 포트 `6001~6040` 직결)
- **ws-scrcpy**: `8000` (Redroid 실시간 웹 스트리밍 뷰어)
