# devproxy - HTTP(S) proxy for developers

[<!--lint ignore no-dead-urls-->![GitHub Actions status | rewgaz/devproxy setup](https://github.com/rewgaz/devproxy/workflows/setup/badge.svg)](https://github.com/rewgaz/devproxy/actions?workflow=setup)

HTTP(S) proxy config builder - to make development with multiple containers easier.

## Preface

Working with multiple Docker containers on different projects running on port 80/443 at the same time requires a lot of annoying configuration and potentially ends in a headache. This project tries to make this process a lot easier and faster, and makes it look like you only have one webserver running.

`!! Use this tool at your own risk. If your system setup differs from common defaults, this tool might not work or even break your system's configuration. !!`

Supported operating systems:

- Fedora (Tested on Fedora Server 30)
- Ubuntu (Tested on Ubuntu 18.04)

Note: Most of the commands need root privileges.

## Setup - Step 1: Initial setup

Note: Most of the commands need root privileges.

Install devproxy:

```bash
make install
```

The setup command disables a potentially running `Apache Webserver`, installs `NGINX`, `Docker`, `docker-compose` and `certbot`.
It also opens port `80` and `443` in your firewall if necessary.

```bash
devproxy setup
```

## Setup - Step 2: Host configuration

Put a config file for each host in the `config` folder and name it for example `my-website.com.json`. Only JSON files with the suffix `.json` will be read.

### Example

This example config file is for a webserver using HTTP and HTTPS. The host names `my-website.com` and `alternative.my-website.com` will be redirected to `www.my-website.com`. All incoming traffic on `www.my-website.com` will be passed to a webserver listening on `0.0.0.0:18010` for HTTP and `0.0.0.0:14010` for HTTPS.

```json
{
    "version": 1,
    "host": {
        "hostname": "www.my-website.com",
        "alternatives": [
            "my-website.com"
            "alternative.my-website.com"
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

This host config will result in the following behaviour:

```plain
http://my-website.com -> (301) -> http://www.my-website.com
http://alternative.my-website.com -> (301) -> http://www.my-website.com
http://www.my-website.com -> (proxy_pass) -> http://0.0.0.0:18010

https://my-website.com -> (301) -> https://www.my-website.com
https://alternative.my-website.com -> (301) -> https://www.my-website.com
https://www.my-website.com -> (proxy_pass) -> https://0.0.0.0:14010
```

## Setup - Step 3: Save config

The `save` command parses all config files and creates all necessary NGINX config files and adds hostnames to your `/etc/hosts` file.
Rerun this command after you changed any config files or added/renewed any SSL certificates.

```bash
devproxy save
```

## SSL certificates

To quickly generate SSL certificates for your hosts you can use the buildin Certbot commands.

### Create a new SSL certificate

Create a SSL certificate with Certbot for your host.

```bash
devproxy cert:create my-website.com
```

### Renew SSL certificates

Renew all SSL certificates created with Certbot if necessary.

```bash
devproxy cert:renew
```

### Fedora: Use Certbot certificate for Cockpit

Configure Cockpit to use a certificate created by the `cert:create` command. This will override the current SSL certificate in Cockpit if present.

```bash
devproxy cert:cockpit.sh my-website.com
```
