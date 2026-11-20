#!/usr/bin/env bash
# RHEL 8/9-compatible firewalld and SELinux operations + port audit.
# Usage: sudo ./security_audit.sh [--audit | --port 8080]
set -u

bar() { printf '\n%s\n%s\n' '==================================================================' "$1"; }
ask_yes() { local ans; read -r -p "$1 (type YES): " ans; [[ "$ans" == YES ]]; }
root_check() { (( EUID == 0 )) || { echo 'Run with sudo.' >&2; exit 1; }; }
fw_ready() { command -v firewall-cmd >/dev/null 2>&1 && firewall-cmd --state >/dev/null 2>&1; }
selinux_mode() { command -v getenforce >/dev/null 2>&1 && getenforce || echo Unknown; }

status() {
  bar 'SECURITY STATUS'
  printf 'Hostname: %s\n' "$(hostname)"
  if command -v systemctl >/dev/null 2>&1; then
    printf 'firewalld runtime: %s\n' "$(systemctl is-active firewalld 2>/dev/null || true)"
    printf 'firewalld at boot: %s\n' "$(systemctl is-enabled firewalld 2>/dev/null || true)"
  else
    echo 'systemctl unavailable.'
  fi
  if fw_ready; then
    printf 'Default firewall zone: %s\n' "$(firewall-cmd --get-default-zone)"
    firewall-cmd --get-active-zones
  fi
  printf 'SELinux runtime mode: %s\n' "$(selinux_mode)"
  if [[ -r /etc/selinux/config ]]; then
    grep -E '^[[:space:]]*SELINUX=' /etc/selinux/config || true
  fi
}

firewalld_menu() {
  bar 'FIREWALLD CONTROL'
  echo '1) Start firewalld now'
  echo '2) Stop firewalld now'
  echo '3) Restart firewalld'
  echo '4) Enable at boot'
  echo '5) Disable at boot'
  echo '6) Enable and start'
  echo '7) Stop and disable at boot'
  echo '0) Cancel'
  local pick
  read -r -p 'Choose: ' pick
  if ! command -v systemctl >/dev/null 2>&1 || ! command -v firewall-cmd >/dev/null 2>&1; then
    echo 'firewalld/systemctl not available; install firewalld first.'
    return 1
  fi
  case "$pick" in
    1) ask_yes 'Start firewalld? Remote connectivity may change' && systemctl start firewalld ;;
    2) ask_yes 'STOP firewalld? Host firewall protection may be removed' && systemctl stop firewalld ;;
    3) ask_yes 'Restart firewalld? Connections may be interrupted' && systemctl restart firewalld ;;
    4) ask_yes 'Enable firewalld at boot?' && systemctl enable firewalld ;;
    5) ask_yes 'Disable firewalld at boot?' && systemctl disable firewalld ;;
    6) ask_yes 'Enable and start firewalld?' && systemctl enable --now firewalld ;;
    7) ask_yes 'STOP firewalld and disable at boot? Host may be exposed' && systemctl disable --now firewalld ;;
    0) return 0 ;;
    *) echo 'Invalid option.'; return 1 ;;
  esac
  status
}

# Update SELINUX= in the persistent configuration (requires root).
write_selinux_config() {
  local mode=$1 cfg=/etc/selinux/config backup
  [[ -f "$cfg" ]] || { echo 'SELinux config missing; no change made.' >&2; return 1; }
  backup="${cfg}.bak.$(date +%Y%m%d%H%M%S).$$"
  cp -a "$cfg" "$backup" || return 1
  if grep -Eq '^[[:space:]]*SELINUX=' "$cfg"; then
    sed -i -E "s/^[[:space:]]*SELINUX=.*/SELINUX=$mode/" "$cfg" || return 1
  else
    printf '\nSELINUX=%s\n' "$mode" >> "$cfg" || return 1
  fi
  echo "Persistent mode: $mode (backup: $backup)"
}

