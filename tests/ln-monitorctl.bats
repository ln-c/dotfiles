#!/usr/bin/env bats
# Tests for .local/bin/ln-monitorctl. Only the external `hyprctl` binary is
# stubbed (PATH shim); the script under test runs unmodified.

bats_require_minimum_version 1.5.0

setup() {
    REPO="$(cd "$BATS_TEST_DIRNAME/.." && pwd)"
    SCRIPT="$REPO/.local/bin/ln-monitorctl"

    STUB_DIR="$BATS_TEST_TMPDIR/stubbin"
    mkdir -p "$STUB_DIR"
    export HYPRCTL_LOG="$BATS_TEST_TMPDIR/hyprctl.log"
    : > "$HYPRCTL_LOG"

    # Fake hyprctl: `monitors all` prints real-format text for $STUB_MONITORS;
    # every invocation's args are logged one line per call. With STUB_FAIL set,
    # every call exits 1 with no output (hyprctl missing/failing/not running).
    cat > "$STUB_DIR/hyprctl" <<'STUB'
#!/usr/bin/env bash
printf '%s\n' "$*" >> "$HYPRCTL_LOG"
if [ -n "$STUB_FAIL" ]; then
    exit 1
fi
if [ "$1" = "monitors" ] && [ "$2" = "all" ]; then
    id=0
    for m in $STUB_MONITORS; do
        printf 'Monitor %s (ID %d):\n' "$m" "$id"
        printf '\t1920x1080@60.00000 at 0x0\n'
        printf '\tdescription: Stub Monitor %s\n' "$m"
        printf '\tmake: Stub\n'
        printf '\tmodel: Stub\n'
        printf '\tscale: 1.00\n'
        printf '\tdisabled: false\n'
        printf '\n'
        id=$((id + 1))
    done
fi
exit 0
STUB
    chmod +x "$STUB_DIR/hyprctl"
    export PATH="$STUB_DIR:$PATH"
}

eval_lines() {
    grep '^eval ' "$HYPRCTL_LOG" || true
}

# Breaks if: validation loop rejects every monitor except the last/only one
# (non-first listed monitors are wrongly "Invalid monitor").
@test "DP-1 off with eDP-1 and DP-1 disables DP-1" {
    export STUB_MONITORS="eDP-1 DP-1"
    run bash "$SCRIPT" DP-1 off
    [ "$status" -eq 0 ]
    grep -Fxq 'eval hl.monitor({ output = "DP-1", disabled = true })' "$HYPRCTL_LOG"
}

# Breaks if: 'on' for a non-first monitor is rejected as invalid.
@test "DP-1 on with eDP-1 and DP-1 enables DP-1" {
    export STUB_MONITORS="eDP-1 DP-1"
    run bash "$SCRIPT" DP-1 on
    [ "$status" -eq 0 ]
    grep -Fxq 'eval hl.monitor({ output = "DP-1", disabled = false })' "$HYPRCTL_LOG"
}

# Breaks if: an unknown monitor is accepted, or an eval is issued for it.
@test "unknown monitor is rejected with Invalid monitor and no eval" {
    export STUB_MONITORS="eDP-1 DP-1"
    run bash "$SCRIPT" HDMI-A-9 off
    [ "$status" -eq 1 ]
    [[ "$output" == *"Invalid monitor"* ]]
    [ -z "$(eval_lines)" ]
}

# Breaks if: `ini` with several monitors exits non-zero (script has `exit 1`)
# or fails to disable the laptop panel eDP-1.
@test "ini with two monitors disables eDP-1 and exits 0" {
    export STUB_MONITORS="eDP-1 DP-1"
    run bash "$SCRIPT" ini
    grep -Fxq 'eval hl.monitor({ output = "eDP-1", disabled = true })' "$HYPRCTL_LOG"
    [ "$status" -eq 0 ]
}

# Breaks if: the monitor-count check is not numeric (a string comparison such
# as `> 1` is always true), so the only display gets disabled.
@test "ini with only eDP-1 does not disable anything and exits 0" {
    export STUB_MONITORS="eDP-1"
    run bash "$SCRIPT" ini
    [ -z "$(eval_lines)" ]
    [ "$status" -eq 0 ]
}

# Regression guard: the first-listed monitor must keep working.
@test "eDP-1 off with eDP-1 and DP-1 disables eDP-1" {
    export STUB_MONITORS="eDP-1 DP-1"
    run bash "$SCRIPT" eDP-1 off
    [ "$status" -eq 0 ]
    grep -Fxq 'eval hl.monitor({ output = "eDP-1", disabled = true })' "$HYPRCTL_LOG"
}

