# probes_minmax

| kernel | arch | compare | select | min/max | permute | total | opcodes in classes |
|---|---|---|---|---|---|---|---|
| `get_kth_order<__half, 16, 8, MinMaxComparator<__half>>` | sm_120 | 0 | 0 | 56 | 42 | 128 | HMNMX2 56, PRMT 42 |
| `get_kth_order<__half, 16, 8, MinMaxComparator<__half>>` | sm_80 | 0 | 0 | 56 | 42 | 126 | HMNMX2 56, PRMT 42 |
| `get_kth_order<__half, 16, 8, MinMaxComparator<__half>>` | sm_87 | 1 | 0 | 56 | 42 | 146 | HMNMX2 56, ISETP 1, PRMT 42 |
| `get_kth_order<__half, 16, 8, MinMaxComparator<__half>>` | sm_90 | 0 | 0 | 56 | 42 | 128 | HMNMX2 50, PRMT 42, VHMNMX 6 |
| `get_kth_order<__half, 40, 20, MinMaxComparator<__half>>` | sm_120 | 0 | 0 | 284 | 166 | 505 | HMNMX2 284, PRMT 166 |
| `get_kth_order<__half, 40, 20, MinMaxComparator<__half>>` | sm_80 | 0 | 0 | 284 | 166 | 502 | HMNMX2 284, PRMT 166 |
| `get_kth_order<__half, 40, 20, MinMaxComparator<__half>>` | sm_87 | 1 | 0 | 284 | 166 | 522 | HMNMX2 284, ISETP 1, PRMT 166 |
| `get_kth_order<__half, 40, 20, MinMaxComparator<__half>>` | sm_90 | 0 | 0 | 284 | 166 | 504 | HMNMX2 279, PRMT 166, VHMNMX 5 |
| `get_kth_order<__half2, 16, 8, MinMaxComparator<__half2>>` | sm_120 | 0 | 0 | 111 | 0 | 141 | HMNMX2 111 |
| `get_kth_order<__half2, 16, 8, MinMaxComparator<__half2>>` | sm_80 | 0 | 0 | 111 | 0 | 139 | HMNMX2 111 |
| `get_kth_order<__half2, 16, 8, MinMaxComparator<__half2>>` | sm_87 | 1 | 0 | 111 | 0 | 159 | HMNMX2 111, ISETP 1 |
| `get_kth_order<__half2, 16, 8, MinMaxComparator<__half2>>` | sm_90 | 0 | 0 | 105 | 0 | 135 | HMNMX2 99, VHMNMX 6 |
| `get_kth_order<__half2, 40, 20, MinMaxComparator<__half2>>` | sm_120 | 0 | 0 | 567 | 0 | 621 | HMNMX2 567 |
| `get_kth_order<__half2, 40, 20, MinMaxComparator<__half2>>` | sm_80 | 0 | 0 | 567 | 0 | 619 | HMNMX2 567 |
| `get_kth_order<__half2, 40, 20, MinMaxComparator<__half2>>` | sm_87 | 1 | 0 | 567 | 0 | 640 | HMNMX2 567, ISETP 1 |
| `get_kth_order<__half2, 40, 20, MinMaxComparator<__half2>>` | sm_90 | 0 | 0 | 562 | 0 | 616 | HMNMX2 557, VHMNMX 5 |
| `get_kth_order<double, 16, 8, MinMaxComparator<double>>` | sm_120 | 111 | 222 | 0 | 0 | 875 | DSETP 111, FSEL 111, SEL 111 |
| `get_kth_order<double, 16, 8, MinMaxComparator<double>>` | sm_80 | 111 | 222 | 0 | 0 | 973 | DSETP 111, FSEL 111, SEL 111 |
| `get_kth_order<double, 16, 8, MinMaxComparator<double>>` | sm_87 | 112 | 222 | 0 | 0 | 993 | DSETP 111, FSEL 111, ISETP 1, SEL 111 |
| `get_kth_order<double, 16, 8, MinMaxComparator<double>>` | sm_90 | 111 | 222 | 0 | 0 | 902 | DSETP 111, FSEL 111, SEL 111 |
| `get_kth_order<double, 40, 20, MinMaxComparator<double>>` | sm_120 | 567 | 1134 | 0 | 0 | 4732 | DSETP 567, FSEL 567, SEL 567 |
| `get_kth_order<double, 40, 20, MinMaxComparator<double>>` | sm_80 | 568 | 1134 | 0 | 0 | 4914 | DSETP 567, FSEL 567, ISETP 1, SEL 567 |
| `get_kth_order<double, 40, 20, MinMaxComparator<double>>` | sm_87 | 568 | 1134 | 0 | 0 | 4915 | DSETP 567, FSEL 567, ISETP 1, SEL 567 |
| `get_kth_order<double, 40, 20, MinMaxComparator<double>>` | sm_90 | 567 | 1134 | 0 | 0 | 4902 | DSETP 567, FSEL 567, SEL 567 |
| `get_kth_order<float, 16, 8, MinMaxComparator<float>>` | sm_120 | 0 | 0 | 111 | 0 | 141 | FMNMX 111 |
| `get_kth_order<float, 16, 8, MinMaxComparator<float>>` | sm_80 | 0 | 0 | 111 | 0 | 139 | FMNMX 111 |
| `get_kth_order<float, 16, 8, MinMaxComparator<float>>` | sm_87 | 1 | 0 | 111 | 0 | 159 | FMNMX 111, ISETP 1 |
| `get_kth_order<float, 16, 8, MinMaxComparator<float>>` | sm_90 | 0 | 0 | 111 | 0 | 141 | FMNMX 111 |
| `get_kth_order<float, 40, 20, MinMaxComparator<float>>` | sm_120 | 0 | 0 | 567 | 0 | 621 | FMNMX 567 |
| `get_kth_order<float, 40, 20, MinMaxComparator<float>>` | sm_80 | 0 | 0 | 567 | 0 | 619 | FMNMX 567 |
| `get_kth_order<float, 40, 20, MinMaxComparator<float>>` | sm_87 | 1 | 0 | 567 | 0 | 640 | FMNMX 567, ISETP 1 |
| `get_kth_order<float, 40, 20, MinMaxComparator<float>>` | sm_90 | 0 | 0 | 567 | 0 | 621 | FMNMX 567 |
| `get_kth_order<int, 16, 8, MinMaxComparator<int>>` | sm_120 | 0 | 0 | 111 | 0 | 141 | VIMNMX 111 |
| `get_kth_order<int, 16, 8, MinMaxComparator<int>>` | sm_80 | 0 | 0 | 111 | 0 | 139 | IMNMX 111 |
| `get_kth_order<int, 16, 8, MinMaxComparator<int>>` | sm_87 | 1 | 0 | 111 | 0 | 159 | IMNMX 111, ISETP 1 |
| `get_kth_order<int, 16, 8, MinMaxComparator<int>>` | sm_90 | 0 | 0 | 105 | 0 | 135 | VIMNMX 99, VIMNMX3 6 |
| `get_kth_order<int, 40, 20, MinMaxComparator<int>>` | sm_120 | 0 | 0 | 567 | 0 | 621 | VIMNMX 567 |
| `get_kth_order<int, 40, 20, MinMaxComparator<int>>` | sm_80 | 0 | 0 | 567 | 0 | 619 | IMNMX 567 |
| `get_kth_order<int, 40, 20, MinMaxComparator<int>>` | sm_87 | 1 | 0 | 567 | 0 | 640 | IMNMX 567, ISETP 1 |
| `get_kth_order<int, 40, 20, MinMaxComparator<int>>` | sm_90 | 0 | 0 | 562 | 0 | 616 | VIMNMX 557, VIMNMX3 5 |
