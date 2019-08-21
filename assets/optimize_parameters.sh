#!/usr/bin/env bash

set -e
source /assets/colorecho
source ~/.bashrc

processes_val=${processes_num:-2000}

echo_green "Optimizing parameters...."
sqlplus / as sysdba <<-EOF |
	shutdown immediate;
	startup;
	alter system set event='10949 trace name context forever, level 1' scope=spfile;
	alter system set processes=${processes_val} scope=spfile;
	exit 0
EOF
while read line; do echo -e "sqlplus: $line"; done
