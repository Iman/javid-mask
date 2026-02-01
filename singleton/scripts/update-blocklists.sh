#!/bin/bash

set -e

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
WORKSPACE_DIR="$(dirname "$SCRIPT_DIR")"
BLOCKLIST_FILE="$WORKSPACE_DIR/../iran_blocklist.txt"
TEMP_DIR="/tmp/blocklist-update-$$"

echo "=========================================="
echo "Blocklist Update Script"
echo "=========================================="
echo ""

mkdir -p "$TEMP_DIR"

SOURCES=(
    "https://raw.githubusercontent.com/kiumarsj/iranian-adlist/main/hosts"
    "https://raw.githubusercontent.com/farrokhi/adblock-iran/master/adblock-iran.txt"
    "https://raw.githubusercontent.com/MasterKia/PersianBlocker/main/PersianBlockerHosts.txt"
    "https://pgl.yoyo.org/adservers/serverlist.php?hostformat=hosts&showintro=0&mimetype=plaintext"
    "https://raw.githubusercontent.com/hoshsadiq/adblock-nocoin-list/master/hosts.txt"
    "https://raw.githubusercontent.com/StevenBlack/hosts/master/alternates/fakenews-gambling/hosts"
)

echo "Downloading blocklists..."
for i in "${!SOURCES[@]}"; do
    echo "  [$((i+1))/${#SOURCES[@]}] ${SOURCES[$i]}"
    curl -sSL "${SOURCES[$i]}" > "$TEMP_DIR/source-$i.txt" 2>/dev/null || echo "    Failed to download"
done

echo ""
echo "Processing and deduplicating..."

cat "$TEMP_DIR"/source-*.txt | \
    grep -v '^#' | \
    grep -v '^$' | \
    grep -v '127.0.0.1' | \
    grep -v '0.0.0.0' | \
    grep -v 'localhost' | \
    sed 's/^127.0.0.1[[:space:]]\+//' | \
    sed 's/^0.0.0.0[[:space:]]\+//' | \
    sed 's/[[:space:]]\+$//' | \
    grep -E '^[a-zA-Z0-9]' | \
    sort -u > "$TEMP_DIR/combined.txt"

DOMAIN_COUNT=$(wc -l < "$TEMP_DIR/combined.txt" | tr -d ' ')

echo "# Globally Ad & Tracker Blocklist for Pi-hole" > "$BLOCKLIST_FILE"
echo "#" >> "$BLOCKLIST_FILE"
echo "# This list combines domains from the following sources:" >> "$BLOCKLIST_FILE"
echo "# - https://github.com/kiumarsj/iranian-adlist" >> "$BLOCKLIST_FILE"
echo "# - https://github.com/farrokhi/adblock-iran" >> "$BLOCKLIST_FILE"
echo "# - https://github.com/MasterKia/PersianBlocker" >> "$BLOCKLIST_FILE"
echo "# - Peter Lowe's Ad and tracking server list" >> "$BLOCKLIST_FILE"
echo "# - NoCoin adblock list (hoshsadiq)" >> "$BLOCKLIST_FILE"
echo "# - StevenBlack Unified Hosts" >> "$BLOCKLIST_FILE"
echo "#" >> "$BLOCKLIST_FILE"
echo "# Total unique domains: $DOMAIN_COUNT" >> "$BLOCKLIST_FILE"
echo "# Last updated: $(date -u +"%Y-%m-%d %H:%M:%S UTC")" >> "$BLOCKLIST_FILE"
echo "#" >> "$BLOCKLIST_FILE"

cat "$TEMP_DIR/combined.txt" >> "$BLOCKLIST_FILE"

rm -rf "$TEMP_DIR"

echo ""
echo "=========================================="
echo "Update Complete!"
echo "=========================================="
echo "Blocklist: $BLOCKLIST_FILE"
echo "Total domains: $DOMAIN_COUNT"
echo ""
