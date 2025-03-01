#!/bin/bash

# Log file path
logPath="/var/log/firewallscript.log"
backupDir="/opt/firewallbackups"

# Host service definitions
declare -A host_services
host_services["ebanking"]="HTTP,SSH"   # Ebanking; Arch Linux 2024.11.01; HTTP, SSH
host_services["accounts"]="MySQL,SSH"  # Accounts; Debian 12.7; MySQL, SSH
host_services["atm"]="SSH"           # ATM; Ubuntu 22.04, SSH
host_services["lobby"]="Proxmox-Web"  # Lobby; Proxmox 8.2; Proxmox Web Interface
host_services["lockbox"]="FTP,SSH"       # Lockbox (formerly FTP); Ubuntu 22.04, FTP, SSH <--- RENAMED and SSH added

# Service to port mapping (add more as needed)
declare -A service_ports
service_ports["HTTP"]="80:tcp"
service_ports["HTTPS"]="443:tcp"
service_ports["SSH"]="22:tcp"
service_ports["MySQL"]="3306:tcp"
service_ports["Proxmox-Web"]="8006:tcp" # Default Proxmox Web Interface port
service_ports["FTP"]="21:tcp"
service_ports["FTP-DATA"]="20:tcp" # FTP Data channel (might need passive FTP handling too for more robust FTP)


# Function to log actions
log_action() {
    local message="$1"
    timestamp=$(date "+%Y-%m-%d %H:%M:%S")
    echo "[$timestamp] $message" >> "$logPath"
}

# Function to validate port number (basic check)
validate_port_number() {
    local port_number="$1"
    if ! [[ "$port_number" =~ ^[0-9]+$ ]]; then
        echo "Invalid port number! Port must be a number."
        return 1
    fi
    if [[ "$port_number" -lt 1 || "$port_number" -gt 65535 ]]; then
        echo "Invalid port number! Port must be between 1 and 65535."
        return 1
    fi
    return 0
}

# Function to validate protocol (basic check)
validate_protocol() {
    local protocol="$1"
    if ! [[ "$protocol" =~ ^(tcp|udp|TCP|UDP)$ ]]; then
        echo "Invalid protocol! Protocol must be TCP or UDP."
        return 1
    fi
    return 0
}

# Function to detect firewall system
detect_firewall() {
    if command -v ufw >/dev/null 2>&1; then
        echo "ufw"
    elif command -v nft >/dev/null 2>&1; then
        echo "nftables"
    elif command -v iptables >/dev/null 2>&1; then
        echo "iptables"
    else
        echo "unknown"
    fi
}

# Function to display current firewall rules
show_firewall_rules() {
    local firewall_system=$(detect_firewall)
    if [[ "$firewall_system" == "ufw" ]]; then
        echo -e "\nCurrently Active Firewall Rules (ufw):\n"
        sudo ufw status verbose
    elif [[ "$firewall_system" == "nftables" ]]; then
        echo -e "\nCurrently Active Firewall Rules (nftables):\n"
        sudo nft list ruleset
    elif [[ "$firewall_system" == "iptables" ]]; then
        echo -e "\nCurrently Active Firewall Rules (iptables):\n"
        sudo iptables -L -n -v
    else
        echo "Unknown firewall system, cannot display rules."
    fi
}

