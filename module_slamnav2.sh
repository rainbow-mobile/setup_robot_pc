#!/bin/bash
# module_slamnav2.sh: SLAMNAV2 관련 의존성 및 SDK 설치 (소스 빌드)

source ./common.sh

echo "========================================"
echo "5. SLAMNAV2 관련 의존성 및 SDK 설치"
echo "========================================"

# 5.1 CMake 3.27.7
CMAKE_VERSION=3.27.7
run_step "CMake $CMAKE_VERSION" \
    "[ -x \$(command -v cmake) ] && cmake --version | grep $CMAKE_VERSION &> /dev/null" \
    "wget https://github.com/Kitware/CMake/releases/download/v$CMAKE_VERSION/cmake-$CMAKE_VERSION.tar.gz && tar -xvzf cmake-$CMAKE_VERSION.tar.gz && cd cmake-$CMAKE_VERSION && ./bootstrap --qt-gui && make -j$NUM_CORES && sudo make install && cd ~"

# 5.2 Sophus
run_step "Sophus" \
    "[ -d Sophus/build ]" \
    "git clone https://github.com/strasdat/Sophus.git && cd Sophus && mkdir -p build && cd build && cmake .. -DBUILD_TESTS=OFF -DBUILD_EXAMPLES=OFF -DSOPHUS_USE_BASIC_LOGGING=ON && make -j$NUM_CORES && sudo make install && cd ~"

# 5.3 GTSAM (버전 4.2.0)
run_step "GTSAM" \
    "[ -d gtsam/build ]" \
    "git clone https://github.com/borglab/gtsam.git && cd gtsam && git checkout 4.2.0 && mkdir -p build && cd build && cmake .. -DGTSAM_USE_SYSTEM_EIGEN=ON -DGTSAM_BUILD_TESTS=OFF -DGTSAM_BUILD_EXAMPLES_ALWAYS=OFF && make -j$NUM_CORES && sudo make install && cd ~"

# 5.4 OMPL (버전 1.6.0)
run_step "OMPL" \
    "[ -d ompl/build ]" \
    "git clone https://github.com/ompl/ompl.git && cd ompl && git checkout 1.6.0 && mkdir -p build && cd build && cmake .. && make -j$NUM_CORES && sudo make install && cd ~"

# 5.5 socket.io-client-cpp
run_step "socket.io-client-cpp" \
    "[ -d socket.io-client-cpp/build ]" \
    "git clone --recurse-submodules https://github.com/socketio/socket.io-client-cpp.git && cd socket.io-client-cpp && mkdir -p build && cd build && cmake .. -DBUILD_SHARED_LIBS=ON -DLOGGING=OFF && make -j$NUM_CORES && sudo make install && cd ~"

# 5.6 OctoMap (버전 1.10.0)
run_step "OctoMap" \
    "[ -d octomap/build ]" \
    "git clone https://github.com/OctoMap/octomap.git && cd octomap && git checkout v1.10.0 && mkdir -p build && cd build && cmake .. -DBUILD_DYNAMICETD3D=OFF -DBUILD_OCTOVIS_SUBPROJECT=OFF -DBUILD_TESTING=OFF && make -j$NUM_CORES && sudo make install && cd ~"

# 5.7 PDAL
run_step "PDAL" \
    "dpkg -s pdal libpdal-dev &> /dev/null" \
    "sudo apt update && sudo apt install -y pdal libpdal-dev"

# 5.8 Livox SDK2
run_step "Livox SDK2" \
    "[ -d Livox-SDK2/build ]" \
    "git clone https://github.com/Livox-SDK/Livox-SDK2.git && cd Livox-SDK2 && mkdir -p build && cd build && cmake .. && make -j$NUM_CORES && sudo make install && cd ~"

