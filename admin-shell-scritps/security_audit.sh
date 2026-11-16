
#!/usr/bin/env bash
# security_audit.sh
# Read-only firewalld, SELinux and port audit
# Supports RHEL 8/9 and compatible distributions

set -u

LINE="=========================================================================="

header() {
    echo
    echo "$LINE"
    echo "$1"
    echo "$LINE"
}

table_header() {
    printf "%-18s %-10s %-20s %-30s\n" \
        "$1" "$2" "$3" "$4"
    printf '%s\n' "--------------------------------------------------------------------------"
}

# 1. System information
header "SYSTEM INFORMATION"

echo "Hostname    : $(hostname)"
echo "Date        : $(date)"
echo "OS          : $(grep '^PRETTY_NAME=' /etc/os-release |
                    cut -d= -f2- | tr -d '"')"

if [[ $EUID -ne 0 ]]; then
    echo "NOTICE      : Run with sudo for more complete results."
fi

# 2. firewalld status
header "FIREWALLD STATUS"

FW_ACTIVE=false

if command -v firewall-cmd >/dev/null 2>&1; then
    if firewall-cmd --state >/dev/null 2>&1; then
        FW_ACTIVE=true
        echo "Status       : RUNNING"
        echo "Default zone : $(firewall-cmd --get-default-zone)"
    else
        echo "Status       : NOT RUNNING"
    fi

    if command -v systemctl >/dev/null 2>&1; then
        echo "Boot enabled : $(systemctl is-enabled firewalld 2>/dev/null || true)"
    fi
else
    echo "Status       : NOT INSTALLED"
fi

# 3. SELinux configuration
header "SELINUX STATUS"

if command -v getenforce >/dev/null 2>&1; then
    echo "Current mode : $(getenforce)"
else
    echo "Current mode : UNKNOWN"
fi

if [[ -f /etc/selinux/config ]]; then
    configured=$(sed -n \
        's/^[[:space:]]*SELINUX[[:space:]]*=[[:space:]]*//p' \
        /etc/selinux/config | tail -1)
    echo "Boot setting : ${configured:-UNKNOWN}"
fi

if command -v sestatus >/dev/null 2>&1; then
    sestatus | grep -E \
        'Loaded policy name:|Policy MLS status:'
fi

# 4. Active and default firewall zones
header "FIREWALL ZONES"

if [[ $FW_ACTIVE == true ]]; then
    firewall-cmd --get-active-zones
    echo
    echo "Default zone: $(firewall-cmd --get-default-zone)"
else
    echo "Unavailable: firewalld is not running."
fi

# 5. Allowed firewall ports
header "FIREWALL ALLOWED PORTS (RUNTIME)"

table_header "ZONE" "PROTOCOL" "PORT/RANGE" "SOURCE"

if [[ $FW_ACTIVE == true ]]; then

    # Include the default zone even if no interface is bound.
    zones=$(
        {
            firewall-cmd --get-active-zones |
                awk '!/^[[:space:]]/ {print $1}'
            firewall-cmd --get-default-zone
        } | sort -u
    )

    for zone in $zones; do

        # Explicit open ports
        ports=$(firewall-cmd --zone="$zone" --list-ports 2>/dev/null)

        for entry in $ports; do
            port="${entry%/*}"
            proto="${entry##*/}"
            printf "%-18s %-10s %-20s %-30s\n" \
                "$zone" "$proto" "$port" "Explicit port"
        done

        # Services permitted by firewalld
        services=$(firewall-cmd --zone="$zone" --list-services 2>/dev/null)

        for service in $services; do
            info=$(firewall-cmd --info-service="$service" 2>/dev/null)
            service_ports=$(printf '%s\n' "$info" |
                sed -n 's/^[[:space:]]*ports:[[:space:]]*//p' |
                head -1)

            if [[ -n "$service_ports" ]]; then
                for entry in $service_ports; do
                    port="${entry%/*}"
                    proto="${entry##*/}"

                    printf "%-18s %-10s %-20s %-30s\n" \
                        "$zone" "$proto" "$port" "Service: $service"
                done
            else
                printf "%-18s %-10s %-20s %-30s\n" \
                    "$zone" "-" "-" "Service: $service (no fixed port)"
            fi
        done
    done
fi

# 6. Explicit block / reject rules
header "FIREWALL EXPLICIT BLOCK RULES"

if [[ $FW_ACTIVE == true ]]; then
    found=false

    for zone in $zones; do
        while IFS= read -r rule; do
            [[ -z "$rule" ]] && continue

            if [[ "$rule" =~ (^|[[:space:]])(drop|reject)([[:space:]]|$) ]]; then
                found=true
                echo "Zone   : $zone"
                echo "Action : DROP/REJECT"
                echo "Rule   : $rule"
                echo
            fi
        done < <(firewall-cmd --zone="$zone" --list-rich-rules 2>/dev/null)

        target=$(firewall-cmd --zone="$zone" --get-target 2>/dev/null)
        if [[ "$target" == DROP || "$target" == REJECT ]]; then
            found=true
            echo "Zone   : $zone"
            echo "Action : $target"
            echo "Rule   : Zone target"
            echo
        fi
    done

    if [[ "$found" == false ]]; then
        echo "No explicit rich-rule DROP/REJECT or DROP/REJECT zone target found."
    fi

    echo
    echo "NOTE: Ports not explicitly allowed may still be blocked by"
    echo "the zone policy. A complete blocked-port list cannot be"
    echo "determined from explicit rules alone."
fi

# 7. SELinux port assignments
header "SELINUX PORT TYPE ASSIGNMENTS"

if command -v semanage >/dev/null 2>&1; then
    printf "%-30s %-10s %s\n" "SELINUX TYPE" "PROTOCOL" "PORTS"
    echo "$LINE"

    semanage port -l 2>/dev/null |
        awk 'NR > 1 && NF >= 3 {
            type=$1
            proto=$2
            ports=""
            for (i=3; i<=NF; i++) {
                ports=ports (i==3 ? "" : " ") $i
            }
            printf "%-30s %-10s %s\n", type, proto, ports
        }'
else
    echo "semanage not installed."
    echo "Install: sudo dnf install policycoreutils-python-utils"
fi

# 8. Listening network ports
header "LISTENING TCP/UDP PORTS"

printf "%-8s %-28s %-35s\n" \
    "PROTO" "LOCAL ADDRESS:PORT" "PROCESS"
echo "$LINE"

if command -v ss >/dev/null 2>&1; then
    ss -H -lntup 2>/dev/null |
        awk '{
            proc="-"
            if (NF >= 7) {
                proc=$7
            }
            printf "%-8s %-28s %-35s\n", $1, $5, proc
        }'
else
    echo "ss not installed (iproute package required)."
fi

# 9. Firewall forwarding
header "FIREWALL PORT FORWARDING"

if [[ $FW_ACTIVE == true ]]; then
    for zone in $zones; do
        forwards=$(firewall-cmd --zone="$zone" --list-forward-ports 2>/dev/null)
        if [[ -n "$forwards" ]]; then
            echo "Zone: $zone"
            echo "$forwards"
        fi
    done
fi

# 10. End of report
header "SECURITY AUDIT COMPLETE"

echo "Audit completed: $(date)"
echo "No configuration changes were made."
