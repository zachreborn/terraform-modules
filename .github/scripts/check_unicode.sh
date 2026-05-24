#!/usr/bin/env bash
# check_unicode.sh
#
# Scans the repository for invisible and dangerous Unicode characters that can
# silently corrupt Terraform configs, scripts, or documentation.
#
# Categories checked:
#   - Byte Order Mark (BOM)              U+FEFF
#   - Soft Hyphen                        U+00AD
#   - Zero-Width Space                   U+200B
#   - Zero-Width Non-Joiner              U+200C
#   - Zero-Width Non-Breaking Space      U+FEFF (also caught by BOM pattern)
#   - Zero-Width Joiner                  U+200D
#   - Word Joiner                        U+2060
#   - Left-to-Right / Right-to-Left marks U+200E, U+200F
#   - Bidirectional control characters   U+202A–U+202E  (LRE, RLE, PDF, LRO, RLO)
#   - Bidirectional isolates             U+2066–U+2069  (LRI, RLI, FSI, PDI)
#   - "Trojan Source" bidi overrides     U+202D, U+202E (LRO, RLO — subset of above)
#
# Exit codes:
#   0 — no matches found (clean)
#   1 — one or more matches found (CI failure)

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

# PCRE pattern — matches any of the code points listed above.
# Each \x{NNNN} escape matches one Unicode scalar value.
PATTERN=$(
	cat <<'EOF'
[\x{00AD}\x{200B}\x{200C}\x{200D}\x{200E}\x{200F}\x{202A}\x{202B}\x{202C}\x{202D}\x{202E}\x{2060}\x{2066}\x{2067}\x{2068}\x{2069}\x{FEFF}]
EOF
)
# Trim trailing newline introduced by the heredoc
PATTERN="${PATTERN%$'\n'}"

echo "Scanning for invisible Unicode characters in: ${REPO_ROOT}"
echo "Pattern: ${PATTERN}"
echo ""

# grep flags:
#   -r  recursive
#   -P  Perl-compatible regex (required for \x{NNNN} Unicode escapes)
#   -n  print line numbers
#   -l  (not used) — we want file:line detail, not just filenames
#   --include is omitted intentionally — scan all text files
#   -I  skip binary files
#   --exclude-dir skips .git to avoid false positives in git internals
MATCHES=$(grep \
	--recursive \
	--perl-regexp \
	--line-number \
	--binary-files=without-match \
	--exclude-dir=".git" \
	-- "${PATTERN}" "${REPO_ROOT}" 2>/dev/null || true)

if [[ -z "${MATCHES}" ]]; then
	echo "✓ No invisible Unicode characters found."
	exit 0
fi

echo "✗ Invisible Unicode characters detected. Remove them before merging."
echo ""
echo "Matches (file:line:content):"
echo "----------------------------------------------------------------------"
echo "${MATCHES}"
echo "----------------------------------------------------------------------"
echo ""
echo "To locate and remove these manually, run locally:"
echo "  grep -rPn '${PATTERN}' <file>"
echo ""
exit 1
