source ./commons.sh

ROOT_ACCESS
APP_MODULE=redis
START_TIMER
REDIS_SETUP
sed -i -e 's/127.0.0.1/0.0.0.0/g' -e '/protected-mode/ c protected-mode no' /etc/redis/redis.conf &>> "$LOGS_FILE"
VALIDATE $? "Allowing the remote connection"

SERVICE_SETUP
END_TIMER