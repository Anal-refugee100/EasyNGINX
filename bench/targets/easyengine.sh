#!/usr/bin/env bash
# EasyEngine target adapter.
# Notes:
#   * EE v4 spawns Docker-in-Docker for sites; the orchestrator passes
#     --privileged so dockerd can start.
#   * EE's ee installer apt-installs PHP mid-run and immediately invokes
#     the ee phar, which has #!/usr/bin/env php. On a fresh container the
#     shell's hash table doesn't yet know about /usr/bin/php. We pre-install
#     PHP CLI and `hash -r` so EE's own apt step is a no-op and the env
#     resolves php correctly.

t_install() {
    apt-get update -qq
    apt-get install -y --no-install-recommends \
        php-cli php-common ca-certificates >/dev/null 2>&1
    hash -r

    # EE wants a swap or it bails on low-RAM checks; the bench container
    # has plenty of RAM so we skip swap by faking the check.
    mkdir -p /etc/easyengine
    : > /etc/easyengine/easyengine.yml

    wget -qO ee https://rt.cx/ee4
    bash ee
}

t_create_site() {
    local domain="$1"
    local upstream="$2"
    sudo ee site create "$domain" --proxy="$upstream"
}

t_audit() {
    return 99
}

t_backup() {
    return 99
}

t_restore() {
    return 99
}

t_remove_site() {
    local domain="$1"
    sudo ee site delete "$domain" --yes
}

t_uninstall() {
    sudo rm -f /usr/local/bin/ee
    sudo docker rm -f $(sudo docker ps -aq) 2>/dev/null || true
}
