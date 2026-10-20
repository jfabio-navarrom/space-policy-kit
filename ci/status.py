#!/usr/bin/env python3
"""
Reads the monitoring database and prints the current state of every control.

    ci/status.py                 current state
    ci/status.py --alerts        transitions not yet notified
    ci/status.py --history C-02  one control over time
    ci/status.py --json          machine readable, for the status page
"""

import argparse
import json
import os
import sqlite3
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--db", default="build/state.db")
    ap.add_argument("--alerts", action="store_true")
    ap.add_argument("--history", metavar="CONTROL")
    ap.add_argument("--json", action="store_true")
    ap.add_argument("--site", metavar="PATH",
                    help="write the status document the dashboard reads")
    args = ap.parse_args()

    path = ROOT / args.db
    if not path.exists():
        print(f"no database at {path}; run ci/orchestrate.py first", file=sys.stderr)
        return 1

    conn = sqlite3.connect(path)
    conn.row_factory = sqlite3.Row

    if args.history:
        rows = conn.execute(
            "SELECT r.started_at, o.status, o.findings, o.gaps"
            " FROM observations o JOIN runs r ON r.id = o.run_id"
            " WHERE o.control = ? ORDER BY o.run_id",
            (args.history,),
        ).fetchall()
        for r in rows:
            print(f"{r['started_at']}  {r['status']:<8} "
                  f"findings={len(json.loads(r['findings']))} "
                  f"gaps={len(json.loads(r['gaps']))}")
        return 0

    if args.alerts:
        rows = conn.execute(
            "SELECT * FROM transitions WHERE alerted = 0 ORDER BY id"
        ).fetchall()
        for r in rows:
            print(f"#{r['id']}  {r['control']}  "
                  f"{r['from_status'] or 'new'} -> {r['to_status']}  {r['at']}")
        return 0

    rows = conn.execute(
        "SELECT control, name, source, status, since, last_checked,"
        " CAST((julianday(last_checked) - julianday(since)) AS INT) AS days,"
        " findings, gaps FROM control_state"
        " ORDER BY CASE status WHEN 'fail' THEN 0 WHEN 'unknown' THEN 1"
        " ELSE 2 END, control"
    ).fetchall()

    controls = [
        {
            "id": r["control"],
            "name": r["name"],
            "source": r["source"],
            "status": r["status"],
            "since": r["since"],
            "days_in_state": r["days"],
            "last_checked": r["last_checked"],
            "findings": json.loads(r["findings"]),
            "coverage_gaps": json.loads(r["gaps"]),
        }
        for r in rows
    ]

    if args.json or args.site:
        last = max((c["last_checked"] for c in controls), default="")
        doc = {
            "generated_at": last,
            "repo": os.environ.get("GITHUB_REPOSITORY", ""),
            "controls": controls,
            "summary": {
                "total": len(controls),
                "failing": sum(1 for c in controls if c["status"] == "fail"),
                "unknown": sum(1 for c in controls if c["status"] == "unknown"),
                "observed": sum(1 for c in controls if c["source"] == "observed"),
                "coverage_gaps": sum(len(c["coverage_gaps"]) for c in controls),
            },
        }
        text = json.dumps(doc, indent=2)
        if args.site:
            out = ROOT / args.site
            out.parent.mkdir(parents=True, exist_ok=True)
            out.write_text(text)
            print(f"wrote {args.site}")
        else:
            print(text)
        return 0

    for r in rows:
        print(f"{r['status']:<8} {r['control']}  {r['name']}")
        print(f"         {r['source']}, unchanged for {r['days']}d, "
              f"last checked {r['last_checked']}")
        for m in json.loads(r["findings"]) + json.loads(r["gaps"]):
            print(f"         - {m}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
