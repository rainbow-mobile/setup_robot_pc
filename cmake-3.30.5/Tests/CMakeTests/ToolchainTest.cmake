############################################################
# some preparations so that the CMakeDetermineXXX.cmake files will work in scripted mode

# overwrite mark_as_advanced(), since this is used in CMakeDetermineCCompiler.cmake
# which will complain that it can"t be used in script mode
macro(MARK_AS_ADVANCED)
endmacro()
# set this to a place where we are allowed to write
set(CMAKE_PLATFORM_INFO_DIR "${CMAKE_CURRENT_BINARY_DIR}")

# don't run the compiler detection
set(CMAKE_C_COMPILER_ID_RUN 1)
set(CMAKE_CXX_COMPILER_ID_RUN 1)

set(MY_SOURCE_DIR "/home/rainbow/setup_robot_pc/cmake-3.30.5/Tests/CMakeTests")

# at first load CMakeDetermineSystem.cmake without toolchain file
set(CMAKE_TOOLCHAIN_FILE)
include(CMakeDetermineSystem)

# check that CMAKE_SYSTEM_XXX and CMAKE_HOST_SYSTEM_xxx are identical
if(NOT "${CMAKE_SYSTEM_NAME}" STREQUAL "${CMAKE_HOST_SYSTEM_NAME}")
   message(FATAL_ERROR "CMAKE_SYSTEM_NAME and CMAKE_HOST_SYSTEM_NAME not identical: \"${CMAKE_SYSTEM_NAME}\" vs. \"${CMAKE_HOST_SYSTEM_NAME}\"")
endif()

if(NOT "${CMAKE_SYSTEM}" STREQUAL "${CMAKE_HOST_SYSTEM}")
   message(FATAL_ERROR "CMAKE_SYSTEM and CMAKE_HOST_SYSTEM not identical: \"${CMAKE_SYSTEM}\" vs. \"${CMAKE_HOST_SYSTEM}\"")
endif()

if(NOT "${CMAKE_SYSTEM_VERSION}" STREQUAL "${CMAKE_HOST_SYSTEM_VERSION}")
   message(FATAL_ERROR "CMAKE_SYSTEM_VERSION and CMAKE_HOST_SYSTEM_VERSION not identical: \"${CMAKE_SYSTEM_VERSION}\" vs. \"${CMAKE_HOST_SYSTEM_VERSION}\"")
endif()

if(NOT "${CMAKE_SYSTEM_PROCESSOR}" STREQUAL "${CMAKE_HOST_SYSTEM_PROCESSOR}")
   message(FATAL_ERROR "CMAKE_SYSTEM_PROCESSOR and CMAKE_HOST_SYSTEM_PROCESSOR not identical: \"${CMAKE_SYSTEM_PROCESSOR}\" vs. \"${CMAKE_HOST_SYSTEM_PROCESSOR}\"")
endif()

# save the values so we can compare them to CMAKE_HOST_SYSTEM_XXX in the toolchain case

set(NATIVE_SYSTEM           "${CMAKE_SYSTEM}")
set(NATIVE_SYSTEM_NAME      "${CMAKE_SYSTEM_NAME}")
set(NATIVE_SYSTEM_VERSION   "${CMAKE_SYSTEM_VERSION}")
set(NATIVE_SYSTEM_PROCESSOR "${CMAKE_SYSTEM_PROCESSOR}")

# reset them so they will be detected again now
set(CMAKE_SYSTEM)
set(CMAKE_SYSTEM_NAME)
set(CMAKE_SYSTEM_VERSION)
set(CMAKE_SYSTEM_PROCESSOR)
set(CMAKE_HOST_SYSTEM)
set(CMAKE_HOST_SYSTEM_VERSION)
set(CMAKE_HOST_SYSTEM_PROCESSOR)


############################################################

# now define a toolchain file and check that everything is
# detected correctly and nothing predefined is overwritten

set(CMAKE_TOOLCHAIN_FILE "${MY_SOURCE_DIR}/DummyToolchain.cmake")

include(CMakeDetermineSystem)
# make cmake think we are cross compiling for test to work
set(CMAKE_CROSSCOMPILING TRUE)
set(CMAKE_C_COMPILER_ID "GNU")
include(CMakeDetermineCCompiler)
include(CMakeDetermineCXXCompiler)

#############################################################

# check the results from DetermineSystem

if(NOT "${CMAKE_SYSTEM_NAME}" STREQUAL "Dumdidum")
   message(FATAL_ERROR "CMAKE_SYSTEM_NAME overwritten: \"${CMAKE_SYSTEM_NAME}\", was: \"Dumdidum\"")
endif()

if(NOT "${CMAKE_SYSTEM}" STREQUAL "Dumdidum-1.0")
   message(FATAL_ERROR "CMAKE_SYSTEM wrong: \"${CMAKE_SYSTEM}\", expected: \"Dumdidum-1.0\"")
