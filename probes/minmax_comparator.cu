#include <cuda_fp16.h>

#include <cub/warp/warp_bitonic_sort.cuh>

#include <cuda/functional>

// Min/Max comparator
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

// k-th order statistic of one array per thread
template <typename T, int Length, int K>
__global__ void get_kth_order(const T* arrays, T* kth_order)
{
  static_assert(0 <= K && K < Length, "K must index into the array");

  using SortT = cub::detail::WarpBitonicSort<T, Length, 1>;
  typename SortT::TempStorage sort_storage;

  // Load array into registers
  const int tid = blockIdx.x * blockDim.x + threadIdx.x;

  T keys[Length];

  for (int i = 0; i < Length; ++i)
  {
    keys[i] = arrays[tid * Length + i];
  }

  SortT{sort_storage}.Sort(keys, MinMaxComparator<T>{});

  // Storing the result keeps the compiler from removing the sort
  kth_order[tid] = keys[K];
}

// Different data types to inspect SASS for
template __global__ void get_kth_order<int, 16, 8>(const int*, int*);
template __global__ void get_kth_order<int, 40, 20>(const int*, int*);
template __global__ void get_kth_order<float, 16, 8>(const float*, float*);
template __global__ void get_kth_order<float, 40, 20>(const float*, float*);
template __global__ void get_kth_order<double, 16, 8>(const double*, double*);
template __global__ void get_kth_order<double, 40, 20>(const double*, double*);
template __global__ void get_kth_order<__half, 16, 8>(const __half*, __half*);
template __global__ void get_kth_order<__half, 40, 20>(const __half*, __half*);
// Two independent arrays per thread, one per component
template __global__ void get_kth_order<__half2, 16, 8>(const __half2*, __half2*);
template __global__ void get_kth_order<__half2, 40, 20>(const __half2*, __half2*);

