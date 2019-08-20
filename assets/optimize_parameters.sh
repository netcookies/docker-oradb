#!/usr/bin/env bash
#版权声明：本文为CSDN博主「VincentQB」的原创文章，遵循CC 4.0 by-sa版权协议，转载请附上原文出处链接及本声明。
#原文链接：https://blog.csdn.net/zwjzqqb/article/details/80621713

processes_val=${processes_num:-2000}

# 首先关闭数据库
echo 'shutdown immediate;'|sqlplus / as sysdba

echo 'startup;'|sqlplus / as sysdba
echo "alter system set event='10949 trace name context forever, level 1' scope=spfile;"|sqlplus -s / as sysdba
echo "alter system set processes=${processes_val} scope=spfile;"|sqlplus -s / as sysdba

