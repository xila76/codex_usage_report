#!/usr/bin/env bash
set -euo pipefail

MESSAGE_TITLE=${NOTIFY_TITLE:-"Codex quota"}
MESSAGE_BODY=${NOTIFY_MESSAGE:-"Le quota Codex est de nouveau disponible."}
IOS_SHORTCUT=${IOS_SHORTCUT_NAME:-}
NTFY_TOPIC=${NTFY_TOPIC:-}
POLL_INTERVAL=${POLL_INTERVAL:-300}
LOG_FILE=${WATCH_LOG_FILE:-}

log_line() {
  local line=$1
  local timestamp
  timestamp=$(date '+%Y-%m-%d %H:%M:%S')
  printf '[%s] %s\n' "$timestamp" "$line"
  if [[ -n "$LOG_FILE" ]]; then
    printf '[%s] %s\n' "$timestamp" "$line" >>"$LOG_FILE"
  fi
}

if ! [[ $POLL_INTERVAL =~ ^[0-9]+$ ]] || (( POLL_INTERVAL <= 0 )); then
  log_line "Valeur de POLL_INTERVAL invalide ('$POLL_INTERVAL'), utilisation de 300 secondes."
  POLL_INTERVAL=300
fi

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
    log_line "⚠️  Notification non envoyée automatiquement. Message: $message"
  else
    log_line "🔔 Notification envoyée ($message)."
  fi
}

cooldown_from_output() {
  local output=$1
  grep -i "Estimated recharge in:" <<<"$output" | tail -n 1 || true
}

default_command() {
  if command -v codex_usage_report >/dev/null 2>&1; then
    COMMAND=(codex_usage_report)
    return
  fi

  if [[ -x "./dist/codex_usage_report" ]]; then
    COMMAND=("./dist/codex_usage_report")
    return
  fi

  COMMAND=(go run ./cmd/codex_usage_report)
}

format_eta() {
  local seconds=$1
  python3 - "$seconds" <<'PY'
import datetime
import sys

seconds = int(sys.argv[1])
eta = datetime.datetime.now() + datetime.timedelta(seconds=seconds)
print(eta.strftime('%Y-%m-%d %H:%M:%S'))
PY
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
  log_line "Surveillance démarrée en mode manuel (notification immédiate si délai nul)."
  cooldown_line=$manual_text
else
  if (( $# )); then
    COMMAND=("$@")
  else
    default_command
  fi

  log_line "Surveillance démarrée. Commande surveillée: ${COMMAND[*]} (intervalle: ${POLL_INTERVAL}s)."

  while true; do
    if [[ -n "${COMMAND[*]:-}" ]]; then
      output="$(${COMMAND[@]})"
    else
      echo "Aucune commande à exécuter pour récupérer le quota." >&2
      exit 1
    fi

    log_line "Commande exécutée: ${COMMAND[*]}"
    printf '%s\n' "$output"
    cooldown_line=$(cooldown_from_output "$output")

    if [[ -z "$cooldown_line" ]]; then
      log_line "✅ Aucune ligne de cooldown détectée, notification immédiate."
      notify_all "$MESSAGE_BODY"
      exit 0
    fi

    seconds=$(parse_seconds "$cooldown_line")

    if [[ "$seconds" -le 0 ]]; then
      log_line "✅ Temps restant nul ou invalide, notification immédiate."
      notify_all "$MESSAGE_BODY"
      exit 0
    fi

    eta=$(format_eta "$seconds")
    sleep_duration=$POLL_INTERVAL
    if (( seconds < POLL_INTERVAL )); then
      sleep_duration=$seconds
    fi

    log_line "⏳ Quota en recharge (ligne: '$cooldown_line'). Notification estimée vers $eta. Prochaine vérification dans $sleep_duration secondes."
    sleep "$sleep_duration"
  done
fi

seconds=$(parse_seconds "$cooldown_line")

if [[ "$seconds" -le 0 ]]; then
  log_line "✅ Temps restant nul ou invalide, notification immédiate."
  notify_all "$MESSAGE_BODY"
  exit 0
fi

eta=$(format_eta "$seconds")
log_line "⏳ Cooldown manuel détecté. Notification estimée vers $eta (attente de $seconds secondes)."
sleep "$seconds"
notify_all "$MESSAGE_BODY"
