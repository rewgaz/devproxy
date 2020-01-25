#!/bin/bash
set -e

certbot certonly --cert-name "$@"
