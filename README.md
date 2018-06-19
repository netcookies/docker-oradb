Image for running Oracle Database 11g Standard/Enterprise. Due to oracle license restrictions image is not contain database itself and will install it on first run from external directory.

``This image for development use only``

# Usage
Download database installation files from [Oracle site](http://www.oracle.com/technetwork/database/in-memory/downloads/index.html) and unpack them to **install_folder**.
Run container and it will install oracle and create database:

```sh
docker-compose up -d
docker-compose logs -f oradb
```
Then you can commit this container to have installed and configured oracle database:
```sh
docker commit oracle11g oracle11g-installed
```

Connect to instance:
```sh
sqlcl sys/oracle@localhost:1521:ORCL as sysdba
```

Connect to container:
```sh
docker-compose exec oradb bash
```

Connect to container with user 'oracle':
```sh
docker-compose exec --user oracle oradb bash
```

Database located in /u01/app/oracle folder.
ORACLE_HOME=/u01/app/oracle/product/11.2.0/dbhome_1

OS users:
* root/install
* oracle/install

DB users:
* SYS/oracle

Optionally you can map dpdump folder to easy upload dumps:
```sh
docker run --privileged --name oracle11g -p 1521:1521 -v <install_folder>:/install -v <local_dpdump>:/opt/oracle/dpdump jaspeen/oracle-11g
```
To execute impdp/expdp just use docker exec command:
```sh
docker exec -it oracle11g impdp ..
```
