# SLAMNAV2 systemd 자동실행 등록 스크립트 설계

- **날짜:** 2026-06-04
- **산출물:** `rb_sn/systemd/setup_slamnav2_service_260604.sh`
- **상태:** 설계 승인됨

## 1. 목적

로봇 PC(ODROID-H4)에는 SLAMNAV2 앱이 이미 새 구조로 설치되어 있다:

```
~/slamnav2/
  bin/      libs/     run.sh    config/  data/  pdu/  Log/
  slam_build_info.txt  slamnav2-topic-echo  slamnav2-topic-list  test_avoid
```

`run.sh`는 다음 한 줄이 핵심이다:

```bash
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
exec env LD_LIBRARY_PATH="${SCRIPT_DIR}/libs" "${SCRIPT_DIR}/bin/SLAMNAV2" "$@"
```

의존성·repo·바이너리는 이미 다 깔려 있으므로, 이 스크립트의 **유일한 역할**은
`~/slamnav2/run.sh`를 **systemd system 서비스로 등록하여 부팅 시 GUI 자동실행**하는 것이다.
v7/v8 설치 스크립트의 의존성 설치 단계(run_1~run_6)는 포함하지 않는다.

비목표(Non-goals):
- 패키지/SDK/의존성 설치
- 바탕화면 더블클릭 단축키 생성 (systemd 자동실행으로 대체)
- 버전 체인 유지 (v9 형태가 아니라 단일 목적 독립 스크립트)

## 2. 배경 / 기존 방식과의 차이

| 항목 | v7 (옛 방식) | 기존 v8 systemd | **본 설계** |
|------|--------------|-----------------|-------------|
| 실행 대상 | 바탕화면 단축키 → `slamnav2.sh` → `./SLAMNAV2` | `bin/SLAMNAV2` 직접 | **`run.sh`** |
| 부팅 자동실행 | ❌ (수동 더블클릭) | ✅ system 서비스 | ✅ system 서비스 |
| 라이브러리 경로 | slamnav2.sh가 설정 | EnvironmentFile이 `bin/lib`·`bin` 지정(❌ 새 구조와 불일치) | **run.sh가 `libs/` 자체 처리** |
| Qt 플러그인 경로 | 미설정 | `QT_PLUGIN_PATH=bin` | 미설정(옛 더블클릭도 미설정으로 동작) |
| CPU affinity | 없음 | `CPUAffinity=1-7` 하드코딩 | **`nproc` 기반 자동 계산** |
| RT priority | 없음 | `fifo/50` | `fifo/50` 유지 |
| Install target | - | `multi-user.target` | **`graphical.target`** |

최근 커밋 흐름(`유저 서비스 → 시스템 서비스 전환`, `sudo 없이 CPU affinity/RT priority 설정`)에 따라
**RT priority + CPU affinity가 필요**하므로 system 서비스 방식을 유지한다. (user 서비스로 가면 해당 설정을 잃음.)

## 3. run.sh가 처리하는 것 / 안 하는 것

- ✅ 처리: `LD_LIBRARY_PATH=~/slamnav2/libs`, `bin/SLAMNAV2` 실행
- ❌ 미처리: `DISPLAY`, `XAUTHORITY`, `QT_QPA_PLATFORM`, `XDG_RUNTIME_DIR` 등 **GUI 환경**

데스크톱 더블클릭 시에는 세션 환경을 상속받아 무방하지만, systemd가 띄울 때는 위 GUI 환경을
**유닛이 직접 주입**해야 화면에 창이 뜬다. 이것이 본 설계의 핵심 위험 지점이다.

## 4. 동작 흐름

1. **root 체크** — `/etc/systemd/system` 작성 및 RT priority 설정을 위해 `sudo` 필요. 아니면 에러 후 종료.
2. **사용자/경로 해석**
   - `USER_NAME=${SUDO_USER:-$USER}`, `USER_ID=$(id -u "$USER_NAME")`
   - `HOME_DIR=$(getent passwd "$USER_NAME" | cut -d: -f6)`
   - `APP_DIR="$HOME_DIR/slamnav2"`, `RUN_SH="$APP_DIR/run.sh"`
   - `run.sh` 존재 확인(없으면 에러 종료), 실행권한 없으면 `chmod +x`.
3. **기존 잔재 정리**
   - 옛 user 서비스 `~/.config/systemd/user/slamnav2.service` → stop/disable/삭제 + user daemon-reload
   - 기존 system `slamnav2.service` → stop/disable (재설치 멱등성)
   - pm2 존재 시 `pm2 stop/delete SLAMNAV2`
4. **자동 감지 (설치 시점, 로봇 실값 기준)**
   - **CPU 코어:** `NCORES=$(nproc)`. `NCORES>1`이면 `AFFINITY="1-$((NCORES-1))"`(코어0은 시스템용), 아니면 affinity 생략.
   - **DISPLAY:** 활성 그래픽 세션에서 감지(`loginctl`/`who`), 실패 시 `:0`.
   - **XAUTHORITY:** `/run/user/$USER_ID/gdm/Xauthority` → `$HOME_DIR/.Xauthority` 순으로 존재하는 경로 선택. 둘 다 없으면 gdm 경로를 기본값으로.
