#!/bin/bash
#Asentry 
#By Daniel Louis
#05/14/2025

tailscale_install(){
  # Install TaleScale
  set -euo pipefail

  TS_AUTHKEY="tskey-REPLACE_ME"   # pre-auth, reusable key recommended
  read -p "Please enter an auth key for Tailscale" TS_AUTHKEY
  
  # Install Tailscale (official method)
  curl -fsSL https://tailscale.com/install.sh | sh  # :contentReference[oaicite:1]{index=1}
  # Enable + start daemon
  systemctl enable --now tailscaled
  # Bring it up (non-interactive)
  sudo tailscale up \
      --authkey "${TS_AUTHKEY}" \
      --accept-routes \
      --advertise-tags=tag:prod
}
