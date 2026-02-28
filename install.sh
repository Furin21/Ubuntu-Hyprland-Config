#!/usr/bin/env bash
# ================================================================
#  Furin21 · Hyprland Ubuntu 24.04 · One-Line Installer
# ================================================================
#  bash <(curl -sL https://raw.githubusercontent.com/Furin21/Ubuntu-Hyprland-Config/main/install.sh)
# ================================================================

set -euo pipefail
IFS=$'\n\t'

REPO_URL="https://github.com/Furin21/Ubuntu-Hyprland-Config"
REPO_RAW="https://raw.githubusercontent.com/Furin21/Ubuntu-Hyprland-Config/main"
CONFIG_DEST="$HOME/.config"
TMP_DIR="$(mktemp -d /tmp/hypr-install-XXXXXX)"

# ── Colours ───────────────────────────────────────────────────────
RED='\033[0;31m'; GRN='\033[0;32m'; YLW='\033[1;33m'
BLU='\033[0;34m'; CYN='\033[0;36m'; BOLD='\033[1m'; NC='\033[0m'
info()    { echo -e "${CYN}  →${NC} $*"; }
ok()      { echo -e "${GRN}  ✓${NC} $*"; }
warn()    { echo -e "${YLW}  !${NC} $*"; }
die()     { echo -e "${RED}  ✗ FATAL:${NC} $*"; exit 1; }
section() { echo -e "\n${BOLD}${BLU}── $* ──${NC}"; }

# ── Helpers ───────────────────────────────────────────────────────
gh_latest() {
    # Returns the latest tag for a GitHub repo (e.g. "v1.2.3")
    curl -fsSI "https://github.com/$1/releases/latest" \
        | grep -i '^location:' | awk -F/ '{print $NF}' | tr -d '[:space:]\r'
}

apt_try() {
    # Install a package; warn but don't exit on failure
    sudo apt-get install -y "$1" 2>/dev/null && ok "$1" || warn "apt: could not install $1 (skipping)"
}

# ── 0. Sanity checks ──────────────────────────────────────────────
check_system() {
    section "System check"
    [[ "$(id -u)" -eq 0 ]] && die "Run as your normal user, not root. (sudo will be called internally)"
    command -v sudo >/dev/null     || die "sudo is required."
    command -v curl >/dev/null     || die "curl is required. Install with: sudo apt install curl"
    command -v git  >/dev/null     || sudo apt-get install -y git
    . /etc/os-release 2>/dev/null || true
    [[ "${ID:-}" != "ubuntu" ]]        && warn "Not Ubuntu — may need manual adjustments."
    [[ "${VERSION_ID:-}" != "24.04" ]] && warn "Designed for Ubuntu 24.04; got ${VERSION_ID:-unknown}."
    ok "Running as $USER on ${PRETTY_NAME:-Linux}"
}

# ── 1. Hyprland + ecosystem via apt/PPA ───────────────────────────
install_hyprland_apt() {
    section "Hyprland & Wayland stack (apt)"

    # Enable Universe repo
    sudo add-apt-repository -y universe 2>/dev/null || true

    # Try known PPAs for latest Hyprland on Ubuntu Noble
    local ppa_ok=0
    for ppa in "hyprwm/hyprland" "solopasha/hyprland"; do
        info "Trying ppa:$ppa …"
        if sudo add-apt-repository -y "ppa:$ppa" 2>/dev/null; then
            ok "Added ppa:$ppa"
            ppa_ok=1
            break
        fi
    done
    [[ $ppa_ok -eq 0 ]] && warn "No Hyprland PPA succeeded. Installing from Ubuntu universe (may be older)."

    sudo apt-get update -qq

    # Core Hyprland suite
    for pkg in hyprland hyprlock hypridle xdg-desktop-portal-hyprland xdg-desktop-portal-gtk; do
        apt_try "$pkg"
    done
}

# ── 2. All other apt dependencies ────────────────────────────────
install_apt_deps() {
    section "Dependencies (apt)"

    local pkgs=(
        # Wayland / display
        waybar
        libdrm-dev libgbm-dev

        # Notifications
        swaync libnotify-bin

        # Terminal & files
        kitty nautilus

        # Screenshots
        grim slurp swappy

        # Clipboard
        wl-clipboard

        # Audio / volume
        pipewire wireplumber pipewire-pulse pipewire-alsa
        pavucontrol pamixer

        # Media / brightness
        playerctl brightnessctl

        # Networking / Bluetooth
        network-manager-gnome blueman

        # App launcher
        rofi

        # Utilities used by scripts
        jq yad wlogout xdotool

        # Theming
        nwg-look gnome-themes-extra
        qt5ct qt6ct

        # Polkit authentication agent
        policykit-1-gnome

        # Fonts
        fonts-jetbrains-mono fonts-inter

        # Build & runtime tools (for cargo / pip installs below)
        python3-pip python3-pipx
        build-essential cmake meson ninja-build
        cargo rustup
        wget curl unzip tar
    )

    sudo apt-get update -qq
    for pkg in "${pkgs[@]}"; do
        apt_try "$pkg"
    done
}

