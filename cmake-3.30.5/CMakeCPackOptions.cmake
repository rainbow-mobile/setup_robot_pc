# This file is configured at cmake time, and loaded at cpack time.
# To pass variables to cpack from cmake, they must be configured
# in this file.

if(CPACK_GENERATOR MATCHES "NSIS")
  set(CPACK_NSIS_INSTALL_ROOT "$PROGRAMFILES")

  # set the install/uninstall icon used for the installer itself
  # There is a bug in NSI that does not handle full unix paths properly.
  set(CPACK_NSIS_MUI_ICON "/home/rainbow/setup_robot_pc/cmake-3.30.5/Utilities/Release\\CMakeLogo.ico")
  set(CPACK_NSIS_MUI_UNIICON "/home/rainbow/setup_robot_pc/cmake-3.30.5/Utilities/Release\\CMakeLogo.ico")
  # set the package header icon for MUI
  set(CPACK_PACKAGE_ICON "/home/rainbow/setup_robot_pc/cmake-3.30.5/Utilities/Release\\CMakeInstall.bmp")
  # tell cpack to create links to the doc files
  set(CPACK_NSIS_MENU_LINKS
    "doc/cmake-3.30/html/index.html" "CMake Documentation"
    "https://cmake.org" "CMake Web Site"
    )
  # Use the icon from cmake-gui for add-remove programs
  set(CPACK_NSIS_INSTALLED_ICON_NAME "bin\\cmake-gui.exe")

  set(CPACK_NSIS_PACKAGE_NAME "CMake 3.30.5")
  set(CPACK_NSIS_DISPLAY_NAME "CMake 3.30.5, a cross-platform, open-source build system")
  set(CPACK_NSIS_HELP_LINK "https://cmake.org")
  set(CPACK_NSIS_URL_INFO_ABOUT "http://www.kitware.com")
  set(CPACK_NSIS_CONTACT cmake+development@discourse.cmake.org)
  set(CPACK_NSIS_MODIFY_PATH ON)
endif()

# include the cpack options for qt dialog if they exist
# they might not if qt was not enabled for the build
include("/home/rainbow/setup_robot_pc/cmake-3.30.5/Source/QtDialog/QtDialogCPack.cmake" OPTIONAL)

