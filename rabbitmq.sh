source ./commons.sh


ROOT_ACCESS
START_TIMER
APP_MODULE=rabbitmq-server

cp $SCRIPT_DIR/rabbitmq.repo /etc/yum.repos.d/rabbitmq.repo &>> $LOGS_FILE
VALIDATE $? "copying the rabbitmq repo"

RABBITMQ_SETUP
SERVICE_SETUP

id roboshop &>> $LOGS_FILE   # idempotency: if you perform operation multiple times the end result would be same 
if [ $? -ne 0 ]; then 
echo "System user is not created, now creating system user"         
    rabbitmqctl add_user roboshop roboshop123 &>> $LOGS_FILE
    VALIDATE $? "Adding System User"
else
    echo -e "System user is already created, $Y SKIPPING $N"
fi

rabbitmqctl set_permissions -p / roboshop ".*" ".*" ".*"
VALIDATE $? "set the permission"
END_TIMER