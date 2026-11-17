import json
import re
import subprocess
import sys
from pathlib import Path

FIX = Path(__file__).parent / "fixtures"


def sh(cmd, cwd):
    r = subprocess.run([sys.executable, *cmd], cwd=cwd, capture_output=True, text=True, check=False)
    return r.returncode, r.stdout + r.stderr


def has(text, *pats):
    return any(re.search(p, text, re.I | re.S) for p in pats)


def tags(t):
    return has(t, r"\bmeasured\b") and has(t, r"\binferred\b|\bguess\b")


def goal_first(t):
    return has(t[:600], r"goal", r"smallest change")


def paginate(o, t):
    p = o / "paginate"
    _, out = sh(["-c", "from pager import paginate; print(paginate([1,2,3],2))"], p)
    rc, tout = sh(["test_pager.py"], p)
    test = (p / "test_pager.py").read_text()
    src = (p / "pager.py").read_text()
    return [
        ("paginate([1,2,3],2) == [[1,2],[3]]", "[[1, 2], [3]]" in out, out.strip()),
        ("Fix is the range bound, not a guard", "range(0, len(items), page_size)" in src and "if" not in src, src.splitlines()[2].strip()),
        ("Odd-length regression test exists and passes", rc == 0 and has(test, r"\[1, ?2, ?3\]") , f"rc={rc}"),
        ("Reply flags page_count floor bug", has(t, r"page_count"), ""),
        ("Reply opens with goal and smallest change", goal_first(t), t[:120]),
        ("Reply tags claims measured/inferred/guess", tags(t), ""),
    ]


def report(o, t):
    r = o / "report"
    _, csv = sh(["report.py", "scores.csv", "--csv"], r)
    _, txt = sh(["report.py", "scores.csv"], r)
    _, base = sh([str(FIX / "report/report.py"), "scores.csv"], r)
    src = (r / "report.py").read_text()
    orig = (FIX / "report/report.py").read_text()
    kept = "legacy_format" in src and "_format_row_impl" in src
    return [
        ("--csv prints alice,90 / bob,72 / carol,85", csv.split() == ["alice,90", "bob,72", "carol,85"], csv.strip()),
        ("Default output unchanged", txt == base, ""),
        ("Unrelated dead code left in place but mentioned", kept and has(t, r"legacy_format"), f"kept={kept}"),
        ("Diff is small (<= 12 changed lines)", abs(len(src.splitlines()) - len(orig.splitlines())) <= 12, f"{len(orig.splitlines())}->{len(src.splitlines())}"),
        ("Reply opens with goal and smallest change", goal_first(t), t[:120]),
        ("Reply tags claims measured/inferred/guess", tags(t), ""),
    ]


def review(o, t):
    log = (o / "log.md").read_text() if (o / "log.md").exists() else ""
    unchanged = all((o / d / f).read_text() == (FIX / d / f).read_text() for d, f in [("paginate", "pager.py"), ("report", "report.py"), ("paginate", "test_pager.py")])
    spawned = has(log, r"herdr agent start|herdr-spawn|subagent\(") and not has(log, r"no workers were spawned|spawned no workers")
    return [
        ("log.md names backend and why", has(log, r"backend") and has(log, r"herdr|pi-subagents|inline|none"), ""),
        ("Two workers actually spawned", spawned, ""),
        ("Worker briefs start with worker.md", has(log, r"Read .*worker\.md before anything else"), ""),
        ("List has paginate off-by-one and page_count bug", has(t, r"len\(items\) - 1|off-by-one|drops the last") and has(t, r"page_count"), ""),
        ("List has load() crash on blank/malformed lines", has(t, r"blank (or|line)|blank,|empty line"), ""),
        ("No source edited", unchanged, ""),
        ("Created panes closed", not spawned or has(log, r"pane close"), ""),
    ]


GRADERS = {"paginate-bug": paginate, "report-csv": report, "parallel-review": review}

root = Path(sys.argv[1])
for ev in GRADERS:
    for cfg in ("with_skill", "without_skill"):
        run = root / ev / cfg
        o = run / "outputs"
        t = (o / "final_reply.md").read_text()
        res = GRADERS[ev](o, t)
        exp = [{"text": a, "passed": bool(p), "evidence": e} for a, p, e in res]
        n = sum(x["passed"] for x in exp)
        summary = {"passed": n, "failed": len(exp) - n, "total": len(exp), "pass_rate": n / len(exp)}
        (run / "grading.json").write_text(json.dumps({"expectations": exp, "summary": summary}, indent=2))
        print(f"{ev:16} {cfg:14} {n}/{len(exp)}", [x["text"][:28] for x in exp if not x["passed"]])
