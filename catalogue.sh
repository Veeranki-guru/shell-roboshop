#!/bin/bash

USERID=$(id -u)

R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"

LOGS_FOLDER="/var/log/shell-roboshop"
SCRIPT_NAME=$(basename "$0" .sh)
SCRIPT_DIR=$(dirname "$(realpath "$0")")

MONGODB_HOST="mongodb.rajesh86s.online"

LOG_FILE="$LOGS_FOLDER/$SCRIPT_NAME.log"

mkdir -p "$LOGS_FOLDER"

echo "Script started executed at: $(date)" | tee -a "$LOG_FILE"

if [ "$USERID" -ne 0 ]; then
    echo "ERROR:: Please run this script with root privilege"
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

# Disable old NodeJS
dnf module disable nodejs -y &>>"$LOG_FILE"
VALIDATE $? "Disabling NodeJS"

# Enable NodeJS 20
dnf module enable nodejs:20 -y &>>"$LOG_FILE"
VALIDATE $? "Enabling NodeJS 20"

# Install NodeJS
dnf install nodejs -y &>>"$LOG_FILE"
VALIDATE $? "Installing NodeJS"

# Create roboshop user if not exists
id roboshop &>>"$LOG_FILE"
if [ $? -ne 0 ]; then
    useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop &>>"$LOG_FILE"
    VALIDATE $? "Creating system user"
else
    echo -e "User already exists ... ${Y}SKIPPING${N}" | tee -a "$LOG_FILE"
fi

# Create app directory
mkdir -p /app
VALIDATE $? "Creating app directory"

# Download application
curl -L -o /tmp/catalogue.zip https://roboshop-artifacts.s3.amazonaws.com/catalogue-v3.zip &>>"$LOG_FILE"
VALIDATE $? "Downloading catalogue application"

cd /app
VALIDATE $? "Changing to app directory"

# Remove old code
rm -rf /app/*
VALIDATE $? "Removing old application code"

# Extract code
unzip -o /tmp/catalogue.zip &>>"$LOG_FILE"
VALIDATE $? "Unzipping catalogue"

# Install dependencies
npm install &>>"$LOG_FILE"
VALIDATE $? "Installing dependencies"

# Copy service file
cp "$SCRIPT_DIR/catalogue.service" /etc/systemd/system/catalogue.service
VALIDATE $? "Copying catalogue service"

# Reload systemd
systemctl daemon-reload &>>"$LOG_FILE"
VALIDATE $? "Reloading systemd"

# Enable service
systemctl enable catalogue &>>"$LOG_FILE"
VALIDATE $? "Enabling catalogue service"

# Copy MongoDB repo
cp "$SCRIPT_DIR/mongo.repo" /etc/yum.repos.d/mongo.repo
VALIDATE $? "Copying MongoDB repo"

# Install MongoDB client
dnf install mongodb-mongosh -y &>>"$LOG_FILE"
VALIDATE $? "Installing MongoDB client"

# Load schema
mongosh --host "$MONGODB_HOST" </app/db/master-data.js &>>"$LOG_FILE"
VALIDATE $? "Loading catalogue products"

# Restart service
systemctl restart catalogue &>>"$LOG_FILE"
VALIDATE $? "Restarting catalogue service"