# ── 3. swww (wallpaper daemon) ────────────────────────────────────
install_swww() {
    section "swww (wallpaper daemon)"
    if command -v swww &>/dev/null; then
        ok "swww already installed ($(swww --version 2>/dev/null || true))"
        return
    fi
    local tag; tag=$(gh_latest "LGFae/swww")
    local base="swww-${tag#v}-x86_64-unknown-linux-musl"
    local url="https://github.com/LGFae/swww/releases/download/${tag}/${base}.tar.gz"
    info "Downloading swww ${tag} …"
    wget -qO "$TMP_DIR/swww.tar.gz" "$url" || { warn "swww download failed — install manually from https://github.com/LGFae/swww"; return; }
    tar -xf "$TMP_DIR/swww.tar.gz" -C "$TMP_DIR/"
    sudo install -Dm755 "$TMP_DIR/swww"        /usr/local/bin/swww
    sudo install -Dm755 "$TMP_DIR/swww-daemon" /usr/local/bin/swww-daemon
    ok "swww ${tag} installed"
}

# ── 4. cliphist (clipboard history) ──────────────────────────────
install_cliphist() {
    section "cliphist (clipboard history)"
    if command -v cliphist &>/dev/null; then
        ok "cliphist already installed"; return
    fi
    local tag; tag=$(gh_latest "sentriz/cliphist")
    local url="https://github.com/sentriz/cliphist/releases/download/${tag}/cliphist-linux-amd64"
    info "Downloading cliphist ${tag} …"
    wget -qO "$TMP_DIR/cliphist" "$url" || { warn "cliphist download failed — install manually from https://github.com/sentriz/cliphist"; return; }
    sudo install -Dm755 "$TMP_DIR/cliphist" /usr/local/bin/cliphist
    ok "cliphist ${tag} installed"
}

# ── 5. wallust (colour scheme from wallpaper) ─────────────────────
install_wallust() {
    section "wallust (wallpaper colour generator)"
    if command -v wallust &>/dev/null; then
        ok "wallust already installed"; return
    fi
    # Ensure cargo is available (prefer rustup over distro cargo)
    if ! command -v cargo &>/dev/null; then
        info "Installing Rust toolchain via rustup …"
        curl -sSf https://sh.rustup.rs | sh -s -- -y --no-modify-path
        # shellcheck source=/dev/null
        source "$HOME/.cargo/env" 2>/dev/null || export PATH="$HOME/.cargo/bin:$PATH"
    fi
    cargo install wallust 2>&1 | tail -3
    # Persist ~/.cargo/bin in PATH
    local line='export PATH="$HOME/.cargo/bin:$PATH"'
    for rc in "$HOME/.bashrc" "$HOME/.zshrc" "$HOME/.profile"; do
        [[ -f "$rc" ]] && grep -q 'cargo/bin' "$rc" || echo "$line" >> "$rc"
    done
    ok "wallust installed"
}

# ── 6. pyprland (scratchpad / zoom plugin manager) ────────────────
install_pyprland() {
    section "pyprland (Hyprland plugin daemon)"
    if command -v pypr &>/dev/null; then
        ok "pyprland already installed"; return
    fi
    if command -v pipx &>/dev/null; then
        pipx install pyprland && ok "pyprland installed via pipx"
    else
        pip3 install --user pyprland && ok "pyprland installed via pip3"
        local line='export PATH="$HOME/.local/bin:$PATH"'
        for rc in "$HOME/.bashrc" "$HOME/.zshrc" "$HOME/.profile"; do
            [[ -f "$rc" ]] && grep -q '.local/bin' "$rc" || echo "$line" >> "$rc"
        done
    fi
}

# ── 7. Nerd Fonts ─────────────────────────────────────────────────
install_fonts() {
    section "Nerd Fonts"
    local font_dir="$HOME/.local/share/fonts/NerdFonts"
    mkdir -p "$font_dir"
    local tag; tag=$(gh_latest "ryanoasis/nerd-fonts")
    for font in JetBrainsMono; do
        if fc-list | grep -qi "$font Nerd"; then
            ok "$font Nerd Font already installed"; continue
        fi
        info "Downloading $font Nerd Font ${tag} …"
        wget -qO "$TMP_DIR/${font}.tar.xz" \
            "https://github.com/ryanoasis/nerd-fonts/releases/download/${tag}/${font}.tar.xz" \
            || { warn "Failed to download $font — falling back to apt fonts-jetbrains-mono"; continue; }
        tar -xf "$TMP_DIR/${font}.tar.xz" -C "$font_dir" --wildcards '*.ttf' 2>/dev/null || true
        ok "$font Nerd Font installed"
    done
    fc-cache -fq
    ok "Font cache refreshed"
}

