#!/bin/bash
set -e

THIS=$(readlink -f "$0")
THIS_DIR=$(dirname "$THIS")
SRC=$THIS_DIR"/src"
CONFIG=$THIS_DIR"/config"
BUILD=$THIS_DIR"/build"

get_distribution() {
    LSB_DIST=""
    if [ -r /etc/os-release ]; then
        LSB_DIST="$(. /etc/os-release && echo "$ID")"
    fi
    echo "$LSB_DIST"
}

LSB_DIST=$( get_distribution )
LSB_DIST="$(echo "$LSB_DIST" | tr '[:upper:]' '[:lower:]')"

mkdir -p "$BUILD"
\cp /etc/hosts "$BUILD"/hosts
\cp /etc/hosts /etc/hosts~"$(date +%s)"

case "$LSB_DIST" in
    centos|fedora)
        SELINUXSTATUS=$(getenforce)
        if [ "$SELINUXSTATUS" == "Permissive" ] || [ "$SELINUXSTATUS" == "Enforcing" ]; then
            chcon -Rt svirt_sandbox_file_t "$SRC"
            chcon -Rt svirt_sandbox_file_t "$CONFIG"
            chcon -Rt svirt_sandbox_file_t "$BUILD"
        fi;
        docker run -it --rm \
            --name http-gateway-builder \
            -v "$SRC":/usr/src/http-gateway-src \
            -v "$CONFIG":/usr/src/http-gateway-config \
            -v "$BUILD":/usr/src/http-gateway-build \
            -w /usr/src/http-gateway-src \
            python:3 python builder.py
        \cp -r "$BUILD"/conf.d /etc/nginx/
        \cp -r "$SRC"/html /usr/share/nginx/
        \cp -r "$BUILD"/ssl /etc/nginx/ssl_cert
        systemctl restart nginx
        \cp "$BUILD"/hosts /etc/hosts
    ;;
    rhel|ol|sles)
        echo "Operating system not supported."
    ;;
    ubuntu|debian|raspbian)
        echo "Operating system not supported."
    ;;
    *)
        echo "Operating system not supported."
    ;;
esac
