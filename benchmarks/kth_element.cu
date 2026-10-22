#include <thrust/device_vector.h>

#include <cstddef>
#include <limits>
#include <random>
#include <type_traits>
#include <vector>

#include "../probes/kernels.cuh"
#include <nvbench/nvbench.cuh>

constexpr int threads_per_block = 256;

// k-th element of a sliding window (1D median filter)
// Loads come from shared memory, so computation dominates
template <typename T, int Length, int K, typename Op>
__global__ void sliding_window_kth(const T* input, T* output)
{
  static_assert(0 <= K && K < Length, "K must index into the window");

  __shared__ T tile[threads_per_block + Length - 1];
  const int tid          = static_cast<int>(threadIdx.x);
  const int block_offset = static_cast<int>(blockIdx.x) * threads_per_block;
  for (int i = tid; i < threads_per_block + Length - 1; i += threads_per_block)
  {
    tile[i] = input[block_offset + i];
  }
  __syncthreads();

  T keys[Length];
  for (int i = 0; i < Length; ++i)
  {
    keys[i] = tile[tid + i];
  }

  using SortT = cub::detail::WarpBitonicSort<T, Length, 1>;
  typename SortT::TempStorage sort_storage;
  SortT{sort_storage}.Sort(keys, Op{});

  output[block_offset + tid] = keys[K];
}

// One benchmark case: key type, operator, and results per output (two for __half2, one per component)
template <typename T, typename Op, int Lanes = 1>
struct Case
{
  using key_t                = T;
  using op_t                 = Op;
  static constexpr int lanes = Lanes;
};

using float_bool   = Case<float, Less<float>>;
using float_minmax = Case<float, MinMaxComparator<float>>;
using half_bool    = Case<__half, Less<__half>>;
using half_minmax  = Case<__half, MinMaxComparator<__half>>;
using half2_minmax = Case<__half2, MinMaxComparator<__half2>, 2>;

NVBENCH_DECLARE_TYPE_STRINGS(float_bool, "float (bool)", "");
NVBENCH_DECLARE_TYPE_STRINGS(float_minmax, "float (min/max)", "");
NVBENCH_DECLARE_TYPE_STRINGS(half_bool, "__half (bool)", "");
NVBENCH_DECLARE_TYPE_STRINGS(half_minmax, "__half (min/max)", "");
NVBENCH_DECLARE_TYPE_STRINGS(half2_minmax, "__half2 (min/max)", "");

template <typename T>
T random_key(std::mt19937& rng)
{
  if constexpr (std::is_same_v<T, __half2>)
  {
    const __half low = random_key<__half>(rng);
    return __halves2half2(low, random_key<__half>(rng));
  }
  else
  {
    std::uniform_int_distribution<int> dist(-20, 20);
    return static_cast<T>(dist(rng));
  }
}

template <typename CaseT, int Length>
void kth_element(nvbench::state& state, nvbench::type_list<CaseT, nvbench::enum_type<Length>>)
{
  using T         = typename CaseT::key_t;
  using Op        = typename CaseT::op_t;
  constexpr int K = Length / 2;

  const auto size = state.get_int64("Size");
  if (size > std::numeric_limits<int>::max())
  {
    state.skip("Size must fit into int");
    return;
  }
  const auto num_results = static_cast<int>(size);
  if (num_results % (threads_per_block * CaseT::lanes) != 0)
  {
    state.skip("Size must be a multiple of the block size times the lanes");
    return;
  }
  const int num_outputs = num_results / CaseT::lanes;

  // The network is data-oblivious -> values do not matter
  std::mt19937 rng(1909);
  std::vector<T> h_input(num_outputs + Length - 1);
  for (T& key : h_input)
  {
    key = random_key<T>(rng);
  }
  thrust::device_vector<T> input(h_input.begin(), h_input.end());
  thrust::device_vector<T> output(num_outputs);

  state.add_element_count(static_cast<std::size_t>(num_results), "Results");
  state.add_global_memory_reads<T>(input.size());
  state.add_global_memory_writes<T>(output.size());

  state.exec([&](nvbench::launch& launch) {
    sliding_window_kth<T, Length, K, Op>
      <<<num_outputs / threads_per_block, threads_per_block, 0, launch.get_stream()>>>(
        thrust::raw_pointer_cast(input.data()), thrust::raw_pointer_cast(output.data()));
  });
}

using cases   = nvbench::type_list<float_bool, float_minmax, half_bool, half_minmax, half2_minmax>;
using lengths = nvbench::enum_type_list<16, 32, 40, 48, 56, 64>;

NVBENCH_BENCH_TYPES(kth_element, NVBENCH_TYPE_AXES(cases, lengths))
  .set_type_axes_names({"Case", "Length"})
  .add_int64_power_of_two_axis("Size", {22});