5. **env 파일 생성** `~/.config/slamnav2/env` (GUI 환경만; LD_LIBRARY_PATH는 run.sh 담당이라 제외):
   ```
   DISPLAY=<감지값>
   XAUTHORITY=<감지값>
   QT_QPA_PLATFORM=xcb
   XDG_RUNTIME_DIR=/run/user/<USER_ID>
   ```
   - 디렉터리/파일 소유권을 `USER_NAME`으로 `chown`.
6. **유닛 파일 생성** `/etc/systemd/system/slamnav2.service`:
   ```ini
   [Unit]
   Description=SLAMNAV2 (GUI autostart)
   After=graphical.target network-online.target
   Wants=network-online.target

   [Service]
   Type=simple
   User=<USER_NAME>
   Group=<USER_NAME>
   WorkingDirectory=<APP_DIR>
   EnvironmentFile=<HOME_DIR>/.config/slamnav2/env
   ExecStartPre=/usr/bin/sleep 10
   ExecStart=<APP_DIR>/run.sh
   CPUAffinity=<자동: 1-(nproc-1)>      # NCORES<=1이면 이 줄 생략
   CPUSchedulingPolicy=fifo
   CPUSchedulingPriority=50
   Restart=on-failure
   RestartSec=5
   StandardOutput=journal
   StandardError=journal

   [Install]
   WantedBy=graphical.target
   ```
   - 권한 `chmod 644`.
7. **활성화** — `systemctl daemon-reload` → `systemctl enable --now slamnav2.service`.
8. **관리용 alias/함수** `~/.bashrc`에 추가(중복 가드: 기존에 `slamnav2-save` 있으면 건너뜀):
   - `slamnav2-status` = `systemctl status slamnav2.service --no-pager`
   - `slamnav2-logs` = `journalctl -u slamnav2.service -f -o cat`
   - `slamnav2-restart` = `sudo systemctl restart slamnav2.service`
   - `slamnav2-stop` = `sudo systemctl stop slamnav2.service`
   - `slamnav2-why` = status + 최근 로그 + dmesg(OOM/SEGV) 요약
   - `slamnav2-save` = 위 정보를 `~/slamnav2_logs/`에 타임스탬프 파일로 저장하는 함수
9. **메뉴** — `select`로 `설치/업데이트` · `서비스 제거` · `종료` 제공.
   - **설치/업데이트:** 위 1~8 수행(멱등).
   - **서비스 제거:** stop/disable → 유닛 파일·`~/.config/slamnav2` 삭제 → `daemon-reload` + `reset-failed`. bashrc alias는 자동 삭제하지 않고 안내만.

## 5. 컴포넌트 경계

- `do_install()` — 감지 + env/유닛 생성 + 활성화 + alias 등록. 멱등.
- `do_uninstall()` — 서비스/파일 정리.
- 감지 헬퍼 — CPU 코어, DISPLAY, XAUTHORITY 각각 독립 함수로 분리해 단위 검증 가능하게.
- 로그 헬퍼 — `log/warn/err` 색상 출력.

## 6. 에러 처리

- root 아님 → 명확한 메시지 후 `exit 1`.
- `run.sh` 부재 → 경로 안내 후 `exit 1`.
- 옛 서비스/pm2 정리 실패 → `|| true`로 무시하고 진행.
- DISPLAY/XAUTHORITY 감지 실패 → 합리적 기본값(`:0`, gdm 경로)으로 폴백 + 경고 로그.

## 7. 전제 조건 / 알려진 한계 (스크립트가 강제하지 않고 안내)

- **자동로그인 활성화 필수.** GUI 세션이 떠 있어야 창 출력 가능. GDM 로그인 화면에 머물면 서비스가 실행돼도 화면에 안 나옴.
- `XAUTHORITY`(특히 gdm 런타임 경로)는 세션 시작 후 생성됨. `ExecStartPre=sleep 10` + `Restart=on-failure`로 완화하나, 그래픽 세션 기동이 더 느리면 첫 시도가 실패할 수 있음(재시작으로 복구).
- 본 설계 검증은 로봇(ODROID-H4)에서 이뤄져야 함. 개발 PC와 코어 수·세션 환경이 다름(예: 개발 PC `nproc=16`, 로봇은 다를 수 있음 → CPUAffinity 자동 계산이 필요한 이유).

## 8. 검증(테스트) 방법

1. 로봇에서 `sudo ./setup_slamnav2_service_260604.sh` → `설치/업데이트` 선택.
2. `systemctl status slamnav2.service` → `active (running)` 확인.
3. 재부팅 → 로그인 후 SLAMNAV2 창이 자동으로 뜨는지 확인.
4. `slamnav2-logs`로 런타임 로그 확인, GUI 환경 관련 에러 없는지 점검.
5. `서비스 제거` 후 유닛/`~/.config/slamnav2` 정리 및 부팅 시 미실행 확인.
