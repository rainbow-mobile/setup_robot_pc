#!/bin/bash

TEAMVIEWER_DIR=/opt/teamviewer/tv_bin

# TeamViewer 전용 Qt 환경 구성
export QT_PLUGIN_PATH="$TEAMVIEWER_DIR/qt/plugins"
export QT_QPA_PLATFORM_PLUGIN_PATH="$TEAMVIEWER_DIR/qt/plugins/platforms"
export LD_LIBRARY_PATH="$TEAMVIEWER_DIR/qt/lib:$LD_LIBRARY_PATH"
export QML2_IMPORT_PATH="$TEAMVIEWER_DIR/qt/qml"

# QT_DEBUG_PLUGINS=1 로 디버깅도 가능
# export QT_DEBUG_PLUGINS=1

# TeamViewer 실행
exec "$TEAMVIEWER_DIR/TeamViewer"

