# PostgreSQL Database (`postgres`)

카카오톡 백엔드 서버 및 제반 시스템을 위한 PostgreSQL 데이터베이스 컨테이너입니다.

---

## 📁 디렉터리 구성

- `docker-compose.yml`: PostgreSQL 단독 기동 설정
- `.env`: 접속 계정, 비밀번호, 포트 및 데이터베이스명 설정
- `data/`: 실제 DB 영구 데이터 볼륨 (자동 생성, `.gitignore` 등록됨)

---

## 🚀 실행 가이드

```bash
# 컨테이너 시작 (백그라운드)
docker compose up -d

# 로그 확인
docker compose logs -f

# 컨테이너 상태 및 헬스체크 확인
docker compose ps

# 컨테이너 중지
docker compose down
```

---

## ⚙️ 기본 설정 정보

- **호스트 포트**: `5432` (기본값)
- **데이터베이스명**: `kakaotalk`
- **사용자명**: `postgres`
- **비밀번호**: `postgres1234` (운영 환경에서는 `.env`에서 변경 권장)
- **JDBC URL**: `jdbc:postgresql://localhost:5432/kakaotalk`
