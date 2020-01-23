#!/bin/bash

set -e

THIS=$(readlink -f "$0")
THIS_DIR=$(dirname "$THIS")
BUILDER=$THIS_DIR"/builder"
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

case "$LSB_DIST" in
    centos|fedora)
        su -c "
            docker run -it --rm \
                --name http-gateway-builder \
                -v $BUILDER:/usr/src/http-gateway-builder \
                -v $CONFIG:/usr/src/http-gateway-config \
                -v $BUILD:/usr/src/http-gateway-build \
                -v /etc/hosts:/usr/src/http-gateway-hosts \
                -w /usr/src/http-gateway-builder \
                python:3 python builder.py
            cp -r $BUILD/conf.d /etc/nginx/
            cp -r $BUILDER/html /usr/share/nginx/
            cp -r $BUILD/ssl /etc/nginx/ssl_cert
            systemctl restart nginx
        "
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
