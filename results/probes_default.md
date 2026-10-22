# probes_default

| kernel | arch | compare | select | min/max | permute | total | opcodes in classes |
|---|---|---|---|---|---|---|---|
| `get_kth_order<__half, 16, 8, Less<__half>>` | sm_120 | 32 | 111 | 0 | 62 | 235 | HSETP2 32, PRMT 62, SEL 111 |
| `get_kth_order<__half, 16, 8, Less<__half>>` | sm_80 | 32 | 111 | 0 | 62 | 233 | HSETP2 32, PRMT 62, SEL 111 |
| `get_kth_order<__half, 16, 8, Less<__half>>` | sm_87 | 33 | 111 | 0 | 62 | 253 | HSETP2 32, ISETP 1, PRMT 62, SEL 111 |
| `get_kth_order<__half, 16, 8, Less<__half>>` | sm_90 | 32 | 111 | 0 | 62 | 235 | HSETP2 32, PRMT 62, SEL 111 |
| `get_kth_order<__half, 40, 20, Less<__half>>` | sm_120 | 152 | 567 | 0 | 302 | 1075 | HSETP2 152, PRMT 302, SEL 567 |
| `get_kth_order<__half, 40, 20, Less<__half>>` | sm_80 | 152 | 567 | 0 | 302 | 1073 | HSETP2 152, PRMT 302, SEL 567 |
| `get_kth_order<__half, 40, 20, Less<__half>>` | sm_87 | 153 | 567 | 0 | 302 | 1094 | HSETP2 152, ISETP 1, PRMT 302, SEL 567 |
| `get_kth_order<__half, 40, 20, Less<__half>>` | sm_90 | 152 | 567 | 0 | 302 | 1075 | HSETP2 152, PRMT 302, SEL 567 |
| `get_kth_order<double, 16, 8, Less<double>>` | sm_120 | 63 | 222 | 0 | 0 | 315 | DSETP 63, FSEL 222 |
| `get_kth_order<double, 16, 8, Less<double>>` | sm_80 | 63 | 222 | 0 | 0 | 313 | DSETP 63, FSEL 222 |
| `get_kth_order<double, 16, 8, Less<double>>` | sm_87 | 64 | 222 | 0 | 0 | 334 | DSETP 63, FSEL 222, ISETP 1 |
| `get_kth_order<double, 16, 8, Less<double>>` | sm_90 | 63 | 222 | 0 | 0 | 315 | DSETP 63, FSEL 222 |
| `get_kth_order<double, 40, 20, Less<double>>` | sm_120 | 303 | 1134 | 0 | 0 | 1491 | DSETP 303, FSEL 1134 |
| `get_kth_order<double, 40, 20, Less<double>>` | sm_80 | 303 | 1134 | 0 | 0 | 1489 | DSETP 303, FSEL 1134 |
| `get_kth_order<double, 40, 20, Less<double>>` | sm_87 | 304 | 1134 | 0 | 0 | 1510 | DSETP 303, FSEL 1134, ISETP 1 |
| `get_kth_order<double, 40, 20, Less<double>>` | sm_90 | 303 | 1134 | 0 | 0 | 1491 | DSETP 303, FSEL 1134 |
| `get_kth_order<float, 16, 8, Less<float>>` | sm_120 | 63 | 111 | 0 | 0 | 204 | FSEL 111, FSETP 63 |
| `get_kth_order<float, 16, 8, Less<float>>` | sm_80 | 63 | 111 | 0 | 0 | 202 | FSEL 111, FSETP 63 |
| `get_kth_order<float, 16, 8, Less<float>>` | sm_87 | 64 | 111 | 0 | 0 | 222 | FSEL 111, FSETP 63, ISETP 1 |
| `get_kth_order<float, 16, 8, Less<float>>` | sm_90 | 63 | 111 | 0 | 0 | 204 | FSEL 111, FSETP 63 |
| `get_kth_order<float, 40, 20, Less<float>>` | sm_120 | 303 | 567 | 0 | 0 | 924 | FSEL 567, FSETP 303 |
| `get_kth_order<float, 40, 20, Less<float>>` | sm_80 | 303 | 567 | 0 | 0 | 922 | FSEL 567, FSETP 303 |
| `get_kth_order<float, 40, 20, Less<float>>` | sm_87 | 304 | 567 | 0 | 0 | 942 | FSEL 567, FSETP 303, ISETP 1 |
| `get_kth_order<float, 40, 20, Less<float>>` | sm_90 | 303 | 567 | 0 | 0 | 924 | FSEL 567, FSETP 303 |
| `get_kth_order<int, 16, 8, Less<int>>` | sm_120 | 0 | 0 | 111 | 0 | 141 | VIMNMX 111 |
| `get_kth_order<int, 16, 8, Less<int>>` | sm_80 | 0 | 0 | 111 | 0 | 139 | IMNMX 111 |
| `get_kth_order<int, 16, 8, Less<int>>` | sm_87 | 1 | 0 | 111 | 0 | 159 | IMNMX 111, ISETP 1 |
| `get_kth_order<int, 16, 8, Less<int>>` | sm_90 | 0 | 0 | 105 | 0 | 135 | VIMNMX 99, VIMNMX3 6 |
| `get_kth_order<int, 40, 20, Less<int>>` | sm_120 | 0 | 0 | 567 | 0 | 621 | VIMNMX 567 |
| `get_kth_order<int, 40, 20, Less<int>>` | sm_80 | 0 | 0 | 567 | 0 | 619 | IMNMX 567 |
| `get_kth_order<int, 40, 20, Less<int>>` | sm_87 | 1 | 0 | 567 | 0 | 640 | IMNMX 567, ISETP 1 |
| `get_kth_order<int, 40, 20, Less<int>>` | sm_90 | 0 | 0 | 562 | 0 | 616 | VIMNMX 557, VIMNMX3 5 |
