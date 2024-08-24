# Security Audit and Server Hardening Script

This script automates security audits and server hardening processes for Linux servers. It is designed to be reusable and modular, making it easy to deploy across multiple servers to ensure they meet stringent security standards.

## Table of Contents
1. [Installation](#installation)
2. [Configuration](#configuration)
3. [Usage](#usage)
4. [Examples](#examples)
5. [Customization](#customization)
6. [Contributing](#contributing)
7. [License](#license)

## Installation

1. **Clone this Repository**

2. **Make the Script Executable**
`chmod +x security_audit.sh
`

3. **Ensure Dependencies are Installed**

The script relies on standard Linux utilities. Ensure you have the following packages installed:

 bash  
 awk  
 grep  
 ss  
 find  
 systemctl  
 iptables or ufw  
 apt-get, yum, or dnf (depending on your distribution)  

For Debian-based systems:
`
apt-get install iptables iproute2
`

For Red Hat-based systems:
`
yum install iptables iproute
`
## Configuration
The script uses default configurations but can be customized using the configuration files provided in the config directory.

1. SSH Key Configuration
Place your SSH public key in the config/authorized_keys file.

2. GRUB Bootloader Configuration
Update the config/grub_password.txt file with the desired GRUB password.

3. Firewall Rules
Customize firewall rules in the config/iptables_rules.sh file.

## Usage

1. Run the Script
Execute the script with root privileges:
`
sudo ./security.sh
`
The script will perform a security audit and apply hardening measures, logging all activities to /var/log/security_audit.log.

2. Review the Log File
After execution, review the log file for details on the audit and hardening process:
`
cat /var/log/security_audit.log
`

