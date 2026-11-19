#!/bin/sh
set -eu

ROOT=$(CDPATH= cd -- "$(dirname "$0")/.." && pwd)
NMAP=${NMAP:-"$ROOT/nmap"}
SCRIPTS="$ROOT/tests/nse-runtime"
TMPDIR=$(mktemp -d "${TMPDIR:-/tmp}/nse-runtime-test.XXXXXX")
trap 'rm -rf "$TMPDIR"' EXIT HUP INT TERM

run_nmap() {
  "$NMAP" -n -sn -Pn --datadir "$ROOT" "$@"
}

extract_lines() {
  name=$1
  file=$2
  sed -n "s/^|_${name}: //p" "$file" | sort
}

printf '%s\n' "== output parity (1270 targets) =="
run_nmap --script="$SCRIPTS/reuse_host.nse" \
  192.0.2-6.1-254 -d > "$TMPDIR/default.out" 2>&1
run_nmap --script="$SCRIPTS/reuse_host.nse" --script-runtime-reuse \
  192.0.2-6.1-254 -d > "$TMPDIR/reused.out" 2>&1
extract_lines reuse_host "$TMPDIR/default.out" > "$TMPDIR/default.lines"
extract_lines reuse_host "$TMPDIR/reused.out" > "$TMPDIR/reused.lines"
diff -u "$TMPDIR/default.lines" "$TMPDIR/reused.lines"
test "$(wc -l < "$TMPDIR/reused.lines")" -eq 1270
grep 'NSE runtime reuse:' "$TMPDIR/reused.out"
grep -E 'hit_rate=[1-9][0-9]*(\.[0-9]+)?%' "$TMPDIR/reused.out"

printf '%s\n' "== same-name global isolation =="
run_nmap \
  --script="$SCRIPTS/isolation_a.nse,$SCRIPTS/isolation_b.nse" \
  --script-runtime-reuse --script-runtime-state=session \
  192.0.2.1-32 -d > "$TMPDIR/isolation.out" 2>&1
extract_lines isolation_a "$TMPDIR/isolation.out" > "$TMPDIR/a.lines"
extract_lines isolation_b "$TMPDIR/isolation.out" > "$TMPDIR/b.lines"
test "$(wc -l < "$TMPDIR/a.lines")" -eq 32
test "$(wc -l < "$TMPDIR/b.lines")" -eq 32
if grep -Ev '^Aa*$' "$TMPDIR/a.lines"; then
  echo "script A observed state from another script" >&2
  exit 1
fi
if grep -Ev '^Bb*$' "$TMPDIR/b.lines"; then
  echo "script B observed state from another script" >&2
  exit 1
fi

printf '%s\n' "== state pollution fallback =="
run_nmap --script="$SCRIPTS/stateful_auto.nse" --script-runtime-reuse \
  192.0.2.1-32 -d > "$TMPDIR/stateful.out" 2>&1
extract_lines stateful_auto "$TMPDIR/stateful.out" > "$TMPDIR/stateful.lines"
if grep -Ev ':[1]$' "$TMPDIR/stateful.lines"; then
  echo "stateful auto script leaked a global across invocations" >&2
  exit 1
fi
grep 'isolation fallback: script=stateful_auto' "$TMPDIR/stateful.out"

printf '%s\n' "== failure continuation =="
run_nmap --script="$SCRIPTS/failure_once.nse" --script-runtime-reuse \
  192.0.2.1-32 -d > "$TMPDIR/failure.out" 2>&1
test "$(extract_lines failure_once "$TMPDIR/failure.out" | wc -l)" -eq 31
grep 'NSE runtime retained after failure: script=failure_once' "$TMPDIR/failure.out"
grep 'NSE runtime reuse:' "$TMPDIR/failure.out"

printf '%s\n' "== timeout retains runtime =="
"$NMAP" -n -sn -Pn --datadir "$ROOT" \
  --script="$SCRIPTS/timeout_retain.nse" --script-runtime-reuse \
  --script-runtime-state=session --script-timeout=1s \
  192.0.2.1-32 -d > "$TMPDIR/timeout.out" 2>&1
grep 'NSE runtime retained after timeout: script=timeout_retain' "$TMPDIR/timeout.out"
grep 'NSE runtime reuse:' "$TMPDIR/timeout.out"

printf '%s\n' "== idle reclamation =="
"$NMAP" -n -Pn -sT -p 1 --max-hostgroup 1 --scan-delay 2s \
  --datadir "$ROOT" --script="$SCRIPTS/reuse_host.nse" \
  --script-runtime-reuse --script-runtime-state=session \
  --script-runtime-idle-timeout=1s 127.0.0.1-3 -d \
  > "$TMPDIR/reclaim.out" 2>&1
grep 'NSE runtime reclaimed: script=reuse_host' "$TMPDIR/reclaim.out"

printf '%s\n' "all NSE runtime reuse checks passed"
