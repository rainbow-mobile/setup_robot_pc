QT += core widgets gui
CONFIG += c++11

TARGET = docker_manager
TEMPLATE = app

SOURCES += \
    src/main.cpp \
    src/mainwindow.cpp

HEADERS += \
    src/mainwindow.h

# AppImage 설정
QMAKE_LFLAGS += -no-pie

# 리소스 파일 (필요시)
# RESOURCES += resources/resources.qrc

