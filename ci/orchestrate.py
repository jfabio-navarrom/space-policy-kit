#!/usr/bin/env python3
"""
Control monitoring orchestrator.

    collect -> evaluate -> classify -> append -> index

The durable store is `state/observations.jsonl`: one line per control per
run, appended, never rewritten, kept in git. That file is the evidence
trail, and git makes it timestamped and tamper-evident for free.

The SQLite database is a derived index. It is rebuilt from the log on every
run and can be deleted at any time without losing anything, which is what
makes this safe to run on an ephemeral CI runner.

Two rules this file exists to enforce:

  1. The set of controls that exist comes from the catalogue, never from
     the Conftest output. Conftest reports only what fails, so a policy
     that silently stopped loading would otherwise look like a clean run.

  2. A control that was not evaluated is `unknown`, never `pass`. A missing
     permission, a crashed collector or an empty result must never be able
     to look like compliance.

Usage:
    ci/orchestrate.py                      collect, evaluate, append
    ci/orchestrate.py --reindex-only       rebuild the database from the log
"""

from __future__ import annotations

import argparse
import json
import shutil
import sqlite3
import subprocess
import sys
from datetime import datetime, timezone
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
SCHEMA = Path(__file__).resolve().parent / "schema.sql"


def now() -> str:
    return datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")


def sh(cmd: list[str]) -> subprocess.CompletedProcess:
    return subprocess.run(cmd, capture_output=True, text=True, cwd=ROOT)


# --------------------------------------------------------------- collect

def collect(target: dict) -> bool:
    """Run the target's collector. False means it produced no usable facts."""
    collector = target.get("collector")
    facts = ROOT / target["facts"]
    facts.parent.mkdir(parents=True, exist_ok=True)

    if not collector:
        return facts.exists()

    proc = sh(["bash", collector])
    if proc.returncode != 0 or not proc.stdout.strip():
        print(f"  collector failed: {proc.stderr.strip()[:200]}", file=sys.stderr)
        return False
    try:
        json.loads(proc.stdout)
    except json.JSONDecodeError as exc:
        print(f"  collector produced invalid JSON: {exc}", file=sys.stderr)
        return False

    facts.write_text(proc.stdout)
    return True


# -------------------------------------------------------------- evaluate

def evaluate(target: dict) -> list | None:
    """Run conftest. None means the evaluation did not happen."""
    proc = sh([
        "conftest", "test", target["facts"],
        "--policy", target.get("policy", "policy/"),
        "--namespace", target["namespace"],
        "--output", "json", "--no-color",
    ])
    # Exit 1 is "there are findings", a normal result. Anything else is a
    # broken run, and a broken run must not read as a clean one.
    if proc.returncode not in (0, 1):
        print(f"  conftest error: {proc.stderr.strip()[:300]}", file=sys.stderr)
        return None
    try:
        return json.loads(proc.stdout)
    except json.JSONDecodeError:
        print(f"  conftest output was not JSON: {proc.stdout[:200]}", file=sys.stderr)
        return None


def messages(result: list | None, key: str) -> list[str]:
    out = []
    for block in result or []:
        for item in block.get(key) or []:
            if item.get("msg"):
                out.append(item["msg"])
    return out


def classify(cid: str, failures: list[str], warnings: list[str]):
    """fail beats unknown beats pass."""
    f = [m for m in failures if cid in m]
    g = [m for m in warnings if cid in m]
    if f:
        return "fail", f, g
    if g:
        return "unknown", f, g
    return "pass", f, g


# ----------------------------------------------------------------- index

def apply(conn: sqlite3.Connection, rec: dict) -> str | None:
    """Fold one observation into the index. Returns the previous status."""
    ts, cid = rec["run_at"], rec["control"]

    # Identity is the run's own uid, not its timestamp: two runs can share a
    # second, and collapsing them would silently drop observations.
    uid = rec.get("run_uid", ts)
    row = conn.execute(
        "SELECT id FROM runs WHERE run_uid = ? AND target = ?",
        (uid, rec["target"]),
    ).fetchone()
    if row:
        run_id = row["id"]
    else:
        run_id = conn.execute(
            "INSERT INTO runs (run_uid, started_at, target, facts_path, namespace,"
            " collector, collector_ok, conftest_version)"
            " VALUES (?, ?, ?, ?, ?, ?, ?, ?)",
            (uid, ts, rec["target"], rec.get("facts", ""), rec["namespace"],
             rec.get("collector"), int(rec.get("collector_ok", 1)),
             rec.get("conftest_version", "")),
        ).lastrowid

    conn.execute(
        "INSERT OR REPLACE INTO observations"
        " (run_id, control, status, findings, gaps) VALUES (?, ?, ?, ?, ?)",
        (run_id, cid, rec["status"],
         json.dumps(rec["findings"]), json.dumps(rec["gaps"])),
    )

    prev = conn.execute(
        "SELECT status, since FROM control_state WHERE control = ?", (cid,)
    ).fetchone()
    previous = prev["status"] if prev else None

    if previous != rec["status"]:
        conn.execute(
            "INSERT INTO transitions (control, from_status, to_status, at, run_id)"
            " VALUES (?, ?, ?, ?, ?)",
            (cid, previous, rec["status"], ts, run_id),
        )
        since = ts
    else:
        since = prev["since"]

    conn.execute(
        "INSERT INTO control_state (control, name, source, status, since,"
        " last_checked, last_run_id, findings, gaps)"
        " VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)"
        " ON CONFLICT(control) DO UPDATE SET"
        "   name = excluded.name, source = excluded.source,"
        "   status = excluded.status, since = excluded.since,"
        "   last_checked = excluded.last_checked, last_run_id = excluded.last_run_id,"
        "   findings = excluded.findings, gaps = excluded.gaps",
        (cid, rec["name"], rec["source"], rec["status"], since, ts, run_id,
         json.dumps(rec["findings"]), json.dumps(rec["gaps"])),
    )
    return previous


