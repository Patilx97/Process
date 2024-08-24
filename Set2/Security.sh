
#!/bin/bash

# Ensure the script is run as root
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root" 
   exit 1
fi

LOGFILE="/var/log/security_audit.log"
exec > >(tee -a $LOGFILE) 2>&1

echo "Starting security audit..."

##############################
# 1. User and Group Audits
##############################

echo "1. User and Group Audits"
echo "------------------------"

# List all users and groups
echo "Listing all users:"
cut -d: -f1 /etc/passwd
echo "Listing all groups:"
cut -d: -f1 /etc/group

# Check for users with UID 0 (root privileges)
echo "Checking for users with UID 0:"
awk -F: '($3 == "0") {print $1}' /etc/passwd

# Identify users without passwords
echo "Identifying users without passwords:"
awk -F: '($2 == "" || $2 == "*") {print $1 " has no password"}' /etc/shadow

# Note: Identifying weak passwords would require a more complex tool like cracklib-check, not included here.

##############################
# 2. File and Directory Permissions
##############################

echo "2. File and Directory Permissions"
echo "---------------------------------"

# Scan for world-writable files and directories, excluding /proc, /sys, /dev
echo "Scanning for world-writable files and directories:"
find / -path /proc -prune -o -path /sys -prune -o -path /dev -prune -o -type f -perm -o+w -print
find / -path /proc -prune -o -path /sys -prune -o -path /dev -prune -o -type d -perm -o+w -print

# Check for the presence of .ssh directories and their permissions
echo "Checking .ssh directories and their permissions:"
find /home -type d -name ".ssh" -exec ls -ld {} \;
find /root -type d -name ".ssh" -exec ls -ld {} \;

# Report files with SUID or SGID bits set
echo "Scanning for files with SUID or SGID bits set:"
find / -xdev \( -perm -4000 -o -perm -2000 \) -type f -exec ls -l {} \;

##############################
# 3. Service Audits
##############################

echo "3. Service Audits"
echo "-----------------"

# List all running services
echo "Listing all running services:"
systemctl list-units --type=service --state=running

# Check for critical services (sshd, iptables)
echo "Checking if critical services (sshd, iptables) are running:"
systemctl is-active sshd
systemctl is-active iptables

# Check for services listening on non-standard or insecure ports
echo "Checking for services listening on non-standard or insecure ports:"
ss -tuln

##############################
# 4. Firewall and Network Security
##############################

echo "4. Firewall and Network Security"
echo "--------------------------------"

# Verify that a firewall is active
echo "Checking if a firewall is active:"
if systemctl is-active iptables >/dev/null 2>&1 || systemctl is-active ufw >/dev/null 2>&1; then
    echo "Firewall is active."
else
    echo "Firewall is not active!"
fi

# Report open ports and their associated services
echo "Listing open ports and associated services:"
ss -tuln

# Check for IP forwarding or insecure network configurations
echo "Checking for IP forwarding:"
if sysctl net.ipv4.ip_forward | grep -q "1"; then
    echo "Warning: IP forwarding is enabled."
else
    echo "IP forwarding is disabled."
fi

##############################
# 5. IP and Network Configuration Checks
##############################

echo "5. IP and Network Configuration Checks"
echo "--------------------------------------"

# Identify whether the server’s IP addresses are public or private
echo "Identifying IP addresses:"
for ip in $(ip addr show | grep 'inet ' | awk '{print $2}'); do
    if echo $ip | grep -qE "^10\.|^172\.16\.|^192\.168\."; then
        echo "$ip is a private IP."
    else
        echo "$ip is a public IP."
    fi
done

# Check for SSH exposed on public IPs
echo "Checking for SSH exposed on public IPs:"
ss -tuln | grep ":22" | grep -v "127.0.0.1"

##############################
# 6. Security Updates and Patching
##############################

echo "6. Security Updates and Patching"
echo "--------------------------------"

# Check for available security updates
echo "Checking for available security updates:"
if command -v apt-get >/dev/null 2>&1; then
    apt-get update && apt-get -s upgrade | grep -i security
elif command -v yum >/dev/null 2>&1; then
    yum check-update --security
elif command -v dnf >/dev/null 2>&1; then
    dnf check-update --security
