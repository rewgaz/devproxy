cert_create() {
    certbot certonly --cert-name "$1"
}

cert_renew() {
    systemctl stop nginx
    certbot renew
    systemctl start nginx
}

cert_cockpit() {
    domain="$1"
    cat /etc/letsencrypt/live/"$domain"/fullchain.pem > /etc/cockpit/ws-certs.d/"$domain".cert
    cat /etc/letsencrypt/live/"$domain"/privkey.pem >> /etc/cockpit/ws-certs.d/"$domain".cert
    systemctl restart cockpit.service
}
