#!/bin/bash
set -e

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
            systemctl stop httpd
            systemctl disable httpd
            dnf -y install nginx
            systemctl start nginx
            systemctl enable nginx
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