def reindex(db_path: Path, log_path: Path) -> sqlite3.Connection:
    """Rebuild the index from the log. Dropping the database loses nothing."""
    if db_path.exists():
        db_path.unlink()
    db_path.parent.mkdir(parents=True, exist_ok=True)

    conn = sqlite3.connect(db_path)
    conn.row_factory = sqlite3.Row
    conn.executescript(SCHEMA.read_text())

    if log_path.exists():
        for n, line in enumerate(log_path.read_text().splitlines(), 1):
            line = line.strip()
            if not line:
                continue
            try:
                apply(conn, json.loads(line))
            except (json.JSONDecodeError, KeyError) as exc:
                print(f"  log line {n} is unreadable, skipped: {exc}", file=sys.stderr)
    conn.commit()
    return conn


# ------------------------------------------------------------------ main

def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--config", default="ci/monitor.json")
    ap.add_argument("--db", default="build/state.db")
    ap.add_argument("--log", default="state/observations.jsonl")
    ap.add_argument("--reindex-only", action="store_true")
    args = ap.parse_args()

    log_path = ROOT / args.log
    conn = reindex(ROOT / args.db, log_path)

    if args.reindex_only:
        n = conn.execute("SELECT COUNT(*) c FROM observations").fetchone()["c"]
        print(f"rebuilt the index from {n} observations")
        conn.close()
        return 0

    if not shutil.which("conftest"):
        print("conftest is not on PATH", file=sys.stderr)
        return 2

    config = json.loads((ROOT / args.config).read_text())
    ts = now()
    run_uid = datetime.now(timezone.utc).strftime("%Y%m%dT%H%M%S.%fZ")
    version = sh(["conftest", "--version"]).stdout.split("\n")[0].strip()
    records, changed, failing = [], [], []

    for target in config["targets"]:
        ns = target["namespace"]
        catalogue = [c for c in config["controls"] if c["namespace"] == ns]
        print(f"[{target['name']}] namespace={ns} controls={len(catalogue)}")

        ok = collect(target)
        result = evaluate(target) if ok else None
        failures = messages(result, "failures")
        warnings = messages(result, "warnings")

        for control in catalogue:
            cid = control["id"]
            if result is None:
                reason = "collector failed" if not ok else "policy evaluation failed"
                status, f, g = "unknown", [], [f"[COVERAGE] {cid} | not evaluated: {reason}"]
            else:
                status, f, g = classify(cid, failures, warnings)

            rec = {
                "run_at": ts, "run_uid": run_uid, "target": target["name"], "namespace": ns,
                "facts": target["facts"], "collector": target.get("collector"),
                "collector_ok": ok, "conftest_version": version,
                "control": cid, "name": control["name"], "source": control["source"],
                "status": status, "findings": f, "gaps": g,
            }
            records.append(rec)
            previous = apply(conn, rec)

            mark = {"pass": "  ok  ", "fail": " FAIL ", "unknown": "  ??  "}[status]
            arrow = f"  ({previous or 'new'} -> {status})" if previous != status else ""
            print(f"  {mark} {cid}  {control['name']}{arrow}")

            if previous != status:
                changed.append((cid, previous, status))
            if status == "fail":
                failing.append(cid)

    # Append only after every evaluation succeeded in producing a record, so
    # a crash halfway cannot leave a partial run in the evidence trail.
    log_path.parent.mkdir(parents=True, exist_ok=True)
    with log_path.open("a") as fh:
        for rec in records:
            fh.write(json.dumps(rec, sort_keys=True) + "\n")

    conn.commit()
    conn.close()

    print(f"\n{len(failing)} failing, {len(changed)} changed, "
          f"{len(records)} observations appended")
    for cid, prev, cur in changed:
        print(f"  transition: {cid} {prev or 'new'} -> {cur}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
