#!/usr/bin/env bash
#版权声明：本文为CSDN博主「VincentQB」的原创文章，遵循CC 4.0 by-sa版权协议，转载请附上原文出处链接及本声明。
#原文链接：https://blog.csdn.net/zwjzqqb/article/details/80621713

su - oracle
# 首先关闭数据库
echo 'shutdown immediate;'|sqlplus / as sysdba

# 计算根据当前内存容量SGA和PGA的容量
SGA_Bytes=$(grep 'MemTotal' /proc/meminfo |awk '{printf ("%d\n",$2*1024*0.8*0.8)}')
PGA_Bytes=$(grep 'MemTotal' /proc/meminfo |awk '{printf ("%d\n",$2*1024*0.8*0.2)}')

# 生成pfile，进行配置
cd $ORACLE_HOME/dbs
echo 'create pfile from spfile;'|sqlplus / as sysdba
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
echo 'create spfile from pfile;'|sqlplus / as sysdba
mv -v init${ORACLE_SID}.ora /tmp/
echo 'startup;'|sqlplus / as sysdba
echo 'show parameter memory_target'|sqlplus -s / as sysdba
echo 'show parameter memory_max_target'|sqlplus -s / as sysdba
echo 'show parameter sga_target'|sqlplus -s / as sysdba
echo 'show parameter pga_aggregate_target'|sqlplus -s / as sysdba
echo 'show parameter workarea_size_policy'|sqlplus -s / as sysdba
