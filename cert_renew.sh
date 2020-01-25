#!/bin/bash
set -e

systemctl stop nginx
certbot renew
systemctl start nginx
