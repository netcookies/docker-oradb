#!/usr/bin/env bash
#版权声明：本文为CSDN博主「VincentQB」的原创文章，遵循CC 4.0 by-sa版权协议，转载请附上原文出处链接及本声明。
#原文链接：https://blog.csdn.net/zwjzqqb/article/details/80621713

# 首先关闭数据库
echo 'shutdown immediate;'|sqlplus -s / as sysdba

## OS和Oracle内存分配依然遵循二八原则
## SGA和PGA内存分配也遵循二八原则
#SUM_Bytes=$(grep 'MemTotal' /proc/meminfo |awk '{printf ("%d\n",$2*1024*0.8)}')
#
## 获取当前的/dev/shm容量
#TMPFS_Bytes=$(df -k|awk '{if($1~/tmpfs/) print $2*1024}')
#
## /dev/shm容量默认是物理内存的一半，而Oracle使用的内存占物理内存的80%
## 是需要调整的，调整方法是计算容量(要稍大一点)，修改fstab，重新挂载：
#FIN_MB=$(echo "size=$((${SUM_Bytes}/1024/1024+10))M")
#sed -i "s|\(^.*/dev/shm.*\)\(defaults\)\(.*$\)|\1\2,${FIN_MB}\3|g" /etc/fstab
#mount -o remount /dev/shm

# 切换到Oracle用户，生成pfile进行编辑设置
cd $ORACLE_HOME/dbs
echo 'create pfile from spfile;'|sqlplus -s / as sysdba
mv -v spfile${ORACLE_SID}.ora /tmp/

# 配置pfile
sed -i '/^[^*]/d' init${ORACLE_SID}.ora
sed -i '/^.*memory_target.*$/d' init${ORACLE_SID}.ora
sed -i '/^.*memory_max_target.*$/d' init${ORACLE_SID}.ora
sed -i '/^.*sga_target.*$/d' init${ORACLE_SID}.ora
sed -i '/^.*pga_aggregate_target.*$/d' init${ORACLE_SID}.ora
sed -i '/^.*workarea_size_policy.*$/d' init${ORACLE_SID}.ora
SUM_Bytes=$(grep 'MemTotal' /proc/meminfo |awk '{printf ("%d\n",$2*1024*0.8)}')
echo "*.memory_max_target=${SUM_Bytes}">>init${ORACLE_SID}.ora
echo "*.memory_target=${SUM_Bytes}">>init${ORACLE_SID}.ora

# 启动验证
echo 'create spfile from pfile;'|sqlplus -s / as sysdba
mv -v init${ORACLE_SID}.ora /tmp/
echo 'startup;'|sqlplus -s / as sysdba
echo 'show parameter memory_target'|sqlplus -s / as sysdba
echo 'show parameter memory_max_target'|sqlplus -s / as sysdba
echo 'show parameter sga_target'|sqlplus -s / as sysdba
echo 'show parameter pga_aggregate_target'|sqlplus -s / as sysdba
echo 'show parameter workarea_size_policy'|sqlplus -s / as sysdba

