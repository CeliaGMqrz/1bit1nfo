---
title: "Servidor de base de datos. MariaDB en Ubuntu"
date: 2021-01-13T14:51:48+01:00
draft: false
toc: false
images:
tags: ['mariadb','ubuntu']
---

![mysqlu.jpg](/images/escenario/mysqlu.jpg)

En sancho (Ubuntu) vamos a instalar un servidor de base de datos mariadb (bd.celia.gonzalonazareno.org). 


### 1. Instalación de mariadb en Ubuntu

Antes de nada tendremos que actualizar la paquetería

```sh
sudo apt-get update
sudo apt-get upgrade
```

Instalamos mysql agregando el repositorio

```sh
sudo apt-get install software-properties-common

sudo apt-key adv --fetch-keys 'https://mariadb.org/mariadb_release_signing_key.asc'

sudo add-apt-repository 'deb [arch=amd64,arm64,ppc64el] https://mirror.one.com/mariadb/repo/10.4/ubuntu focal main'

sudo apt install mariadb-server
```


Procederemos a la instalación segura de mysql

```sh
sudo mysql_secure_installation
```


```sh
ubuntu@sancho:~$ sudo mysql_secure_installation

NOTE: RUNNING ALL PARTS OF THIS SCRIPT IS RECOMMENDED FOR ALL MariaDB
      SERVERS IN PRODUCTION USE!  PLEASE READ EACH STEP CAREFULLY!

In order to log into MariaDB to secure it, we'll need the current
password for the root user. If you've just installed MariaDB, and
haven't set the root password yet, you should just press enter here.

Enter current password for root (enter for none): 
OK, successfully used password, moving on...

Setting the root password or using the unix_socket ensures that nobody
can log into the MariaDB root user without the proper authorisation.

You already have your root account protected, so you can safely answer 'n'.

Switch to unix_socket authentication [Y/n] n
 ... skipping.

You already have your root account protected, so you can safely answer 'n'.

Change the root password? [Y/n] n
 ... skipping.

By default, a MariaDB installation has an anonymous user, allowing anyone
to log into MariaDB without having to have a user account created for
them.  This is intended only for testing, and to make the installation
go a bit smoother.  You should remove them before moving into a
production environment.

Remove anonymous users? [Y/n] Y
 ... Success!

Normally, root should only be allowed to connect from 'localhost'.  This
ensures that someone cannot guess at the root password from the network.

Disallow root login remotely? [Y/n] Y
 ... Success!

By default, MariaDB comes with a database named 'test' that anyone can
access.  This is also intended only for testing, and should be removed
before moving into a production environment.

Remove test database and access to it? [Y/n] Y
 - Dropping test database...
 ... Success!
 - Removing privileges on test database...
 ... Success!

Reloading the privilege tables will ensure that all changes made so far
will take effect immediately.

Reload privilege tables now? [Y/n] Y
 ... Success!

Cleaning up...

All done!  If you've completed all of the above steps, your MariaDB
installation should now be secure.

Thanks for using MariaDB!

```
Vemos que está funcionando correctamente

```sh
ubuntu@sancho:~$ sudo systemctl status mariadb
● mariadb.service - MariaDB 10.4.17 database server
     Loaded: loaded (/lib/systemd/system/mariadb.service; enabled; vendor preset: enabled)
    Drop-In: /etc/systemd/system/mariadb.service.d
             └─migrated-from-my.cnf-settings.conf
     Active: active (running) since Wed 2021-01-13 16:30:24 CET; 24s ago
       Docs: man:mysqld(8)
             https://mariadb.com/kb/en/library/systemd/
   Main PID: 7291 (mysqld)
     Status: "Taking your SQL requests now..."
      Tasks: 32 (limit: 533)
     Memory: 81.5M
     CGroup: /system.slice/mariadb.service
             └─7291 /usr/sbin/mysqld

Jan 13 16:30:34 sancho /etc/mysql/debian-start[7331]: Processing databases
Jan 13 16:30:34 sancho /etc/mysql/debian-start[7331]: information_schema
Jan 13 16:30:34 sancho /etc/mysql/debian-start[7331]: mysql
Jan 13 16:30:34 sancho /etc/mysql/debian-start[7331]: performance_schema
Jan 13 16:30:34 sancho /etc/mysql/debian-start[7331]: Phase 6/7: Checking and upgrading tables
Jan 13 16:30:34 sancho /etc/mysql/debian-start[7331]: Processing databases
Jan 13 16:30:34 sancho /etc/mysql/debian-start[7331]: information_schema
Jan 13 16:30:34 sancho /etc/mysql/debian-start[7331]: performance_schema
Jan 13 16:30:34 sancho /etc/mysql/debian-start[7331]: Phase 7/7: Running 'FLUSH PRIVILEGES'
Jan 13 16:30:34 sancho /etc/mysql/debian-start[7331]: OK

```

### 2. Configurar mariadb para acceder remotamente

Ahora ya podemos acceder a mysql, crear un usuario que tendrá acceso remotamente desde quijote (10.0.2.4) a la base de datos alojada en Sancho.

