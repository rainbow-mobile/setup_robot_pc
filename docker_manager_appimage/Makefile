# 간단한 Makefile
.PHONY: clean build appimage

build:
	@echo "빌드 디렉토리 생성..."
	mkdir -p build
	cd build && qmake ../docker_manager.pro && make

clean:
	rm -rf build
	rm -f *.AppImage
	rm -f *.appimage

appimage: build
	@echo "AppImage 생성을 위해 build.sh를 실행하세요."
	@echo "./build.sh"

