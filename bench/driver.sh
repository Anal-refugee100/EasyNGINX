#!/usr/bin/env bash
# In-container orchestrator. Sources the target adapter for $BENCH_TARGET,
# runs every scenario in order, and emits one CSV line per scenario to stdout.
#
# A scenario function may exit non-zero — we don't want that to kill the
# whole driver. Hence `set -uo pipefail`, no `-e`.

set -uo pipefail

if [[ -z "${BENCH_TARGET:-}" || -z "${BENCH_RUN:-}" ]]; then
    echo "BENCH_TARGET and BENCH_RUN must be set" >&2
    exit 2
fi

# shellcheck disable=SC1091
source "/work/targets/${BENCH_TARGET}.sh"

run_scenario() {
    local sc="$1"
    # shellcheck disable=SC1090
    source "/work/scenarios/${sc}.sh"

    local short fn
    short="${sc#[0-9][0-9]-}"
    fn="scenario_${short//-/_}"

    if declare -F "$fn" >/dev/null; then
        "$fn"
    else
        echo "[driver] missing function $fn" >&2
        echo "${BENCH_TARGET},${sc},${BENCH_RUN},0,0,0,0"
        return 1
    fi
}

for sc in 01-install 02-create-site 03-audit 04-backup 05-resources; do
    run_scenario "$sc"
done
