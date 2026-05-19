#!/usr/bin/env bash
# disk-monitor installer
set -euo pipefail

RED='\033[0;31m'; GREEN='\033[0;32m'; AMBER='\033[0;33m'
BLUE='\033[0;34m'; BOLD='\033[1m'; RESET='\033[0m'

ok()   { echo -e "${GREEN}  ✓${RESET}  $*"; }
info() { echo -e "${BLUE}  →${RESET}  $*"; }
warn() { echo -e "${AMBER}  !${RESET}  $*"; }
die()  { echo -e "${RED}  ✗${RESET}  $*" >&2; exit 1; }
hr()   { echo -e "${BLUE}$(printf '%.0s─' {1..52})${RESET}"; }

hr
echo -e "${BOLD}  disk-monitor installer${RESET}"
hr
echo ""

# ── Detect distro package manager ─────────────────────────────────────────────
install_pkg() {
  if   command -v apt-get &>/dev/null; then sudo apt-get install -y "$@"
  elif command -v dnf     &>/dev/null; then sudo dnf install -y "$@"
  elif command -v pacman  &>/dev/null; then sudo pacman -S --noconfirm "$@"
  elif command -v zypper  &>/dev/null; then sudo zypper install -y "$@"
  else die "No supported package manager found (apt/dnf/pacman/zypper)"; fi
}

# ── Check bash version ─────────────────────────────────────────────────────────
(( BASH_VERSINFO[0] >= 4 )) || die "bash 4+ required (you have $BASH_VERSION)"

# ── sqlite3 ───────────────────────────────────────────────────────────────────
if ! command -v sqlite3 &>/dev/null; then
  info "Installing sqlite3..."
  install_pkg sqlite3
  ok "sqlite3 installed"
else
  ok "sqlite3 found ($(sqlite3 --version | cut -d' ' -f1))"
fi

# ── Python 3 ──────────────────────────────────────────────────────────────────
if ! command -v python3 &>/dev/null; then
  die "python3 not found — install it with your package manager"
fi
ok "python3 found ($(python3 --version 2>&1 | cut -d' ' -f2))"

# ── PyQt5 ─────────────────────────────────────────────────────────────────────
if ! python3 -c "import PyQt5" 2>/dev/null; then
  info "Installing PyQt5..."
  if command -v apt-get &>/dev/null; then
    sudo apt-get install -y python3-pyqt5 || pip3 install --user PyQt5
  else
    pip3 install --user PyQt5
  fi
  ok "PyQt5 installed"
else
  ok "PyQt5 found"
fi

# ── matplotlib ────────────────────────────────────────────────────────────────
if ! python3 -c "import matplotlib" 2>/dev/null; then
  info "Installing matplotlib..."
  pip3 install --user matplotlib
  ok "matplotlib installed"
else
  ok "matplotlib found ($(python3 -c 'import matplotlib; print(matplotlib.__version__)'))"
fi

# ── Directories ───────────────────────────────────────────────────────────────
info "Creating directories..."
mkdir -p \
  "$HOME/.local/bin" \
  "$HOME/.config/disk-monitor" \
  "$HOME/.local/share/disk-monitor" \
  "$HOME/.config/systemd/user" \
  "$HOME/.local/share/applications"
ok "Directories ready"

# ── Copy scripts ──────────────────────────────────────────────────────────────
info "Installing scripts to ~/.local/bin/..."
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

for script in disk-cleaner disk-monitor disk-stats disk-gui; do
  if [[ -f "$SCRIPT_DIR/bin/$script" ]]; then
    cp "$SCRIPT_DIR/bin/$script" "$HOME/.local/bin/$script"
    chmod +x "$HOME/.local/bin/$script"
    ok "$script"
  else
    warn "$script not found in bin/ — skipping"
  fi
done

# ── Config (don't overwrite existing) ────────────────────────────────────────
if [[ ! -f "$HOME/.config/disk-monitor/config.sh" ]]; then
  cp "$SCRIPT_DIR/config/config.sh.default" "$HOME/.config/disk-monitor/config.sh"
  ok "Config installed at ~/.config/disk-monitor/config.sh"
else
  ok "Config already exists — not overwritten"
fi

# ── Systemd user services ─────────────────────────────────────────────────────
if command -v systemctl &>/dev/null && systemctl --user status &>/dev/null 2>&1; then
  info "Installing systemd user services..."
  for f in disk-monitor.service disk-cleaner.service disk-cleaner.timer; do
    if [[ -f "$SCRIPT_DIR/systemd/$f" ]]; then
      cp "$SCRIPT_DIR/systemd/$f" "$HOME/.config/systemd/user/$f"
      ok "$f"
    fi
  done

  info "Enabling services..."
  systemctl --user daemon-reload
  systemctl --user enable --now disk-monitor.service  2>/dev/null && ok "disk-monitor.service started"
  systemctl --user enable --now disk-cleaner.timer    2>/dev/null && ok "disk-cleaner.timer enabled (weekly)"
else
  warn "systemd --user not available — services not installed"
  warn "You can still run disk-cleaner and disk-monitor manually"
fi

# ── Desktop entry ─────────────────────────────────────────────────────────────
cat > "$HOME/.local/share/applications/disk-monitor.desktop" << 'EOF'
[Desktop Entry]
Name=Disk Monitor
Comment=Disk usage monitor and cache cleaner
Exec=disk-gui
Icon=drive-harddisk
Terminal=false
Type=Application
Categories=System;Utility;
StartupWMClass=disk-gui
EOF
command -v update-desktop-database &>/dev/null && \
  update-desktop-database "$HOME/.local/share/applications/" 2>/dev/null || true
ok "Desktop entry installed"

# ── PATH check ────────────────────────────────────────────────────────────────
echo ""
if echo "$PATH" | grep -q "$HOME/.local/bin"; then
  ok "~/.local/bin is already in your PATH"
else
  warn "~/.local/bin is NOT in your PATH"
  echo "     Add this to your ~/.bashrc or ~/.zshrc:"
  echo -e "     ${BOLD}export PATH=\"\$HOME/.local/bin:\$PATH\"${RESET}"
  echo "     Then run: source ~/.bashrc"
fi

# ── Done ──────────────────────────────────────────────────────────────────────
echo ""
hr
echo -e "${BOLD}  Installation complete!${RESET}"
hr
echo ""
echo "  Commands available:"
echo -e "    ${BOLD}disk-gui${RESET}       — open the analytics dashboard"
echo -e "    ${BOLD}disk-cleaner${RESET}   — run a manual cleanup"
echo -e "    ${BOLD}disk-stats${RESET}     — terminal stats report"
echo ""
echo "  First run (populates the database):"
echo -e "    ${BOLD}disk-cleaner${RESET}"
echo ""
echo "  Check monitor is running:"
echo -e "    ${BOLD}systemctl --user status disk-monitor.service${RESET}"
echo ""
