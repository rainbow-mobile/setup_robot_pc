include("/home/rainbow/setup_robot_pc/cmake-3.30.5/Tests/CMakeTests/CheckCMakeTest.cmake")

macro(TEST command expected)
  if("x${result}" STREQUAL "x${expected}")
    #message("TEST \"${command}\" success: \"${result}\" expected: \"${expected}\"")
  else()
    message(SEND_ERROR "${CMAKE_CURRENT_LIST_LINE}: TEST \"${command}\" failed: \"${result}\" expected: \"${expected}\"")
  endif()
endmacro()

set(mylist andy bill ken brad)

list(LENGTH mylist result)
TEST("LENGTH mylist result" "4")
list(LENGTH "mylist" result)
TEST("LENGTH \"mylist\" result" "4")

list(LENGTH "nonexiting_list1" result)
TEST("LENGTH \"nonexiting_list1\" result" "0")

list(GET mylist 3 2 1 0 result)
TEST("GET mylist 3 2 1 0 result" "brad;ken;bill;andy")

list(GET mylist 0 item0)
list(GET mylist 1 item1)
list(GET mylist 2 item2)
list(GET mylist 3 item3)
set(result "${item3}" "${item0}" "${item1}" "${item2}")
TEST("GET individual 3 2 1 0 result" "brad;andy;bill;ken")

list(GET mylist -1 -2 -3 -4 result)
TEST("GET mylist -1 -2 -3 -4 result" "brad;ken;bill;andy")

list(GET mylist -1 2 -3 0 result)
TEST("GET mylist -1 2 -3 0 ${result}" "brad;ken;bill;andy")

list(GET "nonexiting_list2" 1 result)
TEST("GET \"nonexiting_list2\" 1 result" "NOTFOUND")

set(result andy)
list(APPEND result brad)
TEST("APPEND result brad" "andy;brad")

list(APPEND "nonexiting_list3" brad)
set(result "${nonexiting_list3}")
TEST("APPEND \"nonexiting_list3\" brad" "brad")

list(INSERT "nonexiting_list4" 0 andy bill brad ken)
set(result "${nonexiting_list4}")
TEST("APPEND \"nonexiting_list4\" andy bill brad ken" "andy;bill;brad;ken")

set(result andy brad)
list(INSERT result -1 bill ken)
TEST("INSERT result -1 bill ken" "andy;bill;ken;brad")

set(result andy brad)
list(INSERT result 2 bill ken)
TEST("INSERT result 2 bill ken" "andy;brad;bill;ken")

set(result andy bill brad ken bob)
list(REMOVE_ITEM result bob)
TEST("REMOVE_ITEM result bob" "andy;bill;brad;ken")

set(result andy bill bob brad ken peter)
list(REMOVE_ITEM result peter bob)
TEST("REMOVE_ITEM result peter bob" "andy;bill;brad;ken")

set(result bob andy bill bob brad ken bob)
list(REMOVE_ITEM result bob)
TEST("REMOVE_ITEM result bob" "andy;bill;brad;ken")

set(result andy bill bob brad ken peter)
list(REMOVE_AT result 2 -1)
TEST("REMOVE_AT result 2 -1" "andy;bill;brad;ken")

# ken is at index 2, nobody is not in the list so -1 should be returned
set(mylist andy bill ken brad)
list(FIND mylist ken result)
TEST("FIND mylist ken result" "2")

list(FIND mylist nobody result)
TEST("FIND mylist nobody result" "-1")

set(result ken bill andy brad)
list(SORT result)
TEST("SORT result" "andy;bill;brad;ken")

list(SORT result COMPARE NATURAL)
TEST("SORT result COMPARE NATURAL" "andy;bill;brad;ken")

set(result andy bill brad ken)
list(REVERSE result)
TEST("REVERSE result" "ken;brad;bill;andy")

set(result bill andy bill brad ken ken ken)
list(REMOVE_DUPLICATES result)
TEST("REMOVE_DUPLICATES result" "bill;andy;brad;ken")

# these commands should just do nothing if the list is already empty
set(result "")
list(REMOVE_DUPLICATES result)
TEST("REMOVE_DUPLICATES empty result" "")

list(REVERSE result)
TEST("REVERSE empty result" "")

list(SORT result)
TEST("SORT empty result" "")

