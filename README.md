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
The argument is based on the generated SASS for different target architectures and will be backed by benchmarks on
sm_87 (Jetson Orin).

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

## The proposed change

The proposed change (prototype) to CUB lives in `patches/` and is applied on top of the pinned commit. The patch is generated
with `git format-patch` from the commits up to
[`lennartvoelz/cccl@688bb93311`](https://github.com/lennartvoelz/cccl/commit/688bb933112657c344a79c6c9b93e171ba2cefc8)
on the branch `bitonic-minmax-issue`
([compare](https://github.com/lennartvoelz/cccl/compare/26210d7cce...688bb933112657c344a79c6c9b93e171ba2cefc8)).

## Reproduce the results

To generate the tables and run the correctness check, see [REPRODUCE.md](REPRODUCE.md).
