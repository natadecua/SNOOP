#!/bin/bash

# Default Values
network="192.168.1.1/24"
interface="eth0"
LOGFILE="network_tool.log"

# Function to log errors
log_error() {
    echo "[$(date)] ERROR: $1" >> $LOGFILE
}

# Function to log information
log_info() {
    echo "[$(date)] INFO: $1" >> $LOGFILE
}

# Function to display usage
usage() {
    echo "Usage: $0 [-n network_range] [-i interface]"
    echo "  -n    Network range to scan (e.g., 192.168.1.0/24)"
    echo "  -i    Network interface to use (e.g., eth0)"
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
    usage
fi

# Start network scans
log_info "Starting network scan on $network using interface $interface"

# Run Nmap scan
if ! nmap -sn $network -oG network_scan.txt; then
    log_error "Nmap scan failed"
    exit 1
fi
log_info "Nmap scan completed successfully"

# Run ARP scan
if ! arp-scan --interface=$interface $network > arp_scan.txt; then
    log_error "ARP scan failed"
    exit 1
fi
log_info "ARP scan completed successfully"

# Generate Report
echo "Active IPs Report" > report.txt
echo "=================" >> report.txt
cat network_scan.txt >> report.txt

echo "" >> report.txt
echo "ARP Scan Results" >> report.txt
echo "=================" >> report.txt
cat arp_scan.txt >> report.txt

log_info "Report generated and saved to report.txt"

echo "Script execution completed. Check $LOGFILE for details."
