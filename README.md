# HTTP(S) Gateway for developers

HTTP(S) gateway config builder - to make development with multiple Docker containers easier.

## Preface

Working with multiple docker containers on different projects running on port 80/443 at the same time requires a lot of annoying configuration and potentially ends in a headache. This project tries to make this process a lot easier and faster.

`!! Use this tool at your own risk. If your system setup differs from common defaults, this tool might not work or even break your system. !!`

Supported operating systems:

- Fedora (Tested on Fedora Server 30)

## Initial installation

```bash
sudo ./install.sh
```

The installation script disables a potentially running `Apache Webserver`, installs `NGINX`, `Docker`, `docker-compose` and `certbot`.
It also opens port `80` and `443` in your firewall.

## Usage guide

### Host configuration

Place a config file for each host in the `config` folder and name it for example `my-website.com.json`. Only JSON files with the suffix `.json` will be read.

#### Examples

Config file for a website using only HTTP. `my-website.com` will be redirected to `www.my-website.com`. Incoming traffic will redirected to a host running on `0.0.0.0:18010` for HTTP and to `0.0.0.0:14010` for HTTPS.

```json
{
    "version": 1,
    "host": {
        "hostname": "www.my-website.com",
        "alternatives": [
            "my-website.com"
        ],
        "targets": [
            {
                "protocol": "http",
                "ip": "0.0.0.0",
                "port": "18010"
            },
            {
                "protocol": "https",
                "ip": "0.0.0.0",
                "port": "14010",
                "ssl_cert": "/etc/letsencrypt/live/my-website.com/fullchain.pem",
                "ssl_key": "/etc/letsencrypt/live/my-website.com/privkey.pem"
            }
        ]
    }
}
```

### Setup & config renewal

```bash
sudo ./setup.sh
```

The setup script creates all necessary NGINX config files and adds hostnames to your `/etc/hosts` file.
Rerun this script after you changed any config files or created or renewed any SSL certificates.

### Create a new SSL certificate

```bash
sudo ./cert_create.sh my-website.com
```

Create a SSL certificate with Certbot for your host.

### Renew SSL certificates

```bash
sudo ./cert_renew.sh
```

Renew all SSL certificates created with Certbot if necessary.

### Use Certbot certificate for Cockpit

```bash
sudo ./cert_cockpit.sh my-website.com
```

Configure Cockpit to use a certificate created by the `cert_create.sh` script.
