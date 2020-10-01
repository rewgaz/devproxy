setup() {
    dir_src="$1"
    dir_config="$2"
    dir_build="$3"
    distribution=$(get_distribution)

    mkdir -p "$dir_build"
    \cp /etc/hosts "$dir_build"/hosts
    \cp /etc/hosts /etc/hosts~"$(date +%s)"

    case "$distribution" in
        centos|fedora)
            selinux_status=$(getenforce)
            if [ "$selinux_status" == "Permissive" ] || [ "$selinux_status" == "Enforcing" ]; then
                chcon -Rt svirt_sandbox_file_t "$dir_src"
                chcon -Rt svirt_sandbox_file_t "$dir_config"
                chcon -Rt svirt_sandbox_file_t "$dir_build"
            fi;
            docker run -it --rm \
                --name http-gateway-builder \
                -v "$dir_src":/usr/src/http-gateway-src \
                -v "$dir_config":/usr/src/http-gateway-config \
                -v "$dir_build":/usr/src/http-gateway-build \
                -w /usr/src/http-gateway-src \
                python:3 python builder.py
            \cp -r "$dir_build"/conf.d /etc/nginx/
            \cp -r "$dir_src"/html /usr/share/nginx/
            \cp -r "$dir_build"/ssl /etc/nginx/ssl_cert
            systemctl restart nginx
            \cp "$dir_build"/hosts /etc/hosts
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