# Function to backup firewall rules
backup_firewall_rules() {
    local firewall_system=$(detect_firewall)
    if [[ ! -d "$backupDir" ]]; then
        sudo mkdir -p "$backupDir"
        if [[ $? -ne 0 ]]; then
            echo "Error creating backup directory $backupDir. Backup failed."
            log_action "Backup directory creation failed!"
            return 1
        fi
    fi
    local backupPath="$backupDir/firewall_backup_$(date +%Y%m%d_%H%M%S)"
    if [[ "$firewall_system" == "ufw" ]]; then
        sudo ufw status verbose > "$backupPath.txt"
        if [[ $? -eq 0 ]]; then
            echo "Backup successful! Rules saved at $backupPath.txt"
            log_action "Backup created at $backupPath.txt (ufw)"
            return 0
        else
            echo "Backup failed (ufw)!"
            log_action "Backup failed (ufw)!"
            return 1
        fi
    elif [[ "$firewall_system" == "nftables" ]]; then
        sudo nft save > "$backupPath.conf"
        if [[ $? -eq 0 ]]; then
            echo "Backup successful! Rules saved at $backupPath.conf"
            log_action "Backup created at $backupPath.conf (nftables)"
            return 0
        else
            echo "Backup failed (nftables)!"
            log_action "Backup failed (nftables)!"
            return 1
        fi
    elif [[ "$firewall_system" == "iptables" ]]; then
        sudo iptables-save > "$backupPath.rules"
        if [[ $? -eq 0 ]]; then
            echo "Backup successful! Rules saved at $backupPath.rules"
            log_action "Backup created at $backupPath.rules (iptables)"
            return 0
        else
            echo "Backup failed (iptables)!"
            log_action "Backup failed (iptables)!"
            return 1
        fi
    else
        echo "Unknown firewall system, backup not supported."
        log_action "Backup not supported (unknown firewall)"
        return 1
    fi
}

# Function to restore firewall rules
restore_firewall_rules() {
    local firewall_system=$(detect_firewall)
    if [[ ! -d "$backupDir" ]]; then
        echo "No backups found in $backupDir!"
        return 1
    fi
    find "$backupDir" -maxdepth 1 -type f -print
    read -p "Enter the full name of the backup file to restore (within $backupDir): " selectedBackup

    local backupPath="$backupDir/$selectedBackup"

    if [[ ! -f "$backupPath" ]]; then
        echo "Backup file not found at $backupPath!"
        log_action "Failed to restore backup: $backupPath not found"
        return 1
    fi

    if [[ "$firewall_system" == "ufw" ]]; then
        echo "Restore for ufw is manual. Please review $backupPath and manually apply rules using 'ufw allow/deny ...'"
        log_action "Manual restore needed for ufw. Backup file: $backupPath"
        return 0 # Manual restore, consider successful in script context
    elif [[ "$firewall_system" == "nftables" ]]; then
        sudo nft -f "$backupPath"
        if [[ $? -eq 0 ]]; then
            echo "Firewall rules restored from $backupPath!"
            log_action "Firewall rules restored from $backupPath (nftables)"
            return 0
        else
            echo "Failed to restore firewall rules from $backupPath (nftables)!"
            log_action "Failed to restore backup (nftables): $backupPath"
            return 1
        fi
    elif [[ "$firewall_system" == "iptables" ]]; then
        sudo iptables-restore < "$backupPath"
        if [[ $? -eq 0 ]]; then
            echo "Firewall rules restored from $backupPath!"
            log_action "Firewall rules restored from $backupPath (iptables)"
            return 0
        else
            echo "Failed to restore firewall rules from $backupPath (iptables)!"
            log_action "Failed to restore backup (iptables): $backupPath"
            return 1
        fi
    else
        echo "Unknown firewall system, restore not fully automated."
        echo "Please review backup file $backupPath and manually configure your firewall."
        log_action "Manual restore needed for unknown firewall. Backup file: $backupPath"
        return 0 # Manual restore, consider successful in script context
    fi
}

