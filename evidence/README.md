# 증거 자료 관리 안내

이 디렉터리에는 실제 실험에서 얻은 **비식별화된 핵심 증거**만 저장합니다.

## 권장 구조

```text
evidence/
├── oom/
├── cpu/
└── deadlock/
```

Git은 빈 디렉터리를 저장하지 않으므로 실험을 시작할 때 해당 폴더를 만드세요.

```bash
mkdir -p evidence/{oom,cpu,deadlock}
```

## 파일명 규칙

```text
YYYYMMDD-HHMMSS_장애유형_자료종류_before-or-after.ext
```

예: `20260723-103000_oom_monitor_before.csv`

## 각 장애에 필요한 최소 증거

| 장애 | 최소 자료 |
| --- | --- |
| OOM | 관제 CSV, 종료 로그, Before/After 설정과 생존 시간 |
| CPU | 관제 CSV, `top` 또는 `ps` 결과, Watchdog 로그 |
| Deadlock | PID 확인, `top -H` 또는 `ps -L`, 마지막 앱 로그 |

## 보안 점검

커밋 전에 다음을 제거하거나 가리세요.

- API 키, 토큰, 비밀번호
- 개인 사용자명과 불필요한 절대 경로
- 공인·사설 IP, 호스트명 등 내부 인프라 정보
- 제공 바이너리와 라이선스가 불명확한 원본
- 전체 로그 중 미션 증거와 무관한 민감정보

실제 `secret.key`는 절대로 이 저장소에 올리지 않습니다.
