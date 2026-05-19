# Changelog

## [1.0.0] — 2026-05-19

### Added
- `disk-cleaner` — bash script that cleans pip, npm, Chrome, Brave, Firefox, Sublime Text, uv, Composer, and old thumbnails; logs every action to SQLite
- `disk-monitor` — systemd user daemon that watches `/home` and `/` every 5 minutes and auto-triggers cleanup at configurable thresholds
- `disk-stats` — terminal analytics report with 14-day trend table and all-time totals
- `disk-gui` — PyQt5 dashboard with 5 tabs: Dashboard, History, Analytics, Cleanup, Settings
- SQLite database schema: `cleanups`, `actions`, `snapshots` tables
- Systemd user service (`disk-monitor.service`) and weekly timer (`disk-cleaner.timer`)
- Configurable thresholds, cooldown, and check intervals via `~/.config/disk-monitor/config.sh`
- Desktop notifications via `notify-send` on auto-triggered cleanups
- `install.sh` — one-command installer with distro detection (apt/dnf/pacman/zypper)
- `uninstall.sh` — clean removal with optional data wipe
