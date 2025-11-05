# Docker SLAMNAV2 Manager AppImage

Docker를 사용하여 SLAMNAV2 GUI 컨테이너를 관리하는 GUI 애플리케이션입니다.

## 기능

- **Install**: Docker 및 필요한 환경 설치
- **Remove**: 설치된 모든 항목 제거 (Docker, 이미지, 컨테이너)
- **Run**: Docker 컨테이너 실행 (GUI 옵션 포함)
- **Exit**: 애플리케이션 종료

## 빌드 방법

### 필수 요구사항

- Qt 5.12 이상 또는 Qt 6.x
- CMake 또는 qmake
- linuxdeploy (AppImage 생성용)

### 빌드

```bash
cd docker_manager_appimage
chmod +x build.sh
./build.sh
```

빌드가 완료되면 `build/Docker_SLAMNAV2_Manager-x86_64.AppImage` 파일이 생성됩니다.

## 사용 방법

1. AppImage 파일에 실행 권한 부여:
   ```bash
   chmod +x Docker_SLAMNAV2_Manager-x86_64.AppImage
   ```

2. 실행:
   ```bash
   ./Docker_SLAMNAV2_Manager-x86_64.AppImage
   ```

3. Install 버튼을 클릭하여 Docker 설치

4. Run 버튼을 클릭하여 컨테이너 실행

## Run 옵션

- **Enable GUI**: X11 forwarding 활성화 (기본 활성화)
- **Mount Volume**: 호스트 볼륨 마운트
  - Host Path: 호스트 머신의 디렉토리 경로
  - Container Path: 컨테이너 내부 경로
- **Docker Image**: 사용할 Docker 이미지 이름
- **Container Name**: 컨테이너 이름

## 주의사항

- Windows에서는 AppImage가 동작하지 않습니다. Linux 전용입니다.
- GUI 기능을 사용하려면 X11 서버가 실행 중이어야 합니다.
- Docker 설치 시 sudo 권한이 필요할 수 있습니다.

