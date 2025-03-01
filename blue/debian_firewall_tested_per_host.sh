#!/bin/bash

# Function to configure ufw
configure_ufw() {
    echo "UFW is installed. Setting up firewall rules..."
    # Reset existing UFW rules
    sudo ufw reset
    sudo ufw default deny incoming
    sudo ufw default deny outgoing
    sudo ufw enable

    # Ask the user which ports to open
    echo "Enter the ports you want to open (space-separated):"
    read -r ports

    # check for ftp and open passive ports
    if [[ "$ports" =~  "21" ]]; then
        echo "add passive port 40000-50000"
        sudo ufw allow 40000:50000/tcp
    fi

    # Open the specified ports
    for port in $ports; do
        echo "Allowing traffic on port $port..."
	
	if [[ "$port" == "53" ]]; then
            echo "DNS is UDP"
            sudo ufw allow $port/udp
	else
	    sudo ufw allow $port/tcp
        fi

    done

    sudo ufw status verbose
}

# Function to configure iptables
configure_iptables() {
    echo "iptables is installed. Setting up firewall rules..."
    # Flush existing iptables rules
    sudo iptables -F


    # Ask the user which ports to open
    echo "Enter the ports you want to open (space-separated):"
    read -r ports

    # Open the specified ports
    for port in $ports; do
        echo "Allowing traffic on port $port..."
        sudo iptables -A INPUT -p tcp --dport $port -j ACCEPT
        sudo iptables -A OUTPUT -p tcp --sport $port -j ACCEPT
    done

    # Set default policies to deny incoming and outgoing traffic
    sudo iptables -P INPUT DROP
    sudo iptables -P OUTPUT DROP

    sudo iptables -L -v

}

#service iptables stop to kill

# Check if ufw is installed
if command -v ufw &> /dev/null; then
    configure_ufw
# If ufw is not installed, check for iptables
elif command -v iptables &> /dev/null; then
    configure_iptables
else
    echo "Neither ufw nor iptables are installed. Please install one of them to proceed."
    exit 1
fi

echo "Firewall configuration complete."
