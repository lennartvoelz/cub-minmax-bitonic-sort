# cub-minmax-bitonic-sort

WarpBitonicSort accepts a comparator that returns a bool. For `float`, every compare-exchange
compiles to one comparison (FSETP) and two selects (FSEL). FSETP compares two floats
and writes a predicate, which is followed by two selects that read the predicate.
`double` and `__half` follow the same pattern with DSETP and HSETP2, and `__half` also needs a PRMT.
For integral data types, the compiler already turns the comparator into two min/max instructions.

The compare-exchange with a `bool` comparator is worse in two ways:

1. **More instructions:** 3 instead of 2 for e.g. float.
2. **A dependency inside compare-exchange:** Both selects wait for the compare, so a compare-exchange takes two
   dependent instructions instead of one. The two min/max instructions only depend on the inputs and can issue in any
   order.

Compiling with `--use_fast_math` has no effect.

## Usecase

The usecase I have in mind is sorting many many small arrays on the GPU (think of a median filter in image processing).
A perfect candidate for this is the bitonic sort implementation in CUB (not yet in any public API, but I already use it).
When using half precision, the min/max overload also allows to use __hmax/__hmin instructions on two independent sorts, e.g.
of two neighbouring pixels. This is not possible with the bool comparator.

## Purpose of this repository

This repository aims at providing a motivation for adding an overload to CUB's bitonic sort that accepts a min/max
operator instead of a comparator.
The argument is based on the generated SASS for different target architectures and backed by benchmarks on sm_87
(Jetson Orin).

**What this is not:** a production grade implementation!

## SASS analyis for the default (bool) comparator

Only `keys[K]` is stored, so the compiler removes compare-exchanges that do not lead to it. Length 40, K = 20, sm_87:

| Type | Compare | Select | Permute | Min/max |
|---|---|---|---|---|
| `int` | 0 | 0 | 0 | 567 |
| `float` | 303 | 567 | 0 | 0 |
| `double` | 303 | 1134 | 0 | 0 |
| `__half` | 152 | 567 | 302 | 0 |


Full tables per kernel and architecture:

- [Default flags](results/probes_default.md)
- [`--use_fast_math`](results/probes_fast_math.md)

## SASS analysis for the min/max operator

With the patch in `patches/`, `WarpBitonicSort` also accepts an operator with `min` and `max` members that return keys.
The probe uses `cuda::minimum` and `cuda::maximum`, which forward to `cuda::std::fmin` and `cuda::std::fmax` for
floating-point types, and `__hmin2` and `__hmax2` for `__half2`. `__half2` holds two independent arrays per thread, one
per component, which a `bool` comparator cannot express. Same kernel as above, length 40, K = 20, sm_87:

| Type | Compare | Select | Permute | Min/max | Total, `bool` | Total, min/max |
|---|---|---|---|---|---|---|
| `int` | 0 | 0 | 0 | 567 | 640 | 640 |
| `float` | 0 | 0 | 0 | 567 | 942 | 640 |
| `double` | 567 | 1134 | 0 | 0 | 1510 | 4915 |
| `__half` | 0 | 0 | 166 | 284 | 1094 | 522 |
| `__half2` | 0 | 0 | 0 | 567 | - | 640, for two arrays |

The totals include loads, stores and address computation, about 70 instructions per kernel.

- **`float`:** every compare-exchange output is a single `FMNMX` -> breaks the depedency chain between
  the compare and select.
- **`__half`:** the compiler packs two independent min/max operations into one `HMNMX2`, so `__half` needs
  half the min/max instructions of `float`.
- **`__half2`:** two arrays sort with as many instructions as one `float` array.
- **`int`:** unchanged, as the compiler already uses `IMNMX` for the `bool` comparator.
- **`double`:** worse. The compiler emits no `double` min/max instruction.

Full table per kernel and architecture: [min/max operator](results/probes_minmax.md)

### Contract of the min/max operator

A comparator only decides which of two keys comes first, so the keys are always swapped, never changed. A min/max
operator returns the keys itself, so it has to keep them a permutation: for every pair of keys `a` and `b`,
`{min(a, b), max(a, b)}` must equal `{a, b}`, with `min(a, b)` ordered before or equivalent to `max(a, b)` under one
order for all pairs.

