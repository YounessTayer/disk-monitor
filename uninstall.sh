#!/usr/bin/env bash
# disk-monitor uninstaller
set -euo pipefail

RED='\033[0;31m'; GREEN='\033[0;32m'; AMBER='\033[0;33m'
BLUE='\033[0;34m'; BOLD='\033[1m'; RESET='\033[0m'

ok()   { echo -e "${GREEN}  ✓${RESET}  $*"; }
info() { echo -e "${BLUE}  →${RESET}  $*"; }
warn() { echo -e "${AMBER}  !${RESET}  $*"; }
hr()   { echo -e "${BLUE}$(printf '%.0s─' {1..52})${RESET}"; }

hr
echo -e "${BOLD}  disk-monitor uninstaller${RESET}"
hr
echo ""

# ── Stop and disable services ─────────────────────────────────────────────────
if command -v systemctl &>/dev/null && systemctl --user status &>/dev/null 2>&1; then
  info "Stopping and disabling services..."
  systemctl --user stop  disk-monitor.service 2>/dev/null && ok "disk-monitor.service stopped" || true
  systemctl --user stop  disk-cleaner.timer   2>/dev/null && ok "disk-cleaner.timer stopped"   || true
  systemctl --user disable disk-monitor.service 2>/dev/null || true
  systemctl --user disable disk-cleaner.timer   2>/dev/null || true

  info "Removing service files..."
  for f in disk-monitor.service disk-cleaner.service disk-cleaner.timer; do
    rm -f "$HOME/.config/systemd/user/$f" && ok "$f removed" || true
  done
  systemctl --user daemon-reload
fi

# ── Remove scripts ────────────────────────────────────────────────────────────
info "Removing scripts from ~/.local/bin/..."
for script in disk-cleaner disk-monitor disk-stats disk-gui; do
  rm -f "$HOME/.local/bin/$script" && ok "$script removed" || true
done

# ── Remove desktop entry ──────────────────────────────────────────────────────
rm -f "$HOME/.local/share/applications/disk-monitor.desktop"
command -v update-desktop-database &>/dev/null && \
  update-desktop-database "$HOME/.local/share/applications/" 2>/dev/null || true
ok "Desktop entry removed"

# ── Config ────────────────────────────────────────────────────────────────────
if [[ -f "$HOME/.config/disk-monitor/config.sh" ]]; then
  echo ""
  read -rp "  Remove config at ~/.config/disk-monitor/? [y/N] " ans
  if [[ "$ans" =~ ^[Yy]$ ]]; then
    rm -rf "$HOME/.config/disk-monitor"
    ok "Config removed"
  else
    ok "Config kept at ~/.config/disk-monitor/"
  fi
fi

# ── Data / database ───────────────────────────────────────────────────────────
if [[ -d "$HOME/.local/share/disk-monitor" ]]; then
  echo ""
  read -rp "  Remove all data and stats database at ~/.local/share/disk-monitor/? [y/N] " ans
  if [[ "$ans" =~ ^[Yy]$ ]]; then
    rm -rf "$HOME/.local/share/disk-monitor"
    ok "Data removed"
  else
    ok "Data kept at ~/.local/share/disk-monitor/"
  fi
fi

echo ""
hr
echo -e "${BOLD}  Uninstall complete.${RESET}"
hr
echo ""
