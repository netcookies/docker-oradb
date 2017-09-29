set -e

source /assets/colorecho
trap "echo_red '******* ERROR: Something went wrong.'; exit 1" SIGTERM
trap "echo_red '******* Caught SIGINT signal. Stopping...'; exit 2" SIGINT

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

	cp /assets/sysctl.conf /etc/sysctl.conf
	cat /assets/limits.conf >> /etc/security/limits.conf

}

deps
users
sysctl_and_limits
