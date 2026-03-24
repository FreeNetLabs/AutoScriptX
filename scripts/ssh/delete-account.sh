#!/bin/bash


today=$(date +%s)

USER_LIST=$(jq -r '.users[] | .user + " (" + (.expire // "Never") + ")"' /etc/AutoScriptX/config/ssh-ify.json)

gum format --theme dracula --type markdown <<< "# Delete SSH Accounts"

if [ -z "$USER_LIST" ]; then
  gum style --foreground 1 "No SSH Account available to delete."
  echo -e
  gum confirm "Return to menu?" && asx
  exit 1
fi

SEL=$(echo -e "$USER_LIST" | gum choose --height=15 --no-limit --header="Use SPACE or X to select")
if [ -z "$SEL" ]; then
  gum style --foreground 1 "No accounts selected. Use SPACE or X to select"
  echo -e
  gum confirm "Return to menu?" && asx
  exit 0
fi

if ! gum confirm "Delete selected accounts?"; then
  gum format --type markdown <<< "** Cancelled.**"
  echo -e
  gum confirm "Return to menu?" && asx
  exit 0
fi

COUNT=0
while IFS= read -r u; do
  u_clean=$(echo "$u" | sed -r 's/ \([^\)]+\)//g')
  if jq -e --arg usr "$u_clean" '.users | map(select(.user == $usr)) | length > 0' /etc/AutoScriptX/config/ssh-ify.json > /dev/null; then
    jq --arg usr "$u_clean" '.users |= map(select(.user != $usr))' /etc/AutoScriptX/config/ssh-ify.json > /tmp/ssh-ify.json
    mv /tmp/ssh-ify.json /etc/AutoScriptX/config/ssh-ify.json
    ((COUNT++))
  fi
done <<< "$SEL"

if [ "$COUNT" -gt 0 ]; then
  systemctl restart ssh-ify
fi

gum format --type markdown <<< "# $COUNT Account(s) deleted"

echo -e
gum confirm "Return to menu?" && asx