# Function to block all ports and allow specific ones for Linux
block_all_and_allow_specific_ports() {
    local firewall_system=$(detect_firewall)
    local -a allowed_ports=("$@") # Assume input is space-separated list of "port:protocol" strings

    read -p "This will block all ports except the ones you specify. Do you want to continue? (y/N) " -n 1 -r
    echo    # (optional) move to a new line
    if [[ ! "$REPLY" =~ ^[Yy]$ ]]; then
        echo "Action cancelled."
        return 0
    fi

    backup_firewall_rules

    if [[ "$firewall_system" == "ufw" ]]; then
        echo "Resetting ufw firewall..."
        sudo ufw reset yes
        if [[ $? -ne 0 ]]; then
            echo "Error resetting ufw. Please check manually and try again."
            log_action "Error resetting ufw!"
            return 1
        fi
        echo "Setting default deny for incoming and outgoing..."
        sudo ufw default deny incoming
        sudo ufw default deny outgoing
        log_action "Set ufw default deny incoming/outgoing"

        echo "Allowing specified ports..."
        for port_proto in "${allowed_ports[@]}"; do
            local port=$(echo "$port_proto" | cut -d':' -f1)
            local proto=$(echo "$port_proto" | cut -d':' -f2)
            if validate_port_number "$port" && validate_protocol "$proto"; then
                echo "Allowing $port/$proto..."
                sudo ufw allow "$port/$proto"
                if [[ $? -ne 0 ]]; then
                    echo "Error allowing port $port/$proto with ufw."
                    log_action "Error allowing port $port/$proto (ufw)!"
                else
                    log_action "Allowed port $port/$proto (ufw)"
                fi
            else
                echo "Invalid port or protocol: $port_proto. Skipping."
                log_action "Invalid port/protocol input: $port_proto"
            fi
        done
        echo "Enabling ufw..."
        sudo ufw enable
        if [[ $? -ne 0 ]]; then
            echo "Error enabling ufw. Firewall configuration may not be active."
            log_action "Error enabling ufw!"
            return 1
        fi

    elif [[ "$firewall_system" == "nftables" ]]; then
        echo "Flushing nftables ruleset..."
        sudo nft flush ruleset
        if [[ $? -ne 0 ]]; then
            echo "Error flushing nftables ruleset. Please check manually and try again."
            log_action "Error flushing nftables ruleset!"
            return 1
        fi

        echo "Setting default drop for input and output chains..."
        sudo nft add table inet filter
        sudo nft add chain inet filter input { type filter hook input priority 0 \; policy drop \; }
        sudo nft add chain inet filter output { type filter hook output priority 0 \; policy drop \; }
        log_action "Set nftables default drop input/output"


        echo "Allowing specified ports..."
        for port_proto in "${allowed_ports[@]}"; do
            local port=$(echo "$port_proto" | cut -d':' -f1)
            local proto=$(echo "$port_proto" | cut -d':' -f2)
            if validate_port_number "$port" && validate_protocol "$proto"; then
                echo "Allowing $port/$proto..."
                sudo nft add rule inet filter input "$proto dport $port accept"
                sudo nft add rule inet filter output "$proto sport $port accept" # Outbound might be needed for some services
                if [[ $? -ne 0 ]]; then
                    echo "Error allowing port $port/$proto with nftables."
                    log_action "Error allowing port $port/$proto (nftables)!"
                else
                    log_action "Allowed port $port/$proto (nftables)"
                fi
            else
                echo "Invalid port or protocol: $port_proto. Skipping."
                log_action "Invalid port/protocol input: $port_proto"
            fi
        done

        # Allow established and related connections (important for stateful firewalls)
        sudo nft add rule inet filter input ct state established,related accept
        sudo nft add rule inet filter output ct state established,related accept
        log_action "Allowed established/related connections (nftables)"


    elif [[ "$firewall_system" == "iptables" ]]; then
        echo "Flushing iptables rules..."
        sudo iptables -F
        sudo iptables -X # delete user-defined chains
        if [[ $? -ne 0 ]]; then
            echo "Error flushing iptables rules. Please check manually and try again."
            log_action "Error flushing iptables rules!"
            return 1
        fi
        echo "Setting default DROP policy for INPUT and OUTPUT chains..."
        sudo iptables -P INPUT DROP
        sudo iptables -P OUTPUT DROP
        log_action "Set iptables default DROP input/output"

        echo "Allowing specified ports..."
        for port_proto in "${allowed_ports[@]}"; do
            local port=$(echo "$port_proto" | cut -d':' -f1)
            local proto=$(echo "$port_proto" | cut -d':' -f2)
            if validate_port_number "$port" && validate_protocol "$proto"; then
                echo "Allowing $port/$proto..."
                sudo iptables -A INPUT -p "$proto" --dport "$port" -j ACCEPT
                sudo iptables -A OUTPUT -p "$proto" --sport "$port" -j ACCEPT # Outbound might be needed for some services
                if [[ $? -ne 0 ]]; then
                    echo "Error allowing port $port/$proto with iptables."
                    log_action "Error allowing port $port/$proto (iptables)!"
                else
                    log_action "Allowed port $port/$proto (iptables)"
                fi
            else
                echo "Invalid port or protocol: $port_proto. Skipping."
                log_action "Invalid port/protocol input: $port_proto"
            fi
        done

        # Allow established and related connections (important for stateful firewalls)
        sudo iptables -A INPUT -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT
        sudo iptables -A OUTPUT -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT
        log_action "Allowed established/related connections (iptables)"

    else
        echo "Unknown firewall system, cannot block all and allow specific ports automatically."
        echo "Please configure your firewall manually."
        log_action "Cannot automate block all/allow specific for unknown firewall."
        return 1
    fi

    echo "Firewall configuration completed successfully!"
    log_action "Completed full firewall reset and essential rules creation"
    return 0
}


