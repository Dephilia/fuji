import sys


def load(path):
    rows = []
    with open(path) as f:
        for line in f:
            name, score = line.strip().split(",")
            rows.append((name, int(score)))
    return rows


def format_row(name, score):
    return _format_row_impl(name, score)


def _format_row_impl(name, score):
    return f"{name:<10}{score:>5}"


def legacy_format(rows):
    out = []
    for r in rows:
        out.append(str(r))
    return "\n".join(out)


def render_text(rows):
    return "\n".join(format_row(n, s) for n, s in rows)


def main(argv):
    rows = load(argv[1])
    print(render_text(rows))


if __name__ == "__main__":
    main(sys.argv)
