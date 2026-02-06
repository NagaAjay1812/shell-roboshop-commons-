source ./commons.sh
ROOT_ACCESS
START_TIMER

cp mongo.repo /etc/yum.repos.d/
VALIDATE $? "Copying mongo repo"
APP_MODULE=mongod
MONGODB_SETUP


sed -i 's/127.0.0.1/0.0.0.0/g' /etc/mongod.conf &>> "$LOGS_FILE"
VALIDATE $? "Allowing the remote connection"


SERVICE_SETUP
SERVICE_RESTART_SETUP
END_TIMER