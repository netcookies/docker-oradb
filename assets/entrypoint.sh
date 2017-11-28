#!/usr/bin/env bash

set -e
source /assets/colorecho

if [ ! -d "/u01/app/oracle/product/11.2.0/dbhome_1" ]; then
	echo_yellow "Database is not installed. Installing..."
	/assets/install.sh
fi

ln -s /usr/share/zoneinfo/Europe/Amsterdam /etc/localtime

su oracle -c "/assets/entrypoint_oracle.sh"
