#!/usr/local/bin/bash

#
# currently this script runs every 3 minutes, but the behavior for toggling
# works thusly:
#
# 1. get the current minute of this execution (0 3 6 9 12 ... etc.)
# 2. get the current ACTIVE and INACTIVE service (these are managed by
#    symlinks to their supervisor directories in $HOME/.config/toggle-rtl)
# 3. if the ACTIVE service is `amridm2mqtt` then, if the modulo of the
#    current minute divided by 5, and if the value is not 0 (meaning it
#    is not evenly divisible by 5), stop running
# 4. else toggle running service:
#    * activate:
#      - remove the `down` file from supervisor directory
#      - set the service to `up`
#      - rewrite the `active` symlink in the STATE_DIR
#    * deactivate:
#      - create a `down` file in the supervisor directory
#      - terminate and set the service to `down`
#      - rewrite the `inactive` symlink in the STATE_DIR
#

STATE_DIR="$HOME/.config/toggle-rtl"

MINUTE=${MINUTE:-$(date +'%M' | sed -e 's/^0//')}
ACTIVE=$(readlink -f "$STATE_DIR/active")
INACTIVE=$(readlink -f "$STATE_DIR/inactive")

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
    echo DEACTIVATING: $ACTIVE
    touch "$ACTIVE/down"
    svc -td "$ACTIVE"
    ln -nsf "$ACTIVE" "$STATE_DIR/inactive"
}

activate
deactivate