selinux_menu() {
  bar 'SELINUX CONTROL'
  echo 'SELinux is not a systemd service; use setenforce to change its live mode.'
  printf 'Current runtime mode: %s\n' "$(selinux_mode)"
  echo '1) Enforcing now (live only)'
  echo '2) Permissive now (live only; stops enforcement)'
  echo '3) Enforcing now + at next boot'
  echo '4) Permissive now + at next boot'
  echo '5) Show SELinux details'
  echo '0) Cancel'
  local pick current desired
  read -r -p 'Choose: ' pick
  case "$pick" in
    5) if command -v sestatus >/dev/null 2>&1; then sestatus; else echo 'sestatus unavailable'; fi; return 0 ;;
    0) return 0 ;;
    1|3) desired=enforcing ;;
    2|4) desired=permissive ;;
    *) echo 'Invalid option.'; return 1 ;;
  esac
  current=$(selinux_mode)
  if [[ "$current" == Disabled || "$current" == Unknown ]]; then
    echo 'SELinux is disabled or cannot be detected. Live switching is not possible.'
    echo 'Reactivation requires a reviewed boot/relabel procedure. No change made.'
    return 1
  fi
  command -v setenforce >/dev/null 2>&1 || { echo 'setenforce is unavailable.'; return 1; }
  if [[ "$desired" == permissive ]]; then
    ask_yes 'STOP SELinux enforcement (Permissive)? Access controls will no longer be enforced' || return 0
    setenforce 0 || return 1
  else
    ask_yes 'START SELinux enforcement (Enforcing)? Applications may be denied access' || return 0
    setenforce 1 || return 1
  fi
  if [[ "$pick" == 3 || "$pick" == 4 ]]; then
    write_selinux_config "$desired" || return 1
  fi
  printf 'SELinux runtime mode is now: %s\n' "$(selinux_mode)"
}

