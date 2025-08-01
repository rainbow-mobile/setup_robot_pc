#!/bin/bash

# TeamViewer 전용 Qt 라이브러리 경로
export LD_LIBRARY_PATH=/opt/teamviewer/tv_bin/qt/lib:$LD_LIBRARY_PATH
export QT_QPA_PLATFORM_PLUGIN_PATH=/opt/teamviewer/tv_bin/qt/plugins

# TeamViewer 실행
/opt/teamviewer/tv_bin/TeamViewer

