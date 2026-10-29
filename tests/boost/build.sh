# Build step: runs inside the job after modules load (bash -e).
$cxx -o boost_hello boost_hello.cpp -lboost_filesystem -lboost_regex -lboost_program_options -lboost_date_time
