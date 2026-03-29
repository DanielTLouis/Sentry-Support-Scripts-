#!/bin/bash
#Asentry 
#By Daniel Louis
#06/11/2025
setup_network_config(){
    local CFG_DIR="/etc/sysconfig/network"

    # Require root (writing ifcfg files + managing services)
    if [[ ${EUID:-$(id -u)} -ne 0 ]]; then
        echo "ERROR: setup_network_config must be run as root (use sudo -i or sudo bash)." >&2
        return 1
    fi

    # Ensure config directory exists
    mkdir -p "$CFG_DIR"

    #try to start the wicked service if not running 
    systemctl enable --now wicked >/dev/null 2>&1 || systemctl enable --now wicked.service >/dev/null 2>&1 || true

    #Save the status of wicked service, will return "active" if active 
    wicked_status=$(systemctl is-active wicked || true)
    networkManager_status=$(systemctl is-active NetworkManager || true)

    # check if wicked is running 
    if [[ "$wicked_status" != "active" && "$networkManager_status" == "active" ]]; then
        echo "Stopping NetworkManager and starting Wicked"
        systemctl stop NetworkManager
        systemctl disable NetworkManager
        #try to start the wicked service if not running 
        systemctl enable --now wicked >/dev/null 2>&1 || systemctl enable --now wicked.service >/dev/null 2>&1 || true
    elif [[ "$wicked_status" != "active" && "$networkManager_status" != "active" ]]; then
        #try to start the wicked service if not running 
        echo "Wicked is starting..."
        systemctl enable --now wicked >/dev/null 2>&1 || systemctl enable --now wicked.service >/dev/null 2>&1 || true
    else
        echo "Wicked is running. No change needed for the network."
    fi

    wicked_status=$(systemctl is-active wicked)
    echo "Wicked status is: ${wicked_status}"


    # Collect candidate interfaces:
    # - Skip loopback
    # - Only en*/eth* names
    # - Prefer physical NICs: /sys/class/net/<iface>/device exists
    # - Skip common virtual/bridge/bond types
    local iface iface_path cfg_file changed=0
    for iface_path in /sys/class/net/*; do
        iface="$(basename "$iface_path")"

        [[ "$iface" == "lo" ]] && continue
        [[ "$iface" =~ ^(en|eth) ]] || continue

        # Skip virtual/bridge/bond/dockery names that might still match en* on some systems
        [[ "$iface" =~ ^(veth|virbr|docker|br-|br0|bond|team|tap|tun) ]] && continue

        # Prefer physical NICs
        [[ -e "/sys/class/net/$iface/device" ]] || continue

        cfg_file="${CFG_DIR}/ifcfg-${iface}"

        # Backup existing config once
        if [[ -f "$cfg_file" && ! -f "${cfg_file}.bak" ]]; then
          cp -a "$cfg_file" "${cfg_file}.bak"
        fi

        # Write DHCP config (include DEVICE/NAME for broader ifcfg compatibility)
        # NOTE: Whitespace/quoting style matches typical SUSE ifcfg files.
        tee "$cfg_file" >/dev/null <<EOF
STARTMODE='auto'
BOOTPROTO='dhcp'
DEVICE='$iface'
NAME='$iface'
DHCLIENT_SET_DEFAULT_ROUTE='yes'
DHCLIENT6_SET_DEFAULT_ROUTE='yes'
DNS1='8.8.8.8'
DNS2='1.1.1.1'
EOF

        echo " - Set DHCP: $cfg_file"
        changed=1
    done
    
    # Configure DNS via netconfig (YaST reads this)
    if grep -q '^NETCONFIG_DNS_STATIC_SERVERS=' /etc/sysconfig/network/config; then
      sed -i 's/^NETCONFIG_DNS_STATIC_SERVERS=.*/NETCONFIG_DNS_STATIC_SERVERS="8.8.8.8 1.1.1.1"/' \
        /etc/sysconfig/network/config
    else
      echo 'NETCONFIG_DNS_STATIC_SERVERS="8.8.8.8 1.1.1.1"' >> /etc/sysconfig/network/config
    fi

    if grep -q '^NETCONFIG_DNS_POLICY=' /etc/sysconfig/network/config; then
      sed -i 's/^NETCONFIG_DNS_POLICY=.*/NETCONFIG_DNS_POLICY="auto"/' \
        /etc/sysconfig/network/config
    else
      echo 'NETCONFIG_DNS_POLICY="auto"' >> /etc/sysconfig/network/config
    fi

    netconfig update


    if [[ "$changed" -eq 0 ]]; then
        echo "WARNING: No matching physical en*/eth* interfaces found; nothing changed." >&2
    fi

    echo "Reloading wicked..."
    # Prefer an interface reload if wicked CLI exists; otherwise restart the service
    if command -v wicked >/dev/null 2>&1; then
        wicked ifreload all || systemctl restart wicked || systemctl restart wicked.service || true
    else
        systemctl restart wicked || systemctl restart wicked.service || true
    fi

    echo "Done. Current wicked status: $(systemctl is-active wicked 2>/dev/null || systemctl is-active wicked.service 2>/dev/null || true)"

}
