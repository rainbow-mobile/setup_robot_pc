# This file will be configured to contain variables for CPack. These variables
# should be set in the CMake list file of the project before CPack module is
# included. The list of available CPACK_xxx variables and their associated
# documentation may be obtained using
#  cpack --help-variable-list
#
# Some variables are common to all generators (e.g. CPACK_PACKAGE_NAME)
# and some are specific to a generator
# (e.g. CPACK_NSIS_EXTRA_INSTALL_COMMANDS). The generator specific variables
# usually begin with CPACK_<GENNAME>_xxxx.


set(CPACK_BINARY_DEB "OFF")
set(CPACK_BINARY_FREEBSD "OFF")
set(CPACK_BINARY_IFW "OFF")
set(CPACK_BINARY_NSIS "OFF")
set(CPACK_BINARY_RPM "OFF")
set(CPACK_BINARY_STGZ "ON")
set(CPACK_BINARY_TBZ2 "OFF")
set(CPACK_BINARY_TGZ "ON")
set(CPACK_BINARY_TXZ "OFF")
set(CPACK_BINARY_TZ "ON")
set(CPACK_BUILD_SOURCE_DIRS "/home/rainbow/setup_robot_pc/cmake-3.30.5;/home/rainbow/setup_robot_pc/cmake-3.30.5")
set(CPACK_CMAKE_GENERATOR "Unix Makefiles")
set(CPACK_COMPONENT_UNSPECIFIED_HIDDEN "TRUE")
set(CPACK_COMPONENT_UNSPECIFIED_REQUIRED "TRUE")
set(CPACK_DEFAULT_PACKAGE_DESCRIPTION_FILE "/home/rainbow/setup_robot_pc/cmake-3.30.5/Templates/CPack.GenericDescription.txt")
set(CPACK_DEFAULT_PACKAGE_DESCRIPTION_SUMMARY "CMake built using CMake")
set(CPACK_DMG_SLA_USE_RESOURCE_FILE_LICENSE "OFF")
set(CPACK_GENERATOR "STGZ;TGZ;TZ")
set(CPACK_IFW_ADMIN_TARGET_DIRECTORY "@ApplicationsDir@/CMake")
set(CPACK_IFW_COMPONENT_GROUP_CMAKE_LICENSES_DEFAULT "CMake Copyright;/home/rainbow/setup_robot_pc/cmake-3.30.5/Copyright.txt")
set(CPACK_IFW_TARGET_DIRECTORY "@HomeDir@/CMake")
set(CPACK_INNOSETUP_ARCHITECTURE "x64")
set(CPACK_INSTALL_CMAKE_PROJECTS "/home/rainbow/setup_robot_pc/cmake-3.30.5;CMake;ALL;/")
set(CPACK_INSTALL_PREFIX "/usr/local")
set(CPACK_MODULE_PATH "/home/rainbow/setup_robot_pc/cmake-3.30.5/Source/Modules")
set(CPACK_NSIS_DISPLAY_NAME "CMake")
set(CPACK_NSIS_INSTALLER_ICON_CODE "")
set(CPACK_NSIS_INSTALLER_MUI_ICON_CODE "")
set(CPACK_NSIS_INSTALL_ROOT "$PROGRAMFILES")
set(CPACK_NSIS_PACKAGE_NAME "CMake 3.30.5")
set(CPACK_NSIS_UNINSTALL_NAME "Uninstall")
set(CPACK_OBJCOPY_EXECUTABLE "/usr/bin/objcopy")
set(CPACK_OBJDUMP_EXECUTABLE "/usr/bin/objdump")
set(CPACK_OUTPUT_CONFIG_FILE "/home/rainbow/setup_robot_pc/cmake-3.30.5/CPackConfig.cmake")
set(CPACK_PACKAGE_CONTACT "cmake+development@discourse.cmake.org")
set(CPACK_PACKAGE_DEFAULT_LOCATION "/")
set(CPACK_PACKAGE_DESCRIPTION_FILE "/home/rainbow/setup_robot_pc/cmake-3.30.5/Copyright.txt")
set(CPACK_PACKAGE_DESCRIPTION_SUMMARY "CMake is a build tool")
set(CPACK_PACKAGE_EXECUTABLES "ccmake;CMake")
set(CPACK_PACKAGE_FILE_NAME "cmake-3.30.5-Linux-x86_64")
set(CPACK_PACKAGE_INSTALL_DIRECTORY "CMake")
set(CPACK_PACKAGE_INSTALL_REGISTRY_KEY "CMake 3.30.5")
set(CPACK_PACKAGE_NAME "CMake")
set(CPACK_PACKAGE_RELOCATABLE "true")
set(CPACK_PACKAGE_VENDOR "Kitware")
set(CPACK_PACKAGE_VERSION "3.30.5")
set(CPACK_PACKAGE_VERSION_MAJOR "0")
set(CPACK_PACKAGE_VERSION_MINOR "1")
set(CPACK_PACKAGE_VERSION_PATCH "1")
set(CPACK_PROJECT_CONFIG_FILE "/home/rainbow/setup_robot_pc/cmake-3.30.5/CMakeCPackOptions.cmake")
set(CPACK_READELF_EXECUTABLE "/usr/bin/readelf")
set(CPACK_RESOURCE_FILE_LICENSE "/home/rainbow/setup_robot_pc/cmake-3.30.5/Copyright.txt")
set(CPACK_RESOURCE_FILE_README "/home/rainbow/setup_robot_pc/cmake-3.30.5/Templates/CPack.GenericDescription.txt")
set(CPACK_RESOURCE_FILE_WELCOME "/home/rainbow/setup_robot_pc/cmake-3.30.5/Templates/CPack.GenericWelcome.txt")
set(CPACK_SET_DESTDIR "OFF")
set(CPACK_SOURCE_GENERATOR "TBZ2;TGZ;TXZ;TZ")
set(CPACK_SOURCE_IGNORE_FILES "/\\.git/;/\\.gitattributes$;/\\.github/;/\\.gitignore$;/\\.hooks-config$;/\\.build/;\\.swp$;\\.#;/#;~$")
set(CPACK_SOURCE_OUTPUT_CONFIG_FILE "/home/rainbow/setup_robot_pc/cmake-3.30.5/CPackSourceConfig.cmake")
set(CPACK_SOURCE_PACKAGE_FILE_NAME "cmake-3.30.5")
set(CPACK_SOURCE_RPM "OFF")
set(CPACK_SOURCE_STRIP_FILES "")
set(CPACK_SOURCE_TBZ2 "ON")
set(CPACK_SOURCE_TGZ "ON")
set(CPACK_SOURCE_TXZ "ON")
set(CPACK_SOURCE_TZ "ON")
set(CPACK_SOURCE_ZIP "OFF")
set(CPACK_STRIP_FILES "bin/ccmake;bin/cmake;bin/cpack;bin/ctest")
set(CPACK_SYSTEM_NAME "Linux-x86_64")
set(CPACK_THREADS "1")
set(CPACK_TOPLEVEL_TAG "Linux-x86_64")
set(CPACK_WIX_SIZEOF_VOID_P "8")
set(CPACK_WIX_UPGRADE_GUID "8ffd1d72-b7f1-11e2-8ee5-00238bca4991")

if(NOT CPACK_PROPERTIES_FILE)
  set(CPACK_PROPERTIES_FILE "/home/rainbow/setup_robot_pc/cmake-3.30.5/CPackProperties.cmake")
endif()

if(EXISTS ${CPACK_PROPERTIES_FILE})
  include(${CPACK_PROPERTIES_FILE})
endif()
