# Add SSH password-login resilience
configure_ssh_password_login()
{
  SSHD_MAIN="/etc/ssh/sshd_config"
  SSHD_DROPIN_DIR="/etc/ssh/sshd_config.d"
  SSHD_DROPIN="$SSHD_DROPIN_DIR/99-asentry-password-login.conf"

  mkdir -p "$SSHD_DROPIN_DIR"

  cat > "$SSHD_DROPIN" <<'EOF'
# Managed by Asentry base config
PasswordAuthentication yes
KbdInteractiveAuthentication yes
UsePAM yes
PubkeyAuthentication yes
EOF

  # Validate SSH config before restarting
  if sshd -t; then
    systemctl restart sshd
    echo "SSH password login enabled and sshd restarted."
  else
    echo "ERROR: SSH config validation failed. sshd was not restarted."
    return 1
  fi
}

# Update root and vcs passwords

# Get the service tag if dmidecode is available
if command -v dmidecode >/dev/null 2>&1; then
    service_tag=$(sudo dmidecode -s system-serial-number 2>/dev/null | tr -d '[:space:]')
else
    service_tag=""
fi

# Verify we received a valid service tag
if [[ -n "$service_tag" && "$service_tag" != "NotSpecified" && "$service_tag" != "Not" ]]; then
    suffix=$(printf "%s" "$service_tag" | rev | cut -c1-4 | tr '[:upper:]' '[:lower:]')
    prefix="${service_tag:0:3}"
    prefix="${prefix,,}"

    root_password="${service_tag}@${suffix}"
    vcs_password="b3nchm@rk$prefix"

    if echo "root:$root_password" | sudo chpasswd; then
        echo "Root password updated."
    else
        echo "ERROR: Failed to update root password."
    fi

    if id vcs >/dev/null 2>&1; then
        if echo "vcs:$vcs_password" | sudo chpasswd; then
            echo "VCS password updated."
        else
            echo "ERROR: Failed to update vcs password."
        fi
    else
        echo "WARNING: User 'vcs' does not exist."
    fi

else
    default_password="Asdf370)"

    echo "root:$default_password" | sudo chpasswd

    echo "Using default password because no valid service tag was found."
fi

#Call SSH Permissions 
configure_ssh_password_login