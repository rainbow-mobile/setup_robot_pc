#!/bin/bash

# 패키지 리스트 업데이트
sudo apt-get update

# 팀뷰어 설치 파일을 Home 경로에 다운로드
#wget -P ~/ https://download.teamviewer.com/download/linux/teamviewer_arm64.deb
wget -P ~/ https://download.teamviewer.com/download/linux/teamviewer-host_amd64.deb

# 다운로드한 설치 파일을 이용하여 팀뷰어 설치
sudo apt install ~/teamviewer-host_amd64.deb -y

# 원본 파일 백업
sudo cp /etc/gdm3/custom.conf /etc/gdm3/custom.conf.bak

# "#WaylandEnable=false" 라인을 찾아 주석 해제
sudo sed -i 's/^[[:space:]]*#\s*WaylandEnable=false/WaylandEnable=false/' /etc/gdm3/custom.conf

echo "✅ /etc/gdm3/custom.conf 에서 WaylandEnable=false 설정을 적용했습니다."
