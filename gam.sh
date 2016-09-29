#!/bin/sh
# GAM is a Guomi App Manager tool.

REPOS_ROOT=/opt/app-deploy
REPOS_ASSETS=$REPOS_ROOT/clearn-assets
REPOS_ASSETS2=$REPOS_ROOT/clearn-assets2
REPOS_STATIC=$REPOS_ROOT/clearn-static
REPOS_PAGES=$REPOS_ROOT/clearn-pages
REPOS_STUDENT=$REPOS_ROOT/clearn-student
REPOS_TEACHER=$REPOS_ROOT/clearn-teacher
REPOS_SUPPORT=$REPOS_ROOT/clearn-support
REPOS_ASK=$REPOS_ROOT/clearn-ask

TOMCAT_SUPPORT_KEY=tomcat-support
TOMCAT_SUPPORT_HOME=/opt/tomcat/$TOMCAT_SUPPORT_KEY
TOMCAT_WEB_HOME=/opt/tomcat7
CATALINA_LOG=logs/catalina.out

print_title() {
    echo
    echo "============================================================"
    echo $1
}

print_footer() {
    echo $1
    echo "============================================================"
}

# 更新静态资源
update_assets() {
    print_title "开始更新 clearn-assets ..."

    app_repos="$REPOS_ASSETS $REPOS_STATIC"
    for app in $app_repos
    do
        cd $app
        git checkout .
        git pull
    done

    cd $REPOS_ASSETS
    grunt publish

    cd $REPOS_STATIC
    grunt publish

    print_footer "clearn-assets 更新完毕"
}

# 更新静态资源 v2
update_assets2() {
    print_title "开始更新 clearn-assets2 ..."

    cd $REPOS_ASSETS2
    git checkout .
    git pull
    gulp dist

    print_footer "clearn-assets2 更新完毕"
}

# 更新运营平台
update_support() {
    print_title "开始更新 web-03 ..."
    app_repos="$REPOS_PAGES $REPOS_SUPPORT"
    ssh -t dev@web-03 "$( typeset -f ); update_web_apps $app_repos"
    print_footer "web-03 更新完毕"
}

# 更新 web 服务器程序主函数
update_web() {
    print_title "开始更新 web-$1 ..."
    app_repos="$REPOS_PAGES $REPOS_STUDENT $REPOS_TEACHER"
    ssh -t dev@web-$1 "$( typeset -f ); update_web_apps $app_repos"
    print_footer "web-$1 更新完毕"
}

# 更新 web 服务器上的应用程序
update_web_apps() {
    #app_repos=$*
    app_repos=( $* )
    for app in $app_repos
    do
        echo "---------------------------------------------"
        echo "开始更新 ${app:15} ..."
        cd $app
        git checkout .
        git pull
        echo "${app:15} 更新完毕"
        echo
    done
}

update() {
    case "$1" in
        "assets" )
            update_assets
            update_assets2
        ;;

        "assets2" )
            update_assets2
        ;;

        "support" )
            update_support
        ;;

        "web01" )
            update_web "01"
        ;;

        "web02" )
            update_web "02"
        ;;

        * )
            echo "Unknow update target, please choose again: $0 update [target]"
    esac
}

start() {
    case "$1" in
        "web01" )
            start_web "01"
        ;;

        "web02" )
            start_web "02"
        ;;

        "support" )
            start_web "03"
        ;;

        * )
            echo "Unknow start target, please choose again: $0 start [target]"
    esac
}

start_web() {
    ssh -t dev@web-$1 "sudo systemctl start tomcat"
    echo "web-$1 is starting..."
}

stop() {
    case "$1" in
        "web01" )
            stop_web "01"
        ;;

        "web02" )
            stop_web "02"
        ;;

        "support" )
            stop_web "03"
        ;;

        * )
            echo "Unknow stop target, please choose again: $0 stop [target]"
    esac
}

stop_web() {
    ssh -t dev@web-$1 "sudo systemctl stop tomcat"
    echo "web-$1 is stopping..."
}

restart() {
    case "$1" in
        "web01" )
            restart_web "01"
        ;;

        "web02" )
            restart_web "02"
        ;;

        "support" )
            restart_web "03"
        ;;

        * )
            echo "Unknow restart target, please choose again: $0 restart [target]"
    esac
}

restart_web() {
    ssh -t dev@web-$1 "sudo systemctl restart tomcat"
    echo "web-$1 is restarting..."
}

status() {
    case "$1" in
        "web01" )
            status_web "01"
        ;;

        "web02" )
            status_web "02"
        ;;

        "support" )
            status_web "03"
        ;;

        * )
           echo "Unknow status target, please choose again: $0 status [target]"
    esac
}

status_web() {
    ssh -t dev@web-$1 "sudo systemctl status tomcat -l"
}

log() {
    case "$1" in
        "web01" )
            log_web "01"
        ;;

        "web02" )
            log_web "02"
        ;;

        "support" )
            log_web "03"
        ;;

        * )
            echo "Unknow log target, please choose again: $0 log [target]"
    esac
}

log_web() {
    ssh -t dev@web-$1 "tail -n 100 -f $TOMCAT_WEB_HOME/$CATALINA_LOG"
}

help() {
    echo "Usage: $0 [OPTION] [TARGET]"
    echo
    echo "  upgrade [support|web**]         update app and restart app"
    echo "  update  [assets|support|web**]  update app"
    echo "  start   [support|web**]         start app"
    echo "  stop    [support|web**]         stop app"
    echo "  restart [support|web**]         restart app"
    echo "  status  [support|web**]         show started app info"
    echo "  log     [support|web**]         show last app logs"
    echo "  help                            display this help and exit"
    echo
}

RETVAL=0

case "$1" in
    update )
        update $2
    ;;
    start )
        start $2
    ;;
    stop )
        stop $2
    ;;
    restart )
        restart $2
    ;;
    status )
        status $2
    ;;
    log )
        log $2
    ;;
    upgrade )
        update assets && update $2 && restart $2 && log $2
    ;;
    * )
      help
      RETVAL=1
esac

exit $RETVAL
