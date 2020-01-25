import glob
import json
import os
import shutil


path_config = '/usr/src/http-gateway-config'
path_build = '/usr/src/http-gateway-build'
path_hosts = '/usr/src/http-gateway-build/hosts'
hosts_separator = '### http-gateway ###'

template_location = '''location / {{
        proxy_pass http://{ip}:{port}/;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    }}'''

template_http = '''server {{
    listen 80;
    listen [::]:80;
    server_name {server_name};

    '''+template_location+'''
}}'''

template_https = '''server {{
    listen 443 ssl;
    listen [::]:443 ssl;
    server_name {server_name};
    
    ssl_certificate "{ssl_cert}";
    ssl_certificate_key "{ssl_key}";
    ssl_session_cache shared:SSL:1m;
    ssl_session_timeout  10m;
    ssl_ciphers PROFILE=SYSTEM;
    ssl_prefer_server_ciphers on;

    '''+template_location+'''
}}'''


def read_config():

    config = []
    config_files = glob.glob(path_config+'/*.json')

    for config_filename in config_files: 
        with open(config_filename) as json_file:
            data = json.load(json_file)
            if isinstance(data, dict):
                config.append(data)
            elif isinstance(data, list):
                for obj in data:
                    if isinstance(obj, dict):
                        config.append(obj)
    
    return config


def build_hosts_str(host):

    return '127.0.0.1 '+host['hostname'].strip()+'\n'


def build_nginx_conf_host(host, hostname, path_cert, path_key):

    if host['protocol'] == 'http':
        host_config = template_http.format(
            server_name=hostname,
            ip=host['target']['ip'].strip(),
            port=host['target']['port'].strip(),
        )
    elif host['protocol'] == 'https':
        host_config = template_https.format(
            server_name=hostname,
            ip=host['target']['ip'].strip(),
            port=host['target']['port'].strip(),
            ssl_cert=path_cert,
            ssl_key=path_key,
        )
    else:
        print("Unrecognized protocol @ " + hostname)
        return

    text_file = open(path_build+'/conf.d/'+hostname+'.'+host['protocol']+'.conf', 'x')
    text_file.write(host_config)
    text_file.close()


def build_nginx_conf(host):

    hostname = host['hostname'].strip()
    path_cert = '/etc/nginx/ssl_cert/' + hostname + '.pem'
    path_key = '/etc/nginx/ssl_cert/' + hostname + '.key'

    build_nginx_conf_host(host, hostname, path_cert, path_key)

    for alternativehostname in host['alternatives']:
        build_nginx_conf_host(host, alternativehostname.strip(), path_cert, path_key)


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


def build():

    config = read_config()
    hosts_data = []

    hosts_file = open(path_hosts, 'rt')
    hosts_file_lines = hosts_file.readlines()
    hosts_file.close()

    shutil.rmtree(path_build, ignore_errors=True)
    os.makedirs(path_build + '/conf.d/', exist_ok=True)
    os.makedirs(path_build + '/ssl/', exist_ok=True)

    for host in config:
        build_nginx_conf(host)
        build_ssl_cert(host)
        hosts_data.append(build_hosts_str(host))

    first_line_to_ignore = None
    for num, line in enumerate(hosts_file_lines, start=0):
        if line.startswith(hosts_separator):
            first_line_to_ignore = num
            break
    
    if first_line_to_ignore is None:
        hosts_data_all = hosts_file_lines
    else:
        hosts_data_all = hosts_file_lines[0:first_line_to_ignore]

    hosts_data_all.append('\n'+hosts_separator+'\n')
    hosts_data_all = hosts_data_all + hosts_data

    hosts_file = open(path_hosts, 'wt')
    for line in hosts_data_all:
        hosts_file.write(line)
    hosts_file.close()


if __name__ == '__main__':
    build()
