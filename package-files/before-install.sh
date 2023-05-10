#! /bin/sh
set -e

adduser --force-badname --system --home /var/lib/vaultwarden --quiet --group vaultwarden || true