# Breaks if: the Invalid monitor diagnostic is written to stdout instead of
# stderr, or an eval is issued for an unknown monitor. (Regression guard: the
# current script already sends this message to stderr.)
@test "unknown monitor reports Invalid monitor on stderr only, no eval" {
    export STUB_MONITORS="eDP-1 DP-1"
    run --separate-stderr bash "$SCRIPT" HDMI-A-9 off
    [ "$status" -eq 1 ]
    [[ "$stderr" == *"Invalid monitor"* ]]
    [[ "$output" != *"Invalid monitor"* ]]
    [ -z "$(eval_lines)" ]
}

# Breaks if: an invalid action's error goes to stdout instead of stderr, or
# an eval is issued despite the bad action.
@test "invalid action reports on/off usage on stderr only, no eval" {
    export STUB_MONITORS="eDP-1 DP-1"
    run --separate-stderr bash "$SCRIPT" DP-1 sideways
    [ "$status" -eq 1 ]
    [[ "$stderr" == *"'on' or 'off'"* ]]
    [[ "$output" != *"'on' or 'off'"* ]]
    [ -z "$(eval_lines)" ]
}

# Breaks if: a failing hyprctl is misreported as "Invalid monitor" (the failed
# query is not guarded, so the empty monitor list is treated as an unknown
# monitor), or no hyprctl diagnostic is given.
@test "hyprctl failure on DP-1 off reports hyprctl error, not Invalid monitor" {
    export STUB_MONITORS="eDP-1 DP-1"
    export STUB_FAIL=1
    run --separate-stderr bash "$SCRIPT" DP-1 off
    [ "$status" -eq 1 ]
    [[ "$stderr" == *"hyprctl"* ]]
    [[ "$stderr" != *"Invalid monitor"* ]]
    [[ "$output" != *"Invalid monitor"* ]]
    [ -z "$(eval_lines)" ]
}

# Breaks if: `ini` swallows a hyprctl failure and exits 0 silently (a failed
# query yields an empty monitor list that looks like "single monitor"), hiding
# that nothing was checked.
@test "ini with failing hyprctl exits 1 with hyprctl error and no eval" {
    export STUB_MONITORS="eDP-1 DP-1"
    export STUB_FAIL=1
    run --separate-stderr bash "$SCRIPT" ini
    [ "$status" -eq 1 ]
    [[ "$stderr" == *"hyprctl"* ]]
    [ -z "$(eval_lines)" ]
}

# Breaks if: the no-argument help (usage + available monitors) goes to stderr
# instead of stdout, or the monitor names are missing from it. NEW BEHAVIOR:
# help is requested output, not an error diagnostic; exit status stays 1.
@test "no arguments prints usage and monitor names on stdout, stderr empty, exit 1" {
    export STUB_MONITORS="eDP-1 DP-1"
    run --separate-stderr bash "$SCRIPT"
    [[ "$output" == *"Usage"* ]]
    [[ "$output" == *"eDP-1"* ]]
    [[ "$output" == *"DP-1"* ]]
    [ -z "$stderr" ]
    [ "$status" -eq 1 ]
}

# Regression guard (passes already): the monitor list is fetched with exactly
# one `hyprctl monitors all` per run. Breaks if the script queries twice
# (e.g. once for validation and again for the count).
@test "DP-1 off queries hyprctl monitors all exactly once" {
    export STUB_MONITORS="eDP-1 DP-1"
    run bash "$SCRIPT" DP-1 off
    [ "$status" -eq 0 ]
    [ "$(grep -c '^monitors all$' "$HYPRCTL_LOG")" -eq 1 ]
}

# Regression guard (passes already): same single-query property for `ini`.
@test "ini queries hyprctl monitors all exactly once" {
    export STUB_MONITORS="eDP-1 DP-1"
    run bash "$SCRIPT" ini
    [ "$status" -eq 0 ]
    [ "$(grep -c '^monitors all$' "$HYPRCTL_LOG")" -eq 1 ]
}

# Regression guard (passes already): the action defaults to 'off'. Breaks if
# a bare `ln-monitorctl DP-1` does nothing, enables, or is rejected.
@test "DP-1 with no action disables DP-1" {
    export STUB_MONITORS="eDP-1 DP-1"
    run bash "$SCRIPT" DP-1
    [ "$status" -eq 0 ]
    [[ "$output" == *"Disabling DP-1"* ]]
    grep -Fxq 'eval hl.monitor({ output = "DP-1", disabled = true })' "$HYPRCTL_LOG"
}
