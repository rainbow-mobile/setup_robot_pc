set(MD5-BadArg1-RESULT 1)
set(MD5-BadArg1-STDERR "string MD5 requires an output variable")
set(MD5-BadArg2-RESULT 1)
set(MD5-BadArg2-STDERR "string MD5 requires an output variable and an input string")
set(MD5-BadArg4-RESULT 1)
set(MD5-BadArg4-STDERR "string MD5 requires an output variable and an input string")
set(MD5-Works-RESULT 0)
set(MD5-Works-STDERR "10d20ddb981a6202b84aa1ce1cb7fce3")
set(SHA1-Works-RESULT 0)
set(SHA1-Works-STDERR "83f093e04289b21a9415f408ad50be8b57ad2f34")
set(SHA224-Works-RESULT 0)
set(SHA224-Works-STDERR "e995a7789922c4ef9279d94e763c8375934180a51baa7147bc48edf7")
set(SHA256-Works-RESULT 0)
set(SHA256-Works-STDERR "d1c5915d8b71150726a1eef75a29ec6bea8fd1bef6b7299ef8048760b0402025")
set(SHA384-Works-RESULT 0)
set(SHA384-Works-STDERR "1de9560b4e030e02051ea408200ffc55d70c97ac64ebf822461a5c786f495c36df43259b14483bc8d364f0106f4971ee")
set(SHA512-Works-RESULT 0)
set(SHA512-Works-STDERR "3982a1b4e651768bec70ab1fb97045cb7a659f4ba7203d501c52ab2e803071f9d5fd272022df15f27727fc67f8cd022e710e29010b2a9c0b467c111e2f6abf51")
set(SHA3_224-Works-RESULT 0)
set(SHA3_224-Works-STDERR "4272868085f4f25080681a7712509fd12e16dcda79bd356836dd2100")
set(SHA3_256-Works-RESULT 0)
set(SHA3_256-Works-STDERR "be0df472b6bd474417a166d12f2774f2ef5095e86f0a88ef4c78c703800cfc8a")
set(SHA3_384-Works-RESULT 0)
set(SHA3_384-Works-STDERR "935a17cc708443c1369549483656a4521af03a52e4f3b314566272017ccae03a2c5db838f6d4c156b1dc5c366182481b")
set(SHA3_512-Works-RESULT 0)
set(SHA3_512-Works-STDERR "471a85ed537e8f77f31412a089f22d836054ffa179599f87a5d7568927d8fa236b6793ded8a387d1de92398c967177bcc6361672a722bf736cb0f63a0956d5cf")
set(TIMESTAMP-BadArg1-RESULT 1)
set(TIMESTAMP-BadArg1-STDERR "string sub-command TIMESTAMP requires at least one argument")
set(TIMESTAMP-BadArg2-RESULT 1)
set(TIMESTAMP-BadArg2-STDERR "string TIMESTAMP sub-command does not recognize option UTF")
set(TIMESTAMP-BadArg3-RESULT 1)
set(TIMESTAMP-BadArg3-STDERR "string sub-command TIMESTAMP takes at most three arguments")
set(TIMESTAMP-DefaultFormatLocal-RESULT 0)
set(TIMESTAMP-DefaultFormatLocal-STDERR "~[0-9]*-[01][0-9]-[0-3][0-9]T[0-2][0-9]:[0-5][0-9]:[0-6][0-9]~")
set(TIMESTAMP-DefaultFormatUTC-RESULT 0)
set(TIMESTAMP-DefaultFormatUTC-STDERR "~[0-9]*-[01][0-9]-[0-3][0-9]T[0-2][0-9]:[0-5][0-9]:[0-6][0-9]Z~")
set(TIMESTAMP-CustomFormatLocal-RESULT 0)
set(TIMESTAMP-CustomFormatLocal-STDERR "~([0-5][0-9])|60~")
set(TIMESTAMP-CustomFormatUTC-RESULT 0)
set(TIMESTAMP-CustomFormatUTC-STDERR "~([0-5][0-9])|60~")
set(TIMESTAMP-UnknownSpecifier-RESULT 0)
set(TIMESTAMP-UnknownSpecifier-STDERR "~%g~")
set(TIMESTAMP-IncompleteSpecifier-RESULT 0)
set(TIMESTAMP-IncompleteSpecifier-STDERR "~foobar%~")
set(TIMESTAMP-AllSpecifiers-RESULT 0)
set(TIMESTAMP-AllSpecifiers-STDERR "~[0-9]+(;[0-9]+)*~")
set(TIMESTAMP-TimeZone-RESULT 0)
set(TIMESTAMP-TimeZone-STDERR "~[-,+][0-9][0-9][0-9][0-9]~")
set(TIMESTAMP-MonthWeekNames-RESULT 0)
set(TIMESTAMP-MonthWeekNames-STDERR "~[^%]+;[^%]+~")
set(TIMESTAMP-UnixTime-RESULT 0)
set(TIMESTAMP-UnixTime-STDERR "~[0-9]+~")

include("/home/rainbow/setup_robot_pc/cmake-3.30.5/Tests/CMakeTests/CheckCMakeTest.cmake")
check_cmake_test(String
  MD5-BadArg1
  MD5-BadArg2
  MD5-BadArg4
  MD5-Works
  SHA1-Works
  SHA224-Works
  SHA256-Works
  SHA384-Works
  SHA512-Works
  SHA3_224-Works
  SHA3_256-Works
  SHA3_384-Works
  SHA3_512-Works
  TIMESTAMP-BadArg1
  TIMESTAMP-BadArg2
  TIMESTAMP-BadArg3
  TIMESTAMP-DefaultFormatLocal
  TIMESTAMP-DefaultFormatUTC
  TIMESTAMP-CustomFormatLocal
  TIMESTAMP-CustomFormatUTC
  TIMESTAMP-UnknownSpecifier
  TIMESTAMP-IncompleteSpecifier
  TIMESTAMP-AllSpecifiers
  TIMESTAMP-MonthWeekNames
  TIMESTAMP-TimeZone
  TIMESTAMP-UnixTime
  )

# Execute each test listed in StringTestScript.cmake:
#
set(scriptname "/home/rainbow/setup_robot_pc/cmake-3.30.5/Tests/CMakeTests/StringTestScript.cmake")
set(number_of_tests_expected 74)

include("/home/rainbow/setup_robot_pc/cmake-3.30.5/Tests/CMakeTests/ExecuteScriptTests.cmake")
execute_all_script_tests(${scriptname} number_of_tests_executed)

string(TIMESTAMP timestamp "[%Y-%m-%d %H:%M:%S] UTC %s" UTC)

# And verify that number_of_tests_executed is at least as many as we know
# about as of this writing...
#
message(STATUS "timestamp='${timestamp}'")
message(STATUS "scriptname='${scriptname}'")
message(STATUS "number_of_tests_executed='${number_of_tests_executed}'")
message(STATUS "number_of_tests_expected='${number_of_tests_expected}'")

if(NOT number_of_tests_executed EQUAL number_of_tests_expected)
  message(FATAL_ERROR "error: some test cases were skipped")
endif()
