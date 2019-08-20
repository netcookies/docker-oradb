#!/usr/bin/env bash

set -e
source /assets/colorecho

running_in_docker() {
    (awk -F: '$3 ~ /docker/' /proc/self/cgroup | read non_empty_input)
    return $?
}

setDbDaemon() {
    sed -i 's/\:N/\:Y/g' /etc/oratab
    cp /assets/dbora /etc/init.d/dbora
    chmod 755 /etc/init.d/dbora
    chkconfig --level 35 dbora on
    ln -s /etc/init.d/dbora /etc/rc0.d/K01dbora
    ln -s /etc/init.d/dbora /etc/rc6.d/K01dbora
}

if [ ! -d "/u01/app/oracle/product/11.2.0/dbhome_1" ]; then
	echo_yellow "Database is not installed. Installing..."
	/assets/install.sh
fi

rm -f /etc/localtime \
&& ln -s /usr/share/zoneinfo/Asia/Shanghai /etc/localtime

if running_in_docker; then
    su - oracle -c "/assets/entrypoint_oracle.sh"
else
    su - oracle -c "/assets/install_oracle.sh"
    su - oracle -c "echo 'shutdown immediate;'|sqlplus -s / as sysdba"
    setDbDaemon
fi
