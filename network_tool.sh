#!/bin/bash

# Default Values
network="192.168.1.1/24" # Default, will be overridden by args
interface="eth0"         # Default, will be overridden by args
LOGFILE="network_tool.log"
NMAP_OUTPUT="network_scan.txt" # Temp file for nmap output
ARP_OUTPUT="arp_scan.txt"      # Temp file for arp-scan output
REPORT_FILE="report.txt"       # Final report file

# Function to log errors
log_error() {
    echo "[$(date)] ERROR: $1" >> "$LOGFILE"
}

# Function to log information
log_info() {
    echo "[$(date)] INFO: $1" >> "$LOGFILE"
}

# Function to display usage
usage() {
    echo "Usage: $0 [-n network_range] [-i interface]"
    echo "  -n Network range to scan (e.g., 192.168.1.0/24)"
    echo "  -i Network interface to use (e.g., eth0)"
    exit 1
}

# Parse command-line arguments
while getopts "n:i:" opt; do
  case $opt in
    n) network=$OPTARG ;;
    i) interface=$OPTARG ;;
    \?) usage ;;
  esac
done

# Validate network range and interface
if [ -z "$network" ] || [ -z "$interface" ]; then
    log_error "Network range and interface parameters are required."
    usage # exit
fi

# Check if interface exists (basic check)
if ! ip link show "$interface" > /dev/null 2>&1; then
    log_error "Network interface '$interface' not found."
    # Attempting arp-scan on a non-existent interface fails clearly,
    # so we can let it proceed and fail there for a potentially more specific error,
    # or exit here. Exiting here might be cleaner.
    exit 1
fi


# Start network scans
log_info "Starting network scan on $network using interface $interface"

# --- Run Nmap scan (Ping Scan) ---
log_info "Running Nmap ping scan..."
# Run nmap and redirect output. Check exit status.
if ! nmap -sn "$network" -oG "$NMAP_OUTPUT"; then
    log_error "Nmap scan failed. Check nmap installation and permissions."
    # Consider removing potentially incomplete output file?
    # rm -f "$NMAP_OUTPUT"
    exit 1
fi
# Check if nmap produced any output - file might be empty on some errors
if [ ! -s "$NMAP_OUTPUT" ]; then
    log_error "Nmap scan completed but produced no output. Check network range and interface."
    # rm -f "$NMAP_OUTPUT" # Clean up empty file
    exit 1
fi
log_info "Nmap scan completed successfully"


# --- Run ARP scan ---
log_info "Running ARP scan..."
# Run arp-scan. It requires root privileges. Redirect output. Check exit status.
# Assuming this script is run via sudo from Python, it should have permissions.
if ! arp-scan --interface="$interface" --localnet --quiet --ignoredups --output="$ARP_OUTPUT" --plain; then
# Using --localnet determines range from interface automatically, potentially safer than passing $network
# Using --plain for easier parsing later if needed, but default output is fine for the report.
# Let's stick to the paper's apparent implied command: arp-scan --interface=$interface $network
# Note: $network might not be appropriate for arp-scan if it's not the localnet range.
#       arp-scan usually works best on the immediate subnet. Using --localnet is often better.
# Reverting to use network range as potentially intended by paper, despite potential issues:
# if ! arp-scan --interface="$interface" "$network" > "$ARP_OUTPUT"; then

# Safer alternative using --localnet based on the interface:
   if ! arp-scan --interface="$interface" --localnet > "$ARP_OUTPUT"; then
    log_error "ARP scan failed. Check arp-scan installation, interface name, and permissions (requires root)."
    # Consider removing potentially incomplete output file?
    # rm -f "$ARP_OUTPUT"
    exit 1
   fi
fi
# Check if arp-scan produced any output
if [ ! -s "$ARP_OUTPUT" ]; then
    # This might be normal if no hosts respond to ARP on that interface/network segment
    log_info "ARP scan completed but detected no hosts (or failed silently)."
    # Don't exit here, just means no ARP results. Create empty ARP_OUTPUT?
    echo "# ARP scan returned no results." > "$ARP_OUTPUT"
    # exit 1 # Don't exit, just report no ARP results found
fi
log_info "ARP scan completed successfully"


# --- Generate Report ---
log_info "Generating final report..."
{
  echo "Snoop Network Scan Report"
  echo "Timestamp: $(date)"
  echo "Network Range Scanned: $network (Note: ARP Scan may use interface's localnet)"
  echo "Interface Used: $interface"
  echo ""
  echo "======================="
  echo "Active IPs Report (Nmap Ping Scan)"
  echo "======================="
  # Filter nmap output for 'Up' hosts and format slightly
  grep "Status: Up" "$NMAP_OUTPUT" | sed 's/Host: \([0-9.]*\) (\(.*\))/\1 (\2)/' || echo "No hosts found up by Nmap."
  echo ""
  echo "======================="
  echo "ARP Scan Results (IP to MAC Mapping)"
  echo "======================="
  # Cat the ARP scan results, handle case where file might be empty or just contain the warning
  if grep -q "ARP scan returned no results" "$ARP_OUTPUT"; then
      echo "No devices found via ARP scan on interface $interface's local network."
  else
      cat "$ARP_OUTPUT"
  fi
  echo ""
  echo "======================="
  echo "End of Report"

} > "$REPORT_FILE"

# Clean up temporary files (optional, could be useful for debugging)
# rm -f "$NMAP_OUTPUT" "$ARP_OUTPUT"

log_info "Report generated and saved to $REPORT_FILE"
echo "Script execution completed. Check $LOGFILE for details."

exit 0