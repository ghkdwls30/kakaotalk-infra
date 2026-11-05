# Jenkins CI/CD (`jenkins`)

카카오톡 인프라 및 애플리케이션 자동 빌드/테스트/배포 파이프라인을 위한 Jenkins 컨테이너입니다.

---

## 📁 디렉터리 구성

- `docker-compose.yml`: Jenkins LTS(JDK 17) 실행 compose (호스트 Docker 바이너리 직결 마운트)
- `.env`: 웹 포트, 에이전트 포트, JVM 옵션 및 실행 권한 설정
- `jenkins_home/`: 플러그인, 빌드 작업(jobs), 설정 영구 볼륨 (자동 생성, `.gitignore` 등록됨)

---

## 🚀 실행 가이드

별도의 이미지 빌드 과정 없이, 순정 공식 이미지로 즉시 실행됩니다:

```bash
# Jenkins 시작 (백그라운드)
docker compose up -d

# 로그 확인 (최초 기동 시 초기 어드민 비밀번호 확인)
docker compose logs -f

# 중지
docker compose down
```

---

## ⚙️ 포트 및 초기 설정 안내

- **Jenkins 웹 대시보드 포트**: `http://<호스트IP>:9090` (기본값)
- **JNLP 에이전트 포트**: `50000`

### 🔑 최초 관리자 비밀번호 확인

```bash
docker exec -it jenkins cat /var/jenkins_home/secrets/initialAdminPassword
```

### 🐳 Docker 빌드(DooD - Docker out of Docker) 완벽 지원

- 호스트의 `/usr/bin/docker`, `/usr/libexec/docker/cli-plugins`, `/var/run/docker.sock`이 마운트되어 있어 **별도의 Dockerfile 빌드 없이 순정 Jenkins 상태에서 `docker build`, `docker compose` 명령어가 즉시 동작**합니다.
