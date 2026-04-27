#!/usr/bin/env bash
# render_pdf.sh — render a parallel-blueprint markdown plan to PDF.
#
# Usage:
#   render_pdf.sh <input.md> [output.pdf]
#
# Defaults output.pdf to <input>.pdf next to <input>.md.
#
# Dependencies:
#   - pandoc (required)         — `brew install pandoc`
#   - one PDF engine (auto-detected, in this order):
#       xelatex      — `brew install --cask basictex` then `sudo tlmgr install xetex`
#       wkhtmltopdf  — `brew install --cask wkhtmltopdf`
#       weasyprint   — `pip install weasyprint`

set -euo pipefail

if [[ $# -lt 1 || "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
  sed -n '2,16p' "$0" | sed 's/^# \{0,1\}//'
  exit 0
fi

input="$1"
output="${2:-${input%.md}.pdf}"

if [[ ! -f "$input" ]]; then
  echo "error: input file not found: $input" >&2
  exit 2
fi

if ! command -v pandoc >/dev/null 2>&1; then
  cat >&2 <<'EOF'
error: pandoc not found.

Install pandoc, then re-run:
  brew install pandoc

You also need one PDF engine — the script will auto-detect:
  - xelatex (best output):     brew install --cask basictex && sudo tlmgr install xetex
  - wkhtmltopdf (lighter):     brew install --cask wkhtmltopdf
  - weasyprint (Python-based): pip install weasyprint
EOF
  exit 3
fi

# Detect a PDF engine in preference order.
engine_arg=""
engine_name=""
if command -v xelatex >/dev/null 2>&1; then
  engine_arg="--pdf-engine=xelatex"
  engine_name="xelatex"
elif command -v wkhtmltopdf >/dev/null 2>&1; then
  engine_arg="--pdf-engine=wkhtmltopdf"
  engine_name="wkhtmltopdf"
elif command -v weasyprint >/dev/null 2>&1; then
  engine_arg="--pdf-engine=weasyprint"
  engine_name="weasyprint"
else
  cat >&2 <<'EOF'
error: no PDF engine found. Install one of:
  brew install --cask basictex && sudo tlmgr install xetex   # xelatex (recommended)
  brew install --cask wkhtmltopdf                            # wkhtmltopdf
  pip install weasyprint                                     # weasyprint
EOF
  exit 4
fi

echo "rendering $input -> $output (engine: $engine_name)"

# Engine-specific flags. xelatex respects font variables; wkhtmltopdf/weasyprint don't.
common_args=(
  "$input"
  "$engine_arg"
  --toc
  --highlight-style=tango
  -V geometry:margin=1in
  -V colorlinks=true
  -V linkcolor=NavyBlue
  -V urlcolor=NavyBlue
  -V toccolor=NavyBlue
  -o "$output"
)

if [[ "$engine_name" == "xelatex" ]]; then
  common_args+=(-V mainfont="Helvetica Neue" -V monofont="Menlo")
fi

pandoc "${common_args[@]}"

echo "wrote $output"
