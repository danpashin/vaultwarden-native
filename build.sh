#!/bin/bash
set -exo pipefail

export VAULT_VERSION="v2024.1.2"

VAULT_GIT_VERSION="main"
VAULT_SERVER_VERSION="$VAULT_GIT_VERSION"
VAULT_COMPILER="cross"
VAULT_TARGET="x86_64-unknown-linux-gnu"
VAULT_FEATURES="sqlite"
# VAULT_FEATURES="sqlite,mysql,postgresql"
VAULT_DEB_ARCH="amd64"
VAULT_DEB_DEPENDS="libssl3"

BASEDIR=$(
    RL=$(readlink -n "$0")
    SP="${RL:-$0}"
    dirname "$(
        cd "$(dirname "${SP}")"
        pwd
    )/$(basename "${SP}")"
)
BUILDDIR="$BASEDIR/build"
WEBDIR="$BUILDDIR/bw_web"
VAULTDIR="$BUILDDIR/vaultwarden"
PATCH_NAMES=$(find "$BASEDIR/patches" -maxdepth 1 -type f -name "*.diff" -exec basename "{}" \;)

git clone https://github.com/dani-garcia/bw_web_builds.git "$WEBDIR" || git -C "$WEBDIR" pull
pushd "$WEBDIR"
    cp "$BASEDIR"/patches/*.diff ./patches

    ./scripts/checkout_web_vault.sh
    ./scripts/patch_web_vault.sh

    for patch_name in $PATCH_NAMES; do
    PATCH_NAME="$patch_name" ./scripts/patch_web_vault.sh
    done

    ./scripts/build_web_vault.sh
popd

git clone https://github.com/dani-garcia/vaultwarden "$VAULTDIR" || true
pushd "$VAULTDIR"
    git checkout "$VAULT_GIT_VERSION"
    git pull

    VAULT_SERVER_VERSION=$(git describe --tags)

    cp "$BASEDIR/Cross.toml" .
    $VAULT_COMPILER build --target $VAULT_TARGET --features "$VAULT_FEATURES" --release
popd

fpm \
    --input-type dir \
    --output-type deb \
    --force \
    --log warn \
    --name vaultwarden \
    --architecture "$VAULT_DEB_ARCH" \
    --maintainer dani-garcia \
    --deb-priority optional \
    --depends "$VAULT_DEB_DEPENDS" \
    --description "Bitwarden Server (Rust Edition)" \
    --version "$VAULT_SERVER_VERSION" \
    --license "AGPL-3.0" \
    --url "https://github.com/dani-garcia/vaultwarden" \
    --deb-systemd "$BASEDIR/package-files/vaultwarden.service" \
    --no-deb-systemd-enable \
    --no-deb-systemd-auto-start \
    --no-deb-systemd-restart-after-upgrade \
    --before-install "$BASEDIR/package-files/before-install.sh" \
    "$VAULTDIR/target/$VAULT_TARGET/release/vaultwarden=/usr/bin/vaultwarden" \
    "$WEBDIR/web-vault/apps/web/build/=/usr/share/vaultwarden/web-vault" \
    "$BASEDIR/package-files/vaultwarden.env=/etc/vaultwarden/.env" \
    ;
