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
#   2 — grep itself encountered an error (e.g. unsupported flag, PCRE not available)

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
#   -o  print only the matched character, not the full surrounding line;
#       this prevents sensitive line content (tokens, credentials) from
#       leaking into CI logs
#   --include is omitted intentionally — scan all text files
#   -I  skip binary files
#   --exclude-dir skips .git to avoid false positives in git internals
#
# grep exit codes: 0 = matches found, 1 = no matches, 2+ = error.
# We run without error suppression so that any grep failure (unsupported
# --perl-regexp, bad locale, unreadable path, etc.) surfaces immediately
# rather than silently appearing as a clean scan.
# Initialize to 0 so an inherited GREP_EXIT in the caller's environment
# cannot produce a false positive error result.
GREP_EXIT=0
MATCHES=$(grep \
	--recursive \
	--perl-regexp \
	--line-number \
	--only-matching \
	--binary-files=without-match \
	--exclude-dir=".git" \
	-- "${PATTERN}" "${REPO_ROOT}") || GREP_EXIT=$?

# grep exits 1 when it finds no matches — that is the success case.
# Any other non-zero exit means grep itself failed; abort.
if [[ "${GREP_EXIT:-0}" -ge 2 ]]; then
	echo "✗ grep encountered an error (exit ${GREP_EXIT}). Check that grep supports --perl-regexp (GNU grep required)."
	exit 2
fi

if [[ -z "${MATCHES}" ]]; then
	echo "✓ No invisible Unicode characters found."
	exit 0
fi

echo "✗ Invisible Unicode characters detected. Remove them before merging."
echo ""
echo "Matches (file:line: U+XXXX name):"
echo "----------------------------------------------------------------------"
# Decode each matched invisible character to its Unicode code point name.
# Raw line content is intentionally omitted to avoid leaking sensitive
# text (tokens, credentials, keys) that may appear on the same line.
echo "${MATCHES}" | python3 -c "
import sys
NAMES = {
    0x00AD: 'SOFT HYPHEN',
    0x200B: 'ZERO WIDTH SPACE',
    0x200C: 'ZERO WIDTH NON-JOINER',
    0x200D: 'ZERO WIDTH JOINER',
    0x200E: 'LEFT-TO-RIGHT MARK',
    0x200F: 'RIGHT-TO-LEFT MARK',
    0x202A: 'LEFT-TO-RIGHT EMBEDDING',
    0x202B: 'RIGHT-TO-LEFT EMBEDDING',
    0x202C: 'POP DIRECTIONAL FORMATTING',
    0x202D: 'LEFT-TO-RIGHT OVERRIDE',
    0x202E: 'RIGHT-TO-LEFT OVERRIDE',
    0x2060: 'WORD JOINER',
    0x2066: 'LEFT-TO-RIGHT ISOLATE',
    0x2067: 'RIGHT-TO-LEFT ISOLATE',
    0x2068: 'FIRST STRONG ISOLATE',
    0x2069: 'POP DIRECTIONAL ISOLATE',
    0xFEFF: 'ZERO WIDTH NO-BREAK SPACE (BOM)',
}
for line in sys.stdin:
    line = line.rstrip()
    # grep -n -o output: filepath:linenum:CHAR
    # rsplit from right so filepaths containing colons are preserved
    parts = line.rsplit(':', 2)
    if len(parts) == 3:
        filepath, linenum, char = parts
        if char:
            cp = ord(char[0])
            name = NAMES.get(cp, 'UNKNOWN')
            print(f'{filepath}:{linenum}: U+{cp:04X} ({name})')
"
echo "----------------------------------------------------------------------"
echo ""
echo "To locate and remove these manually, run locally:"
echo "  grep -rPno '${PATTERN}' <file>"
echo ""
exit 1
