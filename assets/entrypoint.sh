#!/usr/bin/env bash

set -e
source /assets/colorecho

mm_policy=${memory_policy:-asmm}

if [ ! -d "/u01/app/oracle/product/11.2.0/dbhome_1" ]; then
	echo_yellow "Database is not installed. Installing..."
	/assets/install.sh
fi

rm -f /etc/localtime \
&& ln -s /usr/share/zoneinfo/Asia/Shanghai /etc/localtime

su oracle -c "/assets/entrypoint_oracle.sh"

/assets/${mm_policy}_memory_policy.sh
