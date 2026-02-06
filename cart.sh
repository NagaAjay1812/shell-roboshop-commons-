source ./commons.sh
APP_MODULE=cart
ROOT_ACCESS

VALIDATE
NODEJS_SETUP
USER_SETUP
APP_SETUP

DEPENDENCY_SETUP

cp $SCRIPT_DIR/cart.service /etc/systemd/system/cart.service &>> $LOGS_FILE
VALIDATE $? "copying the cart service and updated mongodb DNS record"

SERVICE_SETUP