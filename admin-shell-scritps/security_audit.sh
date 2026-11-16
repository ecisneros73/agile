
#!/usr/bin/env bash
# ==========================================================
# Linux Security Audit and Configuration
# RHEL 8/9, Rocky Linux, AlmaLinux
#
# Usage:
#   sudo ./security_audit.sh
#   sudo ./security_audit.sh --port 8080
#   sudo ./security_audit.sh --audit
#
# WARNING:
# Changing firewall or SELinux settings can affect security.
# ==========================================================

set -u

LINE="========================================================================"

header() {
    echo
    echo "$LINE"
    echo "$1"
    echo "$LINE"
}

pause() {
    read -r -p "Press Enter to continue..." _
}

confirm() {
    local answer
    read -r -p "$1 (type YES): " answer
    [[ "$answer" == "YES" ]]
}

require_root() {
    if [[ "$EUID" -ne 0 ]]; then
        echo "ERROR: Run with sudo."
        exit 1
    fi
}

fw_running() {
    command -v firewall-cmd >/dev/null 2>&1 &&
    firewall-cmd --state >/dev/null 2>&1
}

get_zones() {
    firewall-cmd --get-zones 2>/dev/null
}

valid_port() {
    [[ "$1" =~ ^[0-9]+$ ]] &&
    (( 10#$1 >= 1 && 10#$1 <= 65535 ))
}

# Check exact ports and numeric ranges.
# Accepts: 8080, 8000-9000, 8080/tcp, or CSV lists.
port_matches() {
    local requested="$1"
    local specification="$2"
    local token start end

    specification="${specification//,/ }"

    for token in $specification; do
        token="${token%%/*}"

        if [[ "$token" =~ ^([0-9]+)-([0-9]+)$ ]]; then
            start=$((10#${BASH_REMATCH[1]}))
            end=$((10#${BASH_REMATCH[2]}))

            if (( requested >= start && requested <= end )); then
                return 0
            fi
        elif [[ "$token" =~ ^[0-9]+$ ]]; then
            if (( requested == 10#$token )); then
                return 0
            fi
        fi
    done

    return 1
}

# ==========================================================
# SYSTEM INFORMATION
# ==========================================================

system_info() {
    header "SYSTEM INFORMATION"

    echo "Hostname : $(hostname)"
    echo "Date     : $(date)"

    if [[ -f /etc/os-release ]]; then
        . /etc/os-release
        echo "OS       : ${PRETTY_NAME:-Unknown}"
    fi

    echo "Kernel   : $(uname -r)"
}

# ==========================================================
# FIREWALL STATUS
# ==========================================================

firewall_status() {
    header "FIREWALLD STATUS"

    if ! command -v firewall-cmd >/dev/null 2>&1; then
        echo "firewalld: NOT INSTALLED"
        return
    fi

    if fw_running; then
        echo "Runtime status : RUNNING"
        echo "Default zone   : $(firewall-cmd --get-default-zone)"
    else
        echo "Runtime status : STOPPED"
    fi

    echo "Boot status    : $(systemctl is-enabled firewalld 2>/dev/null || true)"

    if fw_running; then
        echo
        echo "Active zones:"
        firewall-cmd --get-active-zones
    fi
}

# ==========================================================
# SELINUX STATUS
# ==========================================================

selinux_status() {
    header "SELINUX STATUS"

    if command -v getenforce >/dev/null 2>&1; then
        echo "Current mode: $(getenforce)"
    else
        echo "SELinux status unavailable."
    fi

    if [[ -f /etc/selinux/config ]]; then
        grep -E '^[[:space:]]*SELINUX=' \
            /etc/selinux/config || true
    fi

    if command -v sestatus >/dev/null 2>&1; then
        sestatus
    fi
}

# ==========================================================
# ENABLE / DISABLE FIREWALLD
# ==========================================================

firewall_menu() {
    header "FIREWALLD CONFIGURATION"

    firewall_status

    echo
    echo "1) Enable firewalld"
    echo "2) Disable firewalld"
    echo "3) Restart firewalld"
    echo "4) No changes"
    echo

    read -r -p "Select option [1-4]: " choice

    case "$choice" in

        1)
            if ! command -v firewall-cmd >/dev/null 2>&1; then
                echo "firewalld is not installed."
                return
            fi

            if confirm "Enable firewalld now and at boot?"; then
                if systemctl enable --now firewalld; then
                    echo "SUCCESS: firewalld enabled."
                else
                    echo "ERROR: Unable to enable firewalld."
                fi
            fi
            ;;

        2)
            echo
            echo "WARNING: Disabling firewalld removes"
            echo "its runtime firewall protections."
            echo "Remote services may become exposed."

            if confirm "Disable firewalld now and at boot?"; then
                if systemctl disable --now firewalld; then
                    echo "SUCCESS: firewalld disabled."
                else
                    echo "ERROR: Unable to disable firewalld."
                fi
            fi
            ;;

        3)
            if confirm "Restart firewalld?"; then
                systemctl restart firewalld
            fi
            ;;

        4)
            echo "No firewall changes."
            ;;

        *)
            echo "Invalid selection."
            ;;
    esac
}

# ==========================================================
# SELINUX CONFIGURATION
# ==========================================================

update_selinux_config() {
    local mode="$1"
    local config="/etc/selinux/config"
    local backup

    if [[ ! -f "$config" ]]; then
        echo "ERROR: SELinux config not found."
        return 1
    fi

    backup="${config}.bak.$(date +%Y%m%d%H%M%S)"

    cp -a "$config" "$backup" || return 1

    if grep -qE '^[[:space:]]*SELINUX=' "$config"; then
        sed -i -E \
            "s/^[[:space:]]*SELINUX=.*/SELINUX=$mode/" \
            "$config"
    else
        echo "SELINUX=$mode" >> "$config"
    fi

    echo "Backup created: $backup"
}

selinux_menu() {
    header "SELINUX CONFIGURATION"

    selinux_status

    echo
    echo "1) Enable SELinux - Enforcing"
    echo "2) SELinux Permissive"
    echo "3) Configure SELinux Disabled at boot"
    echo "4) No changes"
    echo

    read -r -p "Select option [1-4]: " choice

    local current
    current=$(getenforce 2>/dev/null || echo "Unknown")

    case "$choice" in

        1)
            if confirm "Set SELinux to Enforcing?"; then

                if [[ "$current" == "Disabled" ]]; then
                    echo "SELinux is currently disabled."
                    echo "Reactivation requires controlled"
                    echo "boot configuration and relabeling."
                    echo "No changes made."
                else
                    if setenforce 1; then
                        update_selinux_config enforcing
                        echo "SELinux Enforcing configured."
                    fi
                fi
            fi
            ;;

        2)
            if confirm "Set SELinux to Permissive?"; then

                if [[ "$current" == "Disabled" ]]; then
                    echo "SELinux is currently disabled."
                    echo "Reactivation requires additional steps."
                    echo "No changes made."
                else
                    if setenforce 0; then
                        update_selinux_config permissive
                        echo "SELinux Permissive configured."
                    fi
                fi
            fi
            ;;

        3)
            echo
            echo "WARNING: SELinux will not be disabled"
            echo "immediately by changing its config."
            echo "A reboot is required."
            echo "RHEL 9 may also require selinux=0"
            echo "as a kernel boot argument."

            if confirm "Configure SELinux=disabled in config?"; then
                update_selinux_config disabled
                echo "SELinux config updated."
                echo "Review kernel settings before reboot."
                echo "A reboot may be required."
            fi
            ;;

        4)
            echo "No SELinux changes."
            ;;

        *)
            echo "Invalid selection."
            ;;
    esac
}

