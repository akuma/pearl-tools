#!/bin/sh
# Script for manage tomcat start/stop/restart/status/log.

# Change this to a real tomcat dir
TOMCAT=/opt/tomcat/tomcat-foobar

# Shell return value
RETVAL=0

start()
{
    PID=( `jps -v |grep $TOMCAT |awk '{print $1}'` )
    if [ "$PID" = "" ] ; then
        rm -rf work/*
        cd $TOMCAT
        sh bin/startup.sh
        echo "$TOMCAT startup."
    else
        echo "$TOMCAT is already running."
    fi
}

stop()
{
    PID=( `jps -v |grep $TOMCAT |awk '{print $1}'` )
    if [ "$PID" = "" ] ; then
        echo "$TOMCAT is not running."
        return $RETVAL
    else
        cd $TOMCAT
        sh bin/shutdown.sh
        echo "Waiting for $TOMCAT shutdown..."
        sleep 5
    fi
 
    PID=( `jps -v |grep $TOMCAT |awk '{print $1}'` )
    if [ "$PID" = "" ] ; then
        echo "$TOMCAT shutdown normally."
    else
        echo "Kill -9 tomcat[$PID]..."
        kill -9 $PID
        echo "$TOMCAT is killed."
    fi
}

restart()
{
    stop
    start
}

status()
{
    jps -v |grep $TOMCAT
}

log()
{
    tail -n 100 -f $TOMCAT/logs/catalina.out
}

help()
{
    echo "Usage: $0 [OPTION]"
    echo ""
    echo "  start        start tomcat"
    echo "  stop         stop tomcat"
    echo "  restart      restart tomcat"
    echo "  status       show started tomcat pid"
    echo "  log          show tomcat log"
    echo "  help         display this help and exit"
    echo ""
}

case "$1" in
    start)
        start
    ;;
    stop)
        stop
    ;;
    restart)
        restart
    ;;
    status)
        status
        ;;
    log)
        log
        ;;
    *)
    help
    RETVAL=1
esac

exit $RETVAL
