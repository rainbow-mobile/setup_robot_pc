# CMAKE generated file: DO NOT EDIT!
# Generated by "Unix Makefiles" Generator, CMake Version 3.30

# Delete rule output on recipe failure.
.DELETE_ON_ERROR:

#=============================================================================
# Special targets provided by cmake.

# Disable implicit rules so canonical targets will work.
.SUFFIXES:

# Disable VCS-based implicit rules.
% : %,v

# Disable VCS-based implicit rules.
% : RCS/%

# Disable VCS-based implicit rules.
% : RCS/%,v

# Disable VCS-based implicit rules.
% : SCCS/s.%

# Disable VCS-based implicit rules.
% : s.%

.SUFFIXES: .hpux_make_needs_suffix_list

# Command-line flag to silence nested $(MAKE).
$(VERBOSE)MAKESILENT = -s

#Suppress display of executed commands.
$(VERBOSE).SILENT:

# A target that is always out of date.
cmake_force:
.PHONY : cmake_force

#=============================================================================
# Set environment variables for the build.

# The shell in which to execute make rules.
SHELL = /bin/sh

# The CMake executable.
CMAKE_COMMAND = /home/rainbow/setup_robot_pc/cmake-3.30.5/Bootstrap.cmk/cmake

# The command to remove a file.
RM = /home/rainbow/setup_robot_pc/cmake-3.30.5/Bootstrap.cmk/cmake -E rm -f

# Escaping for special characters.
EQUALS = =

# The top-level source directory on which CMake was run.
CMAKE_SOURCE_DIR = /home/rainbow/setup_robot_pc/cmake-3.30.5

# The top-level build directory on which CMake was run.
CMAKE_BINARY_DIR = /home/rainbow/setup_robot_pc/cmake-3.30.5

# Include any dependencies generated for this target.
include Source/QtDialog/CMakeFiles/cmake-gui.dir/depend.make
# Include any dependencies generated by the compiler for this target.
include Source/QtDialog/CMakeFiles/cmake-gui.dir/compiler_depend.make

# Include the progress variables for this target.
include Source/QtDialog/CMakeFiles/cmake-gui.dir/progress.make

# Include the compile flags for this target's objects.
include Source/QtDialog/CMakeFiles/cmake-gui.dir/flags.make

Source/QtDialog/CMakeFiles/cmake-gui.dir/CMakeGUIExec.cxx.o: Source/QtDialog/CMakeFiles/cmake-gui.dir/flags.make
Source/QtDialog/CMakeFiles/cmake-gui.dir/CMakeGUIExec.cxx.o: Source/QtDialog/CMakeGUIExec.cxx
Source/QtDialog/CMakeFiles/cmake-gui.dir/CMakeGUIExec.cxx.o: Source/QtDialog/CMakeFiles/cmake-gui.dir/compiler_depend.ts
	@$(CMAKE_COMMAND) -E cmake_echo_color "--switch=$(COLOR)" --green --progress-dir=/home/rainbow/setup_robot_pc/cmake-3.30.5/CMakeFiles --progress-num=$(CMAKE_PROGRESS_1) "Building CXX object Source/QtDialog/CMakeFiles/cmake-gui.dir/CMakeGUIExec.cxx.o"
	cd /home/rainbow/setup_robot_pc/cmake-3.30.5/Source/QtDialog && /usr/bin/g++ $(CXX_DEFINES) $(CXX_INCLUDES) $(CXX_FLAGS) -MD -MT Source/QtDialog/CMakeFiles/cmake-gui.dir/CMakeGUIExec.cxx.o -MF CMakeFiles/cmake-gui.dir/CMakeGUIExec.cxx.o.d -o CMakeFiles/cmake-gui.dir/CMakeGUIExec.cxx.o -c /home/rainbow/setup_robot_pc/cmake-3.30.5/Source/QtDialog/CMakeGUIExec.cxx

Source/QtDialog/CMakeFiles/cmake-gui.dir/CMakeGUIExec.cxx.i: cmake_force
	@$(CMAKE_COMMAND) -E cmake_echo_color "--switch=$(COLOR)" --green "Preprocessing CXX source to CMakeFiles/cmake-gui.dir/CMakeGUIExec.cxx.i"
	cd /home/rainbow/setup_robot_pc/cmake-3.30.5/Source/QtDialog && /usr/bin/g++ $(CXX_DEFINES) $(CXX_INCLUDES) $(CXX_FLAGS) -E /home/rainbow/setup_robot_pc/cmake-3.30.5/Source/QtDialog/CMakeGUIExec.cxx > CMakeFiles/cmake-gui.dir/CMakeGUIExec.cxx.i

Source/QtDialog/CMakeFiles/cmake-gui.dir/CMakeGUIExec.cxx.s: cmake_force
	@$(CMAKE_COMMAND) -E cmake_echo_color "--switch=$(COLOR)" --green "Compiling CXX source to assembly CMakeFiles/cmake-gui.dir/CMakeGUIExec.cxx.s"
	cd /home/rainbow/setup_robot_pc/cmake-3.30.5/Source/QtDialog && /usr/bin/g++ $(CXX_DEFINES) $(CXX_INCLUDES) $(CXX_FLAGS) -S /home/rainbow/setup_robot_pc/cmake-3.30.5/Source/QtDialog/CMakeGUIExec.cxx -o CMakeFiles/cmake-gui.dir/CMakeGUIExec.cxx.s

