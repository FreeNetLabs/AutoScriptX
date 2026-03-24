#!/bin/bash

CONFIG_FILE="/etc/AutoScriptX/config/ssh-ify.json"

sudo cp "$CONFIG_FILE" "${CONFIG_FILE}.bak"

gum format --theme dracula --type markdown "# Edit SSH Banner"

if [ -s "$CONFIG_FILE" ]; then
    CURRENT_CONTENT=$(jq -r '.banner // ""' "$CONFIG_FILE")
else
    CURRENT_CONTENT="# Enter your new SSH banner message here"
fi

NEW_BANNER=$(echo "$CURRENT_CONTENT" | gum write --width 60 --height 15 --placeholder "Edit SSH Banner")

if [ -z "$NEW_BANNER" ] || [ "$NEW_BANNER" = "$CURRENT_CONTENT" ]; then
    gum style --foreground 1 "No changes detected. Banner not updated."
else
    gum confirm "Do you want to save this as your new SSH banner?" && {
        # Using simple escape for safety
        jq --arg b "$NEW_BANNER\n" '.banner = $b' "$CONFIG_FILE" > /tmp/ssh-ify.json
        mv /tmp/ssh-ify.json "$CONFIG_FILE"
        sudo systemctl restart ssh-ify >/dev/null 2>&1
        gum style --foreground 2 " Banner updated successfully!"
    } || {
        gum style --foreground 2 " Cancelled. No changes were made."
    }
fi

echo -e
gum confirm "Return to menu?" && asx
