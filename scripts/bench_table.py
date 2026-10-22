import argparse
import csv
import pathlib

BASELINES = {
    "float (min/max)": ["float (bool)"],
    "__half (min/max)": ["__half (bool)"],
    "__half2 (min/max)": ["__half (bool)", "__half (min/max)"],
}


def read_rows(path):
    with path.open(newline="") as file:
        header, *rows = csv.reader(file)
    # nvbench leaves out the timing columns if every state was skipped
    if "GPU Time (sec)" not in header:
        return []
    # "Noise" appears twice, for CPU and GPU time, so look columns up by position
    gpu_time = header.index("GPU Time (sec)")
    columns = {name: header.index(name) for name in ("Device Name", "Case", "Length", "Size (pow2)", "Skipped")}
    return [
        {
            "device": row[columns["Device Name"]],
            "case": row[columns["Case"]],
            "length": int(row[columns["Length"]]),
            "size": row[columns["Size (pow2)"]],
            "time": float(row[gpu_time]),
            # nvbench writes the noise to the CSV as a fraction, not in percent
            "noise": float(row[gpu_time + 1]) * 100,
        }
        for row in rows
        if row[columns["Skipped"]] == "No"
    ]


def only(rows, key):
    values = {row[key] for row in rows}
    if len(values) != 1:
        raise SystemExit(f"Expected results for one {key}, got: {', '.join(sorted(map(str, values)))}")
    return values.pop()


def format_time(seconds):
    return f"{seconds * 1e6:.0f} µs" if seconds < 1e-3 else f"{seconds * 1e3:.2f} ms"


def to_markdown(rows, device, size):
    cases = list(dict.fromkeys(row["case"] for row in rows))
    times = {(row["case"], row["length"]): row["time"] for row in rows}
    max_noise = max(row["noise"] for row in rows)
    # A baseline filtered out of the run gets no speedup column
    speedups = {case: [b for b in BASELINES.get(case, []) if b in cases] for case in cases}

    header = ["Length"]
    for case in cases:
        header.append(f"`{case}`")
        header.extend(f"Speedup vs `{baseline}`" for baseline in speedups[case])

    lines = [
        f"Device: {device}. Results per case: {size}. GPU time, noise at most {max_noise:.2f}%.",
        "",
        "| " + " | ".join(header) + " |",
        "|" + "---|" * len(header),
    ]
    for length in sorted({row["length"] for row in rows}):
        cells = [str(length)]
        for case in cases:
            time = times[(case, length)]
            cells.append(format_time(time))
            cells.extend(f"{times[(baseline, length)] / time:.2f}x" for baseline in speedups[case])
        lines.append("| " + " | ".join(cells) + " |")
    return "\n".join(lines) + "\n"


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("csv", type=pathlib.Path, help="nvbench --csv output of bench_kth")
    parser.add_argument("--out-dir", type=pathlib.Path, required=True)
    args = parser.parse_args()

    rows = read_rows(args.csv)
    if not rows:
        raise SystemExit("No results: every benchmark state was skipped")
    device = only(rows, "device")
    table = to_markdown(rows, device, only(rows, "size"))
    args.out_dir.mkdir(parents=True, exist_ok=True)
    (args.out_dir / f"bench_kth_{device.lower().replace(' ', '_')}.md").write_text(f"# bench_kth\n\n{table}")
    print(table)


if __name__ == "__main__":
    main()
