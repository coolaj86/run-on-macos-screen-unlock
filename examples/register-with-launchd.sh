#!/bin/sh
set -e
set -u

serviceman add --user \
    --path "$PATH" \
    --name run-on-macos-screen-unlock.mount-network-shares -- \
    ~/bin/run-on-macos-screen-unlock ./examples/mount-network-shares.sh ~/.config/macos-network-shares/urls.conf
