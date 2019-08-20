set -e

source /assets/colorecho
trap "echo_red '******* ERROR: Something went wrong.'; exit 1" SIGTERM
trap "echo_red '******* Caught SIGINT signal. Stopping...'; exit 2" SIGINT
mm_policy=${memory_policy:-asmm}

#Install prerequisites directly without virtual package
deps () {

	echo "Installing dependencies"
	yum -y install binutils compat-libstdc++-33 compat-libstdc++-33.i686 ksh elfutils-libelf elfutils-libelf-devel glibc glibc-common glibc-devel gcc gcc-c++ libaio libaio.i686 libaio-devel libaio-devel.i686 libgcc libstdc++ libstdc++.i686 libstdc++-devel libstdc++-devel.i686 make sysstat unixODBC unixODBC-devel
	yum clean all
	rm -rf /var/lib/{cache,log} /var/log/lastlog

}

users () {

	echo "Configuring users"
	groupadd -g 500 oinstall
	groupadd -g 501 dba
	useradd -u 500 -g oinstall -G dba oracle
	echo "oracle:install" | chpasswd
	echo "root:install" | chpasswd
	mkdir -p -m 755 /u01/app/oracle
	mkdir -p -m 755 /u01/app/oraInventory
	mkdir -p -m 755 /u01/app/dpdump
	chown -R oracle:oinstall /u01/app
	sed -i "s/pam_namespace.so/pam_namespace.so\nsession    required     pam_limits.so/g" /etc/pam.d/login
	cat /assets/profile >> ~oracle/.bash_profile
	cat /assets/profile >> ~oracle/.bashrc

}

sysctl_and_limits () {

    sed -i '/.*hugepages.*/d' /assets/sysctl.conf
    sed -i '/.*memlock.*/d' /assets/limits.conf
    sed -i '/.*oracle.*/d' /etc/security/limits.conf
    sed -i 's/ transparent_hugepage=never//g' $(find /boot -name grub.conf)

    if [ $mm_policy = "asmm" ]; then
        MEM_IS_HUGE=$(grep 'MemTotal' /proc/meminfo |awk '{printf ("%d\n",$2*1024-64*1024*1024*1024)}')
        if [ $MEM_IS_HUGE -gt 0 ]; then
            SUM_Bytes=$(grep 'MemTotal' /proc/meminfo |awk '{printf ("%d\n",$2*1024*0.8)}')
            HPSIZE_Bytes=$(grep Hugepagesize /proc/meminfo|awk '{print $2*1024}')
            NUM=$((${SUM_Bytes}/${HPSIZE_Bytes}+100))
            NUM_KB=$((${NUM}*2*1024))
            echo "" >> /assets/sysctl.conf
            echo "" >> /assets/limits.conf
            echo "vm.nr_hugepages = ${NUM}">>/assets/sysctl.conf
            echo "oracle soft memlock ${NUM_KB}">>/assets/limits.conf
            echo "oracle hard memlock ${NUM_KB}">>/assets/limits.conf
            sed -i 's/\<kernel.*$/& transparent_hugepage=never/g' $(find /boot -name grub.conf)
        fi
    fi

    echo "" >> /assets/sysctl.conf
    shmmax_Bytes=$(grep 'MemTotal' /proc/meminfo |awk '{printf ("%d\n",$2*1024*0.8)}')
    shmall_Bytes=$(grep 'MemTotal' /proc/meminfo |awk '{printf ("%d\n",$2/4)}')
    sed -i '/^kernel.shmmax.*$/d' /assets/sysctl.conf
    sed -i '/^kernel.shmall.*$/d' /assets/sysctl.conf
    echo "kernel.shmmax=${shmmax_Bytes}" >> /assets/sysctl.conf
    echo "kernel.shmall=${shmall_Bytes}" >> /assets/sysctl.conf

    sed -i '/^$/d' /assets/limits.conf
    sed -i '/^$/d' /assets/sysctl.conf
    cat /assets/limits.conf >> /etc/security/limits.conf
    cp /assets/sysctl.conf /etc/sysctl.conf
    sysctl -p

}

memory_policy() {
    echo_yellow "$mm_policy detected. Setting..."
    if [ $mm_policy = "amm" ]; then
        SUM_Bytes=$(grep 'MemTotal' /proc/meminfo |awk '{printf ("%d\n",$2*0.8)}')
        TMPFS_Bytes=$(df -k|awk '{if($1~/tmpfs/) print $2*1024}')
        FIN_MB=$(echo "size=$((${SUM_Bytes}/1024/1024+10))M")
        sed -i "s|\(^.*/dev/shm.*\)\(defaults\)\(.*$\)|\1\2,${FIN_MB}\3|g" /etc/fstab
        mount -o remount /dev/shm
        sed -i "s/^INITPARAMS.*$/INITPARAMS=\"memory_max_target=${SUM_Bytes}K,memory_target=${SUM_Bytes}K,optimizer_index_cost_adj=40,java_jit_enabled=false\"/g" /assets/dbca.rsp
    fi
    if [ $mm_policy = "asmm" ]; then
        SGA_Bytes=$(grep 'MemTotal' /proc/meminfo |awk '{printf ("%d\n",$2*0.8*0.8)}')
        PGA_Bytes=$(grep 'MemTotal' /proc/meminfo |awk '{printf ("%d\n",$2*0.8*0.2)}')
        sed -i "s/^INITPARAMS.*$/INITPARAMS=\"memory_target=0,sga_target=${SGA_Bytes}K,pga_aggregate_target=${PGA_Bytes}K,workarea_size_policy=auto,optimizer_index_cost_adj=40,java_jit_enabled=false\"/g" /assets/dbca.rsp
    fi

}

deps
users
sysctl_and_limits
memory_policy
