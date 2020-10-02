get_distribution() {
	lsb_dist=""
	if [ -r /etc/os-release ]; then
		lsb_dist="$(. /etc/os-release && echo "$ID")"
	fi
	echo $(echo "$lsb_dist" | tr '[:upper:]' '[:lower:]')
}

print_help() {
    echo -e "\e[94mUsage:\e[39m"
    echo -e "  ./devproxy [command] ?[argument]"
    echo -e ""
    echo -e "\e[94mCommands:\e[39m"
    echo -e "\e[96m  help, -h, --help\e[39m         Display this help message"
    echo -e "\e[96m  install\e[39m                  Install"
    echo -e "\e[96m  setup\e[39m                    Setup"
    echo -e "\e[94m cert\e[39m"
    echo -e "\e[96m  cert:create [domain]\e[39m     Create new certificate"
    echo -e "\e[96m  cert:renew\e[39m               Renew existing certificates"
    echo -e "\e[96m  cert:cockpit [domain]\e[39m    Configure Cockpit to use a certificate"
}
