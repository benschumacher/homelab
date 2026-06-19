#!/usr/local/bin/bash

#
# toggles between two rtl_tcp client services that can't run concurrently
# (amridm2mqtt and rtl_433) since they'd contend for the same SDR dongle.
# runs every 3 minutes via cron; behavior:
#
# 1. get the current minute of this execution (0 3 6 9 12 ... etc.)
# 2. determine ACTIVE_NAME from the symlink $HOME/.config/toggle-rtl/active,
#    which points at /service/<name>. INACTIVE_NAME is derived as "the other
#    entry" in the SERVICES=(amridm2mqtt rtl_433) array -- NOTE: this script
#    only supports exactly 2 services; other_of() assumes a pair.
#    if the symlink is missing/invalid, self-heal by checking svstat
#    directly. if neither service is up, exit 1 rather than guess.
# 3. if ACTIVE_NAME is `amridm2mqtt`, only proceed on minutes evenly
#    divisible by 5 (skip otherwise) -- this gives rtl_433 a 3-minute
#    window once every 15 minutes. since rtl_433's hop_interval (90s)
#    restarts fresh each activation, that 3-minute window only ever
#    covers the first two entries in its frequency list: ~90s on
#    433.92M (WH2 weather station) then ~90s on 912.6M (ERT meters).
# 4. else toggle, deactivate-then-activate (in that order, deliberately,
#    to avoid the dongle-contention overlap bug prior to <8fb280bf1>):
#    * deactivate:
#      - touch `down` in the supervisor dir, svc -td, poll svstat for
#        confirmed-down (up to 10s, falls back to svc -k on timeout)
#    * activate:
#      - rm `down`, svc -u, rewrite the `active` symlink to point at the
#        newly-activated service (the only state write in the script)
#

SERVICES=(amridm2mqtt rtl_433)
STATE_DIR="$HOME/.config/toggle-rtl"
STATE_LINK="$STATE_DIR/active"   # single symlink -> /service/<name>

MINUTE=${MINUTE:-$(date +'%M' | sed -e 's/^0//')}

other_of() {
    local current="$1"
    for s in "${SERVICES[@]}"; do
        [[ "$s" != "$current" ]] && echo "$s" && return
    done
}

ACTIVE_NAME=$(basename "$(readlink -f "$STATE_LINK" 2>/dev/null)")

if [[ -z "$ACTIVE_NAME" ]] || [[ ! " ${SERVICES[*]} " =~ " ${ACTIVE_NAME} " ]]; then
    echo "WARNING: invalid/missing state link, resolving from svstat" >&2
    for s in "${SERVICES[@]}"; do
        if svstat "/service/$s" | grep -q ': up'; then
            ACTIVE_NAME="$s"
            break
        fi
    done
    [[ -z "$ACTIVE_NAME" ]] && { echo "ERROR: neither service is up, refusing to guess" >&2; exit 1; }
fi

INACTIVE_NAME=$(other_of "$ACTIVE_NAME")
ACTIVE="/service/$ACTIVE_NAME"
INACTIVE="/service/$INACTIVE_NAME"

if [[ $(basename "${ACTIVE}") == 'amridm2mqtt' ]]; then
    if [[ $((MINUTE % 5)) != 0 ]]; then
        exit
    fi
fi

activate() {
    echo ACTIVATING: $INACTIVE
    rm -f "$INACTIVE/down"
    svc -u "$INACTIVE"
    ln -nsf "$INACTIVE" "$STATE_DIR/active"
}

deactivate() {
    echo "DEACTIVATING: $ACTIVE"
    touch "$ACTIVE/down"
    svc -td "$ACTIVE"

    local tries=0
    while svstat "$ACTIVE" | grep -q ': up'; do
        sleep 0.5
        tries=$((tries + 1))
        if [ "$tries" -ge 20 ]; then
            echo "WARNING: $ACTIVE didn't go down in time, forcing kill" >&2
            svc -k "$ACTIVE"
            sleep 0.5
            break
        fi
    done
}

deactivate
activate

