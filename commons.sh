#!/bin/bash
USERID=$(id -u)

LOGS_FOLDER="/var/log/shell-roboshop-commons-"
LOGS_FILE="/var/log/shell-roboshop-commons-/$0.log"
SCRIPT_DIR=$PWD


R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"

mkdir -p $LOGS_FOLDER

TIMESTAMP() {
    date +"%Y-%m-%d %H:%M:%S"
}

LOG() {
  # Usage: LOG "message"
  echo -e "$(TIMESTAMP) :: $1" | tee -a "$LOGS_FILE"
}

START_TIMER() {
  SCRIPT_START_TIME=$(date +%s)
  LOG "Script started"
}

END_TIMER() {
  SCRIPT_END_TIME=$(date +%s)
  TOTAL_TIME=$((SCRIPT_END_TIME - SCRIPT_START_TIME))
  LOG "Script completed"
  LOG "Total execution time: ${TOTAL_TIME} seconds"
}

ROOT_ACCESS(){
    if [ $USERID -ne 0 ]; then
        echo -e "$R please run the script with root user access. $N" | tee -a $LOGS_FILE
        exit 1
    fi
}



VALIDATE(){ 
    if [ $1 -ne 0 ]; then
        echo -e "$(TIMESTAMP) :: $2.....$R Failure $N" | tee -a $LOGS_FILE
        exit 1
    else
        echo -e "$(TIMESTAMP) :: $2.....$G Success $N" | tee -a $LOGS_FILE
    fi
}


NODEJS_SETUP(){
    dnf module list nodejs &>> $LOGS_FILE
    VALIDATE $? "Module list of nodejs"

    dnf module enable nodejs:20 -y &>> $LOGS_FILE
    VALIDATE $? "Enable nodejs:20 version"

    dnf list installed nodejs &>> $LOGS_FILE
    if [ $? -ne 0 ]; then
        echo "nodejs is  not installed, installing now" | tee -a $LOGS_FILE
        dnf install nodejs -y &>> $LOGS_FILE
        VALIDATE $? "Installing nodejs"
    else
        echo -e "nodejs is already installed, $Y SKIPPING $N" | tee -a $LOGS_FILE
    fi
}

USER_SETUP(){

    id roboshop &>> $LOGS_FILE   # idempotency: if you perform operation multiple times the end result would be same 
    if [ $? -ne 0 ]; then 
    echo "System user is not created, now creating system user"         
        useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop &>> $LOGS_FILE
        VALIDATE $? "Adding System User"
    else
        echo -e "System user is already created, $Y SKIPPING $N"

    fi
}

APP_SETUP(){
    mkdir -p /app &>> $LOGS_FILE   # if directory is already existed skip to create the direcory again
    VALIDATE $? "Creating directory"

    curl -o /tmp/$APP_MODULE.zip https://roboshop-artifacts.s3.amazonaws.com/$APP_MODULE-v3.zip &>> $LOGS_FILE
    VALIDATE $? "Downloding code from s3 location"

    cd /app &>> $LOGS_FILE
    VALIDATE $? "change directory to app"

    unzip -o /tmp/$APP_MODULE.zip &>> $LOGS_FILE    # o - means overwriting if APP_MODULE is already unzipped it will overwrite those files or you can remove entire app rm -rf /app/*
    VALIDATE $? "unzip the code"

    cd /app 
    VALIDATE $? "change directory to app"
}

DEPENDENCY_SETUP(){
    rm -rf node_modules package-lock.json &>> $LOGS_FILE #if modules or dependencies already installed first we will remove again we will install
    npm install &>> $LOGS_FILE
    VALIDATE $? "read form index.json and installing depenencies using npm build tool"

}
DAEMON_RELOAD_SETUP(){
    systemctl daemon-reload &>> $LOGS_FILE
    VALIDATE $? "daemon-reloaded"
}

SERVICE_SETUP(){
    
    systemctl enable $APP_MODULE &>> $LOGS_FILE
    systemctl start $APP_MODULE &>> $LOGS_FILE
    VALIDATE $? "Enable and start the $APP_MODULE service"
}

SERVICE_RESTART_SETUP(){
    systemctl restart $APP_MODULE &>> $LOGS_FILE
    VALIDATE $? "Restart $APP_MODULE"
}

MONGODB_SETUP(){
    dnf list installed mongodb-org
    if [ $? -ne 0 ]; then
        dnf install mongodb-org -y &>> $LOGS_FILE
        VALIDATE $? "Installing mongoDB server" 
    else
        echo "mongoDB is already installed $Y SKIPPED $N"
fi
}