fi

##############################
# 7. Log Monitoring
##############################

echo "7. Log Monitoring"
echo "-----------------"

# Check for suspicious SSH log entries
echo "Checking for suspicious SSH log entries:"
grep "Failed password" /var/log/auth.log | tail -10

# Note: Additional log checks could be added for other critical logs (e.g., sudo failures).

##############################
# 8. Server Hardening
##############################

echo "8. Server Hardening"
echo "-------------------"

### a. SSH Configuration

echo "Configuring SSH for key-based authentication and disabling root password login..."

SSH_CONFIG="/etc/ssh/sshd_config"
ROOT_AUTH_KEYS="/root/.ssh/authorized_keys"

# Create SSH directory and authorized_keys file if not exists
mkdir -p /root/.ssh
chmod 700 /root/.ssh

# Extract public key from the .pem file and place it in authorized_keys (Assumes ubuntu22.pem exists)
# ssh-keygen -y -f ubuntu22.pem > $ROOT_AUTH_KEYS # Uncomment and replace with your actual key
chmod 600 $ROOT_AUTH_KEYS

# Configure SSHD to use key-based authentication and disable root login
sed -i 's/^#\?PasswordAuthentication .*/PasswordAuthentication no/' $SSH_CONFIG
sed -i 's/^#\?PermitRootLogin .*/PermitRootLogin without-password/' $SSH_CONFIG

# Restart SSHD to apply changes
systemctl restart ssh

echo "SSH configuration completed."

### b. Disabling IPv6 (if not required)

echo "Disabling IPv6..."

# Disable IPv6 in sysctl
grep -q "^net.ipv6.conf.all.disable_ipv6" /etc/sysctl.conf || echo -e "# Disable IPv6\nnet.ipv6.conf.all.disable_ipv6 = 1\nnet.ipv6.conf.default.disable_ipv6 = 1\nnet.ipv6.conf.lo.disable_ipv6 = 1" >> /etc/sysctl.conf

# Apply the changes
sysctl -p

# Disable IPv6 on bootloader level
GRUB_CONFIG="/etc/default/grub"
sed -i 's/^GRUB_CMDLINE_LINUX="\(.*\)"/GRUB_CMDLINE_LINUX="\1 ipv6.disable=1"/' $GRUB_CONFIG

# Update GRUB
update-grub

# Example: Update SafeSquid or other services to listen on correct IPv4 address (replace with actual configuration command)
# SAFE_SQUID_CONFIG="/etc/safesquid/safesquid.conf" # Uncomment if needed
# if [ -f "$SAFE_SQUID_CONFIG" ]; then
#   sed -i 's/^bind_ip6/#bind_ip6/' $SAFE_SQUID_CONFIG
#   sed -i 's/^bind_ip4.*/bind_ip4=0.0.0.0/' $SAFE_SQUID_CONFIG
#   systemctl restart safesquid
#   echo "SafeSquid configured to use IPv4."
# else
#   echo "SafeSquid configuration not found or not required."
# fi

echo "IPv6 disabled. Please reboot the server if necessary."

### c. Securing the Bootloader

echo "Securing GRUB bootloader..."

# Install the grub2 password utility if not already installed
apt-get install -y grub-pc-bin

# Prompt for GRUB password
echo "Enter a password for GRUB:"
read -s GRUB_PASSWORD
GRUB_PASSWORD_HASH=$(echo -e "root\n$GRUB_PASSWORD" | grub-mkpasswd-pbkdf2 | grep "grub.pbkdf2.sha512")

# Update GRUB config to use the password
cat <<EOF >> /etc/grub.d/40_custom
set superusers="root"
password_pbkdf2 root $GRUB_PASSWORD_HASH
EOF

# Update GRUB
update-grub

echo "GRUB password has been set. Ensure to remember the password."

### d. Firewall Configuration

echo "Configuring firewall with iptables..."

# Set default policies
iptables -P INPUT DROP
iptables -P FORWARD DROP
iptables -P OUTPUT ACCEPT

# Allow loopback traffic
iptables -A INPUT -i lo -j ACCEPT

# Allow established and related incoming traffic
iptables -A INPUT -m conntrack --ct
