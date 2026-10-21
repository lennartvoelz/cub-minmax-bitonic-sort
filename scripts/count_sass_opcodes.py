import argparse
import collections
import pathlib
import re
import subprocess

# Opcode classes: compare-exchange/minmax instructions
CLASSES = {
    "compare": re.compile(r"^[A-Z]*SETP\d*$"),  # ISETP, FSETP, HSETP2
    "select": re.compile(r"^F?SEL$"),
    "min/max": re.compile(r"^[A-Z]*MNMX\d*$"),  # IMNMX, FMNMX, HMNMX2
    "permute": re.compile(r"^PRMT$"),
}

FUNCTION_RE = re.compile(r"Function : (\S+)")
ARCH_RE = re.compile(r"arch = (sm_\d+\w*)")
# Instruction lines look like: /*0080*/  @!P0 FSEL R3, R4, R5, P1 ;
INSTRUCTION_RE = re.compile(r"/\*[0-9a-f]{4}\*/\s+(?:@!?U?P\w+\s+)?([A-Z][A-Z0-9_]*)")


def disassemble(objects):
    return "".join(
        subprocess.run(
            ["cuobjdump", "-sass", obj], check=True, capture_output=True, text=True
        ).stdout
        for obj in objects
    )


def demangle(names):
    result = subprocess.run(
        ["cu++filt"], input="\n".join(names), check=True, capture_output=True, text=True
    )
    # "void sort_kernel<float, (int)16, less_t>(T1 *)" -> "sort_kernel<float, 16, less_t>"
    short = (re.sub(r"^void |\(\w+\)|\([^()]*\)$", "", name) for name in result.stdout.splitlines())
    return dict(zip(names, short))


def count_opcodes(sass):
    counts = collections.defaultdict(collections.Counter)
    arch = function = None
    for line in sass.splitlines():
        if m := ARCH_RE.search(line):
            arch = m.group(1)
        elif m := FUNCTION_RE.search(line):
            function = m.group(1)
        elif (m := INSTRUCTION_RE.search(line)) and function:
            counts[(function, arch)][m.group(1)] += 1
    return counts


def classify(opcodes):
    row = dict.fromkeys(CLASSES, 0)
    for opcode, n in opcodes.items():
        for name, pattern in CLASSES.items():
            if pattern.match(opcode):
                row[name] += n
                break
    # NOPs pad the end of every kernel and say nothing about the network
    row["total"] = sum(n for opcode, n in opcodes.items() if opcode != "NOP")
    return row


def to_markdown(counts):
    names = demangle(sorted({function for function, _ in counts}))
    header = ["kernel", "arch", *CLASSES, "total", "opcodes in classes"]
    lines = ["| " + " | ".join(header) + " |", "|" + "---|" * len(header)]
    for (function, arch), opcodes in sorted(counts.items()):
        row = classify(opcodes)
        detail = ", ".join(
            f"{op} {n}"
            for op, n in sorted(opcodes.items())
            if any(p.match(op) for p in CLASSES.values())
        )
        cells = [f"`{names[function]}`", arch, *(str(row[c]) for c in CLASSES), str(row["total"]), detail]
        lines.append("| " + " | ".join(cells) + " |")
    return "\n".join(lines) + "\n"


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--out-dir", type=pathlib.Path, required=True)
    parser.add_argument(
        "--objects",
        nargs="+",
        action="append",
        metavar=("TARGET", "OBJECT"),
        required=True,
        help="probe target name followed by its object files",
    )
    args = parser.parse_args()

    args.out_dir.mkdir(parents=True, exist_ok=True)
    for target, *objects in args.objects:
        sass = disassemble(objects)
        (args.out_dir / f"{target}.sass").write_text(sass)
        table = to_markdown(count_opcodes(sass))
        (args.out_dir / f"{target}.md").write_text(f"# {target}\n\n{table}")
        print(f"## {target}\n\n{table}")


if __name__ == "__main__":
    main()
