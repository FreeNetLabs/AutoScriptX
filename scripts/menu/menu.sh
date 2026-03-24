#!/bin/bash

if [ "$(id -u)" -ne 0 ]; then
  gum style --foreground "#ff5555" --border double --margin "1 2" --padding "1 2" "Please run this script as root."
  exit 1
fi

os_name=$(source /etc/os-release && echo "$PRETTY_NAME")
uptime=$(uptime -p); uptime=${uptime#up }
vps_domain=$(cat /etc/AutoScriptX/domain 2>/dev/null || echo "Not Set")
used_ram=$(free -m | awk 'NR==2 {print $3}')
total_ram=$(free -m | awk 'NR==2 {print $2}')

clear

gum format --theme dracula <<EOF

# AutoScriptX

- **OS**         : $os_name  
- **Uptime**     : $uptime  
- **Domain**     : $vps_domain  

# RAM Information

- **Used RAM**   : ${used_ram} MB  
- **Total RAM**  : ${total_ram} MB  

# Main Menu
EOF

opt=$(gum choose --limit=1 --header "  Choose" \
  "Create Account" \
  "Delete Account" \
  "Edit Banner" \
  "Change Domain" \
  "Manage Services" \
  "System Info" \
  "Uninstall" \
  "Exit")

clear
case "$opt" in
  "Create Account") create-account ;;
  "Delete Account") delete-account ;;
  "Edit Banner") edit-banner ;;
  "Change Domain") change-domain ;;
  "Manage Services") manage-services ;;
  "System Info") system-info ;;
  "Exit") exit ;;
esac
