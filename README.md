# Furin21 · Hyprland Ubuntu 24.04 Dotfiles

A complete, ready-to-run Hyprland desktop configuration for **Ubuntu 24.04 LTS**, updated for **Hyprland 0.53+** syntax.

## One-Line Install

```bash
bash <(curl -sL https://raw.githubusercontent.com/Furin21/Ubuntu-Hyprland-Config/main/install.sh)
```

The script installs everything: Hyprland, all Wayland tools, dependencies, fonts, and these dotfiles. Just run it as your normal user.

## What Gets Installed

| Component | Package |
|---|---|
| Window manager | Hyprland (via PPA) + hyprlock + hypridle |
| Bar | Waybar |
| Notifications | swaync |
| Terminal | kitty |
| App launcher | rofi |
| Wallpaper | swww |
| Clipboard history | cliphist |
| Colour scheme | wallust |
| Scratchpad manager | pyprland |
| Screenshot | grim + slurp + swappy |
| Audio | PipeWire + PulseAudio + pamixer |
| Fonts | JetBrains Mono Nerd Font |

## Post-Install Steps

1. Drop at least one wallpaper into `~/Pictures/wallpapers/`
2. Log out, then select **Hyprland** in your display manager
   - GDM: click the gear icon at the bottom-right before logging in
3. On first launch, `initial-boot.sh` runs automatically to apply the default wallpaper and colour theme — wait ~5 seconds

## Keybinds

| Keys | Action |
|---|---|
| `SUPER + Return` | Terminal (kitty) |
| `SUPER + D` | App launcher (rofi) |
| `SUPER + W` | Wallpaper picker |
| `SUPER + E` | Quick edit config |
| `SUPER + Q` | Close window |
| `SUPER + F` | Fullscreen |
| `SUPER + SHIFT + F` | Toggle float |
| `SUPER + SHIFT + S` | Screenshot (area → clipboard) |
| `SUPER + SHIFT + N` | Notification centre |
| `SUPER + H` | Keybind help |
| `SUPER + S` | Google search (rofi) |
| `SUPER + ALT + V` | Clipboard manager |
| `SUPER + ALT + E` | Emoji picker |
| `CTRL + ALT + L` | Lock screen |
| `CTRL + ALT + P` | Power menu |
| `CTRL + ALT + W` | Random wallpaper |
| `SUPER + Tab` | Next workspace |
| `SUPER + SHIFT + Tab` | Previous workspace |
| `SUPER + [1-0]` | Switch to workspace |
| `SUPER + SHIFT + [1-0]` | Move window to workspace |
| `SUPER + SHIFT + B` | Toggle hide/show waybar |
| `SUPER + CTRL + B` | Waybar style menu |
| `SUPER + ALT + B` | Waybar layout menu |
| `SUPER + ALT + R` | Refresh waybar/swaync/rofi |
| `SUPER + SHIFT + G` | Game mode (toggle animations) |

## Config Structure

```
~/.config/
├── hypr/
│   ├── configs/          # Core Hyprland config (keybinds, animations, etc.)
│   ├── UserConfigs/      # User-editable settings (theme, monitors, startup)
│   ├── scripts/          # Helper scripts (volume, lock, screenshots, etc.)
│   └── UserScripts/      # User scripts (wallpaper, quick edit, etc.)
├── waybar/
│   ├── configs/          # Multiple bar layouts
│   └── style/            # Multiple CSS themes
├── kitty/                # Terminal config
├── wlogout/              # Power menu config
└── wallust/              # Colour scheme generator config
```

## Re-run Any Time

The installer is idempotent — already-installed components are skipped:

```bash
bash <(curl -sL https://raw.githubusercontent.com/Furin21/Ubuntu-Hyprland-Config/main/install.sh)
```

## Credits

Based on [JaKooLit/Hyprland-Dots](https://github.com/JaKooLit/Hyprland-Dots), adapted and updated for Ubuntu 24.04 with Hyprland 0.53+ syntax.
