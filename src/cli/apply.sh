#!/bin/bash

[ -v ${DEVPROXY_COMMAND} ] && exit 1

# apply routine
apply() {

    # start apply routine
    echo "Applying configuration to system..."

    # source directory
    dir_src="$base_dir"

    # config directory
    dir_config="/etc/devproxy/config"
    
    # create build directory in source directory
    rm -rf "$dir_src"/build
    mkdir -p "$dir_src"/build

    # copy /etc/hosts to build directory
    \cp /etc/hosts "$dir_src"/build/hosts

    # make a copy of the old /etc/hosts file to /etc/devproxy/hosts-backup
    mkdir -p /etc/devproxy/hosts-backup
    \cp /etc/hosts /etc/devproxy/hosts-backup/hosts~"$(date +%s)"

    # choose active distribution/system
    distribution=$(get_distribution)
    case "$distribution" in

        # centos / fedora
        centos|fedora)

            # check for selinux status
            selinux_status=$(getenforce)
            
            # set security context type of source folders if necessary
            if [ "$selinux_status" == "Permissive" ] || [ "$selinux_status" == "Enforcing" ]; then
                chcon -Rt svirt_sandbox_file_t "$dir_src"
                chcon -Rt svirt_sandbox_file_t "$dir_config"
            fi;
        ;;

        # ubuntu / debian / raspbian
        ubuntu|debian|raspbian)
            
            # nothing to do
        ;;

        # none of the above
        *)
            echo "Operating system not supported."
            exit 1
        ;;
    esac

    # run config builder
    python3 "$dir_src"/builder/builder.py
    
    # copy conf.d config to /etc/nginx
    \cp -r "$dir_src"/build/conf.d /etc/nginx/

    # copy html error pages to nginx
    \cp -r "$dir_src"/html /usr/share/nginx/

    # copy self-signed ssl certificates to nginx
    \cp -r "$dir_src"/build/ssl /etc/nginx/ssl_cert

    # overwrite /etc/hosts with appended host names
    \cp "$dir_src"/build/hosts /etc/hosts

    # restart nginx
    systemctl restart nginx

    # apply complete
    echo "...complete!"
}
