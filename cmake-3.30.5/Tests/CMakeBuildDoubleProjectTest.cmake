# create the binary directory
make_directory("/home/rainbow/setup_robot_pc/cmake-3.30.5/Tests/DoubleProject")

# remove the CMakeCache.txt file from the source dir
# if there is one, so that in-source cmake tests
# still pass
message("Remove: /home/rainbow/setup_robot_pc/cmake-3.30.5/Tests/DoubleProject/CMakeCache.txt")
file(REMOVE "/home/rainbow/setup_robot_pc/cmake-3.30.5/Tests/DoubleProject/CMakeCache.txt")

# run cmake in the binary directory
message("running: ${CMAKE_COMMAND}")
execute_process(COMMAND "${CMAKE_COMMAND}"
  "/home/rainbow/setup_robot_pc/cmake-3.30.5/Tests/DoubleProject"
  "-GUnix Makefiles"
  -A ""
  -T ""
  WORKING_DIRECTORY "/home/rainbow/setup_robot_pc/cmake-3.30.5/Tests/DoubleProject"
  RESULT_VARIABLE RESULT)
if(RESULT)
  message(FATAL_ERROR "Error running cmake command")
endif()

# Now use the --build option to build the project
message("running: ${CMAKE_COMMAND} --build")
execute_process(COMMAND "${CMAKE_COMMAND}"
  --build "/home/rainbow/setup_robot_pc/cmake-3.30.5/Tests/DoubleProject" --config Debug
  RESULT_VARIABLE RESULT)
if(RESULT)
  message(FATAL_ERROR "Error running cmake --build")
endif()

# run the executable out of the Debug directory if using a
# multi-config generator
set(_isMultiConfig 0)
if(_isMultiConfig)
  set(RUN_TEST "/home/rainbow/setup_robot_pc/cmake-3.30.5/Tests/DoubleProject/Debug/just_silly")
else()
  set(RUN_TEST "/home/rainbow/setup_robot_pc/cmake-3.30.5/Tests/DoubleProject/just_silly")
endif()
# run the test results
message("running [${RUN_TEST}]")
execute_process(COMMAND "${RUN_TEST}" RESULT_VARIABLE RESULT)
if(RESULT)
  message(FATAL_ERROR "Error running test just_silly")
endif()

# build it again with clean and only just_silly target
execute_process(COMMAND "${CMAKE_COMMAND}"
  --build "/home/rainbow/setup_robot_pc/cmake-3.30.5/Tests/DoubleProject" --config Debug
  --clean-first --target just_silly
  RESULT_VARIABLE RESULT)
if(RESULT)
  message(FATAL_ERROR "Error running cmake --build")
endif()

# run it again after clean
execute_process(COMMAND "${RUN_TEST}" RESULT_VARIABLE RESULT)
if(RESULT)
  message(FATAL_ERROR "Error running test just_silly after clean ")
endif()
