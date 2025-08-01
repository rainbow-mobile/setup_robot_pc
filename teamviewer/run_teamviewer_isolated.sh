#!/bin/bash

# TeamViewer 경로 설정
TV_BIN="/opt/teamviewer/tv_bin"
TV_LIB="$TV_BIN/RTlib/qt/lib"
TV_PLUGIN="$TV_BIN/RTlib/qt/plugins"

# 강제 환경 설정
export QT_QPA_PLATFORM_PLUGIN_PATH="$TV_PLUGIN/platforms"
export QT_PLUGIN_PATH="$TV_PLUGIN"
export QML2_IMPORT_PATH="$TV_BIN/RTlib/qt/qml"
export LD_LIBRARY_PATH="$TV_LIB"

# 문제 되는 시스템 경로 제거 (중요!)
unset LD_PRELOAD

# 실행
exec "$TV_BIN/TeamViewer"

