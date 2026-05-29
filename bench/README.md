# EasyNginx vs. EasyEngine vs. Webinoly — benchmark suite

Reproducible, scripted comparison of three nginx automation tools:

| Tool | Repo | Approach |
|---|---|---|
| **EasyNginx** | [nerkoux/EasyNGINX](https://github.com/nerkoux/EasyNGINX) | Bare-metal CLI, Python stdlib only, no Docker |
| **EasyEngine** | [EasyEngine/easyengine](https://github.com/EasyEngine/easyengine) | Docker-based, WordPress-first |
| **Webinoly** | [QROkes/webinoly](https://github.com/QROkes/webinoly) | Bare-metal Bash, Ubuntu-only, WordPress-first |

This suite measures three things, in order of usefulness:

1. **Feature parity** — what each tool can do (the matrix below).
2. **Resource footprint** — how heavy the tool is on disk and memory.
3. **Time benchmarks** — wall-clock for install, create site, audit, backup, restore.

## Run it yourself

You need Docker and ~5 GB of disk for the test images.

```bash
cd bench
./run.sh                    # full suite, all three tools, ~25 min
./run.sh --target easynginx # one tool only
./run.sh --scenario install # one scenario across all tools
```

Results land in `results/<timestamp>/` as CSV plus a summary markdown.

See [methodology.md](methodology.md) for the rules and limitations.

## Feature parity matrix (as of 2026-05-28)

Where the source is uncertain or recently changed, the row is marked with a footnote.

| Capability | EasyNginx | EasyEngine | Webinoly |
|---|:---:|:---:|:---:|
| **Distros supported** | Ubuntu, Debian, Fedora, RHEL, Rocky, Alma, Arch | Any Linux with Docker | Ubuntu 18.04 / 20.04 / 22.04 only |
| **Architecture** | Bare metal | Docker containers per site | Bare metal |
| **Engine language** | Python stdlib | PHP wrapper + Docker | Bash |
| **Third-party runtime deps** | None | Docker, docker-compose | None |
| **Interactive site creation** | ✅ | ✅ | ✅ |
| **Reverse proxy** | ✅ | ✅ | ⚠️ via custom site type |
| **Static site preset** | ✅ HTML / Hugo / Jekyll / Next.js | ⚠️ HTML only | ⚠️ HTML only |
| **PHP-FPM site** | ✅ | ✅ | ✅ |
| **WordPress preset** | ✅ rewrites + security blocks | ✅ DB + Redis included | ✅ DB + Redis + Memcached optional |
| **Laravel preset** | ✅ public/ root + storage perms | ❌ | ❌ |
| **Node.js preset** | ✅ + optional systemd unit | ❌ | ❌ |
| **WebSocket reverse proxy** | ✅ | ⚠️ manual | ⚠️ manual |
| **Load balancer** | ✅ multi-upstream | ❌ | ❌ |
| **Maintenance mode** | ✅ + custom HTML | ❌ | ❌ |
| **Site clone** | ✅ | ❌ | ❌ |
| **Let's Encrypt SSL (HTTP-01)** | ✅ | ✅ | ✅ |
| **Let's Encrypt wildcard (DNS-01)** | ⚠️ flag interface (provider plugins WIP) | ✅ Cloudflare | ✅ Cloudflare / DigitalOcean / EasyDNS |
| **Self-signed cert** | ✅ | ✅ | ✅ |
| **Bring-your-own-cert** | ✅ | ⚠️ manual | ✅ |
| **Cert color-coded expiry list** | ✅ | ❌ | ⚠️ via `info` |
| **Snapshot before write** | ✅ every command | ❌ | ❌ |
| **Auto-rollback on `nginx -t` failure** | ✅ | ❌ | ❌ |
| **Backup (sha256-verified tarball)** | ✅ | ✅ DB + files | ✅ |
| **Restore-during-install** | ✅ `EASYNGINX_RESTORE=path bash install.sh` | ❌ | ❌ |
| **Cross-distro restore** | ✅ | ❌ Docker-portable instead | ❌ |
| **Security audit (cipher / header / .env scan)** | ✅ | ❌ | ⚠️ partial |
| **TLS profile picker (modern/intermediate/legacy)** | ✅ | ❌ | ⚠️ via stack tweak |
| **HSTS toggle** | ✅ | ❌ | ✅ |
| **Bot blocker** | ✅ map-based, named bots | ❌ | ✅ |
| **GeoIP allow/deny** | ✅ (requires GeoIP2 module) | ❌ | ⚠️ via custom mods |
| **fail2ban integration** | ✅ + 3 nginx jails | ✅ | ✅ |
| **ModSecurity / WAF** | ✅ install + per-site toggle | ❌ | ❌ |
| **Access-log analyzer (top IPs / paths / slow URLs)** | ✅ | ❌ | ❌ |
| **Stub_status metrics endpoint** | ✅ localhost-only | ❌ | ⚠️ via stack tweak |
| **/healthz endpoint helper** | ✅ | ❌ | ❌ |
| **Multi-server SSH deploy with rollback** | ✅ | ❌ | ❌ |
| **Read-only web dashboard** | ✅ stdlib HTTP, token-gated | ❌ | ❌ |
| **Auto-update with snapshot rollback** | ✅ atomic `os.replace` | ⚠️ `ee cli update` (no rollback) | ⚠️ `webinoly -update` (no rollback) |
| **Update notification** | ✅ background 24h cache | ❌ | ❌ |
| **First release** | 2026-05 | 2014-04 (v1) / 2018-09 (v4) | 2018-08 |
| **License** | MIT | MIT | GPL-3.0 |

**Where each tool wins:**

- **EasyEngine** — Docker isolation per site, batteries-included WP stack with MariaDB / Redis / mail catcher, the longest track record.
- **Webinoly** — Most mature WordPress-on-bare-metal flow on Ubuntu, dozens of plugins, straightforward stack tweaks.
- **EasyNginx** — Widest distro support, atomic-update + rollback story, audit / cluster / backup-as-archive, no daemons added, no Docker required.

If WordPress is your only use case and you're on Ubuntu, Webinoly is more mature. If you want WP with Docker isolation, EasyEngine is the right pick. If you want one tool that manages stock nginx for any site type across any modern distro, with a safety story baked in, EasyNginx.

---

## Quick numbers (Docker Desktop on Windows, 2026-05-29)

Wall-clock seconds, median of 3 runs in a fresh Ubuntu 22.04 container under Docker Desktop 29.5 (Windows host, 2 vCPU / 4 GB allocated).

| Scenario | EasyNginx | EasyEngine | Webinoly |
|---|---:|---:|---:|
| Install (cold cache) | **23.5 s** | install fails (needs real systemd to enable docker.service inside the bench container) | install fails (Webinoly's distro check rejects the systemd-stubbed bench container) |
| Create reverse-proxy site (no SSL) | **0.24 s** | n/a | n/a |
| Audit 5 sites | **0.09 s** | not supported | install failed |
| Backup 5 sites | **0.10 s** | not supported | install failed |
| Tool disk footprint after install | **452 KB** | 687 MB before fail | 12 KB before fail |
| RSS of any added daemon | 0 (CLI only) | n/a (Docker daemon would be required) | 0 (CLI only) |

Pass rate (3 runs):

| Scenario | EasyNginx | EasyEngine | Webinoly |
|---|:---:|:---:|:---:|
| Install | **3/3** | 0/3 | 0/3 |
| Create site | **3/3** | 0/3 | 0/3 |
| Audit | **3/3** | n/a | 0/3 |
| Backup | **3/3** | n/a | 0/3 |
| Resources | 3/3 | 3/3 | 3/3 |

### Honest interpretation

The bench container intentionally has no real systemd — it's a clean Ubuntu image with a `systemctl` stub that always returns success. **EasyNginx ran every scenario cleanly in this environment**. EasyEngine and Webinoly both explicitly require a real systemd-enabled VPS:

- **EasyEngine** runs nginx, MariaDB, Redis as Docker containers, but its installer itself needs systemd to enable `docker.service` and pull container images on boot. Inside the bench container we get to ~64 s before its install bails.
- **Webinoly** has a strict early distro check that rejects anything not detected as a systemd Ubuntu Server. It exits in under 1 s.

That's a real difference, not a benchmark artifact: **EasyNginx is the only one of the three that installs cleanly in a minimal container or other non-systemd environment.**

Both EasyEngine and Webinoly's numbers should be re-measured on a systemd-enabled VPS for a fully fair comparison. The harness in `bench/` makes that re-measurement reproducible — see [methodology.md](methodology.md).

---

## Limitations

- **WordPress-on-EasyNginx is a preset, not a stack.** EasyNginx writes the nginx config and (optionally) installs PHP-FPM, but expects you to bring your own MariaDB / MySQL. EasyEngine and Webinoly install the database for you.
- **No DB / Redis / cache management.** EasyNginx is an nginx tool. EasyEngine is closer to a "WP appliance".
- **DNS-01 wildcard support** is wired into the CLI but the provider plugins (Cloudflare, Route53, DigitalOcean) are still landing as of v0.1.0. Webinoly is more mature here today.

The matrix is honest. PRs welcome if anything is wrong — the commands used to test each row are in `scenarios/` so you can re-verify.
