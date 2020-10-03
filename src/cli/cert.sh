#!/bin/bash

[ -v ${DEVPROXY_COMMAND} ] && exit 1

# create a certificate with certbot
cert_create() {

    # the domain
    domain="$1"

    # create the certificate
    certbot certonly --cert-name "$domain"
}

# renew certificates
cert_renew() {

    # stop nginx
    systemctl stop nginx
    
    # renew certificates created with certbot
    certbot renew

    # start nginx
    systemctl start nginx
}

# use a certificate created with certbot for fedora cockpit
cert_cockpit() {

    # the domain cockpit is using
    domain="$1"

    # copy certificate and key to cockpit certificates folder
    cat /etc/letsencrypt/live/"$domain"/fullchain.pem > /etc/cockpit/ws-certs.d/"$domain".cert
    cat /etc/letsencrypt/live/"$domain"/privkey.pem >> /etc/cockpit/ws-certs.d/"$domain".cert

    # restart cockpit service
    systemctl restart cockpit.service
}
