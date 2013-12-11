#!/bin/sh
#
# tomcat - this script starts and stops the tomcat server
#
# chkconfig:   345 99 99
# description: This is a script for control tomcat server.
# processname: tomcat

# Source function library.
. /etc/rc.d/init.d/functions

# Source networking configuration.
. /etc/sysconfig/network

# Check that networking is up.
[ "$NETWORKING" = "no" ] && exit 0

JAVA_HOME=/opt/tools/jdk1.7
CATALINA_HOME=/opt/tools/tomcat7

export JAVA_HOME CATALINA_HOME

JPS=$JAVA_HOME/bin/jps
TOMCAT=$CATALINA_HOME
TOMCAT_KEY=tomcat7

start()
{
    get_pid
    if [ "$PID" = "" ] ; then
        rm -rf work/*
        cd $TOMCAT
        sh bin/startup.sh
        echo "$TOMCAT startup."
    else
        echo "$TOMCAT is already running ($PID)."
    fi
}

stop()
{
    get_pid
    if [ "$PID" = "" ] ; then
        echo "$TOMCAT is not running."
        return
    else
        cd $TOMCAT
        sh bin/shutdown.sh
        echo "Waiting for $TOMCAT shutdown..."
        sleep 5
    fi
 
    get_pid
    if [ "$PID" = "" ] ; then
        echo "$TOMCAT shutdown normally."
    else
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
    get_pid
    if [ "$PID" = "" ] ; then
        echo "$TOMCAT is not running."
    else
        echo "$TOMCAT is running ($PID)."
        $JPS -v |grep $TOMCAT
    fi 
}

log()
{
    tail -n 100 -f $TOMCAT/logs/catalina.out
}

get_pid()
{
   PID=( `$JPS -v |grep $TOMCAT_KEY |awk '{print $1}'` ) 
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

RETVAL=0

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
	help
	RETVAL=1
esac

exit $RETVAL

