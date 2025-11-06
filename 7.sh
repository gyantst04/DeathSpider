#!/bin/bash

echo "=== System Disk and Memory Information ==="
echo

# Disk Information
echo ">> Disk Usage:"
df -h --total | awk '/total/ {print "Total Disk: " $2 "\nUsed: " $3 "\nFree: " $4 "\nUsage: " $5}'
echo

# Memory Information
echo ">> Memory Usage:"
free -h | awk '/Mem:/ {print "Total Memory: " $2 "\nUsed: " $3 "\nFree: " $4 "\nAvailable: " $7}'
echo

echo "=========================================="
