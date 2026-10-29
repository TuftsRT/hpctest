# Build step: runs inside the job after modules load (bash -e).
cmake -S . -B build -DCMAKE_C_COMPILER="$cc" -DCMAKE_BUILD_TYPE=Release
cmake --build build --parallel 2
