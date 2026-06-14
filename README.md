# Picons — 400x240 · Light on Transparent

Automatically built channel logo PNGs for Enigma2/DVB receivers, updated weekly via GitHub Actions.

## Source

Logos and service index are sourced from **[picons/picons](https://github.com/picons/picons)**.

## Style

| Property   | Value           |
|------------|-----------------|
| Style      | UTF8 Service Name (`utf8snp`) |
| Resolution | 400×240 px      |
| Logo area  | 370×210 px      |
| Type       | Light           |
| Background | Transparent     |

## GitHub Pages

The built PNG files and index files are published to GitHub Pages (no git history for binaries):

| Path | Content |
|------|---------|
| `/<logoname>.png` | Channel logo PNG |
| `/info/files.md5` | MD5 checksums of all PNGs |
| `/info/files.map` | Service name → logo name mappings (only where they differ) |

## Update Schedule

The workflow runs every **Monday at 06:00 UTC**. It only rebuilds PNGs whose source logo has changed since the last run; new logos are built automatically.

## Repository Contents

| Path | Description |
|------|-------------|
| `build-source/` | Synced from picons/picons (logos, index, config) |
| `2-build-picons.sh` | Build script |
| `.github/workflows/` | GitHub Actions workflow |
