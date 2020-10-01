install() {
    distribution=$(get_distribution)

    case "$distribution" in
        centos|fedora)
            selinux_status=$(getenforce)
            if [ "$selinux_status" == "Permissive" ] || [ "$selinux_status" == "Enforcing" ]; then
                setsebool -P httpd_can_network_connect 1
            fi;
            dnf -y update
            dnf -y install cockpit-docker docker-compose
            systemctl start docker
            systemctl enable docker
            if systemctl is-active httpd; then
                systemctl stop httpd
            fi
            if systemctl is-enabled httpd; then
                systemctl disable httpd
            fi
            dnf -y install nginx
            systemctl start nginx
            systemctl enable nginx
            firewall-cmd --permanent --add-service=https
            firewall-cmd --permanent --add-service=http
            firewall-cmd --reload
            dnf -y install certbot
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
}
