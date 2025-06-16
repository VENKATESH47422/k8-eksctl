#!/bin/bash

ID=$(id -u)
R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"
ARCH="amd64"
PLATFORM="$(uname -s)_$ARCH"

TIMESTAMP=$(date +%F-%H-%M-%S)
LOGFILE="/tmp/$(basename "$0")-$TIMESTAMP.log"

echo "Script started executing at $TIMESTAMP" &>> "$LOGFILE"

VALIDATE() {
    if [ $1 -ne 0 ]; then
        echo -e "$2 ... $R FAILED $N"
        exit 1
    else
        echo -e "$2 ... $G SUCCESS $N"
    fi
}

if [ "$ID" -ne 0 ]; then
    echo -e "$R ERROR: Please run this script with root access $N"
    exit 1
else
    echo "You are running as root user"
fi

# Install yum-utils
yum install -y yum-utils &>> "$LOGFILE"
VALIDATE $? "Installed yum-utils"

# Add Docker repo
yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo &>> "$LOGFILE"
VALIDATE $? "Added Docker repository"

# Install Docker
yum install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin &>> "$LOGFILE"
VALIDATE $? "Installed Docker components"

# Start Docker
systemctl start docker &>> "$LOGFILE"
VALIDATE $? "Started Docker"

# Enable Docker
systemctl enable docker &>> "$LOGFILE"
VALIDATE $? "Enabled Docker to start on boot"

# Add user to Docker group
usermod -aG docker centos &>> "$LOGFILE"
VALIDATE $? "Added 'centos' user to Docker group"

echo -e "$Y Please logout and login again for Docker group changes to apply $N"

# Install kubectl
curl -LO "https://dl.k8s.io/release/$(curl -sL https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl" &>> "$LOGFILE"
chmod +x kubectl &>> "$LOGFILE"
mv kubectl /usr/local/bin/kubectl &>> "$LOGFILE"
VALIDATE $? "Installed kubectl"

# Install eksctl
curl -sLO "https://github.com/eksctl-io/eksctl/releases/latest/download/eksctl_${PLATFORM}.tar.gz" &>> "$LOGFILE"
tar -xzf "eksctl_${PLATFORM}.tar.gz" -C /tmp &>> "$LOGFILE"
rm -f "eksctl_${PLATFORM}.tar.gz"
mv /tmp/eksctl /usr/local/bin &>> "$LOGFILE"
VALIDATE $? "Installed eksctl"
