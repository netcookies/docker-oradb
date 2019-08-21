#!/usr/bin/env bash

set -e
source /assets/colorecho
source ~/.bashrc
#版权声明：本文为CSDN博主「VincentQB」的原创文章，遵循CC 4.0 by-sa版权协议，转载请附上原文出处链接及本声明。
#原文链接：https://blog.csdn.net/zwjzqqb/article/details/80621713

echo_green "Optimizing Memory use ASMM method...."
# 首先关闭数据库
sqlplus / as sysdba <<-EOF |
	shutdown immediate;
	exit 0
EOF
while read line; do echo -e "sqlplus: $line"; done

# 计算根据当前内存容量SGA和PGA的容量
SGA_Bytes=$(grep 'MemTotal' /proc/meminfo |awk '{printf ("%d\n",$2*1024*0.8*0.8)}')
PGA_Bytes=$(grep 'MemTotal' /proc/meminfo |awk '{printf ("%d\n",$2*1024*0.8*0.2)}')

# 生成pfile，进行配置
cd $ORACLE_HOME/dbs
sqlplus / as sysdba <<-EOF |
	create pfile from spfile;
	exit 0
EOF
while read line; do echo -e "sqlplus: $line"; done
mv -v spfile${ORACLE_SID}.ora /tmp/

# 配置pfile
sed -i '/^[^*]/d' init${ORACLE_SID}.ora
sed -i '/^.*memory_target.*$/d' init${ORACLE_SID}.ora
sed -i '/^.*memory_max_target.*$/d' init${ORACLE_SID}.ora
sed -i '/^.*sga_target.*$/d' init${ORACLE_SID}.ora
sed -i '/^.*pga_aggregate_target.*$/d' init${ORACLE_SID}.ora
sed -i '/^.*workarea_size_policy.*$/d' init${ORACLE_SID}.ora
echo "*.sga_target=${SGA_Bytes}">>init${ORACLE_SID}.ora
echo "*.pga_aggregate_target=${PGA_Bytes}">>init${ORACLE_SID}.ora
echo "*.workarea_size_policy=auto">>init${ORACLE_SID}.ora

# 启动验证
sqlplus / as sysdba <<-EOF |
	create spfile from pfile;
	exit 0
EOF
while read line; do echo -e "sqlplus: $line"; done
mv -v init${ORACLE_SID}.ora /tmp/
sqlplus / as sysdba <<-EOF |
	startup;
	show parameter memory_target;
	show parameter memory_max_target;
	show parameter sga_target;
	show parameter pga_aggregate_target;
	show parameter workarea_size_policy;
	exit 0
EOF
while read line; do echo -e "sqlplus: $line"; done

MEM_IS_HUGE=$(grep 'MemTotal' /proc/meminfo |awk '{printf ("%d\n",$2*1024-64*1024*1024*1024)}')
if [ $MEM_IS_HUGE -gt 0 ]; then
    echo_green "Optimizing Hugepages Memory...."
	sqlplus / as sysdba <<-EOF |
		alter system set use_large_pages=only scope=spfile;
		exit 0
	EOF
	while read line; do echo -e "sqlplus: $line"; done
fi
