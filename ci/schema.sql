-- Control monitoring state.
--
-- Three tables, each answering a different question:
--   runs            what was evaluated, when
--   observations    the raw result of one control in one run
--   control_state   the current status of each control, and since when
--   transitions     every time a control changed status — the alert feed

PRAGMA journal_mode = WAL;

CREATE TABLE IF NOT EXISTS runs (
    id               INTEGER PRIMARY KEY AUTOINCREMENT,
    run_uid          TEXT NOT NULL,
    started_at       TEXT NOT NULL,
    target           TEXT NOT NULL,
    facts_path       TEXT NOT NULL,
    namespace        TEXT NOT NULL,
    collector        TEXT,
    collector_ok     INTEGER NOT NULL DEFAULT 1,
    conftest_version TEXT
);

CREATE TABLE IF NOT EXISTS observations (
    run_id    INTEGER NOT NULL REFERENCES runs (id),
    control   TEXT    NOT NULL,
    status    TEXT    NOT NULL CHECK (status IN ('pass', 'fail', 'unknown')),
    findings  TEXT    NOT NULL DEFAULT '[]',
    gaps      TEXT    NOT NULL DEFAULT '[]',
    PRIMARY KEY (run_id, control)
);

-- One row per control. `since` is when it entered its current status, so
-- "how long has this been broken" is a subtraction, not an investigation.
CREATE TABLE IF NOT EXISTS control_state (
    control      TEXT PRIMARY KEY,
    name         TEXT NOT NULL,
    source       TEXT NOT NULL CHECK (source IN ('declared', 'observed')),
    status       TEXT NOT NULL CHECK (status IN ('pass', 'fail', 'unknown')),
    since        TEXT NOT NULL,
    last_checked TEXT NOT NULL,
    last_run_id  INTEGER REFERENCES runs (id),
    findings     TEXT NOT NULL DEFAULT '[]',
    gaps         TEXT NOT NULL DEFAULT '[]'
);

-- Append-only. Reading the rows added since the last alert run is the
-- whole alerting problem.
CREATE TABLE IF NOT EXISTS transitions (
    id          INTEGER PRIMARY KEY AUTOINCREMENT,
    control     TEXT NOT NULL,
    from_status TEXT,
    to_status   TEXT NOT NULL,
    at          TEXT NOT NULL,
    run_id      INTEGER REFERENCES runs (id),
    alerted     INTEGER NOT NULL DEFAULT 0
);

CREATE UNIQUE INDEX IF NOT EXISTS idx_runs_uid ON runs (run_uid, target);
CREATE INDEX IF NOT EXISTS idx_obs_control ON observations (control);
CREATE INDEX IF NOT EXISTS idx_trans_control ON transitions (control, at);
CREATE INDEX IF NOT EXISTS idx_trans_unalerted ON transitions (alerted) WHERE alerted = 0;
