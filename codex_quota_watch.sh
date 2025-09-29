#!/usr/bin/env bash
set -euo pipefail

MESSAGE_TITLE=${NOTIFY_TITLE:-"Codex quota"}
MESSAGE_BODY=${NOTIFY_MESSAGE:-"Le quota Codex est de nouveau disponible."}
IOS_SHORTCUT=${IOS_SHORTCUT_NAME:-}
NTFY_TOPIC=${NTFY_TOPIC:-}

parse_seconds() {
  local text=$1
  python3 - "$text" <<'PY'
import re
import sys

text = sys.argv[1].strip()
match = re.search(r"Estimated recharge in:\s*(.*)", text)
if not match:
    print(0)
    raise SystemExit

remaining = match.group(1)
pattern = re.compile(r"(\d+)\s*(seconds?|minutes?|hours?|days?)", re.IGNORECASE)
unit_to_seconds = {
    "second": 1,
    "minute": 60,
    "hour": 3600,
    "day": 86400,
}

total_seconds = 0
for amount, unit in pattern.findall(remaining):
    unit_key = unit.rstrip('s').lower()
    total_seconds += int(amount) * unit_to_seconds.get(unit_key, 0)

print(total_seconds)
PY
}

notify_macos() {
  local message=$1

  if command -v terminal-notifier >/dev/null 2>&1; then
    terminal-notifier -title "$MESSAGE_TITLE" -subtitle "codex_usage_report" -message "$message" || return 1
    return 0
  fi

  if command -v osascript >/dev/null 2>&1; then
    osascript -e "display notification \"$message\" with title \"$MESSAGE_TITLE\" subtitle \"codex_usage_report\"" || return 1
    return 0
  fi

  return 1
}

notify_ios() {
  local message=$1

  if [[ -n "$IOS_SHORTCUT" ]] && command -v shortcuts >/dev/null 2>&1; then
    shortcuts run "$IOS_SHORTCUT" --input "$message" >/dev/null 2>&1 && return 0
  fi

  if [[ -n "$NTFY_TOPIC" ]] && command -v curl >/dev/null 2>&1; then
    curl -fsS -H "Title: $MESSAGE_TITLE" -H "Tags: bell" -d "$message" "https://ntfy.sh/$NTFY_TOPIC" >/dev/null 2>&1 && return 0
  fi

  return 1
}

notify_all() {
  local message=$1
  local macos_sent=1
  local ios_sent=1

  if notify_macos "$message"; then
    macos_sent=0
  fi

  if notify_ios "$message"; then
    ios_sent=0
  fi

  if [[ $macos_sent -ne 0 && $ios_sent -ne 0 ]]; then
    printf '⚠️  Notification non envoyée automatiquement. Message: %s\n' "$message"
  else
    printf '🔔 Notification envoyée (%s).\n' "$message"
  fi
}

cooldown_from_output() {
  local output=$1
  grep -i "Estimated recharge in:" <<<"$output" | tail -n 1 || true
}

default_command() {
  if command -v codex_usage_report >/dev/null 2>&1; then
    COMMAND=(codex_usage_report --timeline)
    return
  fi

  if [[ -x "./dist/codex_usage_report" ]]; then
    COMMAND=("./dist/codex_usage_report" --timeline)
    return
  fi

  COMMAND=(go run ./cmd/codex_usage_report --timeline)
}

manual_text=${COOLDOWN_TEXT:-}

if (( $# >= 2 )) && [[ $1 == "--cooldown-text" || $1 == "--text" ]]; then
  manual_text=$2
  shift 2
elif (( $# == 1 )) && [[ $1 == Estimated* ]]; then
  manual_text=$1
  shift
fi

if [[ -n "$manual_text" ]]; then
  cooldown_line=$manual_text
else
  if (( $# )); then
    COMMAND=("$@")
  else
    default_command
  fi

  while true; do
    if [[ -n "${COMMAND[*]:-}" ]]; then
      output="$(${COMMAND[@]})"
    else
      echo "Aucune commande à exécuter pour récupérer le quota." >&2
      exit 1
    fi

    printf '%s\n' "$output"
    cooldown_line=$(cooldown_from_output "$output")

    if [[ -z "$cooldown_line" ]]; then
      notify_all "$MESSAGE_BODY"
      exit 0
    fi

    seconds=$(parse_seconds "$cooldown_line")

    if [[ "$seconds" -le 0 ]]; then
      notify_all "$MESSAGE_BODY"
      exit 0
    fi

    echo "⏳ Quota en recharge (ligne: '$cooldown_line'). Nouvelle vérification dans $seconds secondes..."
    sleep "$seconds"
  done
fi

seconds=$(parse_seconds "$cooldown_line")

if [[ "$seconds" -le 0 ]]; then
  notify_all "$MESSAGE_BODY"
  exit 0
fi

echo "⏳ Cooldown manuel détecté. Attente de $seconds secondes..."
sleep "$seconds"
notify_all "$MESSAGE_BODY"
