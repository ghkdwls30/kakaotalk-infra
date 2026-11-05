# Jenkins CI/CD (`jenkins`)

카카오톡 인프라 및 애플리케이션 자동 빌드/테스트/배포 파이프라인을 위한 Jenkins 컨테이너입니다.

---

## 📁 디렉터리 구성

- `docker-compose.yml`: Jenkins LTS(JDK 17) 실행 compose
- `.env`: 웹 포트, 에이전트 포트, JVM 옵션 및 실행 권한 설정
- `jenkins_home/`: 플러그인, 빌드 작업(jobs), 설정 영구 볼륨 (자동 생성, `.gitignore` 등록됨)

---

## 🚀 실행 가이드

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
  - *백엔드 서버 8080 포트와의 충돌을 방지하기 위해 기본 호스트 포트를 `9090`으로 지정했습니다.*
- **JNLP 에이전트 포트**: `50000`

### 🔑 최초 관리자 비밀번호 확인

최초 접속 시 요구하는 `Initial Admin Password`는 아래 명령어로 확인할 수 있습니다:

```bash
# 컨테이너 로그에서 확인
docker compose logs | grep -A 2 "Please use the following password to proceed to installation"

# 또는 jenkins_home 파일 직접 확인
cat ./jenkins_home/secrets/initialAdminPassword
# (컨테이너 내부 경로)
docker exec -it jenkins cat /var/jenkins_home/secrets/initialAdminPassword
```

### 🐳 Docker 빌드(DooD - Docker out of Docker) 지원

- 호스트의 `/var/run/docker.sock`을 공유하도록 마운트되어 있어, Jenkins 파이프라인 스크립트 내부에서 `docker build`, `docker push` 등을 바로 사용할 수 있습니다.
- Jenkins 컨테이너 내부에 docker CLI 바이너리가 없는 경우, 컨테이너 내부에 docker-cli를 설치하거나 Docker 플러그인을 활용하시면 됩니다.
