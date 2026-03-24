#!/bin/bash

DOMAIN_FILE="/etc/AutoScriptX/domain"

gum format --theme dracula --type markdown "# 🛠️ Create SSH Account"

echo -ne "\e[38;5;212m Username:\e[0m "
read -r username
echo -ne "\e[38;5;212m Password:\e[0m "
read -r password

domain=$(cat "$DOMAIN_FILE")

jq --arg u "$username" --arg p "$password" \
   '.users += [{"user": $u, "pass": $p}]' \
   /etc/AutoScriptX/config/ssh-ify.json > /tmp/ssh-ify.json
mv /tmp/ssh-ify.json /etc/AutoScriptX/config/ssh-ify.json

systemctl restart ssh-ify

gum format --theme dracula --type markdown <<EOF
# SSH Account Created

** Username**    : \`$username\`  
** Password**    : \`$password\`  
** Host**        : $domain  

# Ports

- SSH WS (HTTP)  : 80
- SSH WSS (HTTPS): 443
- UDPGW          : 7200,7300

# Payloads

**WSS Payload**
\`\`\`
GET wss://example.com HTTP/1.1[crlf]
Host: $domain[crlf]
Upgrade: websocket[crlf][crlf]
\`\`\`

**WS Payload**  
\`\`\`
GET / HTTP/1.1[crlf]
Host: $domain[crlf]
Upgrade: websocket[crlf][crlf]
\`\`\`
EOF

gum confirm "Return to menu?" && asx
