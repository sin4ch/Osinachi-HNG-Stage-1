# Automating User Creation with Bash: A DevOps Approach

---

In the fast-paced world of software development, efficient onboarding of new team members is crucial. As part of the HNG Internship program (learn more at [https://hng.tech/internship](https://hng.tech/internship)), I was tasked with creating a bash script to automate user creation for a growing development team. This article explains the script's functionality and the reasoning behind its implementation.

Check out [https://hng.tech/hire](https://hng.tech/hire) to learn about hiring our interns.

## The Challenge

---

The task was to create a bash script that could:

1. Read a text file containing usernames and group assignments
2. Create users and their personal groups
3. Assign users to additional specified groups
4. Generate and set random passwords for each user
5. Log all actions
6. Store passwords securely

## The Solution

---

Let's break down the key components of our script:

### 1. Input Validation and Setup

The script starts by checking if it's run as root and if a valid input file is provided. It also sets up necessary log and password files:

```bash
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root"
   exit 1
fi

# ... (file checks)

touch /var/log/user_management.log
mkdir -p /var/secure
touch /var/secure/user_passwords.csv
chmod 600 /var/secure/user_passwords.csv

```

### 2. User Creation and Group Assignment

The main loop reads the input file line by line, creating users and assigning them to groups:

```bash
while IFS=';' read -r username groups
do
    useradd -m -U "$username"
    # ... (password generation and setting)
    IFS=',' read -ra group_array <<< "$groups"
    for group in "${group_array[@]}"; do
        # ... (group creation if necessary)
        usermod -a -G "$group" "$username"
    done
done < "$1"

```

### 3. Password Generation and Storage

We use a function to generate random passwords and store them securely:

```bash
generate_password() {
    tr -dc 'A-Za-z0-9!"#$%&'\\''()*+,-./:;<=>?@[\\]^_`{|}~' </dev/urandom | head -c 12
}

# ... (in main loop)
password=$(generate_password)
echo "$username:$password" | chpasswd
echo "$username,$password" >> /var/secure/user_passwords.csv

```

### 4. Logging

All actions are logged for auditing purposes:

```bash
log_message() {
    echo "$(date): $1" >> /var/log/user_management.log
}

# ... (used throughout the script)
log_message "Created user $username with personal group"

```
