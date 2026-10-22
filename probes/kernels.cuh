#pragma once

#include <cuda_fp16.h>

#include <cub/warp/warp_bitonic_sort.cuh>

#include <cuda/functional>

// Default comparator
template <typename T>
struct Less
{
  __forceinline__ __device__ bool operator()(const T a, const T b) const
  {
    return a < b;
  }
};

// Min/Max comparator; only valid for keys without NaN
template <typename T>
struct MinMaxComparator
{
  __forceinline__ __device__ T max(const T a, const T b) const
  {
    return cuda::maximum<T>{}(a, b);
  }

  __forceinline__ __device__ T min(const T a, const T b) const
  {
    return cuda::minimum<T>{}(a, b);
  }
};

// Specialized comparator for packed __half2
template <>
struct MinMaxComparator<__half2>
{
  __forceinline__ __device__ __half2 max(const __half2 a, const __half2 b) const
  {
    return __hmax2(a, b);
  }

  __forceinline__ __device__ __half2 min(const __half2 a, const __half2 b) const
  {
    return __hmin2(a, b);
  }
};

// Loads the array of this thread into registers and sorts it
template <typename T, int Length, typename Op>
__forceinline__ __device__ void sort_thread_array(const T* arrays, T (&keys)[Length])
{
  using SortT = cub::detail::WarpBitonicSort<T, Length, 1>;
  typename SortT::TempStorage sort_storage;

  const int tid = static_cast<int>(blockIdx.x * blockDim.x + threadIdx.x);
  for (int i = 0; i < Length; ++i)
  {
    keys[i] = arrays[tid * Length + i];
  }

  SortT{sort_storage}.Sort(keys, Op{});
}

// k-th order statistic of one array per thread
template <typename T, int Length, int K, typename Op>
__global__ void get_kth_order(const T* arrays, T* kth_orders)
{
  static_assert(0 <= K && K < Length, "K must index into the array");

  T keys[Length];
  sort_thread_array<T, Length, Op>(arrays, keys);

  // Storing the result keeps the compiler from removing the sort
  const int tid   = static_cast<int>(blockIdx.x * blockDim.x + threadIdx.x);
  kth_orders[tid] = keys[K];
}

// Sorts one array per thread in place
template <typename T, int Length, typename Op>
__global__ void sort_arrays(T* arrays)
{
  T keys[Length];
  sort_thread_array<T, Length, Op>(arrays, keys);

  const int tid = static_cast<int>(blockIdx.x * blockDim.x + threadIdx.x);
  for (int i = 0; i < Length; ++i)
  {
    arrays[tid * Length + i] = keys[i];
  }
}
