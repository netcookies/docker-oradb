#!/usr/bin/env bash

set -e
source /assets/colorecho

if [ ! -d "/u01/app/oracle/product/11.2.0/dbhome_1" ]; then
	echo_yellow "Database is not installed. Installing..."
	/assets/install.sh
fi

cp /usr/share/zoneinfo/Asia/Shanghai /etc/localtime

su oracle -c "/assets/entrypoint_oracle.sh"

