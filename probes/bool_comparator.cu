#include "kernels.cuh"

// Different data types to inspect SASS for
template __global__ void get_kth_order<int, 16, 8, Less<int>>(const int*, int*);
template __global__ void get_kth_order<int, 40, 20, Less<int>>(const int*, int*);
template __global__ void get_kth_order<float, 16, 8, Less<float>>(const float*, float*);
template __global__ void get_kth_order<float, 40, 20, Less<float>>(const float*, float*);
template __global__ void get_kth_order<double, 16, 8, Less<double>>(const double*, double*);
template __global__ void get_kth_order<double, 40, 20, Less<double>>(const double*, double*);
template __global__ void get_kth_order<__half, 16, 8, Less<__half>>(const __half*, __half*);
template __global__ void get_kth_order<__half, 40, 20, Less<__half>>(const __half*, __half*);