# ==========================================================
# ALLOWED FIREWALL PORTS
# ==========================================================

allowed_ports() {
    header "FIREWALL ALLOWED PORTS"

    if ! fw_running; then
        echo "firewalld is not running."
        return
    fi

    printf "%-16s %-12s %-20s %-25s\n" \
        "ZONE" "PROTOCOL" "PORT" "SOURCE"
    echo "$LINE"

    local zone entry service svc_ports

    for zone in $(get_zones); do

        for entry in $(firewall-cmd \
            --zone="$zone" --list-ports 2>/dev/null); do

            printf "%-16s %-12s %-20s %-25s\n" \
                "$zone" \
                "${entry##*/}" \
                "${entry%/*}" \
                "Explicit"
        done

        for service in $(firewall-cmd \
            --zone="$zone" --list-services 2>/dev/null); do

            svc_ports=$(firewall-cmd \
                --info-service="$service" 2>/dev/null |
                sed -n 's/^[[:space:]]*ports:[[:space:]]*//p' |
                head -1)

            for entry in $svc_ports; do

                printf "%-16s %-12s %-20s %-25s\n" \
                    "$zone" \
                    "${entry##*/}" \
                    "${entry%/*}" \
                    "Service:$service"
            done
        done
    done

    echo
    echo "NOTE: Service entries without fixed ports,"
    echo "rich rules, policies, and source-specific"
    echo "permissions are not fully represented."
}

# ==========================================================
# BLOCKED FIREWALL RULES
# ==========================================================

