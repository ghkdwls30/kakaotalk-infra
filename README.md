# KakaoTalk Automation Infrastructure (`kakaotalk-infra`)

카카오톡 자동화 시스템의 배포, 컨테이너 오케스트레이션 및 인프라 운영 레포지토리입니다.

---

## 📁 디렉터리 구조

```text
kakaotalk-infra/
├── docker-compose.yml          # 전체 서비스 통합 실행 compose (Server, Web, Agent)
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
└── scripts/                    # Redroid 단말 배포 및 ADB 관리 스크립트
    ├── apks/                   # 카카오톡 및 필수 APK 파일
    └── linux/                  # 커널 바인더, ws-scrcpy, redroid 런타임 제어 스크립트
```

---

## 🚀 실행 가이드

### 1. 전체 통합 실행 (1대의 서버에서 모두 띄울 때)

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
./stop_all.sh
```

---

### 2. 개별 서비스 실행 (서비스별 독립 배포 또는 분산 서버 운영 시)

각 서비스 디렉터리로 이동하여 독립적으로 기동/중지할 수 있습니다.

#### ① 백엔드 서버 (`kakaotalk-server`)
```bash
cd kakaotalk-server
docker compose up -d
docker compose logs -f
```

#### ② 웹 대시보드 (`kakaotalk-web`)
```bash
cd kakaotalk-web
docker compose up -d
docker compose logs -f
```

#### ③ 단말 제어 에이전트 (`kakaotalk-agent`)
```bash
cd kakaotalk-agent
docker compose up -d
docker compose logs -f
```

---

## ⚙️ 네트워크 및 포트 안내

- **Server**: `8080` (REST API & `/ws/agent` WebSocket)
- **Web**: `80` (HTTP), `443` (HTTPS SSL)
- **Agent**: `host` 모드 동작 (호스트의 Redroid 포트 `6001~6040` 직결)
- **ws-scrcpy**: `8000` (Redroid 실시간 웹 스트리밍 뷰어)
