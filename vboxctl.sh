#!/bin/sh 

### BEGIN INIT INFO
# Provides:          Guomi
# Required-Start:    $remote_fs $syslog $local_fs $network $named
# Required-Stop:     $remote_fs $syslog $local_fs $network $named
# Default-Start:     2 3 4 5
# Default-Stop:      0 1 6
# Short-Description: Manages VirtualBox VMs
# Description:       This script is base on http://www.kernelhardware.org/virtualbox-auto-start-vm-centos-fedora-redhat/.
### END INIT INFO

# Source function library.
if [ -f /etc/init.d/functions ] ; then
    . /etc/init.d/functions
elif [ -f /etc/rc.d/init.d/functions ] ; then
    . /etc/rc.d/init.d/functions
fi

################################################################################
# INITIAL CONFIGURATION
VBOXDIR="/etc/vbox"
VM_USER="vbox"
USE_NAT="no"

export PATH="${PATH:+$PATH:}/bin:/usr/bin:/usr/sbin:/sbin"

if [ -f $VBOXDIR/config ]; then
    . $VBOXDIR/config
fi

SU="su $VM_USER -c"
VBOXMANAGE="VBoxManage -nologo"

################################################################################
# FUNCTIONS

# Determine if USE_NAT is set to "yes"
use_nat() {
    if [ "$USE_NAT" = "yes" ]; then
        return `true`
    else
        return `false`
    fi
}

log_failure_msg() {
    echo $1
}

log_action_msg() {
    echo $1
}

# Check for running machines every few seconds; return when all machines are
# down
wait_for_closing_machines() {
    RUNNING_MACHINES=`$SU "$VBOXMANAGE list runningvms" | wc -l`
    if [ $RUNNING_MACHINES != 0 ]; then
        sleep 5
        wait_for_closing_machines
    fi
}

################################################################################
# RUN
case "$1" in
    start)
        if [ -f /etc/vbox/machines_enabled ]; then

            cat /etc/vbox/machines_enabled | while read VM; do
                log_action_msg "Starting VM: $VM ..."
                $SU "$VBOXMANAGE startvm "$VM" -type vrdp"
                RETVAL=$?
            done
            touch /var/lock/vboxctl
        fi
        ;;
    stop)
# NOTE: this stops all running VM's. Not just the ones listed in the
# config
        $SU "$VBOXMANAGE list runningvms" | awk '{print substr($1, 2, length($1) - 2)}' | while read VM; do
            log_action_msg "Shutting down VM: $VM ..."
            $SU "$VBOXMANAGE controlvm "$VM" poweroff"
        done
        rm -f /var/lock/vboxctl
        wait_for_closing_machines
        ;;
    start-vm)
        log_action_msg "Starting VM: $2 ..."
        $SU "$VBOXMANAGE startvm "$2" -type vrdp"
        ;;
    stop-vm)
        log_action_msg "Stopping VM: $2 ..."
        $SU "$VBOXMANAGE controlvm "$2" acpipowerbutton"
        ;;
    poweroff-vm)
        log_action_msg "Powering off VM: $2 ..."
        $SU "$VBOXMANAGE controlvm "$2" poweroff"
        ;;
    status)
        echo "The following virtual machines are currently running:"
        $SU "$VBOXMANAGE list runningvms" | while read VM; do
            echo -n "$VM ("
            echo -n `$SU "VBoxManage showvminfo ${VM%% *}|grep Name:|sed -e 's/^Name:s*//g'"`
            echo ')'
        done
        ;;
    *)
        echo "Usage: $0 {start|stop|status|start-vm <VM name>|stop-vm <VM name>|poweroff-vm <VM name>}"
        exit 3
esac

exit 0
