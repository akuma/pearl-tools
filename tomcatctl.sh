#!/bin/sh
#
# tomcatctl    Script for control tomcat.
#
# chkconfig: 345 99 99
# description: tomcatctl is a script for control tomcat.

# Change this to tomcat user
OPERATOR=dev

# Change this to real tomcat dir
TOMCATS=( /opt/tomcat/tomcat-foo /opt/tomcat/tomcat-bar )

#TM_REGEX=""
#for TM in ${TOMCATS[@]}
#do
#    TM_REGEX="$TM_REGEX$TM\|"
#done
#if [ $TM_REGEX != "" ] ; then
    #TM_REGEX=""
#fi

# Shell return value
RETVAL=0

start()
{
    for TM in ${TOMCATS[@]}
    do
        su - $OPERATOR -c "cd $TM; rm -rf work/*; bin/startup.sh"
        echo "$TM startup."
    done

    if [ "$TOMCATS" = "" ] ; then
        echo "There is no tomcat configed."
    else
        echo "All tomcats startup."
    fi
}

stop()
{
    PIDS=( `jps -l |grep catalina |awk '{print $1}'` )
    for PID in ${PIDS[@]}
    do
       echo "Shutdown tomcat[$PID]..."
       kill $PID
    done

    if [ "$PIDS" = "" ] ; then
        echo "There is no tomcat running."
    else
        echo "Waiting for tomcats shutdown..."
        sleep 5
    fi

    PIDS=( `jps -l |grep catalina |awk '{print $1}'` )

    if [ "$PIDS" = "" ] ; then
        echo "All tomcats shutdown normally."
    else
        for PID in ${PIDS[@]}
        do
            echo "kill -9 tomcat[$PID]..."
            kill -9 $PID
        done
        echo "All tomcats is killed."
    fi
}

restart()
{
    stop
    start
}

status()
{
    jps -ml |grep catalina
}

help()
{
    echo "Usage: $0 [OPTION]"
    echo ""
    echo "  start        start tomcat"
    echo "  stop         stop tomcat"
    echo "  restart      restart tomcat"
    echo "  status       show started tomcat pid"
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
    *)
        help
        RETVAL=1
esac

exit $RETVAL