if(CPACK_GENERATOR MATCHES "IFW")

  # Installer configuration
  set(CPACK_IFW_PACKAGE_TITLE "CMake Build Tool")
  set(CPACK_IFW_PRODUCT_URL "https://cmake.org")
  
  set(CPACK_IFW_PACKAGE_WINDOW_ICON
    "/home/rainbow/setup_robot_pc/cmake-3.30.5/Source/QtDialog/CMakeSetup128.png")
  set(CPACK_IFW_PACKAGE_CONTROL_SCRIPT
    "/home/rainbow/setup_robot_pc/cmake-3.30.5/Source/QtIFW/controlscript.qs")

  # Uninstaller configuration
  set(CPACK_IFW_PACKAGE_MAINTENANCE_TOOL_NAME "cmake-maintenance")
  
  # Unspecified
  set(CPACK_IFW_COMPONENT__VERSION
    "3.30.5")

  # Package configuration group
  set(CPACK_IFW_PACKAGE_GROUP CMake)

  # Group configuration

  # CMake
  set(CPACK_COMPONENT_GROUP_CMAKE_DISPLAY_NAME
    "CMake")
  set(CPACK_COMPONENT_GROUP_CMAKE_DESCRIPTION
    "CMake is a build tool")
  # CMake IFW configuration
  set(CPACK_IFW_COMPONENT_GROUP_CMAKE_VERSION
    "3.30.5")
  set(CPACK_IFW_COMPONENT_GROUP_CMAKE_PRIORITY
    "100")
  set(CPACK_IFW_COMPONENT_GROUP_CMAKE_SCRIPT_TEMPLATE
    "/home/rainbow/setup_robot_pc/cmake-3.30.5/Source/QtIFW/installscript.qs.in")
  set(CPACK_IFW_COMPONENT_GROUP_CMAKE_SCRIPT_GENERATED
    "/home/rainbow/setup_robot_pc/cmake-3.30.5/CMake.qs")
  set(CPACK_IFW_COMPONENT_GROUP_CMAKE_LICENSES
    "CMake Copyright;/home/rainbow/setup_robot_pc/cmake-3.30.5/Copyright.txt")
  set(CPACK_IFW_COMPONENT_GROUP_CMAKE_SCRIPT
    "/home/rainbow/setup_robot_pc/cmake-3.30.5/CMake.qs")


  # Tools
  set(CPACK_COMPONENT_GROUP_TOOLS_DISPLAY_NAME "Command-Line Tools")
  set(CPACK_COMPONENT_GROUP_TOOLS_DESCRIPTION
    "Command-Line Tools: cmake, ctest and cpack")
  set(CPACK_COMPONENT_GROUP_TOOLS_PARENT_GROUP CMake)
  set(CPACK_IFW_COMPONENT_GROUP_TOOLS_PRIORITY 90)
  set(CPACK_IFW_COMPONENT_GROUP_TOOLS_VERSION
    "3.30.5")

  set(CPACK_COMPONENT_CMAKE_DISPLAY_NAME "cmake")
  set(CPACK_COMPONENT_CMAKE_DESCRIPTION
    "The \"cmake\" executable is the CMake command-line interface")
  set(CPACK_COMPONENT_CMAKE_REQUIRED TRUE)
  set(CPACK_COMPONENT_CMAKE_GROUP Tools)
  set(CPACK_IFW_COMPONENT_CMAKE_NAME "CMake")
  set(CPACK_IFW_COMPONENT_CMAKE_PRIORITY 89)
  set(CPACK_IFW_COMPONENT_CMAKE_VERSION
    "3.30.5")

  set(CPACK_COMPONENT_CTEST_DISPLAY_NAME "ctest")
  set(CPACK_COMPONENT_CTEST_DESCRIPTION
    "The \"ctest\" executable is the CMake test driver program")
  set(CPACK_COMPONENT_CTEST_REQUIRED TRUE)
  set(CPACK_COMPONENT_CTEST_GROUP Tools)
  set(CPACK_IFW_COMPONENT_CTEST_NAME "CTest")
  set(CPACK_IFW_COMPONENT_CTEST_PRIORITY 88)
  set(CPACK_IFW_COMPONENT_CTEST_VERSION
    "3.30.5")

  set(CPACK_COMPONENT_CPACK_DISPLAY_NAME "cpack")
  set(CPACK_COMPONENT_CPACK_DESCRIPTION
    "The \"cpack\" executable is the CMake packaging program")
  set(CPACK_COMPONENT_CPACK_REQUIRED TRUE)
  set(CPACK_COMPONENT_CPACK_GROUP Tools)
  set(CPACK_IFW_COMPONENT_CPACK_NAME "CPack")
  set(CPACK_IFW_COMPONENT_CPACK_PRIORITY 87)
  set(CPACK_IFW_COMPONENT_CPACK_VERSION
    "3.30.5")

  set(CPACK_COMPONENT_CMCLDEPS_DISPLAY_NAME "cmcldeps")
  set(CPACK_COMPONENT_CMCLDEPS_DESCRIPTION
    "The \"cmcldeps\" executable is wrapper around \"cl\" program")
  set(CPACK_COMPONENT_CMCLDEPS_GROUP Tools)
  set(CPACK_IFW_COMPONENT_CMCLDEPS_NAME "CMClDeps")
  set(CPACK_IFW_COMPONENT_CMCLDEPS_PRIORITY 86)
  set(CPACK_IFW_COMPONENT_CMCLDEPS_VERSION
    "3.30.5")

  # Dialogs
  set(CPACK_COMPONENT_GROUP_DIALOGS_DISPLAY_NAME "Interactive Dialogs")
  set(CPACK_COMPONENT_GROUP_DIALOGS_DESCRIPTION
    "Interactive Dialogs with Console and GUI interfaces")
  set(CPACK_COMPONENT_GROUP_DIALOGS_PARENT_GROUP CMake)
  set(CPACK_IFW_COMPONENT_GROUP_DIALOGS_PRIORITY 80)
  set(CPACK_IFW_COMPONENT_GROUP_DIALOGS_VERSION
    "3.30.5")

  set(CPACK_COMPONENT_CMAKE-GUI_DISPLAY_NAME "cmake-gui")
  set(CPACK_COMPONENT_CMAKE-GUI_GROUP Dialogs)
  set(CPACK_IFW_COMPONENT_CMAKE-GUI_NAME "QtGUI")
  set(CPACK_IFW_COMPONENT_CMAKE-GUI_SCRIPT
    "/home/rainbow/setup_robot_pc/cmake-3.30.5/CMake.Dialogs.QtGUI.qs")
  set(CPACK_IFW_COMPONENT_CMAKE-GUI_VERSION
    "3.30.5")
  

  set(CPACK_COMPONENT_CCMAKE_DISPLAY_NAME "ccmake")
  set(CPACK_COMPONENT_CCMAKE_GROUP Dialogs)
  set(CPACK_IFW_COMPONENT_CCMAKE_NAME "CursesGUI")
  set(CPACK_IFW_COMPONENT_CCMAKE_VERSION
    "3.30.5")

  # Documentation
  set(CPACK_COMPONENT_GROUP_DOCUMENTATION_DISPLAY_NAME "Documentation")
  set(CPACK_COMPONENT_GROUP_DOCUMENTATION_DESCRIPTION
    "CMake Documentation in different formats (html, man, qch)")
  set(CPACK_COMPONENT_GROUP_DOCUMENTATION_PARENT_GROUP CMake)
  set(CPACK_IFW_COMPONENT_GROUP_DOCUMENTATION_PRIORITY 60)
  set(CPACK_IFW_COMPONENT_GROUP_DOCUMENTATION_VERSION
    "3.30.5")

  set(CPACK_COMPONENT_SPHINX-MAN_DISPLAY_NAME "man")
  set(CPACK_COMPONENT_SPHINX-MAN_GROUP Documentation)
  set(CPACK_COMPONENT_SPHINX-MAN_DISABLED TRUE)
  set(CPACK_IFW_COMPONENT_SPHINX-MAN_NAME "SphinxMan")
  set(CPACK_IFW_COMPONENT_SPHINX-MAN_VERSION
    "3.30.5")

  set(CPACK_COMPONENT_SPHINX-HTML_DISPLAY_NAME "HTML")
  set(CPACK_COMPONENT_SPHINX-HTML_GROUP Documentation)
  set(CPACK_IFW_COMPONENT_SPHINX-HTML_NAME "SphinxHTML")
  set(CPACK_IFW_COMPONENT_SPHINX-HTML_SCRIPT
    "/home/rainbow/setup_robot_pc/cmake-3.30.5/CMake.Documentation.SphinxHTML.qs")
  set(CPACK_IFW_COMPONENT_SPHINX-HTML_VERSION
    "3.30.5")

  set(CPACK_COMPONENT_SPHINX-SINGLEHTML_DISPLAY_NAME "Single HTML")
  set(CPACK_COMPONENT_SPHINX-SINGLEHTML_GROUP Documentation)
  set(CPACK_COMPONENT_SPHINX-SINGLEHTML_DISABLED TRUE)
  set(CPACK_IFW_COMPONENT_SPHINX-SINGLEHTML_NAME "SphinxSingleHTML")
  set(CPACK_IFW_COMPONENT_SPHINX-SINGLEHTML_VERSION
    "3.30.5")

  set(CPACK_COMPONENT_SPHINX-QTHELP_DISPLAY_NAME "Qt Compressed Help")
  set(CPACK_COMPONENT_SPHINX-QTHELP_GROUP Documentation)
  set(CPACK_COMPONENT_SPHINX-QTHELP_DISABLED TRUE)
  set(CPACK_IFW_COMPONENT_SPHINX-QTHELP_NAME "SphinxQtHelp")
  set(CPACK_IFW_COMPONENT_SPHINX-QTHELP_VERSION
    "3.30.5")

  # Developer Reference
  set(CPACK_COMPONENT_GROUP_DEVELOPERREFERENCE_DISPLAY_NAME "Developer Reference")
  set(CPACK_COMPONENT_GROUP_DEVELOPERREFERENCE_DESCRIPTION
    "CMake Reference in different formats (html, qch)")
  set(CPACK_COMPONENT_GROUP_DEVELOPERREFERENCE_PARENT_GROUP CMake)
  set(CPACK_IFW_COMPONENT_GROUP_DEVELOPERREFERENCE_PRIORITY 50)
  set(CPACK_IFW_COMPONENT_GROUP_DEVELOPERREFERENCE_VERSION
    "3.30.5")

  set(CPACK_COMPONENT_CMAKE-DEVELOPER-REFERENCE-HTML_DISPLAY_NAME "HTML")
  set(CPACK_COMPONENT_CMAKE-DEVELOPER-REFERENCE-HTML_GROUP DeveloperReference)
  set(CPACK_COMPONENT_CMAKE-DEVELOPER-REFERENCE-HTML_DISABLED TRUE)
  set(CPACK_IFW_COMPONENT_CMAKE-DEVELOPER-REFERENCE-HTML_NAME "HTML")
  set(CPACK_IFW_COMPONENT_CMAKE-DEVELOPER-REFERENCE-HTML_SCRIPT
    "/home/rainbow/setup_robot_pc/cmake-3.30.5/CMake.DeveloperReference.HTML.qs")
  set(CPACK_IFW_COMPONENT_CMAKE-DEVELOPER-REFERENCE-HTML_VERSION
    "3.30.5")

  set(CPACK_COMPONENT_CMAKE-DEVELOPER-REFERENCE-QTHELP_DISPLAY_NAME "Qt Compressed Help")
  set(CPACK_COMPONENT_CMAKE-DEVELOPER-REFERENCE-QTHELP_GROUP DeveloperReference)
  set(CPACK_COMPONENT_CMAKE-DEVELOPER-REFERENCE-QTHELP_DISABLED TRUE)
  set(CPACK_IFW_COMPONENT_CMAKE-DEVELOPER-REFERENCE-QTHELP_NAME "QtHelp")
  set(CPACK_IFW_COMPONENT_CMAKE-DEVELOPER-REFERENCE-QTHELP_VERSION
    "3.30.5")

