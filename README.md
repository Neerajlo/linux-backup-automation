# Linux Automation: Production Backup, Monitoring & Recovery Suite

A production-grade automation suite for Linux servers that handles scheduled backups, system health monitoring, log rotation, and automated recovery — built entirely with native Linux tooling (no third-party agents required).

---

## 📌 Overview

This project provides a self-contained toolkit to automate the three pillars of server reliability:

- **Backup** — Incremental, remote backups over SSH using `rsync`
- **Monitoring** — Periodic health checks (disk, memory, CPU, service status) with alerting
- **Recovery** — Scripted restore procedures and automatic service recovery via `systemd`

All components run unattended via `cron` and `systemd` timers/services, with `logrotate` keeping logs under control indefinitely.

---

## ✨ Features

- 🔄 **Automated incremental backups** to a remote/local target using `rsync -avz --delete` with hard-link snapshots (space-efficient, like a poor-man's Time Machine)
- 🔐 **Secure remote sync** over SSH using key-based authentication (no passwords stored)
- ⏱️ **Scheduled execution** via `cron` (backup jobs) and `systemd` timers (monitoring jobs)
- 🩺 **Health monitoring** — disk usage, memory, load average, and critical service status checks
- 🚨 **Alerting** — email/webhook notification on failure or threshold breach
- ♻️ **Auto-recovery** — `systemd` service unit with `Restart=on-failure` to bring critical services back up automatically
- 🗂️ **Log rotation** — `logrotate` config to compress and prune logs, preventing disk fill-up
- 📜 **Restore script** — one-command rollback to any previous backup snapshot
- 🧪 **Dry-run mode** for testing backup/restore logic safely

---

## 🏗️ Architecture

```
┌─────────────┐     cron (nightly)     ┌──────────────┐     rsync + SSH     ┌─────────────┐
│  Production  │ ─────────────────────▶│ backup.sh    │ ───────────────────▶│  Backup      │
│  Server      │                        │              │                     │  Server /NAS │
└─────────────┘                        └──────────────┘                     └─────────────┘
       │
       │ systemd timer (every 5 min)
       ▼
┌──────────────┐     threshold breach    ┌───────────────┐
│ monitor.sh   │ ────────────────────────▶│ alert.sh       │
│              │                          │ (email/webhook)│
└──────────────┘                          └───────────────┘
       │
       │ service down
       ▼
┌──────────────┐
│ systemd       │  Restart=on-failure
│ recovery unit │
└──────────────┘

logrotate ──▶ rotates & compresses all logs in /var/log/backup-suite/
```

---

## 📁 Project Structure

```
linux-automation-suite/
├── bin/
│   ├── backup.sh              # Main rsync backup script
│   ├── restore.sh             # Restore from a chosen snapshot
│   ├── monitor.sh             # System health check script
│   └── alert.sh               # Notification dispatcher (email/webhook)
├── systemd/
│   ├── backup-suite-monitor.service
│   ├── backup-suite-monitor.timer
│   └── app-recovery.service   # Example auto-restart unit for a critical app
├── cron/
│   └── backup-cron.txt        # Crontab entry for nightly backups
├── logrotate/
│   └── backup-suite.conf      # Logrotate config
├── config/
│   └── backup.conf.example    # Editable config (paths, remote host, retention)
├── logs/                      # Runtime logs (gitignored)
└── README.md
```

---

## ⚙️ Prerequisites

- Linux server (Ubuntu/Debian/RHEL/CentOS) with `bash` ≥ 5.0
- `rsync`, `openssh-client`, `cron` or `systemd-cron`, `logrotate` installed
- SSH key-based access configured to the backup target
- `sudo`/root access to install systemd units and logrotate configs

---

## 🚀 Installation

```bash
# 1. Clone the repository
git clone https://github.com/<your-username>/linux-automation-suite.git
cd linux-automation-suite

# 2. Make scripts executable
chmod +x bin/*.sh

# 3. Copy and edit the config file
cp config/backup.conf.example config/backup.conf
nano config/backup.conf   # set SOURCE_DIR, REMOTE_HOST, REMOTE_USER, RETENTION_DAYS

# 4. Set up SSH key auth to the backup target (if not already done)
ssh-keygen -t ed25519 -C "backup-suite"
ssh-copy-id -i ~/.ssh/id_ed25519.pub <REMOTE_USER>@<REMOTE_HOST>

# 5. Install systemd units for monitoring
sudo cp systemd/*.service systemd/*.timer /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable --now backup-suite-monitor.timer

# 6. Install the cron job for backups
crontab cron/backup-cron.txt

# 7. Install logrotate config
sudo cp logrotate/backup-suite.conf /etc/logrotate.d/backup-suite
```

---

## 🔧 Configuration (`config/backup.conf`)

```bash
SOURCE_DIR="/var/www /etc/nginx /var/lib/mysql-backups"
REMOTE_USER="backupuser"
REMOTE_HOST="backup.example.com"
REMOTE_DIR="/backups/prod-server"
RETENTION_DAYS=14
LOG_FILE="/var/log/backup-suite/backup.log"
ALERT_EMAIL="ops@example.com"
```

---

## ▶️ Usage

**Run a manual backup:**
```bash
./bin/backup.sh --config config/backup.conf
```

**Dry run (no changes made):**
```bash
./bin/backup.sh --config config/backup.conf --dry-run
```

**Restore from latest snapshot:**
```bash
./bin/restore.sh --latest --target /
```

**Restore from a specific date:**
```bash
./bin/restore.sh --snapshot 2026-08-20 --target /var/www
```

**Run monitoring check manually:**
```bash
./bin/monitor.sh
```

**Check scheduled jobs:**
```bash
crontab -l
systemctl list-timers backup-suite-monitor.timer
```

---

## 📊 Monitoring & Alerts

`monitor.sh` runs every 5 minutes via a `systemd` timer and checks:

| Check           | Threshold        | Action on breach       |
|------------------|-------------------|--------------------------|
| Disk usage       | > 85%             | Email + log entry        |
| Memory usage     | > 90%             | Email + log entry        |
| Load average     | > core count × 2  | Log entry                |
| Critical service | inactive/failed   | Alert + trigger restart  |

Alerts are dispatched via `alert.sh`, which supports email (`sendmail`/`ssmtp`) and webhook (Slack/Discord) integrations — configurable in `config/backup.conf`.

---

## ♻️ Auto-Recovery (systemd)

Example unit (`systemd/app-recovery.service`) demonstrates automatic restart of a critical service:

```ini
[Service]
Restart=on-failure
RestartSec=5s
StartLimitIntervalSec=60
StartLimitBurst=3
```

Pair this with `OnFailure=` directives to trigger `alert.sh` when a service exceeds its restart limit.

---

## 🗒️ Log Rotation

`logrotate/backup-suite.conf`:

```
/var/log/backup-suite/*.log {
    daily
    rotate 14
    compress
    delaycompress
    missingok
    notifempty
    create 0640 root adm
}
```

---

## 🛡️ Security Notes

- Uses SSH key-based auth only — no plaintext passwords in scripts or configs
- `config/backup.conf` should be excluded from version control if it contains sensitive hostnames/paths (add to `.gitignore`)
- Recommend restricting the backup SSH key to `rsync`-only via `authorized_keys` `command=` restriction

---

## 🧪 Testing

```bash
# Validate backup script syntax
bash -n bin/backup.sh

# Run with dry-run + verbose logging
./bin/backup.sh --config config/backup.conf --dry-run --verbose
```

---

## 🗺️ Roadmap

- [ ] Add Prometheus node-exporter metrics export
- [ ] Slack/Telegram bot integration for alerts
- [ ] Support for database-specific backup hooks (MySQL/PostgreSQL dump)
- [ ] Docker-based test environment

---

## 🤝 Contributing

Pull requests are welcome. For major changes, please open an issue first to discuss what you'd like to change.

---

## 📄 License

This project is licensed under the MIT License — see the [LICENSE](LICENSE) file for details.

---
