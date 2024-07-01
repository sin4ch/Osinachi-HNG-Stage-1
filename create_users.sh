#!/bin/bash

# Function to log messages
log_message() {
    echo "$(date): $1" >> /var/log/user_management.log
}

# Function to generate a random password
generate_password() {
    tr -dc 'A-Za-z0-9!"#$%&'\''()*+,-./:;<=>?@[\]^_`{|}~' </dev/urandom | head -c 12
}

# Check if the script is run as root
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root" 
   exit 1
fi

# Check if a file name is provided
if [ $# -eq 0 ]; then
    echo "Please provide a file name as an argument"
    exit 1
fi

# Check if the file exists
if [ ! -f "$1" ]; then
    echo "File not found!"
    exit 1
fi

# Create log file if it doesn't exist
touch /var/log/user_management.log

# Create secure directory for passwords if it doesn't exist
mkdir -p /var/secure
touch /var/secure/user_passwords.csv
chmod 600 /var/secure/user_passwords.csv

# Read the file line by line
while IFS=';' read -r username groups
do
    # Remove leading/trailing whitespace
    username=$(echo "$username" | xargs)
    groups=$(echo "$groups" | xargs)

    # Check if user already exists
    if id "$username" &>/dev/null; then
        log_message "User $username already exists. Skipping."
        continue
    fi

    # Create user with personal group
    useradd -m -U "$username"
    if [ $? -eq 0 ]; then
        log_message "Created user $username with personal group"
    else
        log_message "Failed to create user $username"
        continue
    fi

    # Generate and set password
    password=$(generate_password)
    echo "$username:$password" | chpasswd
    echo "$username,$password" >> /var/secure/user_passwords.csv
    log_message "Set password for user $username"

    # Add user to additional groups
    IFS=',' read -ra group_array <<< "$groups"
    for group in "${group_array[@]}"; do
        group=$(echo "$group" | xargs)
        if ! getent group "$group" > /dev/null 2>&1; then
            groupadd "$group"
            log_message "Created group $group"
        fi
        usermod -a -G "$group" "$username"
        if [ $? -eq 0 ]; then
            log_message "Added user $username to group $group"
        else
            log_message "Failed to add user $username to group $group"
        fi
    done

    log_message "Completed setup for user $username"
done < "$1"

echo "User creation process completed. Check /var/log/user_management.log for details."