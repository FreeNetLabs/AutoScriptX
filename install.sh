#!/bin/bash


BASE_URL="https://raw.githubusercontent.com/FreeNetLabs/AutoScriptX/rewrite"

domain=""

check_root() {
    if [ "$(id -u)" -ne 0 ]; then
        echo "Run as root."
        exit 1
    fi
}

setup_domain() {
    mkdir -p /etc/AutoScriptX
    read -rp "Enter Your Domain: " domain
    if [[ -n "$domain" ]]; then
        if echo "$domain" > /etc/AutoScriptX/domain; then
            echo "Domain saved: $domain"
        else
            echo "Failed to save domain."
            exit 1
        fi
    else
        echo "Skipping domain setup. You can configure it later from the script menu."
    fi
}

update_system() {
    echo "Updating system..."
    apt update -y
    apt upgrade -y
    if [[ $? -ne 0 ]]; then 
        echo "System update failed."
        exit 1
    fi
    echo "System updated."
}

install_packages() {
    echo "Installing packages..."
    apt install -y debian-keyring debian-archive-keyring apt-transport-https

    curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/gpg.key' | gpg --dearmor -o /usr/share/keyrings/caddy-stable-archive-keyring.gpg
    curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/debian.deb.txt' | tee /etc/apt/sources.list.d/caddy-stable.list

    mkdir -p /etc/apt/keyrings
    curl -fsSL https://repo.charm.sh/apt/gpg.key | gpg --dearmor -o /etc/apt/keyrings/charm.gpg
    echo "deb [signed-by=/etc/apt/keyrings/charm.gpg] https://repo.charm.sh/apt/ * *" | tee /etc/apt/sources.list.d/charm.list

    apt update -y
    apt install -y \
      netfilter-persistent iptables-persistent screen curl jq bzip2 gzip vnstat coreutils rsyslog \
      zip unzip net-tools nano lsof shc gnupg dos2unix dirmngr bc \
      stunnel4 caddy socat xz-utils gnupg gum
    if [[ $? -ne 0 ]]; then 
        echo "Failed to install one or more packages."
        exit 1
    fi

    echo "Packages installed."
}

configure_ssh_ify() {
    echo "Setting up SSH-Ify..."
    systemctl stop ssh-ify || true
    mkdir -p /etc/AutoScriptX/bin
    mkdir -p /etc/AutoScriptX/config
    wget -qO /tmp/ssh-ify.tar.gz "https://github.com/FreeNetLabs/ssh-ify/releases/download/v0.0.1/ssh-ify_0.0.1_linux_amd64.tar.gz" || echo "Failed to download ssh-ify."
    tar -xzf /tmp/ssh-ify.tar.gz -C /tmp
    mv /tmp/ssh-ify /etc/AutoScriptX/bin/ssh-ify
    chmod +x /etc/AutoScriptX/bin/ssh-ify
    rm -f /tmp/ssh-ify.tar.gz

    wget -qO /etc/AutoScriptX/config/ssh-ify.json "$BASE_URL/config/ssh-ify.json" || echo "Failed to download ssh-ify config."
    wget -qO /etc/systemd/system/ssh-ify.service "$BASE_URL/service/systemd/ssh-ify.service" || echo "Failed to download ssh-ify service."
    
    systemctl daemon-reload
    systemctl enable ssh-ify
    systemctl restart ssh-ify || echo "Failed to restart ssh-ify."
    echo "SSH-Ify configured."
}

configure_caddy() {
    echo "Setting up Caddy..."
    wget -qO /etc/caddy/Caddyfile "$BASE_URL/config/Caddyfile" || echo "Failed to download Caddyfile."
    if [[ -n "$domain" ]]; then
        # Only replace the top-level site block address, avoid touching :8080 in proxy targets
        sed -i "/^:80[[:space:]]*{/ s/^:80/$domain:80/" /etc/caddy/Caddyfile
        echo "Caddy configured for domain: $domain:80"
    else
        echo "No domain provided; keeping default :80 in Caddyfile."
    fi

    systemctl daemon-reload
    systemctl enable caddy
    systemctl restart caddy || echo "Failed to restart Caddy."
    echo "Caddy set up."
}

setup_badvpn() {
    echo "Setting up BadVPN..."
    for port in 7200 7300; do
      systemctl stop badvpn-udpgw@${port}.service || true
    done
    pkill -f badvpn-udpgw || true
    rm -f /usr/bin/badvpn-udpgw
    wget -qO /usr/bin/badvpn-udpgw "$BASE_URL/bin/badvpn-udpgw" || echo "Failed to download BadVPN."
    chmod +x /usr/bin/badvpn-udpgw
    wget -qO /etc/systemd/system/badvpn-udpgw@.service "$BASE_URL/service/systemd/badvpn-udpgw@.service" || echo "Failed to download badvpn-udpgw@.service."
    for port in 7200 7300; do
          systemctl enable --now badvpn-udpgw@${port}.service || echo "Failed to start badvpn-udpgw@${port}.service."
    done
    echo "BadVPN set up."
}

install_scripts() {
    echo "Installing scripts..."
    declare -A script_dirs=(
      [menu]="menu.sh"
      [ssh]="create-account.sh delete-account.sh edit-banner.sh"
      [system]="change-domain.sh manage-services.sh system-info.sh"
    )
    for dir in "${!script_dirs[@]}"; do
      for s in ${script_dirs[$dir]}; do
        base="${s%.sh}"
        wget -qO "/usr/bin/$base" "$BASE_URL/scripts/$dir/$s" || echo "Failed to download $s."
        chmod +x "/usr/bin/$base"
      done
    done
    
    echo "Scripts installed."
}

final_cleanup() {
    echo "Final cleanup..."
    
    for link in autoscriptx asx; do
      ln -sf /usr/bin/menu /usr/bin/$link
      chmod +x /usr/bin/$link
    done
    
    echo "Final cleanup done."
}

main() {
    check_root
    setup_domain

    update_system
    install_packages

    configure_ssh_ify
    configure_caddy
    setup_badvpn

    install_scripts
    final_cleanup

    echo "Installation complete."
    echo "Run autoscriptx or asx to start."
}

main "$@"
