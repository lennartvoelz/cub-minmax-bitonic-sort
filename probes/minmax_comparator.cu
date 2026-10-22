#include "kernels.cuh"

// Different data types to inspect SASS for
template __global__ void get_kth_order<int, 16, 8, MinMaxComparator<int>>(const int*, int*);
template __global__ void get_kth_order<int, 40, 20, MinMaxComparator<int>>(const int*, int*);
template __global__ void get_kth_order<float, 16, 8, MinMaxComparator<float>>(const float*, float*);
template __global__ void get_kth_order<float, 40, 20, MinMaxComparator<float>>(const float*, float*);
template __global__ void get_kth_order<double, 16, 8, MinMaxComparator<double>>(const double*, double*);
template __global__ void get_kth_order<double, 40, 20, MinMaxComparator<double>>(const double*, double*);
template __global__ void get_kth_order<__half, 16, 8, MinMaxComparator<__half>>(const __half*, __half*);
template __global__ void get_kth_order<__half, 40, 20, MinMaxComparator<__half>>(const __half*, __half*);
// Two independent arrays per thread, one per component
template __global__ void get_kth_order<__half2, 16, 8, MinMaxComparator<__half2>>(const __half2*, __half2*);
template __global__ void get_kth_order<__half2, 40, 20, MinMaxComparator<__half2>>(const __half2*, __half2*);
