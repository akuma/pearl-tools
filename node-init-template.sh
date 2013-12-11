#!/bin/sh
#
# foo - this script starts and stops the foo service
#
# chkconfig:   345 99 99
# description: This is a init template for node app.
# processname: foo

# Source function library.
. /etc/rc.d/init.d/functions

# Source networking configuration.
. /etc/sysconfig/network

# Check that networking is up.
[ "$NETWORKING" = "no" ] && exit 0

PATH=$PATH:/root/.nvm/v0.10.22/bin
NODE_ENV=test
NODE_CMD=supervisor
APP_HOME=/opt/app-repos/foo
APP_FILE=app.js
LOG_FILE=app.log

start()
{
    get_pid
    if [ "$PID" = "" ] ; then
        echo "Starting foo service..."
        cd $APP_HOME
        NODE_ENV=$NODE_ENV $NODE_CMD $APP_FILE >> $LOG_FILE 2>&1 &
    else
        echo "Foo service is already running ($PID)."
    fi
}

stop()
{
    get_pid
    if [ "$PID" = "" ] ; then
        echo "Foo service is not running."
    else
        echo "Foo service is stopping..."
        kill $PID
        sleep 1

	get_pid
        if [ "$PID" = "" ] ; then
            echo "Foo service is stopped."
        else
            kill -9 $PID
            echo "Foo service is killed."
        fi
    fi
}

restart()
{
    stop
    start
}

status()
{
    get_pid
    if [ "$PID" = "" ] ; then
        echo "Foo service is not running."
    else
        echo "Foo service is running ($PID)."
    fi
}

log()
{
    tail -f $APP_HOME/app.log
}

get_pid()
{
    PID=( `ps uax |grep "supervisor" |grep -v " grep " |awk '{print $2}'` )
}

case "$1" in
    start)
        $1
        ;;
    stop)
        $1
        ;;
    restart)
        $1
        ;;
    status)
        $1
        ;;
    log)
        $1
        ;;
    *)
        echo "Usage: $0 {start|stop|restart|status|log}"
        exit 2
esac
