# System Resource Monitoring Script

This Bash script monitors various system resources and displays them in a dashboard format. It provides real-time insights into CPU usage, memory usage, network activity, disk usage, and more. The script can be run in a full dashboard mode or with individual components displayed separately.

## Features

- **Top 10 Applications**: Displays the top 10 applications consuming the most CPU and memory.
- **Network Monitoring**: Shows the number of concurrent connections, packet drops, and network traffic (in MB).
- **Disk Usage**: Displays disk usage by mounted partitions, highlighting those using more than 80% of the space.
- **System Load**: Shows the current load average and a breakdown of CPU usage (user, system, idle, etc.).
- **Memory Usage**: Displays total, used, and free memory, along with swap memory usage.
- **Process Monitoring**: Shows the number of active processes and the top 5 processes by CPU and memory usage.
- **Service Monitoring**: Monitors the status of essential services like `sshd`, `nginx`, `apache2`, and `iptables`.
- **Custom Dashboard**: Allows users to view specific parts of the dashboard individually using command-line switches.

## Requirements

- The script should be run on a Linux system with Bash.
- Ensure that the necessary commands (`ps`, `netstat`, `ip`, `df`, `uptime`, `mpstat`, `free`, `systemctl`) are available and that you have the necessary permissions to run them.

## Usage

### Running the Full Dashboard

To run the full dashboard that refreshes every 5 seconds (default):

```bash
./monitor.sh -all
