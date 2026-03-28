#!/bin/bash
# ==============================================================================
# Voxtype Toggle Mode Switcher for Omarchy
#
# Switches Omarchy's Voxtype dictation from the default push-to-talk
# (hold to dictate, release to stop) to toggle mode (press once to start,
# press again to stop).
#
# This is useful if you prefer not to hold a key while dictating, especially
# for longer dictation sessions.
#
# Changes the keybind from:
#   Super+Ctrl+X (press)   → Start dictation
#   Super+Ctrl+X (release) → Stop dictation
# To:
#   Super+Ctrl+X → Toggle dictation on/off
# ==============================================================================

set -euo pipefail

CONFIG_FILE="$HOME/.local/share/omarchy/default/hypr/bindings/utilities.conf"
BACKUP_FILE="$CONFIG_FILE.backup.$(date +%Y%m%d_%H%M%S)"

# Verify the config file exists before we try to modify it.
if [[ ! -f "$CONFIG_FILE" ]]; then
    echo "Error: Config file not found at $CONFIG_FILE"
    exit 1
fi

# Check that the # Dictation section exists
if ! grep -q '^# Dictation' "$CONFIG_FILE"; then
    echo "Error: '# Dictation' section not found in config file"
    exit 1
fi

# Create a timestamped backup so the user can restore their previous config.
cp "$CONFIG_FILE" "$BACKUP_FILE"
echo "Backup created at $BACKUP_FILE"

# Remove ALL existing voxtype bindings — both the press/release pair (push-to-talk)
# and any existing toggle binding. This makes the script idempotent (safe to run
# multiple times without duplicating bindings). Uses line-by-line deletion rather
# than range-based sed, which is safer if the config format changes.
sed -i '/^bindd.*SUPER CTRL, X.*voxtype record/d' "$CONFIG_FILE"
sed -i '/^binddr.*SUPER CTRL, X.*voxtype record/d' "$CONFIG_FILE"

# Add the new toggle binding after the # Dictation section marker.
# 'bindd' = bind with description. 'voxtype record toggle' tells voxtype
# to start if stopped, or stop if recording.
sed -i '/^# Dictation$/a bindd = SUPER CTRL, X, Toggle dictation, exec, voxtype record toggle' "$CONFIG_FILE"

# Verify the change was applied. If sed failed silently (e.g. the comment
# format changed), restore from backup rather than leaving a broken config.
if ! grep -q 'voxtype record toggle' "$CONFIG_FILE"; then
    echo "Error: Failed to add new binding. Restoring backup..."
    cp "$BACKUP_FILE" "$CONFIG_FILE"
    exit 1
fi

echo "Updated voxtype binding to toggle mode."
echo ""
echo "Changed from:"
echo "  Super+Ctrl+X (press)   -> Start dictation"
echo "  Super+Ctrl+X (release) -> Stop dictation"
echo ""
echo "To:"
echo "  Super+Ctrl+X -> Toggle dictation on/off"
echo ""
echo "Reloading Hyprland config..."
hyprctl reload

echo "Done! Press Super+Ctrl+X to toggle dictation."
