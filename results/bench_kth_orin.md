# bench_kth

Device: Orin. Results per case: 2^22. GPU time, noise at most 12.78%.

| Length | `float (bool)` | `float (min/max)` | Speedup vs `float (bool)` | `__half (bool)` | `__half (min/max)` | Speedup vs `__half (bool)` | `__half2 (min/max)` | Speedup vs `__half (bool)` | Speedup vs `__half (min/max)` |
|---|---|---|---|---|---|---|---|---|---|
| 16 | 692 µs | 511 µs | 1.35x | 801 µs | 476 µs | 1.68x | 262 µs | 3.06x | 1.82x |
| 32 | 1.90 ms | 1.22 ms | 1.55x | 2.12 ms | 1.09 ms | 1.95x | 616 µs | 3.45x | 1.76x |
| 40 | 3.13 ms | 2.03 ms | 1.54x | 3.33 ms | 1.60 ms | 2.08x | 976 µs | 3.41x | 1.64x |
| 48 | 3.80 ms | 2.51 ms | 1.52x | 4.05 ms | 1.91 ms | 2.12x | 1.22 ms | 3.31x | 1.57x |
| 56 | 4.77 ms | 2.99 ms | 1.59x | 4.94 ms | 2.33 ms | 2.12x | 1.47 ms | 3.36x | 1.59x |
| 64 | 5.43 ms | 3.63 ms | 1.49x | 5.99 ms | 2.63 ms | 2.28x | 1.81 ms | 3.32x | 1.46x |
