#!/bin/bash

gum format --theme dracula --type markdown "# Change Domain"

echo -ne "\e[38;5;212m Domain:\e[0m "
read -r domain

if [[ -z "$domain" ]]; then
  gum style --foreground 1 "No domain entered."
  echo -e
  gum confirm "Return to menu?" && asx
  exit 0
fi

echo "$domain" > /etc/AutoScriptX/domain
gum style --foreground 10 " Domain set to: $domain"

systemctl stop nginx >/dev/null 2>&1
fuser -k 80/tcp >/dev/null 2>&1
sed -i "s/server_name .*/server_name $domain;/" /etc/nginx/conf.d/reverse-proxy.conf

echo -e "\e[38;5;220m Issuing SSL for $domain...\e[0m"
/root/.acme.sh/acme.sh --set-default-ca --server letsencrypt >/dev/null 2>&1
/root/.acme.sh/acme.sh --issue -d $domain --standalone -k ec-256 >/dev/null 2>&1
/root/.acme.sh/acme.sh --installcert -d $domain \
    --fullchainpath /etc/AutoScriptX/cert.crt \
    --keypath /etc/AutoScriptX/cert.key --ecc >/dev/null 2>&1

[[ $? -ne 0 ]] && gum style --foreground 1 "SSL certificate issue failed." && exit 1

systemctl restart nginx >/dev/null 2>&1

gum style --foreground 10 " Domain and SSL setup complete!"

echo -e
gum confirm "Return to menu?" && asx
