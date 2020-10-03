#!/bin/bash

[ -v ${DEVPROXY_COMMAND} ] && exit 1

# apply routine
apply() {

    # start apply routine
    echo "Applying configuration to system..."

    dir_src="$1"
    dir_config="$2"
    dir_build="$3"
    
    mkdir -p "$dir_build"
    \cp /etc/hosts "$dir_build"/hosts
    \cp /etc/hosts /etc/hosts~"$(date +%s)"

    # choose active distribution/system
    distribution=$(get_distribution)
    case "$distribution" in

        # centos / fedora
        centos|fedora)
            selinux_status=$(getenforce)
            if [ "$selinux_status" == "Permissive" ] || [ "$selinux_status" == "Enforcing" ]; then
                chcon -Rt svirt_sandbox_file_t "$dir_src"
                chcon -Rt svirt_sandbox_file_t "$dir_config"
                chcon -Rt svirt_sandbox_file_t "$dir_build"
            fi;
            docker run -it --rm \
                --name http-devproxy-builder \
                -v "$dir_src":/usr/src/http-devproxy-src \
                -v "$dir_config":/usr/src/http-devproxy-config \
                -v "$dir_build":/usr/src/http-devproxy-build \
                -w /usr/src/http-devproxy-src \
                python:3 python builder.py
            \cp -r "$dir_build"/conf.d /etc/nginx/
            \cp -r "$dir_src"/html /usr/share/nginx/
            \cp -r "$dir_build"/ssl /etc/nginx/ssl_cert
            systemctl restart nginx
            \cp "$dir_build"/hosts /etc/hosts
        ;;

        # ubuntu / debian / raspbian
        ubuntu|debian|raspbian)
            echo "Operating system not supported."
            exit 1
        ;;

        # none of the above
        *)
            echo "Operating system not supported."
            exit 1
        ;;
    esac

    # apply complete
    echo "...complete!"
}