endif()
set(fileOne "${_INCLUDED_TOOLCHAIN_FILE}")
set(fileTwo "${MY_SOURCE_DIR}/DummyToolchain.cmake")
if(WIN32)
  string(TOLOWER "${fileOne}" fileOne)
  string(TOLOWER "${fileTwo}" fileTwo)
endif()

if(NOT "${fileOne}"   STREQUAL "${fileTwo}")
   message(FATAL_ERROR "Wrong toolchain was loaded: \"${fileOne}\" expected \"${fileTwo}\"")
endif()

# check that CMAKE_HOST_SYSTEM_XXX and _SYSTEM_xxx detected above are identical
if(NOT "${CMAKE_HOST_SYSTEM_NAME}" STREQUAL "${NATIVE_SYSTEM_NAME}")
   message(FATAL_ERROR "CMAKE_HOST_SYSTEM_NAME and NATIVE_SYSTEM_NAME not identical: \"${CMAKE_HOST_SYSTEM_NAME}\" vs. \"${NATIVE_SYSTEM_NAME}\"")
endif()
if(NOT "${CMAKE_HOST_SYSTEM}" STREQUAL "${NATIVE_SYSTEM}")
   message(FATAL_ERROR "CMAKE_HOST_SYSTEM and NATIVE_SYSTEM not identical: \"${CMAKE_HOST_SYSTEM}\" vs. \"${NATIVE_SYSTEM}\"")
endif()
if(NOT "${CMAKE_HOST_SYSTEM_VERSION}" STREQUAL "${NATIVE_SYSTEM_VERSION}")
   message(FATAL_ERROR "CMAKE_HOST_SYSTEM_VERSION and NATIVE_SYSTEM_VERSION not identical: \"${CMAKE_HOST_SYSTEM_VERSION}\" vs. \"${NATIVE_SYSTEM_VERSION}\"")
endif()
if(NOT "${CMAKE_HOST_SYSTEM_PROCESSOR}" STREQUAL "${NATIVE_SYSTEM_PROCESSOR}")
   message(FATAL_ERROR "CMAKE_HOST_SYSTEM_PROCESSOR and NATIVE_SYSTEM_PROCESSOR not identical: \"${CMAKE_HOST_SYSTEM_PROCESSOR}\" vs. \"${NATIVE_SYSTEM_PROCESSOR}\"")
endif()

#############################################################

# check the results from DetermineCCompiler

if(NOT "${_CMAKE_TOOLCHAIN_PREFIX}" STREQUAL "arm-elf-")
   message(FATAL_ERROR "wrong toolchain prefix detected: \"${_CMAKE_TOOLCHAIN_PREFIX}\", expected: \"arm-elf-\"")
endif()

if(NOT "${_CMAKE_USER_C_COMPILER_PATH}" STREQUAL "/opt/foo/bin")
   message(FATAL_ERROR "wrong C compiler location detected: \"${_CMAKE_USER_C_COMPILER_PATH}\", expected: \"/opt/foo/bin\"")
endif()

if(NOT "${CMAKE_C_OUTPUT_EXTENSION}" STREQUAL ".foo")
   message(FATAL_ERROR "C output extension overwritten: \"${CMAKE_C_OUTPUT_EXTENSION}\", was: \".foo\"")
endif()

#############################################################

# check the results from DetermineCXXCompiler

if(NOT "${_CMAKE_USER_CXX_COMPILER_PATH}" STREQUAL "/opt/bar/bin")
   message(FATAL_ERROR "wrong CXX compiler location detected: \"${_CMAKE_USER_CXX_COMPILER_PATH}\", expected: \"/opt/bar/bin\"")
endif()

if(NOT "${CMAKE_CXX_OUTPUT_EXTENSION}" STREQUAL ".bar")
   message(FATAL_ERROR "C output extension overwritten: \"${CMAKE_CXX_OUTPUT_EXTENSION}\", was: \".bar\"")
endif()

message(STATUS "CMAKE_SYSTEM: \"${CMAKE_SYSTEM}\"")
message(STATUS "_CMAKE_TOOLCHAIN_PREFIX: \"${_CMAKE_TOOLCHAIN_PREFIX}\"")
message(STATUS "_CMAKE_USER_C_COMPILER_PATH: \"${_CMAKE_USER_C_COMPILER_PATH}\"")
message(STATUS "_CMAKE_USER_CXX_COMPILER_PATH: \"${_CMAKE_USER_CXX_COMPILER_PATH}\"")
message(STATUS "CMAKE_C_OUTPUT_EXTENSION: \"${CMAKE_C_OUTPUT_EXTENSION}\"")
message(STATUS "CMAKE_CXX_OUTPUT_EXTENSION: \"${CMAKE_CXX_OUTPUT_EXTENSION}\"")
