#!/bin/sh
## Shell script for install oracle

export ORACLE_APP=/opt/oracle/app
export ORACLE_DATA=/opt/oracle/oradata
export ORACLE_HOME=$ORACLE_APP/product/11.2.0/db_1

ORACLE_PASSWD="abc#123"
SYSDBA_PASSWD="abc#123"

SOURCE_DIR=ftp://192.168.1.10/database/oracle
SCRIPT_DIR=ftp://192.168.1.10/database/oracle/script

uninstall() {
    rm -rf $ORACLE_APP/* $ORACLE_DATA/*
    rm -rf /opt/ORCLfmap
    rm -rf /etc/oracle /etc/inittab.cssd
    rm -f /etc/oraInst.loc /etc/oratab
    rm -f /usr/local/bin/oraenv
    rm -f /usr/local/bin/coraenv
    rm -f /usr/local/bin/dbhome
}

input_sid() {
    ## input SID
    echo -n "Please input SID_NAME:"
    read SID_NAME

    if [ -z $SID_NAME ]
    then SID_NAME=center
    fi
    ORACLE_SID=$SID_NAME
}

set_env() {
    ## backup files
    rm -rf /etc/oraInst.loc
    rm -rf /etc/oratab
    cp /etc/sysctl.conf /etc/sysctl.conf.bak
    cp /etc/security/limits.conf /etc/security/limits.conf.bak
    #cp /etc/pam.d/login /etc/pam.d/login.bak
    cp /etc/selinux/config /etc/selinux/config.bak
    cp /etc/redhat-release /etc/redhat-release.bak

    ## 安装依赖的包
    for PACKAGE in lftp binutils compat-gcc-* compat-gcc-*-c++ compat-libstdc++-*  \
        make gcc gcc-c++ glibc glibc.i686 glibc-* glibc-*.i686 libstdc++ libstdc++-devel \
        sysstat libgcc libaio compat-db libXtst libXp libXtst.i686 libXp.i686;
    do
        yum -y install $PACKAGE
    done

    ## 创建 Oracle 组和用户帐户
    groupadd oinstall
    groupadd dba
    useradd -m -g oinstall -G dba oracle
    id oracle

    ## 设置 oracle 帐户的口令
    echo $ORACLE_PASSWD |passwd oracle --stdin
    cp /home/oracle/.bash_profile /home/oracle/.bash_profile.bak

    ## 创建目录
    mkdir -p $ORACLE_APP
    mkdir -p $ORACLE_DATA
    chown -R oracle:oinstall $ORACLE_APP $ORACLE_DATA
    chmod -R 775 $ORACLE_APP $ORACLE_DATA

    ## 配置 Linux 内核参数
    cat >> /etc/sysctl.conf <<EOF
# use for oracle
fs.file-max = 6815744
#kernel.shmall = 2097152
#kernel.shmmax = 2147483648
#kernel.shmmni = 4096
kernel.sem = 250 32000 100 128
net.ipv4.ip_local_port_range = 9000 65500
net.core.rmem_default = 262144
net.core.rmem_max = 4194304
net.core.wmem_default = 262144
net.core.wmem_max = 1048576
fs.aio-max-nr = 1048576
vm.hugetlb_shm_group = 501
EOF

    /sbin/sysctl -p

    ## 为 oracle 用户设置 Shell
    cat >> /etc/security/limits.conf <<EOF
# use for oracle
oracle soft nproc 16384
oracle hard nproc 16384
oracle soft nofile 10240
oracle hard nofile 65536
EOF

    ## 关闭SELIINUX
    sed -i 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/selinux/config
    sed -i 's/SELINUX=permissive/SELINUX=disabled/g' /etc/selinux/config
    setenforce 0

    ## oracle 用户的环境变量
    cat >> /home/oracle/.bash_profile <<EOF
umask 022

export TMPDIR=/tmp
export ORACLE_BASE=$ORACLE_APP
export ORACLE_HOME=$ORACLE_HOME
export ORACLE_SID=$SID_NAME
export PATH=\$PATH:\$ORACLE_HOME/bin
export LD_LIBRARY_PATH=\$LD_LIBRARY_PATH:\$ORACLE_HOME/lib:/lib:/usr/lib
export NLS_LANG=AMERICAN_AMERICA.ZHS16GBK
EOF

    ##su - oracle -c ". home/oracle/.bash_profile"
    ## 设置Oracle10g支持RHEL5的参数
    echo "redhat-4" > /etc/redhat-release
}

install_soft() {
    ## 下载oracle
    SYSTEM=`uname -p`
    if [ "$SYSTEM" = "x86_64" ]
    then
        lftp -c "pget -n 10 $SOURCE_DIR/10201_database_linux_x86_64.cpio.gz"
        zcat 10201_database_linux_x86_64.cpio.gz |cpio -idmv
    else
        lftp -c "pget -n 10 $SOURCE_DIR/10201_database_linux32.zip"       
        unzip 10201_database_linux32.zip
        sleep 1
    fi

    ## 取得静默安装 oracle 应答文件
    wget $SCRIPT_DIR/oracle_install.rsp -O /usr/local/src/oracle/oracle_install.rsp

    ## 执行静默安装 oracle
    su - oracle -c "/usr/local/src/oracle/database/runInstaller -silent -responseFile /usr/local/src/oracle/oracle_install.rsp"

    echo "#######################################################################"
    echo "安装完毕后以 root 身份执行如下命令："
    echo "$ORACLE_APP/oraInventory/orainstRoot.sh"
    echo "$ORACLE_HOME/root.sh"

    echo "请使用 su - oracle, 登录后执行 oracle_init.sh, 继续完成 oracle 的初始化工作！"
    echo "#######################################################################"
}

set_autorun() {
    echo "${ORACLE_SID}:${ORACLE_HOME}:Y" >/etc/oratab

    sed -i 's/\/ade\/vikrkuma_new\/oracle/\$ORACLE_HOME/g' $ORACLE_HOME/bin/dbstart
    cat > /etc/init.d/oracle <<EOF
#!/bin/bash
#
# chkconfig: 345 90 05
# description: Oracle Server
# /etc/init.d/oracle
#
# Run-level Startup script for the Oracle Instance, Listener, and Web Interface

export ORACLE_BASE=$ORACLE_APP
export ORACLE_HOME=$ORACLE_HOME
export ORACLE_SID=${SID_NAME}
export PATH=\$PATH:\$ORACLE_HOME/bin

ORA_OWNR="oracle"

# if the executables do not exist -- display error
if [ ! -f \$ORACLE_HOME/bin/dbstart -o ! -d \$ORACLE_HOME ]
then
    echo "Oracle startup: cannot start"
    exit 1
fi

# depending on parameter -- startup, shutdown, restart of the instance and listener or usage display
case "\$1" in
    start)
        # Oracle listener and instance startup
        echo -n "Starting Oracle: "
        #su \$ORA_OWNR -c "\$ORACLE_HOME/bin/lsnrctl start"
        su \$ORA_OWNR -c \$ORACLE_HOME/bin/dbstart
        touch /var/lock/oracle
        #su \$ORA_OWNR -c "\$ORACLE_HOME/bin/emctl start dbconsole"
        echo "OK"
        ;;

    stop)
        # Oracle listener and instance shutdown
        echo -n "Shutdown Oracle: "
        su \$ORA_OWNR -c "\$ORACLE_HOME/bin/lsnrctl stop"
        su \$ORA_OWNR -c \$ORACLE_HOME/bin/dbshut
        rm -f /var/lock/oracle
        #su \$ORA_OWNR -c "\$ORACLE_HOME/bin/emctl stop dbconsole"
        echo "OK"
        ;;

    reload|restart)
        \$0 stop
        \$0 start
        ;;

    *)
        echo "Usage: \`basename \$0\` start|stop|restart|reload"
        exit 1
        esac
        exit 0

EOF

chmod a+x /etc/init.d/oracle
chkconfig oracle on
}

###############################################
## 以下仅仅生成 oracle_init.sh 文件, 需要手工执行
###############################################
create_init_oracle() {
    ## create oracle_init.sh file, for continue init oracle
    export ORA_HOME=`cat /etc/passwd |grep oracle |awk -F:  '{print $6}'`

    cat > ${ORA_HOME}/oracle_init.sh <<EOF
#!/bin/bash
## oracle init script

# configure listener
${ORACLE_HOME}/bin/netca /silent /responseFile /usr/local/src/oracle/database/response/netca.rsp

## create dump dir
mkdir -p \${ORACLE_BASE}/admin/\${ORACLE_SID}/adump
mkdir -p \${ORACLE_BASE}/admin/\${ORACLE_SID}/bdump
mkdir -p \${ORACLE_BASE}/admin/\${ORACLE_SID}/cdump
mkdir -p \${ORACLE_BASE}/admin/\${ORACLE_SID}/pdump
mkdir -p \${ORACLE_BASE}/admin/\${ORACLE_SID}/pfile
mkdir -p \${ORACLE_BASE}/admin/\${ORACLE_SID}/udump

mkdir -p ${ORACLE_DATA}/\${ORACLE_SID}/archive

## download spfile
wget ${SCRIPT_DIR}/db_init.ora -O \${ORACLE_HOME}/dbs/init\${ORACLE_SID}.ora
cp -af \${ORACLE_HOME}/dbs/init\${ORACLE_SID}.ora \${ORACLE_BASE}/admin/\${ORACLE_SID}/pfile
sed -i "s/center/\${ORACLE_SID}/g" \${ORACLE_HOME}/dbs/init\${ORACLE_SID}.ora

## download db_create.sql
wget ${SCRIPT_DIR}/db_create.sql -O \$HOME/db_create.sql
sed -i "s/center/\${ORACLE_SID}/g" \$HOME/db_create.sql

## create orapwd file
rm -fr \${ORACLE_HOME}/dbs/orapw${ORACLE_SID}
orapwd file=\${ORACLE_HOME}/dbs/orapw\${ORACLE_SID} password=${SYSDBA_PASSWD}

## Now create database
sqlplus / as sysdba <<EEOF
startup nomount pfile=\${ORACLE_HOME}/dbs/init\${ORACLE_SID}.ora
@\$HOME/db_create.sql;
conn  sys/${SYSDBA_PASSWD} as sysdba
@\$ORACLE_HOME/rdbms/admin/catalog.sql;
@\$ORACLE_HOME/rdbms/admin/catproc.sql;
create spfile from pfile;
conn system/manager
@\$ORACLE_HOME/sqlplus/admin/pupbld.sql;
EEOF

#echo "Oracle init succeed!"
EOF

chown oracle:oinstall ${ORA_HOME}/oracle_init.sh
chmod u+x ${ORA_HOME}/oracle_init.sh
}

RETVAL=0

case "$1" in
    install)
        input_sid
        set_env
        install_soft
        create_init_oracle
        set_autorun
        ;;

    uninstall)
        uninstall
        ;;

    reinstall)
        input_sid               
        install_soft
        create_init_oracle               
        set_autorun
        ;;

    init)
        input_sid
        set_autorun
        ;;

    status)
        RETVAL=$?
        ;;

    *)
        echo $"Usage: $0 {install|uninstall|reinstall|init|status}"
        RETVAL=1
esac
exit $RETVAL
