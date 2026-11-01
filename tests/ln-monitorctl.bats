#!/usr/bin/env bats
# Tests for .local/bin/ln-monitorctl. Only the external `hyprctl` binary is
# stubbed (PATH shim); the script under test runs unmodified.

setup() {
    REPO="$(cd "$BATS_TEST_DIRNAME/.." && pwd)"
    SCRIPT="$REPO/.local/bin/ln-monitorctl"

    STUB_DIR="$BATS_TEST_TMPDIR/stubbin"
    mkdir -p "$STUB_DIR"
    export HYPRCTL_LOG="$BATS_TEST_TMPDIR/hyprctl.log"
    : > "$HYPRCTL_LOG"

    # Fake hyprctl: `monitors all` prints real-format text for $STUB_MONITORS;
    # every invocation's args are logged one line per call.
    cat > "$STUB_DIR/hyprctl" <<'STUB'
#!/usr/bin/env bash
printf '%s\n' "$*" >> "$HYPRCTL_LOG"
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

# Breaks if: the monitor-count check is not numeric (`COUNT > 1` is a string
# test that is always true), so the only display gets disabled.
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