# Object files for target cmake-gui
cmake__gui_OBJECTS = \
"CMakeFiles/cmake-gui.dir/CMakeGUIExec.cxx.o"

# External object files for target cmake-gui
cmake__gui_EXTERNAL_OBJECTS = \
"/home/rainbow/setup_robot_pc/cmake-3.30.5/Source/QtDialog/CMakeFiles/CMakeGUIQRCLib.dir/qrc_CMakeSetup.cpp.o"

bin/cmake-gui: Source/QtDialog/CMakeFiles/cmake-gui.dir/CMakeGUIExec.cxx.o
bin/cmake-gui: Source/QtDialog/CMakeFiles/CMakeGUIQRCLib.dir/qrc_CMakeSetup.cpp.o
bin/cmake-gui: Source/QtDialog/CMakeFiles/cmake-gui.dir/build.make
bin/cmake-gui: Source/QtDialog/libCMakeGUIMainLib.a
bin/cmake-gui: Source/QtDialog/libCMakeGUILib.a
bin/cmake-gui: Source/libCMakeLib.a
bin/cmake-gui: Utilities/std/libcmstd.a
bin/cmake-gui: Source/kwsys/libcmsys.a
bin/cmake-gui: Utilities/cmcurl/lib/libcmcurl.a
bin/cmake-gui: Utilities/cmnghttp2/libcmnghttp2.a
bin/cmake-gui: Utilities/cmexpat/libcmexpat.a
bin/cmake-gui: Utilities/cmlibarchive/libarchive/libcmlibarchive.a
bin/cmake-gui: /usr/lib/x86_64-linux-gnu/libssl.so
bin/cmake-gui: /usr/lib/x86_64-linux-gnu/libcrypto.so
bin/cmake-gui: Utilities/cmbzip2/libcmbzip2.a
bin/cmake-gui: Utilities/cmliblzma/libcmliblzma.a
bin/cmake-gui: Utilities/cmzstd/libcmzstd.a
bin/cmake-gui: Utilities/cmlibrhash/libcmlibrhash.a
bin/cmake-gui: Utilities/cmlibuv/libcmlibuv.a
bin/cmake-gui: Utilities/cmzlib/libcmzlib.a
bin/cmake-gui: Utilities/cmcppdap/libcmcppdap.a
bin/cmake-gui: Utilities/cmjsoncpp/libcmjsoncpp.a
bin/cmake-gui: /usr/lib/x86_64-linux-gnu/libQt5Widgets.so.5.15.3
bin/cmake-gui: /usr/lib/x86_64-linux-gnu/libQt5Gui.so.5.15.3
bin/cmake-gui: /usr/lib/x86_64-linux-gnu/libQt5Core.so.5.15.3
bin/cmake-gui: Source/QtDialog/CMakeFiles/cmake-gui.dir/link.txt
	@$(CMAKE_COMMAND) -E cmake_echo_color "--switch=$(COLOR)" --green --bold --progress-dir=/home/rainbow/setup_robot_pc/cmake-3.30.5/CMakeFiles --progress-num=$(CMAKE_PROGRESS_2) "Linking CXX executable ../../bin/cmake-gui"
	cd /home/rainbow/setup_robot_pc/cmake-3.30.5/Source/QtDialog && $(CMAKE_COMMAND) -E cmake_link_script CMakeFiles/cmake-gui.dir/link.txt --verbose=$(VERBOSE)

# Rule to build all files generated by this target.
Source/QtDialog/CMakeFiles/cmake-gui.dir/build: bin/cmake-gui
.PHONY : Source/QtDialog/CMakeFiles/cmake-gui.dir/build

Source/QtDialog/CMakeFiles/cmake-gui.dir/clean:
	cd /home/rainbow/setup_robot_pc/cmake-3.30.5/Source/QtDialog && $(CMAKE_COMMAND) -P CMakeFiles/cmake-gui.dir/cmake_clean.cmake
.PHONY : Source/QtDialog/CMakeFiles/cmake-gui.dir/clean

Source/QtDialog/CMakeFiles/cmake-gui.dir/depend:
	cd /home/rainbow/setup_robot_pc/cmake-3.30.5 && $(CMAKE_COMMAND) -E cmake_depends "Unix Makefiles" /home/rainbow/setup_robot_pc/cmake-3.30.5 /home/rainbow/setup_robot_pc/cmake-3.30.5/Source/QtDialog /home/rainbow/setup_robot_pc/cmake-3.30.5 /home/rainbow/setup_robot_pc/cmake-3.30.5/Source/QtDialog /home/rainbow/setup_robot_pc/cmake-3.30.5/Source/QtDialog/CMakeFiles/cmake-gui.dir/DependInfo.cmake "--color=$(COLOR)"
.PHONY : Source/QtDialog/CMakeFiles/cmake-gui.dir/depend

