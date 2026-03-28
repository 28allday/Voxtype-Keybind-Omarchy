#!/bin/bash
# ==============================================================================
# Voxtype Push-to-Talk Key Configurator for Omarchy
#
# Switches Omarchy's Voxtype dictation from toggle mode to push-to-talk.
# Instead of pressing Super+Ctrl+X to start and again to stop, you hold
# any key of your choice to dictate and release it to stop — like a
# walkie-talkie.
#
# The script uses wev (Wayland Event Viewer) to detect which key you press,
# then configures Hyprland keybindings to use that key for push-to-talk.
#
# Three options:
#   1. Bind any regular key (e.g. F13, Scroll Lock, a macro key)
#   2. Bind a modifier key (Ctrl, Alt, Shift, Caps Lock)
#   3. Restore the default Super+Ctrl+X binding
#
# The keybind uses Hyprland's 'i' flag to ignore other modifiers, so the
# push-to-talk key works regardless of what other keys you're holding.
# ==============================================================================

set -euo pipefail

CONFIG_FILE="$HOME/.local/share/omarchy/default/hypr/bindings/utilities.conf"
KEY=""
KEYCODE=""

# wev (Wayland Event Viewer) opens a small window that captures all input
# events and prints them. We use it to detect which key the user presses
# so we can bind it. It's the Wayland equivalent of xev.
if ! command -v wev &>/dev/null; then
    echo "Installing wev (Wayland event viewer)..."
    sudo pacman -S --noconfirm wev || { echo "Failed to install wev"; exit 1; }
fi

# Detects a regular (non-modifier) key press using wev.
# Opens a small window for 5 seconds, captures key events, then parses
# the output to find the keycode and key name. Filters out modifier keys
# and Enter (which the user just pressed to launch the detection).
detect_key_press() {
    local tmpfile
    tmpfile=$(mktemp)
    trap "rm -f '$tmpfile'" EXIT

    echo ""
    echo "A small window will open. Press the key you want to use for push-to-talk."
    echo "The window will close after 5 seconds."
    echo ""
    read -rp "Press Enter to continue..."

    # Capture wev output for 5 seconds using script to handle TTY properly
    script -q -c "timeout 5 wev" "$tmpfile" >/dev/null 2>&1 || true

    if [[ ! -s "$tmpfile" ]]; then
        echo "Error: No output captured from wev"
        exit 1
    fi

    # Find all key press events, filter out modifiers and Enter, get the last real key
    # Format: line with "key: KEYCODE; ... state: 1 (pressed)" followed by line with "sym: KEYNAME"
    local key_press_line
    key_press_line=$(grep "state: 1 (pressed)" "$tmpfile" \
        | grep -v -E "key: (36|50|62|37|105|64|108|133|134|66);" \
        | tail -1)

    # Extract keycode from the press line (e.g., "key: 201;" -> 201)
    KEYCODE=$(echo "$key_press_line" | sed -n 's/.*key: \([0-9]*\);.*/\1/p')

    # Get the key name from the following sym line
    local line_num
    line_num=$(grep -n "state: 1 (pressed)" "$tmpfile" | grep "key: ${KEYCODE};" | tail -1 | cut -d: -f1)
    if [[ -n "$line_num" ]]; then
        KEY=$(sed -n "$((line_num + 1))p" "$tmpfile" | sed -n 's/.*sym: \([^ ]*\).*/\1/p')
    fi

    if [[ -z "$KEYCODE" ]]; then
        echo "Error: No key press detected. Make sure to press a key in the wev window."
        exit 1
    fi

    echo ""
    echo "Detected key: $KEY (keycode: $KEYCODE)"
    echo ""
    read -rp "Use this key for push-to-talk? [Y/n]: " confirm
    if [[ "$confirm" =~ ^[Nn]$ ]]; then
        echo "Aborted."
        exit 0
    fi
}

