#!/bin/bash

USERID=$(id -u)

R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"

LOGS_FOLDER="/var/log/shell-roboshop"
SCRIPT_NAME=$(basename "$0" .sh)
SCRIPT_DIR=$(dirname "$(realpath "$0")")

LOG_FILE="$LOGS_FOLDER/$SCRIPT_NAME.log"

mkdir -p "$LOGS_FOLDER"

echo "Script started executing at: $(date)" | tee -a "$LOG_FILE"

if [ "$USERID" -ne 0 ]; then
    echo -e "${R}ERROR: Please run this script with root privileges${N}"
    exit 1
fi

VALIDATE() {
    if [ "$1" -ne 0 ]; then
        echo -e "$2 ... ${R}FAILURE${N}" | tee -a "$LOG_FILE"
        exit 1
    else
        echo -e "$2 ... ${G}SUCCESS${N}" | tee -a "$LOG_FILE"
    fi
}

# Copy MongoDB repo file
cp "$SCRIPT_DIR/mongo.repo" /etc/yum.repos.d/mongo.repo &>>"$LOG_FILE"
VALIDATE $? "Adding MongoDB repo"

# Install MongoDB
dnf install mongodb-org -y &>>"$LOG_FILE"
VALIDATE $? "Installing MongoDB"

# Enable MongoDB
systemctl enable mongod &>>"$LOG_FILE"
VALIDATE $? "Enabling MongoDB"

# Start MongoDB
systemctl start mongod &>>"$LOG_FILE"
VALIDATE $? "Starting MongoDB"

# Allow remote connections
sed -i 's/bindIp: 127.0.0.1/bindIp: 0.0.0.0/' /etc/mongod.conf &>>"$LOG_FILE"
VALIDATE $? "Configuring MongoDB for remote access"

# Restart MongoDB
systemctl restart mongod &>>"$LOG_FILE"
VALIDATE $? "Restarting MongoDB"

echo -e "${G}MongoDB setup completed successfully${N}"