# Function to open a specific port
open_port() {
    local port_number="$1"
    local protocol="${2:-tcp}" # Default to TCP if protocol not provided

    if ! validate_port_number "$port_number"; then
        return 1
    fi
    if ! validate_protocol "$protocol"; then
        return 1
    fi

    local firewall_system=$(detect_firewall)
    if [[ "$firewall_system" == "ufw" ]]; then
        echo "Opening port $port_number for $protocol traffic (ufw)..."
        sudo ufw allow "$port_number/$protocol"
        if [[ $? -eq 0 ]]; then
            log_action "Opened port $port_number for $protocol traffic (ufw)"
        else
            echo "Error opening port $port_number/$protocol with ufw."
            log_action "Error opening port $port_number/$protocol (ufw)!"
            return 1
        fi
    elif [[ "$firewall_system" == "nftables" ]]; then
        echo "Opening port $port_number for $protocol traffic (nftables)..."
        sudo nft add rule inet filter input "$protocol dport $port_number accept"
        sudo nft add rule inet filter output "$protocol sport $port_number accept" # Outbound for service response
        if [[ $? -eq 0 ]]; then
            log_action "Opened port $port_number for $protocol traffic (nftables)"
        else
            echo "Error opening port $port_number/$protocol with nftables."
            log_action "Error opening port $port_number/$protocol (nftables)!"
            return 1
        fi

    elif [[ "$firewall_system" == "iptables" ]]; then
        echo "Opening port $port_number for $protocol traffic (iptables)..."
        sudo iptables -A INPUT -p "$protocol" --dport "$port_number" -j ACCEPT
        sudo iptables -A OUTPUT -p "$protocol" --sport "$port_number" -j ACCEPT # Outbound for service response
        if [[ $? -eq 0 ]]; then
            log_action "Opened port $port_number for $protocol traffic (iptables)"
        else
            echo "Error opening port $port_number/$protocol with iptables."
            log_action "Error opening port $port_number/$protocol (iptables)!"
            return 1
        fi
    else
        echo "Unknown firewall system, cannot open port automatically."
        echo "Please open port $port_number/$protocol manually."
        log_action "Cannot automate open port for unknown firewall: $port_number/$protocol."
        return 1
    fi
    echo "Port $port_number/$protocol opened successfully."
    return 0
}

