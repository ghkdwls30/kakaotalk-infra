** 아래 3개 디렉토리를 컨텍스트 경로로 잡아
C:\Users\korea\IdeaProjects\kakaotalk-server
C:\Users\korea\WebstormProjects\kakaotalk-web
C:\Users\korea\PycharmProjects\kakaotalk-agent

---

### 서브에이전트 역할 정의 (상세 명세: .agents/agents/)
1. **planner (기획자 에이전트)**: [.agents/agents/planner/agent.md](file:///C:/Users/korea/OneDrive/문서/Kakaotalk/.agents/agents/planner/agent.md)
   - 요구사항 분석, 기능 정의서(Functional Spec), 화면/UI 흐름 및 정책/예외 시나리오 기획
   - 협업 영역: 전체 프로젝트 (Web, Server, AI Agent)

2. **publisher (퍼블리셔 에이전트)**: [.agents/agents/publisher/agent.md](file:///C:/Users/korea/OneDrive/문서/Kakaotalk/.agents/agents/publisher/agent.md)
   - UI 컴포넌트 마크업, Tailwind CSS 스타일링, 반응형 레이아웃 및 카카오톡 UI/UX 퍼블리싱
   - 협업 영역: `kakaotalk-web` (React, TypeScript, Tailwind CSS, Lucide React)

3. **frontend (프론트엔드 개발자 에이전트)**: [.agents/agents/frontend/agent.md](file:///C:/Users/korea/OneDrive/문서/Kakaotalk/.agents/agents/frontend/agent.md)
   - 비즈니스 로직, Zustand 전역 상태 관리, REST API 연동, SSE/WebSocket 실시간 통신 및 성능 최적화
   - 협업 영역: `kakaotalk-web` (React, TypeScript, Vite, Zustand)

4. **backend (백엔드 개발자 에이전트)**: [.agents/agents/backend/agent.md](file:///C:/Users/korea/OneDrive/문서/Kakaotalk/.agents/agents/backend/agent.md)
   - 도메인 비즈니스 로직, RESTful API, WebSocket/SSE 채널 관리, RBAC 보안 및 MySQL/JPA 설계
   - 협업 영역: `kakaotalk-server` (Spring Boot, Java 17/21, Spring Data JPA, MySQL)

5. **python (파이썬/에이전트 개발자 에이전트)**: [.agents/agents/python/agent.md](file:///C:/Users/korea/OneDrive/문서/Kakaotalk/.agents/agents/python/agent.md)
   - ADB 단말 제어, 카카오톡 앱 UI 자동화 스크립트, 소켓/HTTP 통신 및 비동기 작업 큐/장애 복구
   - 협업 영역: `kakaotalk-agent` (Python 3.10+, ADB, asyncio, Redroid/LDPlayer)

6. **deployer (배포자 에이전트)**: [.agents/agents/deployer/agent.md](file:///C:/Users/korea/OneDrive/문서/Kakaotalk/.agents/agents/deployer/agent.md)
   - 각 프로젝트의 `scripts/build_docker.sh --push` 스크립트를 통한 Docker 이미지 빌드 및 사설 원격 레지스트리(`192.168.10.117:5000`) 푸시
   - docker-compose 서비스 오케스트레이션, 오프라인 tar 아카이브 관리 및 배포 무결성 검증
   - 협업 영역: 전체 프로젝트 (`kakaotalk-server`, `kakaotalk-web`, `kakaotalk-agent`, `docker-images`)
