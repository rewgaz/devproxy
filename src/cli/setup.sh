setup() {
    echo "Setup..."

    distribution=$(get_distribution)

    case "$distribution" in
        centos|fedora)
            selinux_status=$(getenforce)
            if [ "$selinux_status" == "Permissive" ] || [ "$selinux_status" == "Enforcing" ]; then
                setsebool -P httpd_can_network_connect 1
            fi;
            dnf -y update
            dnf -y install docker cockpit-docker docker-compose nginx certbot
            if [[ -v ${CI_TASK_RUNNER} ]]; then
                systemctl start docker
                systemctl enable docker
            fi
            if systemctl is-active httpd; then
                systemctl stop httpd
            fi
            if systemctl is-enabled httpd; then
                systemctl disable httpd
            fi
            systemctl start nginx
            systemctl enable nginx
            firewall-cmd --permanent --add-service=https
            firewall-cmd --permanent --add-service=http
            firewall-cmd --reload
        ;;
        rhel|ol|sles)
            echo "Operating system not supported."
            exit 1
        ;;
        ubuntu|debian|raspbian)
            apt-get update
            apt-get -y upgrade
            apt-get -y install docker docker-compose nginx certbot
            if [[ -v ${CI_TASK_RUNNER} ]]; then
                systemctl start docker
                systemctl enable docker
            fi
            if systemctl is-active apache2; then
                systemctl stop apache2
            fi
            if systemctl is-enabled apache2; then
                systemctl disable apache2
            fi
            systemctl start nginx
            systemctl enable nginx
        ;;
        *)
            echo "Operating system not supported."
            exit 1
        ;;
    esac

    echo "...complete!"
}
