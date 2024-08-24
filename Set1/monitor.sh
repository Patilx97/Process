#!/bin/bash

# Refresh interval in seconds (default to 5 seconds)
REFRESH_INTERVAL=5

# Function to display the top 10 applications consuming the most CPU and memory
top_apps() {
    echo "Top 10 Applications by CPU Usage:"
    ps -eo pid,comm,%cpu,%mem --sort=-%cpu | head -n 11
    echo

    echo "Top 10 Applications by Memory Usage:"
    ps -eo pid,comm,%cpu,%mem --sort=-%mem | head -n 11
    echo
}

# Function to monitor network statistics
network_monitor() {
    echo "Network Monitoring:"
    echo "Concurrent Connections:"
    netstat -an | grep 'ESTABLISHED' | wc -l

    echo "Packet Drops:"
    ip -s link | awk '/^[1-9]/ {print $2} /TX:/ {print "TX packets dropped:", $5} /RX:/ {print "RX packets dropped:", $5}'

    echo "Network Traffic (MB in and out):"
    ip -s link | awk '/^[1-9]/ {print $2} /RX:/ {print "RX bytes:", $2/1024/1024 " MB"} /TX:/ {print "TX bytes:", $2/1024/1024 " MB"}'
    echo
}

# Function to display disk usage
disk_usage() {
    echo "Disk Usage:"
    echo "-------------------------------"
    df -h | awk 'NR==1; NR > 1 {print $0 | "sort -k6"}'

    echo ""
    echo "Partitions using more than 80% of the space:"
    echo "-------------------------------"

    df -h | awk 'NR==1; NR > 1 {if ($5+0 > 80) print "\033[31m" $0 "\033[0m"; else print $0}'
    echo
}

# Function to show system load
system_load() {
    echo "System Load and CPU Usage:"
    echo "Load Average:"
    uptime | awk -F'load average: ' '{print $2}'

    echo "CPU Usage:"
    mpstat | awk '{if(NR>3) print $1,$2,$3,$4,$5,$6,$7,$8,$9}' | column -t
    echo
}

# Function to display memory usage
memory_usage() {
    echo "Memory Usage:"
    free -h | grep -v + | grep -E "Mem|Swap"
    echo
}

# Function to display process monitoring
process_monitor() {
    echo "Process Monitoring:"
    echo "Number of Active Processes:"
    ps -e | wc -l

    echo "Top 5 Processes by CPU and Memory Usage:"
    ps -eo pid,comm,%cpu,%mem --sort=-%cpu | head -n 6
    echo
}

# Function to monitor services
service_monitor() {
    echo "Service Monitoring:"
    services=("sshd" "nginx" "apache2" "iptables")
    for service in "${services[@]}"; do
        if systemctl is-active --quiet $service; then
            echo "$service is running"
        else
            echo "$service is not running"
        fi
    done
    echo
}

# Function to display the full dashboard
dashboard() {
    echo "==============================="
    echo "          SYSTEM DASHBOARD     "
    echo "==============================="
    top_apps
    network_monitor
    disk_usage
    system_load
    memory_usage
    process_monitor
    service_monitor
    echo "==============================="
}

# Handling command-line switches
while [[ $# -gt 0 ]]; do
    case $1 in
        -cpu)
            top_apps
            shift
            ;;
        -network)
            network_monitor
            shift
            ;;
        -disk)
            disk_usage
            shift
            ;;
        -load)
            system_load
            shift
            ;;
        -memory)
            memory_usage
            shift
            ;;
        -process)
            process_monitor
            shift
            ;;
        -services)
            service_monitor
            shift
            ;;
        -all)
            DASHBOARD=true
            shift
            ;;
        -interval)
            if [[ $2 =~ ^[0-9]+$ ]]; then
                REFRESH_INTERVAL=$2
                shift 2
            else
                echo "Invalid interval value. Must be an integer."
                exit 1
            fi
            ;;
        *)
            echo "Invalid option: $1"
            echo "Usage: $0 [-cpu | -network | -disk | -load | -memory | -process | -services | -all] [-interval seconds]"
            exit 1
            ;;
    esac
done

# Main loop to refresh the dashboard
while true; do
    clear
    if [[ $DASHBOARD == true ]]; then
        dashboard
    else
        case $1 in
            -cpu)
                top_apps
                ;;
            -network)
                network_monitor
                ;;
            -disk)
                disk_usage
                ;;
            -load)
                system_load
                ;;
            -memory)
                memory_usage
                ;;
            -process)
                process_monitor
                ;;
            -services)
                service_monitor
                ;;
        esac
    fi
    sleep $REFRESH_INTERVAL
done
