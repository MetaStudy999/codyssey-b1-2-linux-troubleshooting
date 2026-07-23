# B1-2 리눅스 프로세스 및 시스템 리소스 트러블슈팅

OOM, CPU Spike, Deadlock을 직접 재현하고 Linux 관제 데이터와 애플리케이션 로그를 근거로 원인을 분석하는 Codyssey B1-2 저장소입니다.

> [!IMPORTANT]
> 현재 저장소에는 **실험을 수행하기 위한 안내서·스크립트·리포트 양식**이 준비되어 있습니다. `docs/`의 빈칸과 `evidence/`의 증거는 실제 환경에서 실행한 뒤 본인의 측정값으로 채워야 합니다. 미션 문서의 예시 로그를 실제 결과처럼 제출하지 마세요.

## 현재 진행 상태

| 단계 | 상태 |
| --- | --- |
| 공식 미션·평가 문항 정리 | 완료 |
| 입문자용 실행 안내 | 완료 |
| 환경 설정·관제 스크립트 | 완료 |
| OOM 실제 재현·증거 | 미수행 |
| CPU Spike 실제 재현·증거 | 미수행 |
| Deadlock 실제 재현·증거 | 미수행 |
| GitHub Issue 3건 최종 작성 | 실험 후 완료 필요 |

## 저장소 구조

```text
.
├── README.md
├── B1-2-Mission.md
├── B1-2-Evaluation.md
├── docs/
│   ├── 01-oom-report.md
│   ├── 02-cpu-spike-report.md
│   ├── 03-deadlock-report.md
│   └── 04-scheduling-analysis.md
├── scripts/
│   ├── setup.sh
│   ├── run-agent.sh
│   └── monitor.sh
├── evidence/
│   └── README.md
└── .gitignore
```

## 1. 준비 사항

- Ubuntu 24.04 또는 호환 Linux
- 일반 사용자 계정(root 실행 금지)
- 제공된 `agent-app-leak-x86` 또는 `agent-app-leak-arm64`
- 기본 도구: `bash`, `ps`, `top`, `pgrep`, `tee`

```bash
git clone https://github.com/MetaStudy999/codyssey-b1-2-linux-troubleshooting.git
cd codyssey-b1-2-linux-troubleshooting
chmod +x scripts/*.sh
bash scripts/setup.sh
```

`setup.sh`는 기본 실습 경로 `$HOME/agent-lab`과 필수 디렉터리·키 파일을 만듭니다. 키 파일은 저장소 밖에 생성되며 Git에 올리지 않습니다.

## 2. 바이너리 배치

제공받은 바이너리를 저장소 밖의 실습 경로에 복사하고 실행 권한을 부여합니다.

```bash
cp /바이너리가/있는/경로/agent-app-leak-x86 "$HOME/agent-lab/agent-leak-app"
chmod +x "$HOME/agent-lab/agent-leak-app"
export APP_PATH="$HOME/agent-lab/agent-leak-app"
```

Apple Silicon Linux 환경이면 arm64 바이너리를 사용하세요. 바이너리는 라이선스와 용량 문제를 확인하기 전까지 Git에 올리지 않습니다.

## 3. 기본 실행

```bash
source "$HOME/agent-lab/env.sh"
bash scripts/run-agent.sh
```

다른 터미널에서 PID를 찾고 5초 간격으로 관제를 시작합니다.

```bash
pgrep -af agent-leak-app
bash scripts/monitor.sh --name agent-leak-app --interval 5 \
  --output evidence/monitor-$(date +%Y%m%d-%H%M%S).csv
```

중지할 때는 `Ctrl+C`를 누릅니다. CSV에는 시각, PID, CPU, 메모리, RSS, VSZ, 스레드 수, 상태, 경과 시간, 명령이 기록됩니다.

## 4. 장애별 실험 순서

각 실험은 **설정 확인 → 실행 → 관제 → 장애 확인 → 로그 보존 → 설정 변경 → 재실행 → 비교** 순서로 진행합니다.

