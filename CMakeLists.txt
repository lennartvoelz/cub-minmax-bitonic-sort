cmake_minimum_required(VERSION 3.24)

project(cub_minmax_bitonic CUDA)

# For clangd, see .clangd
set(CMAKE_EXPORT_COMPILE_COMMANDS ON)

include(cmake/CPM.cmake)

# Pin CCCL upstream at the (currently) latest commit
set(CCCL_REPOSITORY "https://github.com/NVIDIA/cccl" CACHE STRING "Git repository to fetch CCCL from")
set(CCCL_TAG "26210d7cce" CACHE STRING "CCCL commit to fetch")

# The proposed change to CUB, as patches on top of CCCL_TAG. Without them, everything builds against upstream as is.
option(CCCL_APPLY_PATCHES "Apply patches/*.patch to CCCL" ON)
file(GLOB CCCL_PATCHES CONFIGURE_DEPENDS "${CMAKE_SOURCE_DIR}/patches/*.patch")
list(SORT CCCL_PATCHES)
set(cccl_patch_args)
if (CCCL_APPLY_PATCHES AND CCCL_PATCHES)
  set(cccl_patch_args PATCHES ${CCCL_PATCHES})
endif()

CPMAddPackage(NAME CCCL GIT_REPOSITORY "${CCCL_REPOSITORY}" GIT_TAG ${CCCL_TAG} ${cccl_patch_args})

set(PROBE_ARCHITECTURES "80-real;87-real;90-real;120-real" CACHE STRING "Architectures to generate SASS for")

find_package(Python3 REQUIRED COMPONENTS Interpreter)

# Compiles one probe source with one set of compiler flags, e.g. with and without --use_fast_math
function(add_probe_set name source)
  add_library(${name} OBJECT ${source})
  target_link_libraries(${name} PRIVATE CCCL::CCCL)
  target_compile_features(${name} PRIVATE cuda_std_17)
  target_compile_options(${name} PRIVATE ${ARGN})
  set_target_properties(${name} PROPERTIES CUDA_ARCHITECTURES "${PROBE_ARCHITECTURES}")
  list(APPEND PROBE_TARGETS ${name})
  set(PROBE_TARGETS ${PROBE_TARGETS} PARENT_SCOPE)
endfunction()

add_probe_set(probes_default probes/bool_comparator.cu)
add_probe_set(probes_fast_math probes/bool_comparator.cu --use_fast_math)
add_probe_set(probes_minmax probes/minmax_comparator.cu)

# Sorts random arrays on the GPU and compares them against std::sort. Needs a GPU of one of PROBE_ARCHITECTURES to run.
add_executable(check_sort checks/check_sort.cu)
target_link_libraries(check_sort PRIVATE CCCL::CCCL)
target_compile_features(check_sort PRIVATE cuda_std_17)
set_target_properties(check_sort PROPERTIES CUDA_ARCHITECTURES "${PROBE_ARCHITECTURES}")

# Throughput of the k-th element of a sliding window, bool comparator vs min/max operator. Uses the NVBench commit
# that CCCL pins. NVBench builds its library for CMAKE_CUDA_ARCHITECTURES.
set(CMAKE_CUDA_ARCHITECTURES "${PROBE_ARCHITECTURES}")
CPMAddPackage(
  NAME nvbench
  GITHUB_REPOSITORY NVIDIA/nvbench
  GIT_TAG 16761f0bf755ba53889a4a964997bcd906b07582
  OPTIONS "NVBench_ENABLE_EXAMPLES OFF" "NVBench_ENABLE_TESTING OFF"
)
add_executable(bench_kth benchmarks/kth_element.cu)
target_link_libraries(bench_kth PRIVATE CCCL::CCCL nvbench::main)
target_compile_features(bench_kth PRIVATE cuda_std_17)
set_target_properties(bench_kth PROPERTIES CUDA_ARCHITECTURES "${PROBE_ARCHITECTURES}")

# Runs the benchmark on the current GPU and writes its table to results/bench_kth_<device>.md
add_custom_target(
  bench_table
  COMMAND bench_kth --no-batch --quiet --csv "${CMAKE_BINARY_DIR}/bench_kth.csv"
  COMMAND Python3::Interpreter "${CMAKE_SOURCE_DIR}/scripts/bench_table.py" "${CMAKE_BINARY_DIR}/bench_kth.csv" --out-dir "${CMAKE_SOURCE_DIR}/results"
  DEPENDS bench_kth
  VERBATIM
)

# Disassembles probes and write opcode tables
set(count_args)
foreach (target IN LISTS PROBE_TARGETS)
  list(APPEND count_args --objects ${target} "$<TARGET_OBJECTS:${target}>")
endforeach()
add_custom_target(
  tables
  COMMAND
    Python3::Interpreter "${CMAKE_SOURCE_DIR}/scripts/count_sass_opcodes.py" --out-dir "${CMAKE_SOURCE_DIR}/results" ${count_args}
  DEPENDS ${PROBE_TARGETS}
  COMMAND_EXPAND_LISTS
  VERBATIM
)
