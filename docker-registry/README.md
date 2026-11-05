# Private Docker Registry (`docker-registry`)

빌드된 컨테이너 이미지를 저장하고 배포하기 위한 사설 도커 레지스트리입니다.

---

## 📁 디렉터리 구성

- `docker-compose.yml`: 레지스트리 단독 실행 설정 (`registry:2`)
- `.env`: 포트(5000) 및 이미지 설정
- `data/`: 저장된 도커 이미지 영구 볼륨 (자동 생성, `.gitignore` 등록됨)

---

## 🚀 실행 가이드

```bash
# 레지스트리 시작
docker compose up -d

# 로그 확인
docker compose logs -f

# 중지
docker compose down
```

---

## ⚙️ 포트 및 접속 안내

- **Registry API / Push / Pull 포트**: `http://<호스트IP>:5000`

---

## 💡 사설 레지스트리 이미지 푸시 & 풀

```bash
# 1. 이미지 태깅
docker tag kakaotalk-server:latest localhost:5000/kakaotalk-server:latest

# 2. 이미지 푸시
docker push localhost:5000/kakaotalk-server:latest

# 3. 이미지 풀
docker pull localhost:5000/kakaotalk-server:latest
```

---

## 🔍 저장된 이미지 및 태그 조회 (API / curl)

별도 UI 없이 `curl`로 간단히 조회할 수 있습니다:

```bash
# 저장된 전체 리포지토리 목록 조회
curl http://localhost:5000/v2/_catalog

# 특정 이미지의 태그 목록 조회 (예: kakaotalk-server)
curl http://localhost:5000/v2/kakaotalk-server/tags/list
```

> [!NOTE]
> 원격 서버에서 HTTP(비보안) 레지스트리로 접근할 경우, 클라이언트 머신의 `/etc/docker/daemon.json`에 `{"insecure-registries": ["<레지스트리IP>:5000"]}` 설정이 필요합니다.