# Function to block a specific port
block_port() {
    local port_number="$1"
    local protocol="${2:-tcp}" # Default to TCP if protocol not provided

    if ! validate_port_number "$port_number"; then
        return 1
    fi
    if ! validate_protocol "$protocol"; then
        return 1
    fi

    local firewall_system=$(detect_firewall)

    if [[ "$firewall_system" == "ufw" ]]; then
        echo "Blocking port $port_number for $protocol traffic (ufw)..."
        sudo ufw deny "$port_number/$protocol"
        if [[ $? -eq 0 ]]; then
            log_action "Blocked port $port_number for $protocol traffic (ufw)"
        else
            echo "Error blocking port $port_number/$protocol with ufw."
            log_action "Error blocking port $port_number/$protocol (ufw)!"
            return 1
        fi
    elif [[ "$firewall_system" == "nftables" ]]; then
        echo "Blocking port $port_number for $protocol traffic (nftables)..."
        sudo nft add rule inet filter input "$protocol dport $port_number drop"
        sudo nft add rule inet filter output "$protocol sport $port_number drop" # Block outbound as well for symmetry
        if [[ $? -eq 0 ]]; then
            log_action "Blocked port $port_number for $protocol traffic (nftables)"
        else
            echo "Error blocking port $port_number/$protocol with nftables."
            log_action "Error blocking port $port_number/$protocol (nftables)!"
            return 1
        fi
    elif [[ "$firewall_system" == "iptables" ]]; then
        echo "Blocking port $port_number for $protocol traffic (iptables)..."
        sudo iptables -A INPUT -p "$protocol" --dport "$port_number" -j DROP
        sudo iptables -A OUTPUT -p "$protocol" --sport "$port_number" -j DROP # Block outbound as well for symmetry
        if [[ $? -eq 0 ]]; then
            log_action "Blocked port $port_number for $protocol traffic (iptables)"
        else
            echo "Error blocking port $port_number/$protocol with iptables."
            log_action "Error blocking port $port_number/$protocol (iptables)!"
            return 1
        fi
    else
        echo "Unknown firewall system, cannot block port automatically."
        echo "Please block port $port_number/$protocol manually."
        log_action "Cannot automate block port for unknown firewall: $port_number/$protocol."
        return 1
    fi
    echo "Port $port_number/$protocol blocked successfully."
    return 0
}

# Function to configure firewall for a specific host
configure_firewall_for_host() {
    local host_name="$1"

    if [[ -z "${host_services[$host_name]}" ]]; then
        echo "Invalid host name: $host_name. Please select from $(echo "${!host_services[@]}")."
        return 1
    fi

    echo "Configuring firewall for host: $host_name"
    local services_string="${host_services[$host_name]}"
    local -a services=($(echo "$services_string" | tr ',' ' '))
    local -a allowed_port_protos=()

    echo "Allowed services for $host_name: $services_string"
    for service in "${services[@]}"; do
        if [[ -n "${service_ports[$service]}" ]]; then
            allowed_port_protos+=("${service_ports[$service]}")
            echo "- $service (${service_ports[$service]})"
        else
            echo "- $service (Port definition missing in service_ports array!)"
            log_action "Warning: Port definition missing for service: $service for host $host_name"
        fi
    done

    block_all_and_allow_specific_ports "${allowed_port_protos[@]}"
    return 0
}


# Main menu
main_menu() {
    if [[ "$(id -u)" -ne 0 ]]; then
        echo "This script requires root privileges! Please run with sudo."
        exit 1
    fi

    while true; do
        show_firewall_rules

        echo -e "\nSelect an option:"
        echo "1) Select a specific ISTS Host (Ebanking, Accounts, ATM, Lobby, Lockbox)" # <--- Lockbox in menu
        echo "2) Backup firewall rules"
        echo "3) Restore firewall rules"
        echo "4) Open a specific port"
        echo "5) Block a specific port"
        echo "6) Exit"
        read -p "Enter your choice: " choice

        case "$choice" in
            1)
                read -p "Enter the ISTS host name (Ebanking, Accounts, ATM, Lobby, Lockbox): " hostName # <--- Lockbox in prompt
                configure_firewall_for_host "$hostName"
                ;;
            2)
                backup_firewall_rules
                ;;
            3)
                restore_firewall_rules
                ;;
            4)
                read -p "Enter the port number to allow: " portNumber
                read -p "Enter the protocol (tcp/udp, default: tcp): " protocol
                open_port "$portNumber" "$protocol"
                ;;
            5)
                read -p "Enter the port number to block: " portNumber
                read -p "Enter the protocol (tcp/udp, default: tcp): " protocol
                block_port "$portNumber" "$protocol"
                ;;
            6)
                echo "Exiting... Goodbye!"
                exit 0
                ;;
            *)
                echo "Invalid choice! Please select a valid option."
                ;;
        esac
    done
}

# Run the main menu
main_menu