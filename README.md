# Dictionary 1 — Spanish (Kaikki / Wiktextract)

This folder contains a self-contained Spanish dictionary database used by the
bot's Spanish-context brain (grammar, semantics, theology-aware reasoning, and
future multi-dictionary lookup).

## Upload this folder to GitHub (quick commit guide)

To commit directly to `main` from this repository root (when `main` is not
protected):

If `dictionary_1_spanish.db` is 100 MB or larger, run the Git LFS block below
first, then continue with these commands.

```bash
git checkout main
git pull origin main
git add .
git commit -m "Add/update Spanish dictionary folder files"
git push origin main
```

If this is your first commit in a new clone, set your identity once
(replace the values with your real name/email used on GitHub):

```bash
git config user.name "Your Name"
git config user.email "your.email@example.com"
```

If your files are in another local folder, open PowerShell in the repo root and
copy only the files you want to upload (replace `<source-directory-path>` with
your real folder path):

```powershell
# example: C:\Users\YourName\Documents\kaikki.org-dictionary-Spanish
Copy-Item "<source-directory-path>\*" `
  "." -Recurse -Force
```

Then review what changed:

```bash
git status
```

If `dictionary_1_spanish.db` is 100 MB or larger, set up Git LFS before running
`git add .`:

```bash
git lfs install   # typically needed once per user account
git lfs track "*.db"
git add .gitattributes *.db
git commit -m "Add dictionary database"
git push origin main
```

If `main` is protected in your repo settings, push to a branch and open a PR.

## Files in this folder

| File | Role | Generated? |
|---|---|---|
| `kaikki.org-dictionary-Spanish.jsonl` | **Raw source** — Kaikki / Wiktextract export. Read-only, never modified. | No (source) |
| `dictionary_1_spanish.db` | **The database** — SQLite 3 with FTS5 full-text search. | Yes |
| `dictionary_1_spanish.db-wal` / `.db-shm` | SQLite Write-Ahead-Log sidecars (transient). | Yes |
| `dictionary_config.json` | Self-describing folder manifest (numbers, names, source type). | Yes |
| `import_log.txt` | Build log (milestones, warnings, errors, final summary). | Yes |
| `import_report.json` | Final import statistics (counts, timings, sizes, flags). | Yes |
| `README.md` | This file. | — |

> The `.jsonl` source file is **never** modified, moved, renamed, or deleted by
> any of the tooling. Its size and SHA-256 are recorded in
> `dictionary_files.file_size_bytes` / `file_hash_sha256` and re-verified at the
> end of every import.

---

## What is `dictionary_1_spanish.db`?

A professional, normalized SQLite database produced from the Kaikki Spanish
JSONL export. It is organized in 5 layers:

| Layer | Purpose | Tables / Objects |
|---|---|---|
| **L1 — Metadata** | Track the source, file, and each import run. | `dictionary_sources`, `dictionary_files`, `import_runs`, `raw_entries` |
| **L2 — Core** | The actual dictionary content. | `entries`, `senses`, `examples`, `forms`, `sounds`, `translations` |
| **L3 — Semantic** | Tags, registers, regions, topics, and word-to-word relations. | `labels`, `entry_labels`, `sense_labels`, `linkages` |
| **L4 — Search & Bot** | Diacritic-insensitive FTS, bot context cache, lookup logs, procedure registry. | `search_documents`, `search_fts` (FTS5), `bot_context_packets`, `bot_lookup_logs`, `procedure_registry` |
| **L5 — Views** | Pre-joined convenience views for app code. | `v_entry_summary`, `v_sense_full`, `v_label_words`, `v_etymology`, `v_search`, `v_bot_context_ready`, `v_word_complete`, `v_dictionary_source_summary` |

### Key features

- **FTS5 full-text search** with `unicode61 remove_diacritics 2` —
  searching `accion` matches `acción`; `nino` matches `niño`.
- **`raw_entries` keeps the original JSON** for every line, so anything not yet
  normalized can be recovered without re-parsing the source file.
- **`linkages`** captures synonyms, antonyms, hyper/hypo/holo/meronyms,
  derived/related/coordinate/compounds, alt_of, descendants, etc.
- **Triggers** keep `updated_at` columns and the FTS index in sync automatically.
- **`procedure_registry`** documents the application-side helpers
  (`dictionary_lookup`, `bot_context_lookup`, `theological_context_lookup`, …)
  since SQLite has no real stored procedures.

---

## How to (re)build the database

From the project root in PowerShell:

```powershell
cd 'D:\projectos\fetch wol'
py -3 .\build_dictionary_db.py `
  --jsonl "D:\projectos\fetch wol\dictionaries\dictionary 1\kaikki.org-dictionary-Spanish.jsonl" `
  --db    "D:\projectos\fetch wol\dictionaries\dictionary 1\dictionary_1_spanish.db" `
  --dictionary-number 1 `
  --dictionary-name "Kaikki Spanish" `
  --reset
```

