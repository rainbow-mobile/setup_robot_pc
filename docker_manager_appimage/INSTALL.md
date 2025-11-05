# 설치 가이드

## 빌드 전 필수 요구사항

### Ubuntu/Debian

```bash
# Qt 개발 도구 설치
sudo apt-get update
sudo apt-get install -y \
    build-essential \
    qt6-base-dev \
    qt6-base-dev-tools \
    qmake6 \
    cmake

# 또는 Qt 5 사용 시
sudo apt-get install -y \
    qt5-default \
    qtbase5-dev \
    qtbase5-dev-tools \
    qmake
```

### AppImage 빌드 도구 (선택사항)

```bash
# linuxdeploy 설치
wget https://github.com/linuxdeploy/linuxdeploy/releases/download/continuous/linuxdeploy-x86_64.AppImage
chmod +x linuxdeploy-x86_64.AppImage
sudo mv linuxdeploy-x86_64.AppImage /usr/local/bin/linuxdeploy

# Qt 플러그인 설치
wget https://github.com/linuxdeploy/linuxdeploy-plugin-qt/releases/download/continuous/linuxdeploy-plugin-qt-x86_64.AppImage
chmod +x linuxdeploy-plugin-qt-x86_64.AppImage
sudo mv linuxdeploy-plugin-qt-x86_64.AppImage /usr/local/bin/linuxdeploy-plugin-qt
```

## 빌드 방법

```bash
cd docker_manager_appimage
./build.sh
```

빌드가 완료되면 `build/Docker_SLAMNAV2_Manager-x86_64.AppImage` 파일이 생성됩니다.

## 사용 방법

1. AppImage에 실행 권한 부여:
```bash
chmod +x Docker_SLAMNAV2_Manager-x86_64.AppImage
```

2. 실행:
```bash
./Docker_SLAMNAV2_Manager-x86_64.AppImage
```

3. 또는 더블 클릭으로 실행 (데스크탑 환경에서)

## 문제 해결

### Qt를 찾을 수 없는 경우

```bash
# qmake 경로 확인
which qmake
qmake --version

# Qt 경로가 PATH에 있는지 확인
echo $PATH
```

### linuxdeploy 오류

linuxdeploy가 없으면 AppImage 없이 바이너리만 빌드됩니다. `build/docker_manager` 파일을 직접 실행할 수 있습니다.

### 권한 오류

Docker 설치 시 sudo 권한이 필요합니다. 설치 스크립트가 실행될 때 비밀번호를 입력하라는 프롬프트가 나타날 수 있습니다.

