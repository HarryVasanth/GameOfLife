#!/usr/bin/env bash
#
# Small self-check for gol.sh. Run: bash bash/test_gol.sh

set -u

here=$(cd "$(dirname "$0")" && pwd)
gol="$here/gol.sh"
fails=0

pass() { printf 'ok   %s\n' "$1"; }
fail() {
    printf 'FAIL %s\n' "$1"
    fails=$((fails + 1))
}

expect_contains() {
    local name=$1 needle=$2 out=$3

    case $out in
    *"$needle"*) pass "$name" ;;
    *) fail "$name" ;;
    esac
}

out=$("$gol" -w 5 -h 5 -p blinker -d 0 -a)
expect_contains "blinker has a period of 2" \
    "repeats every 2 generation(s)" "$out"

first=$("$gol" -w 8 -h 4 -s 12345 -n 3 -d 0 -a)
second=$("$gol" -w 8 -h 4 -s 12345 -n 3 -d 0 -a)
if [[ $first == "$second" ]]; then
    pass "the same seed gives the same run"
else
    fail "the same seed gives the same run"
fi

if "$gol" -w 0 >/dev/null 2>&1; then
    fail "a width of 0 is rejected"
else
    pass "a width of 0 is rejected"
fi

out=$("$gol" -w 6 -h 3 -s 1 -n 1 -d 0 -a)
expect_contains "ASCII mode draws a live cell" "#" "$out"
case $out in
*█*) fail "ASCII mode has no block characters" ;;
*) pass "ASCII mode has no block characters" ;;
esac

out=$("$gol" -w 4 -h 2 -s 1 -n 1 -d 0)
expect_contains "pipe output has frame headers" "--- generation 0 ---" "$out"

printf '\n%d failure(s)\n' "$fails"
((fails == 0))