blocked_ports() {
    header "FIREWALL EXPLICIT BLOCK RULES"

    if ! fw_running; then
        echo "firewalld is not running."
        return
    fi

    local zone rule target found=false

    for zone in $(get_zones); do

        while IFS= read -r rule; do

            [[ -z "$rule" ]] && continue

            if [[ "$rule" =~ (^|[[:space:]])(drop|reject)([[:space:]]|$) ]]; then
                found=true
                echo "ZONE: $zone"
                echo "RULE: $rule"
                echo
            fi

        done < <(firewall-cmd \
            --zone="$zone" --list-rich-rules 2>/dev/null)

        target=$(firewall-cmd \
            --zone="$zone" --get-target 2>/dev/null)

        if [[ "$target" == "DROP" || "$target" == "REJECT" ]]; then
            found=true
            echo "ZONE: $zone"
            echo "TARGET: $target"
            echo
        fi
    done

    if [[ "$found" == false ]]; then
        echo "No explicit rich-rule DROP/REJECT"
        echo "or DROP/REJECT zone target found."
    fi

    echo
    echo "NOTE: This is not a complete effective"
    echo "firewall blocking analysis."
}

# ==========================================================
# SELINUX PORT TABLE
# ==========================================================

selinux_ports() {
    header "SELINUX PORT ASSIGNMENTS"

    if command -v semanage >/dev/null 2>&1; then
        semanage port -l
    else
        echo "semanage not installed."
        echo "Install using:"
        echo "dnf install policycoreutils-python-utils"
    fi
}

# ==========================================================
# LISTENING PORTS
# ==========================================================

listening_ports() {
    header "LISTENING TCP/UDP PORTS"

    if command -v ss >/dev/null 2>&1; then
        ss -tulnp
    else
        echo "ss command not installed."
    fi
}

# ==========================================================
# PORT SEARCH
# ==========================================================

