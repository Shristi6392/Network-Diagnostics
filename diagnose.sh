#!/bin/bash
LOGFILE="/var/log/diagnose.log"
TARGET=$1

echo "=== Diagnosing $TARGET at $(date) ===" >> $LOGFILE
if ping -c 2 -W 1 "$TARGET" &> /dev/null; then
    echo "RESULT: $TARGET is UP" >> $LOGFILE
    exit 0
fi

echo "ALERT: $TARGET is DOWN. Running diagnosis...." >> $LOGFILE

GATEWAY=$(ip route | grep default | awk '{print $3}')
if ! ping -c 2 -W 1 "$GATEWAY" &> /dev/null; then
    echo "ROOT CAUSE: Local network/gateway is down ($GATEWAY unreachable)" >> $LOGFILE
    exit 1
fi
echo "CHECK: Gateway $GATEWAY is reachable - local network OK" >> $LOGFILE

if ! nslookup $TARGET &> /dev/null; then
    echo "ROOT CAUSE: DNS resolution failure for $TARGET" >> $LOGFILE
    exit 1
fi
echo "CHECK: DNS resolves $TARGET - DNS OK" >> $LOGFILE

echo "Running traceroute to isolate failure point:" >> $LOGFILE
traceroute -m 15 "$TARGET" >> $LOGFILE 2>&1

echo "ROOT CAUSE: Target unreachable past network/DNS layer - see traceroute above" >> $LOGFILE