# Test whether a number is within a single port or port range token.
port_in_token() {
  local wanted=$1 token=${2%%/*} low high
  token=${token//,/}
  if [[ "$token" =~ ^([0-9]+)-([0-9]+)$ ]]; then
    low=$((10#${BASH_REMATCH[1]})); high=$((10#${BASH_REMATCH[2]}))
    (( wanted >= low && wanted <= high ))
  elif [[ "$token" =~ ^[0-9]+$ ]]; then
    (( wanted == 10#$token ))
  else
    return 1
  fi
}
valid_port() { [[ $1 =~ ^[0-9]+$ ]] && (( 10#$1 >= 1 && 10#$1 <= 65535 )); }

port_search() {
  local requested=${1:-} zone entry svc token info line stype proto specs item found=false
  [[ -n "$requested" ]] || read -r -p 'Port (1-65535): ' requested
  valid_port "$requested" || { echo 'Invalid port.' >&2; return 1; }
  requested=$((10#$requested))
  bar "FIREWALL RULE MATCHES FOR PORT $requested"
  printf '%-18s %-10s %-12s %s\n' ZONE PROTOCOL CLASS SOURCE
  if fw_ready; then
    for zone in $(firewall-cmd --get-zones); do
      for entry in $(firewall-cmd --zone="$zone" --list-ports 2>/dev/null); do
        if port_in_token "$requested" "$entry"; then
          printf '%-18s %-10s %-12s %s\n' "$zone" "${entry##*/}" ALLOW "explicit:$entry"
          found=true
        fi
      done
      for svc in $(firewall-cmd --zone="$zone" --list-services 2>/dev/null); do
        info=$(firewall-cmd --info-service="$svc" 2>/dev/null || true)
        specs=$(sed -n 's/^[[:space:]]*ports:[[:space:]]*//p' <<< "$info")
        for entry in $specs; do
          if port_in_token "$requested" "$entry"; then
            printf '%-18s %-10s %-12s %s\n' "$zone" "${entry##*/}" ALLOW "service:$svc ($entry)"
            found=true
          fi
        done
      done
      while IFS= read -r line; do
        if [[ "$line" =~ port="([0-9]+(-[0-9]+)?)" ]] && port_in_token "$requested" "${BASH_REMATCH[1]}"; then
          printf '%-18s %-10s %-12s %s\n' "$zone" '?' RULE "$line"
          found=true
        fi
      done < <(firewall-cmd --zone="$zone" --list-rich-rules 2>/dev/null)
    done
    [[ "$found" == true ]] || echo 'No matching basic zone port/service or rich port rule found.'
  else
    echo 'firewalld is not running; no live firewalld rules queried.'
  fi
  bar "SELINUX PORT LABELS FOR $requested"
  if command -v semanage >/dev/null 2>&1; then
    found=false
    while read -r stype proto specs; do
      [[ "$proto" == tcp || "$proto" == udp ]] || continue
      for item in ${specs//,/ }; do
        if port_in_token "$requested" "$item"; then
          printf '%-30s %-8s %s\n' "$stype" "$proto" "$specs"
          found=true; break
        fi
      done
    done < <(semanage port -l 2>/dev/null)
    [[ "$found" == true ]] || echo 'No explicit SELinux port label found for that number.'
  else
    echo 'semanage unavailable (dnf install policycoreutils-python-utils).'
  fi
  bar "LISTENING SOCKETS FOR $requested"
  if command -v ss >/dev/null 2>&1; then
    found=false
    while IFS= read -r line; do
      # ss -H output: Netid State Recv-Q Send-Q LocalAddress:Port PeerAddress:Port ...
      read -r _ _ _ _ entry _ <<< "$line"
      if [[ "${entry##*:}" == "$requested" ]]; then
        echo "$line"; found=true
      fi
    done < <(ss -H -lntup 2>/dev/null)
    [[ "$found" == true ]] || echo 'No listening TCP/UDP socket found.'
  else
    echo 'ss unavailable.'
  fi
  echo 'NOTE: These are rule/label matches, NOT a definitive effective ALLOW/BLOCK decision.'
  echo 'Zone selection, rule precedence, policies, nftables, and AWS security groups may change access.'
}

full_audit() {
  status
  bar 'FIREWALLD ACTIVE ZONES AND RULES'
  if fw_ready; then
    firewall-cmd --list-all-zones
    bar 'FIREWALLD POLICY RULES'
    firewall-cmd --list-all-policies 2>/dev/null || true
  else
    echo 'firewalld not running.'
  fi
  bar 'SELINUX PORT LABELS'
  if command -v semanage >/dev/null 2>&1; then semanage port -l; else echo 'semanage unavailable.'; fi
  bar 'LISTENING TCP/UDP PORTS'
  if command -v ss >/dev/null 2>&1; then ss -tulnp; else echo 'ss unavailable.'; fi
}

menu() {
  local pick port path
  while true; do
    bar 'LINUX SECURITY AUDIT & CONTROL'
    echo '1) Show security status'
    echo '2) Start / Stop / Restart firewalld (and boot enable/disable)'
    echo '3) Enforce / Stop enforcement of SELinux'
    echo '4) Search a specific port'
    echo '5) Full security audit (ports/rules/listeners)'
    echo '6) Save full audit to a report'
    echo '0) Exit'
    read -r -p 'Choose: ' pick
    case "$pick" in
      1) status ;;
      2) firewalld_menu ;;
      3) selinux_menu ;;
      4) read -r -p 'Enter port: ' port; port_search "$port" ;;
      5) full_audit ;;
      6) path="security_audit_$(hostname)_$(date +%Y%m%d_%H%M%S).txt"
         full_audit | tee "$path"
         printf 'Saved to: %s\n' "$path" ;;
      0) exit 0 ;;
      *) echo 'Invalid option.' ;;
    esac
  done
}

root_check
case "${1:-}" in
  '') menu ;;
  --audit) full_audit ;;
  --port) port_search "${2:-}" ;;
  *) echo "Usage: sudo $0 [--audit | --port PORT]" >&2; exit 1 ;;
esac
