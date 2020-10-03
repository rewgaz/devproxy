#!/bin/bash

[ -v ${DEVPROXY_COMMAND} ] && exit 1

# enable service
setup_enable_service() {

    # service name
    service="$1"

    # start service
    systemctl start "$service"

    # enable service
    systemctl enable "$service"
}

# disable service
setup_disable_service() {

    # service name
    service="$1"

    # stop service
    if systemctl is-active "$service"; then
        systemctl stop "$service"
    fi

    # disable service
    if systemctl is-enabled "$service"; then
        systemctl disable "$service"
    fi
}

# setup routine
setup() {

    # start setup
    echo "Setup..."

    # choose active distribution/system
    distribution=$(get_distribution)
    case "$distribution" in

        # centos / fedora
        centos|fedora)

            # check for selinux status
            selinux_status=$(getenforce)

            # enable selinux httpd_can_network_connect flag if necessary
            if [ "$selinux_status" == "Permissive" ] || [ "$selinux_status" == "Enforcing" ]; then
                setsebool -P httpd_can_network_connect 1
            fi;

            # update packages
            dnf -y update

            # install packages
            dnf -y install nginx certbot

            # disable httpd service
            setup_disable_service httpd

            # start/enable nginx
            setup_enable_service nginx

            # allow http/https in firewall
            firewall-cmd --permanent --add-service=https
            firewall-cmd --permanent --add-service=http

            # reload firewall config
            firewall-cmd --reload
        ;;

        # ubuntu / debian / raspbian
        ubuntu|debian|raspbian)

            # update packages
            apt-get update
            apt-get -y upgrade

            # install packages
            apt-get -y install nginx certbot

            # disable apache2 service
            setup_disable_service apache2

            # start/enable nginx
            setup_enable_service nginx
        ;;

        # none of the above
        *)
            echo "Operating system not supported."
            exit 1
        ;;
    esac

    # setup complete
    echo "...complete!"
}