# ── 8. Configs ────────────────────────────────────────────────────
install_configs() {
    section "Installing dotfiles"
    info "Cloning $REPO_URL …"
    git clone --depth 1 "$REPO_URL" "$TMP_DIR/dots"

    # Directories to install
    local dirs=(hypr waybar kitty wlogout wallust)
    for d in "${dirs[@]}"; do
        mkdir -p "$CONFIG_DEST/$d"
        # Merge into existing config dir, not overwrite
        cp -a "$TMP_DIR/dots/$d/." "$CONFIG_DEST/$d/"
        ok "~/.config/$d"
    done

    # Wallpaper directory (scripts expect this path)
    mkdir -p "$HOME/Pictures/wallpapers"
    ok "~/Pictures/wallpapers created"

    # Default waybar config & style (symlinks so WaybarLayout/WaybarStyles still work)
    ln -sf "$CONFIG_DEST/waybar/configs/[TOP] Default Laptop" "$CONFIG_DEST/waybar/config"
    ln -sf "$CONFIG_DEST/waybar/style/[Colored] Chroma Glow.css" "$CONFIG_DEST/waybar/style.css"
    ok "Default waybar layout & style linked"

    # Mark all scripts executable
    find "$CONFIG_DEST/hypr" -name '*.sh' -exec chmod +x {} +
    chmod +x "$CONFIG_DEST/hypr/initial-boot.sh"
    ok "Scripts marked executable"

    # Directories scripts expect but aren't in the repo
    mkdir -p "$CONFIG_DEST/rofi"
    mkdir -p "$CONFIG_DEST/swaync/icons" "$CONFIG_DEST/swaync/images"
    mkdir -p "$CONFIG_DEST/wallust/templates"

    # Remove the one-time boot marker so initial-boot.sh fires on first Hyprland start
    rm -f "$CONFIG_DEST/hypr/.initial_startup_done"
    ok "Dotfiles installed"
}

# ── 9. swaync icons (scripts need them for notifications) ─────────
install_swaync_icons() {
    section "swaync notification icons"
    local icon_dir="$CONFIG_DEST/swaync/icons"
    local img_dir="$CONFIG_DEST/swaync/images"
    mkdir -p "$icon_dir" "$img_dir"
    # Install a minimal set of notification icons from the system
    for icon in audio-volume-high audio-volume-medium audio-volume-low \
                audio-volume-muted microphone-sensitivity-high \
                microphone-sensitivity-muted display-brightness-symbolic \
                bell notification-symbolic camera-photo; do
        local src; src=$(find /usr/share/icons -name "${icon}.png" -path "*/48x48/*" 2>/dev/null | head -1)
        [[ -n "$src" ]] && cp "$src" "$icon_dir/" 2>/dev/null || true
    done
    # Fallback: copy generic bell icon for script notifications
    local bell_src; bell_src=$(find /usr/share/icons -name "bell*.png" 2>/dev/null | head -1)
    [[ -n "$bell_src" ]] && cp "$bell_src" "$img_dir/bell.png" 2>/dev/null || true
    ok "swaync icon dir ready"
}

# ── 10. Post-install summary ──────────────────────────────────────
post_install() {
    section "All done!"
    echo -e "
${BOLD}Next steps:${NC}

  1. Drop at least one wallpaper into ${CYN}~/Pictures/wallpapers/${NC}

  2. ${BOLD}Log out${NC}, then select ${CYN}Hyprland${NC} in your display manager
     (GDM: click the gear icon at the bottom-right before logging in)

  3. On first launch, ${CYN}initial-boot.sh${NC} runs automatically to apply
     the default wallpaper and theme — wait ~5 seconds.

${BOLD}Keybind cheatsheet:${NC}
  ${CYN}SUPER + Return${NC}       Terminal (kitty)
  ${CYN}SUPER + D${NC}            App launcher (rofi)
  ${CYN}SUPER + W${NC}            Wallpaper picker
  ${CYN}SUPER + E${NC}            Edit any config file
  ${CYN}SUPER + Q${NC}            Close window
  ${CYN}SUPER + SHIFT + S${NC}    Screenshot (area → clipboard)
  ${CYN}SUPER + SHIFT + N${NC}    Notification centre
  ${CYN}CTRL  + ALT + L${NC}      Lock screen
  ${CYN}CTRL  + ALT + P${NC}      Power menu

${BOLD}Re-run installer at any time:${NC}
  ${GRN}bash <(curl -sL https://raw.githubusercontent.com/Furin21/Ubuntu-Hyprland-Config/main/install.sh)${NC}
"
}

# ── Entry point ───────────────────────────────────────────────────
main() {
    echo -e "${BOLD}${BLU}"
    cat <<'BANNER'
  ╔══════════════════════════════════════════════════╗
  ║   Hyprland · Ubuntu 24.04 · Furin21 Dotfiles    ║
  ║   github.com/Furin21/Ubuntu-Hyprland-Config     ║
  ╚══════════════════════════════════════════════════╝
BANNER
    echo -e "${NC}"

    # Cleanup on exit
    trap 'rm -rf "$TMP_DIR"' EXIT

    check_system
    install_hyprland_apt
    install_apt_deps
    install_swww
    install_cliphist
    install_wallust
    install_pyprland
    install_fonts
    install_configs
    install_swaync_icons
    post_install
}

main "$@"
