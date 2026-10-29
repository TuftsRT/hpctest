cmake_minimum_required(VERSION 3.10)
project(hpctest_cmake C)

add_library(square STATIC square.c)
add_executable(cmake_hello main.c)
target_link_libraries(cmake_hello square)

enable_testing()
add_test(NAME square_of_7 COMMAND cmake_hello 7)
set_tests_properties(square_of_7 PROPERTIES PASS_REGULAR_EXPRESSION "= 49")
add_test(NAME square_of_12 COMMAND cmake_hello 12)
set_tests_properties(square_of_12 PROPERTIES PASS_REGULAR_EXPRESSION "= 144")
