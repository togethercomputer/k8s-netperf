#!/bin/sh
# CVE-2026-111943: kindest/node images (Debian) ship a ca-certificates that
# still trusts the emSign roots and no fixed node image is released yet.
# Upgrade ca-certificates in place on every node and fail if it is not fixed.
# Usage: kind-ca-upgrade.sh <docker|podman> <node>...
set -eu
runtime="$1"
shift
for node in "$@"; do
  "$runtime" exec "$node" sh -c '
    set -eu
    apt-get update
    apt-get install -y --only-upgrade ca-certificates
    rm -rf /var/lib/apt/lists/*
    . /etc/os-release
    case "$VERSION_ID" in
      12) min="20250419~deb12u2" ;;
      13) min="20250419+deb13u1" ;;
      *) min="20250419+deb13u1" ;;
    esac
    have="$(dpkg-query -W -f="\${Version}" ca-certificates)"
    if ! dpkg --compare-versions "$have" ge "$min"; then
      echo "ca-certificates $have is older than $min (CVE-2026-111943)" >&2
      exit 1
    fi
    echo "$(hostname): ca-certificates $have"
  '
done
