#!/bin/bash

ID=$(id -u)
R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"
ARCH=amd64
PLATFORM=$(uname -s)_$ARCH

TIMESTAMP=$(date +%F-%H-%M-%S)
LOGFILE="/tmp/$0-$TIMESTAMP.log"

echo "Script started executing at $TIMESTAMP" &>> "$LOGFILE"

VALIDATE() {
    if [ $1 -ne 0 ]; then
        echo -e "$2 ... $R FAILED $N"
        exit 1
    else
        echo -e "$2 ... $G SUCCESS $N"
    fi
}

if [ $ID -ne 0 ]; then
    echo -e "$R ERROR:: Please run this script with root access $N"
    exit 1
else
    echo -e "$G You are running the script as root user $N"
fi

yum install -y yum-utils &>> "$LOGFILE"
VALIDATE $? "Installed yum-utils"

yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo &>> "$LOGFILE"
VALIDATE $? "Added Docker repo"

yum install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin &>> "$LOGFILE"
VALIDATE $? "Installed Docker components"

systemctl start docker &>> "$LOGFILE"
VALIDATE $? "Started Docker service"

systemctl enable docker &>> "$LOGFILE"
VALIDATE $? "Enabled Docker service"

# Use the SUDO_USER if run via sudo, otherwise default to 'centos'
USER_TO_ADD=${SUDO_USER:-centos}
usermod -aG docker "$USER_TO_ADD" &>> "$LOGFILE"
VALIDATE $? "Added user '$USER_TO_ADD' to docker group"

echo -e "$Y Logout and login again to use Docker as non-root user $N"

# Install kubectl
curl -LO "https://dl.k8s.io/release/$(curl -Ls https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl" &>> "$LOGFILE"
VALIDATE $? "Downloaded kubectl"

chmod +x kubectl &>> "$LOGFILE"
VALIDATE $? "Made kubectl executable"

mv kubectl /usr/local/bin/kubectl &>> "$LOGFILE"
VALIDATE $? "Moved kubectl to /usr/local/bin"

# Install eksctl
curl -sLO "https://github.com/eksctl-io/eksctl/releases/latest/download/eksctl_$PLATFORM.tar.gz" &>> "$LOGFILE"
VALIDATE $? "Downloaded eksctl"

tar -xzf eksctl_$PLATFORM.tar.gz -C /tmp &>> "$LOGFILE"
VALIDATE $? "Extracted eksctl archive"

rm eksctl_$PLATFORM.tar.gz &>> "$LOGFILE"

mv /tmp/eksctl /usr/local/bin &>> "$LOGFILE"
VALIDATE $? "Moved eksctl to /usr/local/bin"

echo -e "$G Script execution completed successfully $N"
