# Voxtype Keybind - Omarchy

## Video Guide

<p align="center">
  <a href="https://youtu.be/iRutzefEWsg">
    <img src="https://img.youtube.com/vi/iRutzefEWsg/0.jpg" width="700">
  </a>
</p>

Customise how [Voxtype](https://omarchy.com) dictation works in [Omarchy](https://omarchy.com). Switch between push-to-talk (hold to dictate) and toggle mode (press to start/stop), or bind dictation to any key on your keyboard.

## Scripts

| Script | Purpose |
|--------|---------|
| `switch-voxtype-to-ptt.sh` | Set up push-to-talk with any key you choose |
| `switch-voxtype-to-toggle.sh` | Switch to toggle mode (press once to start, again to stop) |

## Quick Start

```bash
git clone https://github.com/28allday/Voxtype-Keybind-Omarchy.git
cd Voxtype-Keybind-Omarchy

# Option 1: Push-to-talk with a custom key
chmod +x switch-voxtype-to-ptt.sh
./switch-voxtype-to-ptt.sh

# Option 2: Toggle mode (Super+Ctrl+X on/off)
chmod +x switch-voxtype-to-toggle.sh
./switch-voxtype-to-toggle.sh
```

## Push-to-Talk Mode

**Hold a key to dictate, release to stop** — like a walkie-talkie.

When you run `switch-voxtype-to-ptt.sh`, you get three options:

| Option | Description |
|--------|-------------|
| **1** | Bind any regular key (F13, Scroll Lock, macro keys, etc.) |
| **2** | Bind a modifier key (Ctrl, Alt, Shift, Caps Lock) |
| **3** | Restore the default (Super+Ctrl+X hold-to-talk) |

### How Key Detection Works

The script uses **wev** (Wayland Event Viewer) to detect which key you press:

1. A small window opens for 5 seconds
2. Press the key you want to use for push-to-talk
3. The window closes and shows the detected key
4. Confirm to apply the binding

The keybind uses the raw **keycode** (not the key name) for reliability across keyboard layouts, and the **'i' flag** to ignore other modifiers — so push-to-talk works regardless of what other keys you're holding.

### Recommended Keys for Push-to-Talk

| Key | Why |
|-----|-----|
| **F13-F24** | Unused by most apps, won't conflict with anything |
| **Scroll Lock** | Rarely used, easy to reach |
| **Caps Lock** | Convenient, but disables caps lock functionality |
| **Mouse side button** | If your mouse supports it via input-remapper |
| **Macro keys** | If your keyboard has dedicated macro keys |

## Toggle Mode

**Press once to start dictating, press again to stop.**

Run `switch-voxtype-to-toggle.sh` to change from the default hold-to-talk to toggle mode using Super+Ctrl+X.

Better for longer dictation sessions where holding a key would be uncomfortable.

## How It Works

Both scripts modify Hyprland's keybinding config at:
```
~/.local/share/omarchy/default/hypr/bindings/utilities.conf
```

They look for the `# Dictation` section and replace the voxtype bindings.

### Push-to-Talk Binding Format

```
bindid  = , code:201, Start dictation, exec, voxtype record start
bindidr = , code:201, Stop dictation, exec, voxtype record stop
```

- `bindid` — triggers on key **press** (i=ignore modifiers, d=has description)
- `bindidr` — triggers on key **release** (r=release)

### Toggle Binding Format

```
bindd = SUPER CTRL, X, Toggle dictation, exec, voxtype record toggle
```

- `bindd` — standard keybind with description

## Backups

Both scripts create a timestamped backup before making changes:
```
utilities.conf.backup.20260328_143000
```

To restore a backup:
```bash
cp ~/.local/share/omarchy/default/hypr/bindings/utilities.conf.backup.TIMESTAMP \
   ~/.local/share/omarchy/default/hypr/bindings/utilities.conf
hyprctl reload
```

## Dependencies

| Dependency | Purpose | Auto-installed? |
|-----------|---------|----------------|
| `wev` | Detects key presses (push-to-talk script only) | Yes |
| `hyprctl` | Reloads Hyprland config after changes | Comes with Hyprland |
| `voxtype` | Omarchy's voice dictation tool | Comes with Omarchy |

## Troubleshooting

### Key detection doesn't work

- Make sure to press the key **inside the wev window**, not the terminal
- Try running `wev` manually to check it works: `wev`

### Binding doesn't work after configuration

- Check the config was updated: `grep voxtype ~/.local/share/omarchy/default/hypr/bindings/utilities.conf`
- Force reload: `hyprctl reload`

### Want to go back to default

Run the push-to-talk script and choose **option 3** (Restore default).

## Credits

- [Omarchy](https://omarchy.com) - The Arch Linux distribution
- [Voxtype](https://omarchy.com) - Voice dictation for Omarchy
- [wev](https://git.sr.ht/~sircmpwn/wev) - Wayland event viewer

## License

This project is provided as-is for the Omarchy community.