search_port() {
    local port="${1:-}"
    local zone entry service svc_ports
    local found target line field proto localaddr
    local sel_type sel_proto sel_ports
    local listed blocked listening

    if [[ -z "$port" ]]; then
        read -r -p "Enter port number (1-65535): " port
    fi

    if ! valid_port "$port"; then
        echo "ERROR: Invalid port number."
        return 1
    fi

    port=$((10#$port))

    header "PORT $port SECURITY SEARCH"

    # -----------------------------------------
    # FIREWALL
    # -----------------------------------------

    header "FIREWALLD - PORT $port"

    printf "%-16s %-12s %-15s %-32s\n" \
        "ZONE" "PROTOCOL" "MATCH" "RULE/SERVICE"
    echo "$LINE"

    found=false

    if fw_running; then

        for zone in $(get_zones); do

            for entry in $(firewall-cmd \
                --zone="$zone" --list-ports 2>/dev/null); do

                if port_matches "$port" "$entry"; then

                    printf "%-16s %-12s %-15s %-32s\n" \
                        "$zone" "${entry##*/}" "ALLOW" "Port:$entry"

                    found=true
                fi
            done

            for service in $(firewall-cmd \
                --zone="$zone" --list-services 2>/dev/null); do

                svc_ports=$(firewall-cmd \
                    --info-service="$service" 2>/dev/null |
                    sed -n 's/^[[:space:]]*ports:[[:space:]]*//p' |
                    head -1)

                for entry in $svc_ports; do

                    if port_matches "$port" "$entry"; then

                        printf "%-16s %-12s %-15s %-32s\n" \
                            "$zone" "${entry##*/}" "ALLOW" \
                            "Service:$service"

                        found=true
                    fi
                done
            done

            # Display rich rules referencing this port.
            # These are candidate matches, not evaluated decisions.
            while IFS= read -r rule; do
                [[ -z "$rule" ]] && continue

                if [[ "$rule" =~ port=\"([0-9]+(-[0-9]+)?)\" ]]; then
                    entry="${BASH_REMATCH[1]}"

                    if port_matches "$port" "$entry"; then
                        echo
                        echo "Rich rule in zone $zone:"
                        echo "$rule"
                        found=true
                    fi
                fi

            done < <(firewall-cmd \
                --zone="$zone" --list-rich-rules 2>/dev/null)

            target=$(firewall-cmd \
                --zone="$zone" --get-target 2>/dev/null)

            if [[ "$target" == "DROP" || "$target" == "REJECT" ]]; then
                echo "Zone $zone target: $target"
            fi

        done

        if [[ "$found" == false ]]; then
            echo "No matching explicit port/service rule found."
        fi

    else
        echo "firewalld is not running."
    fi

    # -----------------------------------------
    # SELINUX
    # -----------------------------------------

    header "SELINUX - PORT $port"

    printf "%-30s %-12s %-25s\n" \
        "SELINUX TYPE" "PROTOCOL" "PORT MATCH"
    echo "$LINE"

    found=false

    if command -v semanage >/dev/null 2>&1; then

        while IFS= read -r line; do

            [[ -z "$line" ]] && continue

            sel_type=$(awk '{print $1}' <<< "$line")
            sel_proto=$(awk '{print $2}' <<< "$line")
            sel_ports=$(awk '{$1=""; $2=""; print}' <<< "$line")

            if port_matches "$port" "$sel_ports"; then

                printf "%-30s %-12s %-25s\n" \
                    "$sel_type" "$sel_proto" "$sel_ports"

                found=true
            fi

        done < <(semanage port -l 2>/dev/null | tail -n +2)

        if [[ "$found" == false ]]; then
            echo "No matching SELinux port assignment found."
        fi

    else
        echo "semanage not installed."
    fi

    # -----------------------------------------
    # LISTENING PROCESS
    # -----------------------------------------

    header "LISTENING PROCESS - PORT $port"

    found=false

    if command -v ss >/dev/null 2>&1; then

        printf "%-8s %-30s %s\n" \
            "PROTO" "LOCAL ADDRESS" "PROCESS"
        echo "$LINE"

        while IFS= read -r line; do

            [[ -z "$line" ]] && continue

            read -r proto _ _ _ localaddr _ <<< "$line"

            entry="${localaddr##*:}"

            if [[ "$entry" == "$port" ]]; then

                echo "$line"
                found=true
            fi

        done < <(ss -H -tulnp 2>/dev/null)

        if [[ "$found" == false ]]; then
            echo "Port $port is not listening."
        fi

    else
        echo "ss command unavailable."
    fi

    # -----------------------------------------
    # SUMMARY
    # -----------------------------------------

    header "PORT $port SEARCH COMPLETE"

    echo "Port checked: $port"
    echo "Date: $(date)"
    echo
    echo "IMPORTANT:"
    echo "A matching ALLOW rule does not guarantee"
    echo "traffic is permitted. Effective results"
    echo "depend on interface, source, zone,"
    echo "rich rules, policies, and other controls."
    echo "SELinux port labels are not firewall rules."
}

# ==========================================================
# FULL SECURITY AUDIT
# ==========================================================

full_audit() {
    system_info
    firewall_status
    selinux_status
    allowed_ports
    blocked_ports
    selinux_ports
    listening_ports

    header "AUDIT COMPLETE"
    echo "Completed: $(date)"
}

# ==========================================================
# MAIN MENU
# ==========================================================

main_menu() {
    local choice port filename

    while true; do

        header "LINUX SECURITY AUDIT MENU"

        echo "1) System information"
        echo "2) Firewalld status"
        echo "3) SELinux status"
        echo "4) Enable / Disable firewalld"
        echo "5) Configure SELinux"
        echo "6) Show allowed firewall ports"
        echo "7) Show explicit blocked firewall rules"
        echo "8) Show SELinux port assignments"
        echo "9) Show listening ports"
        echo "10) Search specific port"
        echo "11) Run full security audit"
        echo "12) Export audit report"
        echo "0) Exit"
        echo

        read -r -p "Select option: " choice

        case "$choice" in

            1)
                system_info
                pause
                ;;

            2)
                firewall_status
                pause
                ;;

            3)
                selinux_status
                pause
                ;;

            4)
                firewall_menu
                pause
                ;;

            5)
                selinux_menu
                pause
                ;;

            6)
                allowed_ports
                pause
                ;;

            7)
                blocked_ports
                pause
                ;;

            8)
                selinux_ports
                pause
                ;;

            9)
                listening_ports
                pause
                ;;

            10)
                search_port
                pause
                ;;

            11)
                full_audit
                pause
                ;;

            12)
                filename="security_audit_$(hostname)_$(date +%Y%m%d_%H%M%S).txt"

                full_audit | tee "$filename"

                echo
                echo "Report saved: $filename"
                pause
                ;;

            0)
                echo "Exiting security audit."
                exit 0
                ;;

            *)
                echo "Invalid option."
                ;;
        esac
    done
}

# ==========================================================
# START
# ==========================================================

require_root

case "${1:-}" in
    --port)
        search_port "${2:-}"
        ;;
    --audit)
        full_audit
        ;;
    "")
        main_menu
        ;;
    *)
        echo "Usage:"
        echo "  sudo $0"
        echo "  sudo $0 --port 8080"
        echo "  sudo $0 --audit"
        exit 1
        ;;
esac
