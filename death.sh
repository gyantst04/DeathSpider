#!/bin/bash

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Function to display section headers
print_header() {
    echo -e "\n${CYAN}========================================${NC}"
    echo -e "${CYAN}   $1${NC}"
    echo -e "${CYAN}========================================${NC}"
}

# Function to check disk information
check_disk() {
    print_header "DISK INFORMATION"
    
    echo -e "${YELLOW}Disk Usage:${NC}"
    df -h | grep -E '^/dev/' | while read output
    do
        usage=$(echo $output | awk '{print $5}' | sed 's/%//g')
        partition=$(echo $output | awk '{print $1}')
        mount_point=$(echo $output | awk '{print $6}')
        size=$(echo $output | awk '{print $2}')
        used=$(echo $output | awk '{print $3}')
        avail=$(echo $output | awk '{print $4}')
        
        if [ $usage -ge 90 ]; then
            color=$RED
            status="CRITICAL"
        elif [ $usage -ge 80 ]; then
            color=$YELLOW
            status="WARNING"
        else
            color=$GREEN
            status="OK"
        fi
        
        echo -e "  Partition: $partition"
        echo -e "  Mount: $mount_point"
        echo -e "  Size: $size | Used: $used | Available: $avail"
        echo -e "  Usage: ${color}$usage% - $status${NC}"
        echo "  --------------------"
    done
    
    echo -e "\n${YELLOW}Inode Usage:${NC}"
    df -i | grep -E '^/dev/' | while read output
    do
        inode_usage=$(echo $output | awk '{print $5}' | sed 's/%//g')
        partition=$(echo $output | awk '{print $1}')
        
        if [ $inode_usage -ge 90 ]; then
            color=$RED
            status="CRITICAL"
        elif [ $inode_usage -ge 80 ]; then
            color=$YELLOW
            status="WARNING"
        else
            color=$GREEN
            status="OK"
        fi
        
        echo -e "  $partition: ${color}$inode_usage% - $status${NC}"
    done
}

# Function to check CPU information
check_cpu() {
    print_header "CPU INFORMATION"
    
    echo -e "${YELLOW}CPU Details:${NC}"
    echo -e "  Processor: $(grep 'model name' /proc/cpuinfo | head -1 | cut -d: -f2 | sed 's/^[ \t]*//')"
    echo -e "  Cores: $(nproc)"
    echo -e "  Threads: $(grep -c 'processor' /proc/cpuinfo)"
    
    echo -e "\n${YELLOW}CPU Usage:${NC}"
    cpu_usage=$(top -bn1 | grep "Cpu(s)" | sed "s/.*, *\([0-9.]*\)%* id.*/\1/" | awk '{print 100 - $1"%"}')
    load_avg=$(uptime | awk -F'load average:' '{print $2}' | sed 's/^[ \t]*//')
    
    # Get individual CPU usage components
    cpu_stats=$(top -bn1 | grep "Cpu(s)")
    us=$(echo $cpu_stats | awk '{print $2}' | sed 's/us,//')
    sy=$(echo $cpu_stats | awk '{print $4}' | sed 's/sy,//')
    id=$(echo $cpu_stats | awk '{print $8}' | sed 's/id,//')
    
    echo -e "  Total Usage: $cpu_usage"
    echo -e "  User: ${us}% | System: ${sy}% | Idle: ${id}%"
    echo -e "  Load Average: $load_avg"
    
    # Check load average
    cores=$(nproc)
    load1=$(echo $load_avg | cut -d, -f1 | sed 's/ //g')
    
    if (( $(echo "$load1 > $cores * 2" | bc -l) )); then
        echo -e "  Load Status: ${RED}HIGH${NC}"
    elif (( $(echo "$load1 > $cores" | bc -l) )); then
        echo -e "  Load Status: ${YELLOW}MEDIUM${NC}"
    else
        echo -e "  Load Status: ${GREEN}NORMAL${NC}"
    fi
}