Useful flags:

- `--limit 10000` — test mode, only the first N entries.
- `--no-dashboard` — disable the live progress dashboard (plain log lines).
- `--dashboard-refresh 0.5` — dashboard refresh interval in seconds.
- `--progress-every 5000` — commit + milestone every N lines.

`--reset` deletes only the generated files (`.db`, `.db-wal`, `.db-shm`,
`import_log.txt`, `import_report.json`) and refuses to delete the `.jsonl`.

---

## Quick sanity checks

```powershell
py -3 -c "import sqlite3; con=sqlite3.connect(r'D:\projectos\fetch wol\dictionaries\dictionary 1\dictionary_1_spanish.db'); print('entries:', con.execute('SELECT COUNT(*) FROM entries').fetchone()[0]); print('senses:', con.execute('SELECT COUNT(*) FROM senses').fetchone()[0]); con.close()"
```

### Example SQL queries

```sql
-- Lemma + all its senses, forms, IPA, labels, linkages (one row per entry)
SELECT * FROM v_word_complete WHERE normalized_word = 'accion';

-- Match by inflected form (e.g. "corremos" -> verb "correr")
SELECT e.*
FROM entries e
JOIN forms f ON f.entry_id = e.entry_id
WHERE f.normalized_form = 'corremos';

-- Diacritic-insensitive full-text search (top 20 by FTS rank)
SELECT sd.word, sd.pos, sd.gloss
FROM search_fts
JOIN search_documents sd ON sd.doc_id = search_fts.rowid
WHERE search_fts MATCH 'nino'
ORDER BY rank
LIMIT 20;

-- Synonyms of "rápido"
SELECT lk.target_word
FROM entries e
JOIN linkages lk ON lk.entry_id = e.entry_id
WHERE e.normalized_word = 'rapido' AND lk.relation_type = 'synonyms';

-- Everything ready for the bot's context packet for one sense
SELECT * FROM v_bot_context_ready WHERE normalized_word = 'gracia';
```

---

## Schema diagram (logical)

```
dictionary_sources ─┬─ dictionary_files ─┬─ import_runs
                    │                    └─ raw_entries ──┐
                    │                                     │
                    └─ entries ───┬─ senses ──┬─ examples │
                                  │           ├─ sense_labels ─ labels
                                  │           └─ linkages
                                  ├─ forms
                                  ├─ sounds
                                  ├─ translations
                                  └─ entry_labels ─ labels

search_documents ── (FTS5) search_fts
bot_context_packets, bot_lookup_logs, procedure_registry
```

Views in **L5** flatten the most common joins for app code.

---

## Future: multi-dictionary brain

Each dictionary folder (`dictionary 1/`, `dictionary 2/`, …) is fully
self-contained and uniformly schemed, so a future `spanish_context_brain.db`
can simply attach them:

```sql
ATTACH DATABASE 'D:\projectos\fetch wol\dictionaries\dictionary 1\dictionary_1_spanish.db' AS dict1;
ATTACH DATABASE 'D:\projectos\fetch wol\dictionaries\dictionary 2\dictionary_2_spanish.db' AS dict2;

-- Cross-dictionary lookup with per-source ranking
SELECT 1 AS dict, * FROM dict1.v_word_complete WHERE normalized_word = :q
UNION ALL
SELECT 2 AS dict, * FROM dict2.v_word_complete WHERE normalized_word = :q;
```

`dictionary_number` and `source_id` are first-class columns in every layer,
so cross-dictionary ranking, diff-detection, and merge are straightforward.

---

## Safety guarantees

- The `.jsonl` is opened **read-only** (binary mode for accurate progress);
  the script never writes to it, renames it, or deletes it.
- `--reset` has an explicit safety guard that refuses to delete the source
  JSONL even if `--db` is mis-typed to point at it.
- Every import re-verifies the JSONL's size and SHA-256 against the values
  recorded in `dictionary_files`.
- Per-line errors are caught and counted; a single bad line never aborts the
  whole import.

---

## Source

- **Project**: [Kaikki](https://kaikki.org/) — Wiktextract Spanish JSON dump.
- **Format**: JSON Lines (one entry per line).
- **License**: Inherits from English Wiktionary (CC BY-SA 3.0 / GFDL).
  Refer to `kaikki.org` and Wiktionary for redistribution terms.
