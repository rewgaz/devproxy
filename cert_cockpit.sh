#!/bin/bash
set -e

HOST="$@"

cat /etc/letsencrypt/live/"$HOST"/fullchain.pem > /etc/cockpit/ws-certs.d/"$HOST".cert
cat /etc/letsencrypt/live/"$HOST"/privkey.pem >> /etc/cockpit/ws-certs.d/"$HOST".cert
