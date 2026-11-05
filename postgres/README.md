# PostgreSQL Database (`postgres`)

카카오톡 백엔드 서버 및 제반 시스템을 위한 고성능 PostgreSQL 데이터베이스 컨테이너입니다.

---

## 📁 디렉터리 구성

- `docker-compose.yml`: PostgreSQL 고성능 단독 기동 설정 (`network_mode: host`)
- `.env`: 관리자 계정, 암호 및 성능 튜닝 파라미터 (64GB RAM 최적화)
- `data/`: 실제 DB 영구 데이터 볼륨 (자동 생성, `.gitignore` 등록됨)

---

## 🚀 실행 가이드

```bash
# 컨테이너 시작 (백그라운드)
docker compose up -d

# 로그 확인
docker compose logs -f

# 헬스체크 및 상태 확인
docker compose ps

# 컨테이너 중지
docker compose down
```

---

## 🔑 접속 정보 (관리자 계정)

- **호스트 / 포트**: `localhost:5432` (또는 `127.0.0.1:5432`)
- **최고 관리자 ID**: `admin`
- **최고 관리자 PW**: `zeus890!`
- **초기 접속 기본 DB**: `postgres` (시스템 관리용 기본 DB)

> DBeaver나 DataGrip 등에서 위 관리자 계정으로 접속하신 후, 원하시는 이름의 비즈니스 데이터베이스(예: `CREATE DATABASE kakaotalk;`)를 직접 생성하시면 됩니다.

---

## ⚡ 적용된 인기 성능 최적화 설정 (64GB 머신 기준)

서버의 넉넉한 64GB RAM과 Redroid 인스턴스(20~40대)가 함께 구동되는 환경을 고려하여 **가장 이상적인 고성능 밸런스**를 맞췄습니다:

| 파라미터 | 기본값 | 64GB 최적화값 | 효과 |
| :--- | :--- | :--- | :--- |
| **`network_mode`** | bridge | **`host`** | Docker NAT 오버헤드 제거, 네트워크 지연 최소화 |
| **`shm_size`** | 64MB | **`2GB`** | 병렬 쿼리 및 대량 조인 시 메모리 크래시 방지 |
| **`shared_buffers`** | 128MB | **`4GB`** | DB 전용 데이터 캐시 메모리 대폭 확장 |
| **`effective_cache_size`**| 4GB | **`12GB`** | OS 캐시를 고려한 효율적인 쿼리 플래닝 유도 |
| **`work_mem`** | 4MB | **`32MB`** | 복잡한 정렬(ORDER BY) 및 해시 조인 연산 고속화 |
| **`maintenance_work_mem`**| 64MB | **`512MB`** | 인덱스 생성 및 VACUUM 속도 대폭 개선 |
| **`random_page_cost`** | 4.0 | **`1.1`** | **(체감 1위)** SSD/NVMe 환경에서 인덱스를 적극 활용 |
| **`effective_io_concurrency`**| 1 | **`200`** | 비동기 SSD 동시 읽기 처리량 극대화 |
| **`checkpoint_completion_target`**| 0.5 | **`0.9`** | 디스크 쓰기 부하를 시간 분산하여 I/O 스파이크 방지 |
