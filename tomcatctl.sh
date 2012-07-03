#!/bin/sh
#
# tomcatctl    Script for control tomcat.
#
# chkconfig: 2345 99 99
# description: tomcatctl is a script for control tomcat.

start()
{
    rm -rf $CATALINA_HOME/webapps/ROOT
    rm -rf $CATALINA_HOME/vhost_*/webapps/ROOT
    rm -rf $CATALINA_HOME/work/*
    cd $CATALINA_HOME/bin
    sh catalina.sh start &
    echo "tomcat startup."
}

stop()
{
    pid=`ps -ef|grep "java"|grep "$CATALINA_HOME"|awk '{print $2}'`
    if [ "$pid" = "" ] ; then
	echo "No tomcat alive."
    else
	sh $CATALINA_HOME/bin/shutdown.sh
	echo "Wait for a moment please..."
	sleep 5 

	pid=`ps -ef|grep "java"|grep "$CATALINA_HOME"|awk '{print $2}'`
	if [ "$pid" = "" ] ; then
	    echo "No tomcat alive."
	else
	    kill $pid
	    echo "tomcat[$pid] shutdown."
	fi
    fi
}

restart()
{
    stop
    start
}

help()
{
    echo "Usage: $0 [OPTION]"
    echo ""
    echo "  start        start tomcat"
    echo "  stop         stop tomcat"
    echo "  restart      restart tomcat"
    echo "  log          tail the catalina log"
    echo "  help         display this help and exit"
    echo ""
}

RETVAL=0

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
    log)
        tail -f $CATALINA_HOME/logs/catalina.out
        ;;
    *)
	help
	RETVAL=1
esac

exit $RETVAL