endif()

if("${CPACK_GENERATOR}" STREQUAL "DragNDrop")
  set(CPACK_DMG_BACKGROUND_IMAGE
      "/home/rainbow/setup_robot_pc/cmake-3.30.5/Packaging/CMakeDMGBackground.tif")
  set(CPACK_DMG_DS_STORE_SETUP_SCRIPT
      "/home/rainbow/setup_robot_pc/cmake-3.30.5/Packaging/CMakeDMGSetup.scpt")
endif()

if("${CPACK_GENERATOR}" STREQUAL "WIX")
  set(CPACK_WIX_VERSION 4)
  set(CPACK_WIX_BUILD_EXTRA_FLAGS "")

  # Reset CPACK_PACKAGE_VERSION to deal with WiX restriction.
  # But the file names still use the full CMake_VERSION value:
  set(CPACK_PACKAGE_FILE_NAME
    "cmake-3.30.5-${CPACK_SYSTEM_NAME}")
  set(CPACK_SOURCE_PACKAGE_FILE_NAME
    "cmake-3.30.5")

  if(NOT CPACK_WIX_SIZEOF_VOID_P)
    set(CPACK_WIX_SIZEOF_VOID_P "8")
  endif()

  set(CPACK_PACKAGE_VERSION
    "3.30")
  # WIX installers require at most a 4 component version number, where
  # each component is an integer between 0 and 65534 inclusive
  set(patch "5")
  if(patch MATCHES "^[0-9]+$" AND patch LESS 65535)
    set(CPACK_PACKAGE_VERSION "${CPACK_PACKAGE_VERSION}.${patch}")
  endif()

  set(CPACK_WIX_PROPERTY_ARPURLINFOABOUT "https://cmake.org")

  set(CPACK_WIX_PROPERTY_ARPCONTACT "cmake+development@discourse.cmake.org")

  set(CPACK_WIX_PROPERTY_ARPCOMMENTS
    "CMake is a cross-platform, open-source build system."
  )

  set(CPACK_WIX_PRODUCT_ICON
    "/home/rainbow/setup_robot_pc/cmake-3.30.5/Utilities/Release/CMakeLogo.ico"
  )

  set_property(INSTALL "doc/cmake-3.30/html/index.html" PROPERTY
    CPACK_START_MENU_SHORTCUTS "CMake Documentation"
  )

  set_property(INSTALL "cmake.org.html" PROPERTY
    CPACK_START_MENU_SHORTCUTS "CMake Web Site"
  )

  list(APPEND CPACK_WIX_BUILD_EXTRA_FLAGS -dcl high)

  set(CPACK_WIX_UI_BANNER
    "/home/rainbow/setup_robot_pc/cmake-3.30.5/Utilities/Release/WiX/ui_banner.jpg"
  )

  set(CPACK_WIX_UI_DIALOG
    "/home/rainbow/setup_robot_pc/cmake-3.30.5/Utilities/Release/WiX/ui_dialog.jpg"
  )

  set(CPACK_WIX_EXTRA_SOURCES
    "/home/rainbow/setup_robot_pc/cmake-3.30.5/Utilities/Release/WiX/install_dir.wxs"
    "/home/rainbow/setup_robot_pc/cmake-3.30.5/Utilities/Release/WiX/options.wxs"
    "/home/rainbow/setup_robot_pc/cmake-3.30.5/Utilities/Release/WiX/options_dlg.wxs"
  )

  set(_WIX_CUSTOM_ACTION_ENABLED "")
  if(_WIX_CUSTOM_ACTION_ENABLED)
    list(APPEND CPACK_WIX_EXTRA_SOURCES
      "/home/rainbow/setup_robot_pc/cmake-3.30.5/Utilities/Release/WiX/cmake_nsis_overwrite_dialog.wxs"
      )
    list(APPEND CPACK_WIX_BUILD_EXTRA_FLAGS -d CHECK_NSIS=1)

    set(_WIX_CUSTOM_ACTION_MULTI_CONFIG "")
    if(_WIX_CUSTOM_ACTION_MULTI_CONFIG)
      if(CPACK_BUILD_CONFIG)
        set(_WIX_CUSTOM_ACTION_CONFIG "${CPACK_BUILD_CONFIG}")
      else()
        set(_WIX_CUSTOM_ACTION_CONFIG "Release")
      endif()

      list(APPEND CPACK_WIX_EXTRA_SOURCES
        "/home/rainbow/setup_robot_pc/cmake-3.30.5/Utilities/Release/WiX/custom_action_dll-${_WIX_CUSTOM_ACTION_CONFIG}.wxs")
    else()
      list(APPEND CPACK_WIX_EXTRA_SOURCES
        "/home/rainbow/setup_robot_pc/cmake-3.30.5/Utilities/Release/WiX/custom_action_dll.wxs")
    endif()
  endif()

  set(CPACK_WIX_UI_REF "CMakeUI_InstallDir_$(sys.BUILDARCHSHORT)")

  set(CPACK_WIX_PATCH_FILE
    "/home/rainbow/setup_robot_pc/cmake-3.30.5/Utilities/Release/WiX/patch_path_env.xml"
  )

  set(CPACK_WIX_TEMPLATE
    "/home/rainbow/setup_robot_pc/cmake-3.30.5/Utilities/Release/WiX/WIX.template.in"
  )

  set(BUILD_QtDialog "1")

  if(BUILD_QtDialog)
    list(APPEND CPACK_WIX_PATCH_FILE
      "/home/rainbow/setup_robot_pc/cmake-3.30.5/Utilities/Release/WiX/patch_desktop_shortcut.xml"
      )
    list(APPEND CPACK_WIX_BUILD_EXTRA_FLAGS -d BUILD_QtDialog=1)
  endif()
endif()