### OOM / Memory Leak

1. `MEMORY_LIMIT`의 Before 값을 기록합니다.
2. 앱과 `monitor.sh`를 실행합니다.
3. RSS 증가와 MemoryGuard·SELF-TERMINATED 로그를 보존합니다.
4. 허용 범위 안에서 `MEMORY_LIMIT`를 변경합니다.
5. 같은 조건으로 다시 실행해 생존 시간과 종료 직전 RSS를 비교합니다.
6. [OOM 리포트](docs/01-oom-report.md)를 채웁니다.

### CPU Spike

1. `CPU_MAX_OCCUPY`의 Before 값을 기록합니다.
2. `ps -p PID -o pid,pcpu,pmem,etime,stat,cmd`와 `top -p PID`로 특정 프로세스를 확인합니다.
3. Watchdog·SIGTERM 로그를 보존합니다.
4. 임계치를 변경한 뒤 같은 조건으로 다시 측정합니다.
5. [CPU 리포트](docs/02-cpu-spike-report.md)를 채웁니다.

### Deadlock

1. `MULTI_THREAD_ENABLE=true`에서 실행합니다.
2. PID가 살아 있는지 확인합니다.
3. `top -H -p PID`와 `ps -L -p PID -o pid,tid,pcpu,pmem,stat,wchan:24,comm`으로 스레드 정체를 확인합니다.
4. 마지막 WAITING·BLOCKED 로그와 측정 시각을 보존합니다.
5. `MULTI_THREAD_ENABLE=false`로 재실행해 회피 여부를 비교합니다.
6. [Deadlock 리포트](docs/03-deadlock-report.md)를 채웁니다.

## 5. 증거 수집 원칙

- 명령어와 출력 결과를 함께 저장합니다.
- 모든 자료에 측정 시각과 PID를 남깁니다.
- Before와 After는 가능한 한 같은 실행 조건을 사용합니다.
- 전체 로그를 그대로 공개하기 전에 키·토큰·사용자명·내부 경로·IP를 점검합니다.
- 원본은 로컬에 보관하고, Git에는 필요한 구간과 비식별화한 스크린샷만 올립니다.
- 추측은 “추론”으로 표시하고 관측 사실과 분리합니다.

자세한 파일명 규칙은 [evidence/README.md](evidence/README.md)를 참고하세요.

## 6. 제출 전 체크리스트

- [ ] OOM·CPU·Deadlock을 각각 재현했다.
- [ ] 장애별 실제 리포트 3건을 완성했다.
- [ ] 모든 리포트에 현상·증거·원인·조치·검증이 있다.
- [ ] Before & After 표에 실제 수치가 있다.
- [ ] PID·시각·명령어·로그·스크린샷이 서로 일치한다.
- [ ] 환경변수 값은 허용 범위를 지킨다.
- [ ] 민감정보와 제공 바이너리가 커밋되지 않았다.
- [ ] [평가 문항](B1-2-Evaluation.md)에 말로 답할 수 있다.
- [ ] 완성한 리포트를 GitHub Issue 3건으로 등록했다.

## 7. 문제 해결

| 증상 | 확인할 것 |
| --- | --- |
| 앱이 즉시 종료됨 | 일반 사용자 실행 여부, 필수 환경변수, 디렉터리, 키 파일 |
| 포트 오류 | `ss -lntp | grep 15034`로 사용 여부 확인 |
| PID를 못 찾음 | `pgrep -af agent-leak-app`, 실제 프로세스 이름 확인 |
| 로그 쓰기 실패 | `AGENT_LOG_DIR` 존재·소유권·쓰기 권한 |
| 관제 CSV가 비어 있음 | 앱이 먼저 실행되었는지, `--name` 값이 맞는지 확인 |
| 수치 해석이 어려움 | 단일 순간값보다 여러 시점의 추세와 앱 로그를 함께 비교 |

공식 요구사항은 [B1-2-Mission.md](B1-2-Mission.md)를 먼저 읽으세요.