# Detects a modifier key press (Ctrl, Alt, Shift, Caps Lock, Super).
# Similar to detect_key_press but doesn't filter out modifiers. Warns
# the user if the detected key isn't a typical modifier.
detect_modifier_key() {
    local tmpfile
    tmpfile=$(mktemp)
    trap "rm -f '$tmpfile'" EXIT

    echo ""
    echo "A small window will open. Press the modifier key you want to use."
    echo "(Ctrl, Alt, Shift, or Caps Lock)"
    echo "The window will close after 5 seconds."
    echo ""
    read -rp "Press Enter to continue..."

    # Capture wev output for 5 seconds
    script -q -c "timeout 5 wev" "$tmpfile" >/dev/null 2>&1 || true

    if [[ ! -s "$tmpfile" ]]; then
        echo "Error: No output captured from wev"
        exit 1
    fi

    # For modifier keys, look for the first key press (they're not filtered)
    local key_press_line
    key_press_line=$(grep "state: 1 (pressed)" "$tmpfile" \
        | grep -v "key: 36;" \
        | head -1)

    KEYCODE=$(echo "$key_press_line" | sed -n 's/.*key: \([0-9]*\);.*/\1/p')

    local line_num
    line_num=$(grep -n "state: 1 (pressed)" "$tmpfile" | grep "key: ${KEYCODE};" | head -1 | cut -d: -f1)
    if [[ -n "$line_num" ]]; then
        KEY=$(sed -n "$((line_num + 1))p" "$tmpfile" | sed -n 's/.*sym: \([^ ]*\).*/\1/p')
    fi

    if [[ -z "$KEYCODE" ]]; then
        echo "Error: No key press detected."
        exit 1
    fi

    # Verify it's a modifier key
    if [[ ! "$KEY" =~ ^(Control_L|Control_R|Alt_L|Alt_R|Shift_L|Shift_R|Caps_Lock|Super_L|Super_R)$ ]]; then
        echo ""
        echo "Warning: '$KEY' is not a typical modifier key."
        read -rp "Use it anyway? [y/N]: " confirm
        if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
            echo "Aborted."
            exit 0
        fi
    fi

    echo ""
    echo "Detected: $KEY (keycode: $KEYCODE)"
    echo ""
    read -rp "Use this key for push-to-talk? [Y/n]: " confirm
    if [[ "$confirm" =~ ^[Nn]$ ]]; then
        echo "Aborted."
        exit 0
    fi
}

echo "Voxtype Push-to-Talk Configuration"
echo "==================================="
echo ""
echo "Options:"
echo "  1) Press any key to bind (interactive)"
echo "  2) Press a modifier key to bind (Ctrl, Alt, Shift, Caps Lock)"
echo "  3) Restore default (Super+Ctrl+X)"
echo ""
read -rp "Choice [1]: " choice
choice="${choice:-1}"

case "$choice" in
    1)
        detect_key_press
        ;;
    2)
        detect_modifier_key
        ;;
    3)
        # Restore default
        if [[ ! -f "$CONFIG_FILE" ]]; then
            echo "Error: Config file not found at $CONFIG_FILE"
            exit 1
        fi
        cp "$CONFIG_FILE" "$CONFIG_FILE.backup.$(date +%Y%m%d_%H%M%S)"
        sed -i '/^bind.*voxtype record/d' "$CONFIG_FILE"
        sed -i '/^# Dictation$/a bindd  = SUPER CTRL, X, Start dictation, exec, voxtype record start\nbinddr = SUPER CTRL, X, Stop dictation, exec, voxtype record stop' "$CONFIG_FILE"
        echo ""
        echo "Restored default: Super+Ctrl+X (hold to dictate, release to stop)"
        hyprctl reload
        exit 0
        ;;
    *)
        echo "Invalid choice"
        exit 1
        ;;
esac

if [[ ! -f "$CONFIG_FILE" ]]; then
    echo "Error: Config file not found at $CONFIG_FILE"
    exit 1
fi

if ! grep -q '^# Dictation' "$CONFIG_FILE"; then
    echo "Error: '# Dictation' section not found in config file"
    exit 1
fi

# Create a timestamped backup before modifying the config. This lets users
# restore their previous binding if something goes wrong.
cp "$CONFIG_FILE" "$CONFIG_FILE.backup.$(date +%Y%m%d_%H%M%S)"

# Remove all existing voxtype bindings to start clean. This makes the
# script idempotent — running it multiple times doesn't accumulate bindings.
sed -i '/^bind.*voxtype record/d' "$CONFIG_FILE"

# Use raw keycodes (code:NNN) instead of key names for reliability.
# Key names can vary between keyboard layouts, but keycodes are consistent.
if [[ -z "$KEYCODE" ]]; then
    echo "Error: No keycode detected"
    exit 1
fi
KEY_SPEC="code:$KEYCODE"
KEY_DISPLAY="${KEY:-keycode $KEYCODE}"

# Hyprland bind flags:
#   'i' = ignore modifiers (the PTT key works even if Ctrl/Alt/etc are held)
#   'd' = has a description (shows in keybind help menus)
#   'r' = triggers on key release (used for the "stop" binding)
# Combined: bindid = press handler, bindidr = release handler
BIND_PRESS="bindid"
BIND_RELEASE="bindidr"

# Add the new push-to-talk bindings after the # Dictation comment
sed -i "/^# Dictation\$/a ${BIND_PRESS} = , ${KEY_SPEC}, Start dictation, exec, voxtype record start\n${BIND_RELEASE} = , ${KEY_SPEC}, Stop dictation, exec, voxtype record stop" "$CONFIG_FILE"

echo ""
echo "Switched to push-to-talk using $KEY_DISPLAY"
echo "Hold the key to dictate, release to stop"
hyprctl reload
