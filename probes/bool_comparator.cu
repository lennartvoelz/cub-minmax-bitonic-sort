#include <cuda_fp16.h>

#include <cub/warp/warp_bitonic_sort.cuh>

// Default comparator
template <typename T>
struct Less
{
  __forceinline__ __device__ bool operator()(const T a, const T b) const
  {
    return a < b;
  }
};

// k-th order statistic of one array per thread
template <typename T, int Length, int K>
__global__ void get_kth_order(const T* arrays, T* kth_orders)
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

  SortT{sort_storage}.Sort(keys, Less<T>{});

  // Storing the result keeps the compiler from removing the sort
  kth_orders[tid] = keys[K];
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