list(SORT result COMPARE NATURAL)
TEST("SORT result COMPARE NATURAL" "")

set(result 1.1 10.0 11.0 12.0 12.1 2.0 2.1 3.0 3.1 3.2 8.0 9.0)

list(SORT result COMPARE NATURAL)
TEST("SORT result COMPARE NATURAL" "1.1;2.0;2.1;3.0;3.1;3.2;8.0;9.0;10.0;11.0;12.0;12.1")

list(SORT result)
TEST("SORT result" "1.1;10.0;11.0;12.0;12.1;2.0;2.1;3.0;3.1;3.2;8.0;9.0")

list(SORT result COMPARE NATURAL ORDER DESCENDING)
TEST("SORT result COMPARE NATURAL ORDER DESCENDING" "12.1;12.0;11.0;10.0;9.0;8.0;3.2;3.1;3.0;2.1;2.0;1.1")

set(result b-1.1 a-10.0 c-2.0 d 1 00 0)

list(SORT result COMPARE NATURAL)
TEST("SORT result COMPARE NATURAL" "00;0;1;a-10.0;b-1.1;c-2.0;d")


# these trigger top-level condition
foreach(cmd IN ITEMS Append Find Get Insert Length Reverse Remove_At Remove_Duplicates Remove_Item Sort)
  set(${cmd}-No-Arguments-RESULT 1)
  set(${cmd}-No-Arguments-STDERR ".*CMake Error at List-${cmd}-No-Arguments.cmake:1 \\(list\\):.*list must be called with at least two arguments.*")
  string(TOUPPER ${cmd} cmd_upper)
  set(_test_file_name "${CMAKE_CURRENT_BINARY_DIR}/List-${cmd}-No-Arguments.cmake")
  file(WRITE "${_test_file_name}" "list(${cmd_upper})\n")
  check_cmake_test_single(List "${cmd}-No-Arguments" "${_test_file_name}")
endforeach()

set(Get-List-Only-STDERR "at least three")
set(Find-List-Only-STDERR "three")
set(Insert-List-Only-STDERR "at least three")
set(Length-List-Only-STDERR "two")
set(Remove_At-List-Only-STDERR "at least two")

foreach(cmd IN ITEMS Find Get Insert Length Remove_At)
  string(TOUPPER ${cmd} cmd_upper)
  set(${cmd}-List-Only-RESULT 1)
  set(${cmd}-List-Only-STDERR ".*CMake Error at List-${cmd}-List-Only.cmake:1 \\(list\\):.*list sub-command ${cmd_upper} requires ${${cmd}-List-Only-STDERR} arguments.*")
  set(_test_file_name "${CMAKE_CURRENT_BINARY_DIR}/List-${cmd}-List-Only.cmake")
  file(WRITE "${_test_file_name}" "list(${cmd_upper} mylist)\n")
  check_cmake_test_single(List "${cmd}-List-Only" "${_test_file_name}")
endforeach()

set(thelist "" NEW OLD)

foreach (_pol ${thelist})
    cmake_policy(SET CMP0007 ${_pol})
    list(GET thelist 1 thevalue)
    if (NOT thevalue STREQUAL _pol)
        message(SEND_ERROR "returned element '${thevalue}', but expected '${_pol}'")
    endif()
endforeach (_pol)

block(SCOPE_FOR POLICIES)
  cmake_policy(SET CMP0007 NEW)
  set(result andy bill brad ken bob)
  list(INSERT result 1 "")
  TEST("INSERT result 1 \"\"" "andy;;bill;brad;ken;bob")
  list(INSERT result 4 ";")
  TEST("INSERT result 1 ;" "andy;;bill;brad;;;ken;bob")
  list(INSERT result 0 "x")
  TEST("INSERT result 1 x" "x;andy;;bill;brad;;;ken;bob")
endblock()
block(SCOPE_FOR POLICIES)
  cmake_policy(SET CMP0007 OLD)
  set(result andy bill brad ken bob)
  list(INSERT result 1 "")
  TEST("INSERT result 1 \"\"" "andy;;bill;brad;ken;bob")
  list(INSERT result 4 ";")
  TEST("INSERT result 1 ;" "andy;bill;brad;ken;;;bob")
  list(INSERT result 0 "x")
  TEST("INSERT result 1 x" "x;andy;bill;brad;ken;bob")
endblock()