# Function to check memory information
check_memory() {
    print_header "MEMORY INFORMATION"
    
    # Get memory info
    total_mem=$(free -h | grep Mem: | awk '{print $2}')
    used_mem=$(free -h | grep Mem: | awk '{print $3}')
    free_mem=$(free -h | grep Mem: | awk '{print $4}')
    available_mem=$(free -h | grep Mem: | awk '{print $7}')
    
    # Get memory usage percentage
    total_mem_kb=$(free | grep Mem: | awk '{print $2}')
    used_mem_kb=$(free | grep Mem: | awk '{print $3}')
    mem_usage_percent=$(( (used_mem_kb * 100) / total_mem_kb ))
    
    echo -e "${YELLOW}RAM:${NC}"
    echo -e "  Total: $total_mem | Used: $used_mem | Free: $free_mem"
    echo -e "  Available: $available_mem"
    
    if [ $mem_usage_percent -ge 90 ]; then
        color=$RED
        status="CRITICAL"
    elif [ $mem_usage_percent -ge 80 ]; then
        color=$YELLOW
        status="WARNING"
    else
        color=$GREEN
        status="OK"
    fi
    echo -e "  Usage: ${color}$mem_usage_percent% - $status${NC}"
    
    # Swap information
    echo -e "\n${YELLOW}Swap:${NC}"
    total_swap=$(free -h | grep Swap: | awk '{print $2}')
    used_swap=$(free -h | grep Swap: | awk '{print $3}')
    free_swap=$(free -h | grep Swap: | awk '{print $4}')
    
    echo -e "  Total: $total_swap | Used: $used_swap | Free: $free_swap"
    
    # Check if swap is being used significantly
    if [ "$used_swap" != "0B" ] && [ "$used_swap" != "0" ]; then
        echo -e "  Swap Status: ${YELLOW}ACTIVE${NC}"
    else
        echo -e "  Swap Status: ${GREEN}INACTIVE${NC}"
    fi
}

# Function to check system information
check_system() {
    print_header "SYSTEM INFORMATION"
    
    echo -e "${YELLOW}Basic Info:${NC}"
    echo -e "  Hostname: $(hostname)"
    echo -e "  OS: $(grep PRETTY_NAME /etc/os-release | cut -d= -f2 | tr -d '"')"
    echo -e "  Kernel: $(uname -r)"
    echo -e "  Architecture: $(uname -m)"
    
    echo -e "\n${YELLOW}Uptime:${NC}"
    echo -e "  $(uptime -p)"
    echo -e "  Since: $(uptime -s)"
    
    echo -e "\n${YELLOW}Logged-in Users:${NC}"
    who | awk '{print "  " $1 " from " $5 " (" $3 " " $4 ")"}' | head -5
}

# Function to check network information
check_network() {
    print_header "NETWORK INFORMATION"
    
    echo -e "${YELLOW}Network Interfaces:${NC}"
    ip -br addr show | grep -v "LOOPBACK" | while read line
    do
        interface=$(echo $line | awk '{print $1}')
        state=$(echo $line | awk '{print $2}')
        ip=$(echo $line | awk '{print $3}')
        echo -e "  $interface: $state | IP: $ip"
    done
    
    echo -e "\n${YELLOW}Network Connections:${NC}"
    echo -e "  ESTABLISHED: $(ss -tun state established | wc -l)"
    echo -e "  LISTEN: $(ss -tun state listening | wc -l)"
}

# Function to check processes
check_processes() {
    print_header "TOP PROCESSES"
    
    echo -e "${YELLOW}Top 5 CPU-consuming processes:${NC}"
    ps aux --sort=-%cpu | head -6 | awk 'NR>1 {print "  " $11 " (PID: " $2 ") - CPU: " $3 "% - MEM: " $4 "%"}'
    
    echo -e "\n${YELLOW}Top 5 Memory-consuming processes:${NC}"
    ps aux --sort=-%mem | head -6 | awk 'NR>1 {print "  " $11 " (PID: " $2 ") - MEM: " $4 "% - CPU: " $3 "%"}'
}

# Main function
main() {
    echo -e "${PURPLE}"
    echo "   _____ _   _ _______ ______  _____  ______ _____  "
    echo "  / ____| \ | |__   __|  ____|/ ____| |  ____|  __ \ "
    echo " | |    |  \| |  | |  | |__  | (___   | |__  | |__) |"
    echo " | |    | .   |  | |  |  __|  \___ \  |  __| |  _  / "
    echo " | |____| |\  |  | |  | |____ ____) | | |____| | \ \ "
    echo "  \_____|_| \_|  |_|  |______|_____/  |______|_|  \_\ "
    echo -e "${NC}"
    echo -e "${BLUE}System Health Check Script${NC}"
    echo -e "${BLUE}Generated on: $(date)${NC}"
    
    check_system
    check_cpu
    check_memory
    check_disk
    check_network
    check_processes
    
    print_header "CHECK COMPLETED"
    echo -e "${GREEN}All system checks completed successfully!${NC}"
    echo -e "Report generated on: $(date)"
}

# Check if bc is installed for floating point calculations
if ! command -v bc &> /dev/null; then
    echo -e "${RED}Error: 'bc' command is required but not installed.${NC}"
    echo "Please install it using:"
    echo "  Ubuntu/Debian: sudo apt-get install bc"
    echo "  CentOS/RHEL: sudo yum install bc"
    exit 1
fi

# Run the main function
main