```sh
ubuntu@sancho:~$ sudo mysql -u root -p
Enter password: 
Welcome to the MariaDB monitor.  Commands end with ; or \g.
Your MariaDB connection id is 56
Server version: 10.4.17-MariaDB-1:10.4.17+maria~focal-log mariadb.org binary distribution

Copyright (c) 2000, 2018, Oracle, MariaDB Corporation Ab and others.

Type 'help;' or '\h' for help. Type '\c' to clear the current input statement.

MariaDB [(none)]> CREATE USER 'celia'@'10.0.2.4' IDENTIFIED BY 'celia';
Query OK, 0 rows affected (0.015 sec)

MariaDB [(none)]> quit
Bye
```

Tenemos que indicar en la configuración de mariadb el 'bind-address' para que escuche desde otras máquinas.

```sh
sudo nano /etc/mysql/my.cnf 
```

Cambiamos la direccion de localhost a 0.0.0.0

```sh
[mysqld]
#
# * Basic Settings
#
user            = mysql
pid-file        = /var/run/mysqld/mysqld.pid
socket          = /var/run/mysqld/mysqld.sock
port            = 3306
basedir         = /usr
datadir         = /var/lib/mysql
tmpdir          = /tmp
lc_messages_dir = /usr/share/mysql
lc_messages     = en_US
skip-external-locking
#
# Instead of skip-networking the default is now to listen only on
# localhost which is more compatible and is not less secure.
bind-address            = 0.0.0.0

```

Reiniciamos el servicio

```sh
sudo systemctl restart mariadb
```

### 3. Prueba de funcionamiento

```sh
[centos@quijote ~]$ mysql -u celia -p -h bd.celia.gonzalonazareno.org
Enter password: 
Welcome to the MariaDB monitor.  Commands end with ; or \g.
Your MariaDB connection id is 36
Server version: 10.4.17-MariaDB-1:10.4.17+maria~focal-log mariadb.org binary distribution

Copyright (c) 2000, 2018, Oracle, MariaDB Corporation Ab and others.

Type 'help;' or '\h' for help. Type '\c' to clear the current input statement.

MariaDB [(none)]> show databases
    -> ;
+--------------------+
| Database           |
+--------------------+
| information_schema |
+--------------------+
1 row in set (0.004 sec)

MariaDB [(none)]> 


```

Entrega una prueba de funcionamiento donde se vea como se realiza una conexión a la base de datos desde quijote


Para ello vamos a crear una base de datos desde sancho y la veremos desde quijote. Tendremos que darle los privilegios al usuario para ver las bases de datos.


```sh
ubuntu@sancho:~$ sudo mysql -u root -p
Enter password: 
Welcome to the MariaDB monitor.  Commands end with ; or \g.
Your MariaDB connection id is 45
Server version: 10.4.17-MariaDB-1:10.4.17+maria~focal-log mariadb.org binary distribution

Copyright (c) 2000, 2018, Oracle, MariaDB Corporation Ab and others.

Type 'help;' or '\h' for help. Type '\c' to clear the current input statement.

MariaDB [(none)]> GRANT ALL PRIVILEGES ON *.* TO 'celia'@'10.0.2.4' IDENTIFIED BY 'celia' WITH GRANT OPTION;
Query OK, 0 rows affected (0.002 sec)

MariaDB [(none)]> FLUSH PRIVILEGES;
Query OK, 0 rows affected (0.001 sec)

MariaDB [(none)]> quit
Bye

```

* Desde sancho:

```sh
ubuntu@sancho:~$ mysql -u celia -p
Enter password: 
Welcome to the MariaDB monitor.  Commands end with ; or \g.
Your MariaDB connection id is 46
Server version: 10.4.17-MariaDB-1:10.4.17+maria~focal-log mariadb.org binary distribution

Copyright (c) 2000, 2018, Oracle, MariaDB Corporation Ab and others.

Type 'help;' or '\h' for help. Type '\c' to clear the current input statement.

MariaDB [(none)]> show databases;
+--------------------+
| Database           |
+--------------------+
| db_quijote         |
| information_schema |
| mysql              |
| performance_schema |
+--------------------+
4 rows in set (0.001 sec)

```

* Desde quijote:

```sh
[centos@quijote ~]$ mysql -u celia -p -h bd.celia.gonzalonazareno.org
Enter password: 
Welcome to the MariaDB monitor.  Commands end with ; or \g.
Your MariaDB connection id is 47
Server version: 10.4.17-MariaDB-1:10.4.17+maria~focal-log mariadb.org binary distribution

Copyright (c) 2000, 2018, Oracle, MariaDB Corporation Ab and others.

Type 'help;' or '\h' for help. Type '\c' to clear the current input statement.

MariaDB [(none)]> show databases;
+--------------------+
| Database           |
+--------------------+
| db_quijote         |
| information_schema |
| mysql              |
| performance_schema |
+--------------------+
4 rows in set (0.002 sec)

```






