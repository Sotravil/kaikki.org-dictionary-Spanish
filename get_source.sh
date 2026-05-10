#!/usr/bin/env bash
# get_source.sh — Download the kaikki.org Spanish JSONL dump.
#
# Usage:
#   bash get_source.sh
#
# The script places the file next to itself with the canonical name expected
# by build_dictionary_db.py and recorded in dictionary_config.json.
# If the file already exists it is NOT re-downloaded (use --force to override).

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEST="${SCRIPT_DIR}/kaikki.org-dictionary-Spanish.jsonl"
URL="https://kaikki.org/dictionary/Spanish/kaikki.org-dictionary-Spanish.jsonl"

if [[ -f "${DEST}" && "${1:-}" != "--force" ]]; then
  echo "Source file already exists: ${DEST}"
  echo "Run with --force to re-download."
  exit 0
fi

echo "Downloading Spanish dictionary from kaikki.org …"
echo "  URL : ${URL}"
echo "  Dest: ${DEST}"

# curl: show progress bar, follow redirects, resume partial downloads
curl --location --continue-at - --progress-bar --output "${DEST}" "${URL}"

echo ""
echo "Download complete."
echo "File size: $(du -h "${DEST}" | cut -f1)"
echo ""
echo "Next step — build the SQLite database:"
echo "  python3 build_dictionary_db.py \\"
echo "    --jsonl \"${DEST}\" \\"
echo "    --db   \"${SCRIPT_DIR}/dictionary_1_spanish.db\" \\"
echo "    --dictionary-number 1 \\"
echo "    --dictionary-name \"Kaikki Spanish\" \\"
echo "    --reset"
