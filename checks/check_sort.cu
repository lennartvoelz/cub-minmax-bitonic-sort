#include <thrust/copy.h>
#include <thrust/device_vector.h>

#include <algorithm>
#include <cstdio>
#include <exception>
#include <random>
#include <stdexcept>
#include <string>
#include <vector>

#include "../probes/kernels.cuh"

namespace
{
constexpr int num_arrays        = 1024;
constexpr int threads_per_block = 128;
static_assert(num_arrays % threads_per_block == 0, "The grid has one thread per array and no bounds check");

// Integers from a small range: many duplicates
constexpr int min_key = -20;
constexpr int max_key = 20;

// Fixed seed
constexpr unsigned seed = 1909;

template <typename T, int Length>
std::vector<T> random_keys(std::mt19937& rng)
{
  std::uniform_int_distribution<int> dist(min_key, max_key);
  std::vector<T> keys(num_arrays * Length);
  for (T& key : keys)
  {
    key = static_cast<T>(dist(rng));
  }
  return keys;
}

// Sorts each array of Length keys on the GPU, one array per thread
template <typename T, int Length, typename Op>
std::vector<T> sort_on_gpu(const std::vector<T>& keys)
{
  thrust::device_vector<T> d_keys(keys.begin(), keys.end());
  sort_arrays<T, Length, Op>
    <<<num_arrays / threads_per_block, threads_per_block>>>(thrust::raw_pointer_cast(d_keys.data()));

  const cudaError_t status = cudaGetLastError();
  if (status != cudaSuccess)
  {
    throw std::runtime_error(cudaGetErrorString(status));
  }

  // Copying back synchronizes; throws if the kernel failed
  std::vector<T> sorted(keys.size());
  thrust::copy(d_keys.begin(), d_keys.end(), sorted.begin());
  return sorted;
}

// Compares every sorted array against std::sort
template <typename T, int Length>
bool matches_std_sort(const std::string& name, const std::vector<T>& input, const std::vector<T>& sorted)
{
  for (int array = 0; array < num_arrays; ++array)
  {
    const auto first = input.begin() + array * Length;
    std::vector<T> expected(first, first + Length);
    std::sort(expected.begin(), expected.end());

    for (int i = 0; i < Length; ++i)
    {
      const T actual = sorted[array * Length + i];
      if (actual != expected[i])
      {
        std::printf("FAIL  %s: array %d, index %d: got %g, expected %g\n",
                    name.c_str(),
                    array,
                    i,
                    static_cast<double>(actual),
                    static_cast<double>(expected[i]));
        return false;
      }
    }
  }
  return true;
}

template <typename Body>
bool run_case(const std::string& name, Body body)
{
  try
  {
    const bool passed = body();
    if (passed)
    {
      std::printf("PASS  %s\n", name.c_str());
    }
    return passed;
  }
  catch (const std::exception& error)
  {
    std::printf("FAIL  %s: %s\n", name.c_str(), error.what());
    return false;
  }
}

template <typename T, int Length, typename Op>
bool check(const std::string& name)
{
  return run_case(name, [&] {
    std::mt19937 rng(seed);
    const std::vector<T> keys = random_keys<T, Length>(rng);
    return matches_std_sort<T, Length>(name, keys, sort_on_gpu<T, Length, Op>(keys));
  });
}

// __half2 holds two independent arrays because operator< cannot be used for sorting here
template <int Length>
bool check_half2(const std::string& name)
{
  return run_case(name, [&] {
    std::mt19937 rng(seed);
    const std::vector<__half> low  = random_keys<__half, Length>(rng);
    const std::vector<__half> high = random_keys<__half, Length>(rng);

    std::vector<__half2> keys(low.size());
    std::transform(low.begin(), low.end(), high.begin(), keys.begin(), __halves2half2);

    const std::vector<__half2> sorted = sort_on_gpu<__half2, Length, MinMaxComparator<__half2>>(keys);

    std::vector<__half> sorted_low(sorted.size());
    std::vector<__half> sorted_high(sorted.size());
    std::transform(sorted.begin(), sorted.end(), sorted_low.begin(), __low2half);
    std::transform(sorted.begin(), sorted.end(), sorted_high.begin(), __high2half);

    return matches_std_sort<__half, Length>(name + ", low", low, sorted_low)
        && matches_std_sort<__half, Length>(name + ", high", high, sorted_high);
  });
}
} // namespace

int main()
{
  bool ok = true;

  ok &= check<float, 7, Less<float>>("float, 7, bool");
  ok &= check<float, 16, Less<float>>("float, 16, bool");
  ok &= check<float, 40, Less<float>>("float, 40, bool");
  ok &= check<__half, 40, Less<__half>>("__half, 40, bool");

  ok &= check<int, 7, MinMaxComparator<int>>("int, 7, min/max");
  ok &= check<int, 16, MinMaxComparator<int>>("int, 16, min/max");
  ok &= check<int, 40, MinMaxComparator<int>>("int, 40, min/max");
  ok &= check<float, 7, MinMaxComparator<float>>("float, 7, min/max");
  ok &= check<float, 16, MinMaxComparator<float>>("float, 16, min/max");
  ok &= check<float, 40, MinMaxComparator<float>>("float, 40, min/max");
  ok &= check<double, 7, MinMaxComparator<double>>("double, 7, min/max");
  ok &= check<double, 16, MinMaxComparator<double>>("double, 16, min/max");
  ok &= check<double, 40, MinMaxComparator<double>>("double, 40, min/max");
  ok &= check<__half, 7, MinMaxComparator<__half>>("__half, 7, min/max");
  ok &= check<__half, 16, MinMaxComparator<__half>>("__half, 16, min/max");
  ok &= check<__half, 40, MinMaxComparator<__half>>("__half, 40, min/max");
  ok &= check_half2<7>("__half2, 7, min/max");
  ok &= check_half2<16>("__half2, 16, min/max");
  ok &= check_half2<40>("__half2, 40, min/max");

  std::printf(ok ? "All cases passed\n" : "Some cases failed\n");
  return ok ? 0 : 1;
}
