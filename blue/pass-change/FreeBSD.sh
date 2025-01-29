#!/bin/sh

# Check if the script is run as root
if [ "$(id -u)" -ne 0 ]; then
    echo "This script must be run as root. Use sudo."
    exit 1
fi

# Prompt for admin and user passwords securely
read -r -s -p "Enter ADMIN password: " ADMIN_PASSWORD
echo
read -r -s -p "Enter USER password: " USER_PASSWORD
echo

declare -A USERS
USERS=(
    [president]="$ADMIN_PASSWORD"
    [vicepresident]="$ADMIN_PASSWORD"
    [defenseminister]="$ADMIN_PASSWORD"
    [secretary]="$ADMIN_PASSWORD"
    [general]="$USER_PASSWORD"
    [admiral]="$USER_PASSWORD"
    [judge]="$USER_PASSWORD"
    [bodyguard]="$USER_PASSWORD"
    [cabinetofficial]="$USER_PASSWORD"
    [treasurer]="$USER_PASSWORD"
)

# Change passwords for specified users
for USER in "${!USERS[@]}"; do
    if pw usershow "$USER" >/dev/null 2>&1; then
        echo "Changing password for user: $USER"
        echo "${USERS[$USER]}" | pw usermod "$USER" -h 0 >/dev/null 2>&1
        if [ $? -eq 0 ]; then
            echo "Password successfully changed for $USER."
        else
            echo "Failed to change password for $USER."
        fi
    else
        echo "User $USER does not exist. Skipping."
    fi
done

# Disable login for all other users
while IFS=: read -r username _ uid _; do
    if [ "$uid" -ge 1000 ] && [ -z "${USERS[$username]}" ]; then
        echo "Disabling login for user: $username"
        pw usermod "$username" -s /usr/sbin/nologin >/dev/null 2>&1
        if [ $? -eq 0 ]; then
            echo "Login disabled for $username."
        else
            echo "Failed to disable login for $username."
        fi
    fi
done < /etc/passwd

echo "Process completed."
