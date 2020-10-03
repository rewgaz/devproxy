# -*- coding: utf-8 -*-
import glob
import json
import os
import shutil


path_config = '/etc/devproxy/config'
path_build = '/usr/local/src/devproxy/build'
path_hosts = '/usr/local/src/devproxy/build/hosts'
hosts_separator = '### http-devproxy ###'

template_location = '''location / {{
        proxy_pass {protocol}://{ip}:{port}/;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    }}'''

template_http = '''server {{
    listen 80;
    listen [::]:80;
    server_name {server_name};

    '''+template_location+'''
    
    {redirects}
}}'''

template_https = '''server {{
    listen 443 ssl;
    listen [::]:443 ssl;
    server_name {server_name};

    ssl_certificate "{ssl_cert}";
    ssl_certificate_key "{ssl_key}";
    ssl_session_cache shared:SSL:1m;
    ssl_session_timeout  10m;
    ssl_prefer_server_ciphers on;
    ssl_protocols TLSv1 TLSv1.1 TLSv1.2;
    ssl_ciphers HIGH:!aNULL:!MD5;
    keepalive_timeout 70;

    '''+template_location+'''
    
    {redirects}
}}'''

template_redirect_to_https = '''if ($scheme != "https") {
        return 301 https://$host$request_uri;
    }'''

template_redirect_to_host = '''if ($host != "{host}") {{
        return 301 {protocol}://{host}$request_uri;
    }}'''


def read_config_ver_1_0(config_file):
    """
        Read host config file and return data
        :param config_file: string
        :return: dict
    """
    parser_version = '1'

    data = json.load(config_file)
    file_version = 'unknown'
    if isinstance(data, dict) and data.get('version') is not None:
        file_version = str(data.get('version'))

    if file_version != parser_version:
        raise Exception('Config file version mismatch: Expected \'{parser_version}\', got \'{file_version}\''.format(
            parser_version=parser_version,
            file_version=file_version,
        ))

    return data


def read_config():
    """
    Read all host config files and return as list
    :return: list
    """
    config = []
    config_files = glob.glob(path_config+'/*.json')

    for config_filename in config_files:
        config_file = open(config_filename, 'rt')
        config.append(read_config_ver_1_0(config_file))
        config_file.close()
    
    return config


def build_hosts_str(host):

    # todo alternatives
    return '127.0.0.1 '+host['host']['hostname'].strip()+'\n'


def build_nginx_conf(host):
    """
    Write NGINX config for a host
    """
    hostname = host['host']['hostname'].strip()
    hostnames_all = hostname
    for alternative in host['host']['alternatives']:
        hostnames_all = hostnames_all + ' ' + alternative.strip()

    for target in host['host']['targets']:

        redirects = ''
        if len(host['host']['alternatives']) > 0:
            redirects = template_redirect_to_host.format(
                host=hostname,
                protocol=target['protocol'],
            )

        if target['protocol'] == 'http':
            host_config = template_http.format(
                server_name=hostnames_all,
                protocol='http',
                ip=target['ip'].strip(),
                port=target['port'].strip(),
                redirects=redirects,
            )

        elif target['protocol'] == 'https':
            host_config = template_https.format(
                server_name=hostnames_all,
                protocol='https',
                ip=target['ip'].strip(),
                port=target['port'].strip(),
                ssl_cert=target['ssl_cert'].strip(),
                ssl_key=target['ssl_key'].strip(),
                redirects=redirects,
            )

        else:
            raise Exception('Unrecognized protocol \'{protocol}\' @ {hostname}'.format(
                hostname=hostname,
                protocol=target['protocol'],
            ))

        config_file = open(path_build + '/conf.d/' + hostname + '.' + target['protocol'] + '.conf', 'xt')
        config_file.write(host_config)
        config_file.close()


def build_ssl_cert(host):

    path_cert = path_build + '/ssl/' + host['hostname'] + '.pem'
    path_key = path_build + '/ssl/' + host['hostname'] + '.key'

    if host['protocol'] == 'https' and not os.path.isfile(path_cert):
        cmd = '''
            openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
            -out '''+path_cert+''' \
            -keyout '''+path_key+''' \
            -subj "/C=AT/ST=Vienna/L=Vienna/O=Security/OU=Development/CN=localhost" \
        '''
        os.system(cmd)


def build_hosts_file(hosts_data, hosts_file_lines):
    """
    Write new /etc/hosts file
    """

    first_line_to_ignore = None
    for num, line in enumerate(hosts_file_lines, start=0):
        if line.startswith(hosts_separator):
            first_line_to_ignore = num
            break

    if first_line_to_ignore is None:
        hosts_data_all = hosts_file_lines
    else:
        hosts_data_all = hosts_file_lines[0:first_line_to_ignore]

    hosts_data_all.append('\n' + hosts_separator + '\n')
    hosts_data_all = hosts_data_all + hosts_data

    hosts_file = open(path_hosts, 'wt')
    for line in hosts_data_all:
        hosts_file.write(line)
    hosts_file.close()


def build():
    """
    Entry point
    """

    # Read existing /etc/hosts file
    hosts_file = open(path_hosts, 'rt')
    hosts_file_lines = hosts_file.readlines()
    hosts_file.close()

    # Remove all files in build folder
    shutil.rmtree(path_build, ignore_errors=True)
    os.makedirs(path_build + '/conf.d/', exist_ok=True)
    os.makedirs(path_build + '/ssl/', exist_ok=True)

    # Read all host config files
    config = read_config()
    hosts_data = []
    for host in config:
        build_nginx_conf(host)
        #build_ssl_cert(host)
        hosts_data.append(build_hosts_str(host))

    # Write new /etc/hosts file
    build_hosts_file(hosts_data, hosts_file_lines)


if __name__ == '__main__':
    build()
