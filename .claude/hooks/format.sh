#!/usr/bin/env bash
# PostToolUse: auto-format edited file. CUSTOMIZE per stack; failures never block.
f=$(jq -r '.tool_input.file_path // ""')
[ -f "$f" ] || exit 0
case "$f" in
  *.ts|*.tsx|*.js|*.jsx|*.json|*.md|*.css) command -v npx >/dev/null && npx --no-install prettier --write "$f" >/dev/null 2>&1 ;;
  *.py) command -v ruff >/dev/null && ruff format "$f" >/dev/null 2>&1 ;;
  *.go) command -v gofmt >/dev/null && gofmt -w "$f" ;;
  *.php) command -v php-cs-fixer >/dev/null && php-cs-fixer fix "$f" -q ;;
esac
exit 0