`fmin` and `fmax` break this for NaN. The operator in the probes is therefore only valid for keys
without NaN!

## Benchmark

`benchmarks/kth_element.cu` computes the k-th element of a sliding window (1D median filter), with K = Length / 2.
A block of 256 threads loads its tile of `256 + Length - 1` keys into shared memory once. Every thread then loads the
window starting at its own offset into registers, runs the sorting network on it and stores `keys[K]`. As in the SASS
analysis, the compiler removes the compare-exchanges that do not lead to `keys[K]`, so this measures the pruned network
(a selection), which is the use case above. The keys are reused Length times, so from length 32 on the network
dominates and not the memory traffic. Every case computes 2^22 results. For `__half2`, the two components are two
independent signals, e.g. two neighbouring pixel rows or two channels, so it needs half the threads for that.

GPU time on Jetson Orin (sm_87):

| Length | `float (bool)` | `float (min/max)` | Speedup vs `float (bool)` | `__half (bool)` | `__half (min/max)` | Speedup vs `__half (bool)` | `__half2 (min/max)` | Speedup vs `__half (bool)` | Speedup vs `__half (min/max)` |
|---|---|---|---|---|---|---|---|---|---|
| 16 | 692 µs | 511 µs | 1.35x | 801 µs | 476 µs | 1.68x | 262 µs | 3.06x | 1.82x |
| 32 | 1.90 ms | 1.22 ms | 1.55x | 2.12 ms | 1.09 ms | 1.95x | 616 µs | 3.45x | 1.76x |
| 40 | 3.13 ms | 2.03 ms | 1.54x | 3.33 ms | 1.60 ms | 2.08x | 976 µs | 3.41x | 1.64x |
| 48 | 3.80 ms | 2.51 ms | 1.52x | 4.05 ms | 1.91 ms | 2.12x | 1.22 ms | 3.31x | 1.57x |
| 56 | 4.77 ms | 2.99 ms | 1.59x | 4.94 ms | 2.33 ms | 2.12x | 1.47 ms | 3.36x | 1.59x |
| 64 | 5.43 ms | 3.63 ms | 1.49x | 5.99 ms | 2.63 ms | 2.28x | 1.81 ms | 3.32x | 1.46x |

- **`float`:** about 1.5x faster from length 32 on, close to the ratio of instructions in the SASS. Length 16
  gains less, as the kernel there is already partly bound by global memory.
- **`__half`:** the gain grows with the length, from 1.7x to 2.3x. `HMNMX2` handles two compare-exchanges at once. The
  min/max operator also needs fewer registers (40 at every length, vs 72 with `bool` at length 64), because the keys
  are packed in pairs, so more threads fit on an SM.
- **`__half2`:** two results per thread in about the time of one `float` result with min/max, so about 3.3x faster than
  `__half` with the `bool` comparator. Against `__half` with the min/max operator, the packing alone gains 1.5x to 1.8x.
- **Length 16** is partly bound by global memory for every case that is fast enough: `float` with min/max and `__half2`
  reach about 80% of the bandwidth there.
- **Noise:** the min/max cases are stable between runs, but `float` with the `bool` comparator varies by up to 7% between
  runs, with single runs up to 13% noise. The slow outliers likely come from the desktop, which shares the GPU on Orin.

Generated table: [results/bench_kth_orin.md](results/bench_kth_orin.md)

## The proposed change

The proposed change (prototype) to CUB lives in `patches/` and is applied on top of the pinned commit. The patch is generated
with `git format-patch` from the commits up to
[`lennartvoelz/cccl@688bb93311`](https://github.com/lennartvoelz/cccl/commit/688bb933112657c344a79c6c9b93e171ba2cefc8)
on the branch `bitonic-minmax-issue`
([compare](https://github.com/lennartvoelz/cccl/compare/26210d7cce...688bb933112657c344a79c6c9b93e171ba2cefc8)).

## Reproduce the results

To generate the tables, run the correctness check and the benchmark, see [REPRODUCE.md](REPRODUCE.md).
