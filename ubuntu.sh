#!/bin/bash

# Function to display usage
usage() {
    echo "Usage: sudo $0 <new_password>"
    exit 1
}

# Ensure the script is run as root
if [ "$EUID" -ne 0 ]; then
    echo "This script must be run as root."
    exit 1
fi

# Ensure the new password is provided as an argument
if [ -z "$1" ]; then
    usage
fi

NEW_PASSWORD="$1"

# Get a list of all user accounts excluding system users
USER_ACCOUNTS=$(awk -F: '($3 >= 1000 && $3 != 65534) {print $1}' /etc/passwd)

# Iterate through the user accounts and change passwords
for USER in $USER_ACCOUNTS; do
    echo "Changing password for user: $USER"
    echo -e "$NEW_PASSWORD\n$NEW_PASSWORD" | passwd "$USER" > /dev/null 2>&1

    if [ $? -eq 0 ]; then
        echo "Password changed successfully for $USER."
    else
        echo "Failed to change password for $USER."
    fi
done

echo "All user passwords have been updated."
