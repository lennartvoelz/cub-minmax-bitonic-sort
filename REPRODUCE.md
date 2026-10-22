# Reproduce the results

How to obtain the SASS tables and run the correctness check from the [README](README.md).

## Requirements

- CUDA Toolkit (`nvcc`, `cuobjdump`, `cu++filt`)
- CMake 3.24 or newer
- Python 3
- Ninja (optional)

No GPU is needed for the SASS tables.

## Generate the tables

```bash
cmake -S . -B build -G Ninja
cmake --build build --target tables
```

This fetches CCCL at the commit pinned in `CMakeLists.txt`, compiles the probes in `probes/` and writes to `results/`:

- `<target>.md`: opcode counts per kernel and architecture
- `<target>.sass`: raw disassembly (not tracked)

There is one target per probe and set of compiler flags: `probes_default` and `probes_fast_math` for the `bool`
comparator, `probes_minmax` for the min/max operator.

After changing `CMakeLists.txt` or a patch in `patches/`, delete `build/` and configure again. Otherwise CMake applies
the patches a second time to the already patched copy of CCCL, and the configure step fails.

## Correctness check

```bash
cmake --build build --target check_sort
./build/check_sort
```

Needs a GPU of one of the probe architectures. Sorts 1024 random arrays per case on the GPU, one array per thread, and
compares every array against `std::sort` on the host. The keys are integers from -20 to 20, so there are many
duplicates. The cases cover the `bool` comparator for `float` with lengths 7, 16 and 40 and for `__half` with length
40, and the min/max operator for `int`, `float`, `double`, `__half` and `__half2` with lengths 7, 16 and 40.

## Options

- `-DCCCL_APPLY_PATCHES=OFF`: build against the pinned CCCL commit without the patches in `patches/`. Use a
  separate build directory, e.g. `cmake -S . -B build-upstream -G Ninja -DCCCL_APPLY_PATCHES=OFF`.

## Count opcodes

```bash
python3 scripts/count_sass_opcodes.py --out-dir results --objects <name> <object files...>
```
