+++
author = "Celia García Márquez"
title = "Cliente remoto usando el interprete de un servidor MySQL"
date = "2021-03-16"
description = "MySQL: Cliente remoto"
tags = [
    "mongodb",
]
thumbnail= "images/mysql/mysql.png"
+++

## Objetivo

Conectar un cliente remoto a la base de datos insertada en el servidor MySQL

## Requisitos previos

* Una máquina virtual con Debian Buster (paquetería actualizada). En mi caso usaré una máquina alzada con vagrant y virtualbox
* Un servidor MySQL instalado. Instalaremos MariaDB.
* Otra máquina virtual que actuará como cliente remoto con una red compartida con el servidor.

Hemos ejecutado los siguientes comandos para hacer todo lo mencionado
```sh
# Actualizamos la máquina
$ sudo apt update && apt upgrade
# Instalamos mariadb desde los repositorios de debian
$ sudo apt install mariadb-server
# Ejecutamos el script de seguridad de mariadb (opcional)
$ sudo mysql_secure_installation
```


## Creación de la base de datos y usuario de prueba

En anteriores posts se ha explicado como llevar a cabo la instalación y creación de bases de datos y usuarios en mysql así que no voy a explicarlo como tal. Sólo indicaré los comandos a ejecutar.

```sh
# Nos conectamos a mysql como root
mysql -u root -p
# Crearemos la nueva base de datos
CREATE DATABASE academia;
# Creamos el usuario que se va conectar a la base de datos
CREATE USER 'celia'@'%' IDENTIFIED BY 'celia';
# Le damos los privilegios oportunos al usuario para usar la base de datos nueva
GRANT ALL PRIVILEGES ON academia.* TO 'celia'@'%';
# Actualizamos los permisos
FLUSH PRIVILEGES;
# Salimos
exit;
```

Comprobamos que podemos conectarnos con el usuario celia a la base de datos academia

```sh
vagrant@servermysql:~/.ssh$ mysql -u celia -p
Enter password: 
Welcome to the MariaDB monitor.  Commands end with ; or \g.
Your MariaDB connection id is 58
Server version: 10.3.27-MariaDB-0+deb10u1 Debian 10

Copyright (c) 2000, 2018, Oracle, MariaDB Corporation Ab and others.

Type 'help;' or '\h' for help. Type '\c' to clear the current input statement.

MariaDB [(none)]> use academia;
Reading table information for completion of table and column names
You can turn off this feature to get a quicker startup with -A

Database changed

```

Ahora vamos a poblar la base de datos con datos de prueba, podrás encontrarlo en el siguiente [repositorio](https://github.com/CeliaGMqrz/proyecto_escuela_sql/blob/main/fase2_mysql.sql).

Comprobamos que están las tablas creadas:

```sh
MariaDB [academia]> show tables;
+--------------------+
| Tables_in_academia |
+--------------------+
| aulas              |
| ausencias          |
| complementos       |
| detalle_recibos    |
| ejemplares         |
| horarios           |
| materiales         |
| ninos              |
| personal           |
| recibos            |
| relaciones         |
| responsables       |
+--------------------+
12 rows in set (0.000 sec)

```

## Habilitar el acceso remoto

Comprobaremos el direccionamiento de ambas máquinas (servidor y cliente), ambas comparten una red y es por donde el cliente se va a conectar remotamente a la base de datos del servidor. Cabe decir que lógicamente hay que instalar el cliente mysql en la máquina cliente.

Para habilitar el acceso remoto tendremos que editar el siguiente fichero

```sh
sudo nano /etc/mysql/mariadb.conf.d/50-server.cnf
```
Buscaremos la siguiente línea y la dejaremos de la siguiente forma

```sh
bind-address            = 0.0.0.0
```

Reiniciamos el servicio y comprobamos que está en funcionamiento 

```sh
sudo systemctl restart mariadb
sudo systemctl status mariadb
```

```sh
vagrant@servermysql:~$ sudo systemctl restart mariadb
vagrant@servermysql:~$ sudo systemctl status mariadb.service 
● mariadb.service - MariaDB 10.3.27 database server
   Loaded: loaded (/lib/systemd/system/mariadb.service; enabled; vendor preset: enabled)
   Active: active (running) since Tue 2021-03-23 08:10:28 GMT; 5s ago
     Docs: man:mysqld(8)
           https://mariadb.com/kb/en/library/systemd/
  Process: 21364 ExecStartPre=/usr/bin/install -m 755 -o mysql -g root -d /var/run/mysqld (code=exited, s
  Process: 21365 ExecStartPre=/bin/sh -c systemctl unset-environment _WSREP_START_POSITION (code=exited, 
  Process: 21368 ExecStartPre=/bin/sh -c [ ! -e /usr/bin/galera_recovery ] && VAR= ||   VAR=`cd /usr/bin/
  Process: 21446 ExecStartPost=/bin/sh -c systemctl unset-environment _WSREP_START_POSITION (code=exited,
  Process: 21448 ExecStartPost=/etc/mysql/debian-start (code=exited, status=0/SUCCESS)
 Main PID: 21415 (mysqld)
   Status: "Taking your SQL requests now..."
    Tasks: 31 (limit: 544)
   Memory: 69.9M
   CGroup: /system.slice/mariadb.service
           └─21415 /usr/sbin/mysqld

Mar 23 08:10:28 servermysql systemd[1]: Starting MariaDB 10.3.27 database server...
Mar 23 08:10:28 servermysql mysqld[21415]: 2021-03-23  8:10:28 0 [Note] /usr/sbin/mysqld (mysqld 10.3.27-
Mar 23 08:10:28 servermysql mysqld[21415]: 2021-03-23  8:10:28 0 [Warning] Could not increase number of m
Mar 23 08:10:28 servermysql systemd[1]: Started MariaDB 10.3.27 database server.
Mar 23 08:10:28 servermysql /etc/mysql/debian-start[21450]: Upgrading MySQL tables if necessary.
Mar 23 08:10:28 servermysql /etc/mysql/debian-start[21453]: /usr/bin/mysql_upgrade: the '--basedir' optio
Mar 23 08:10:28 servermysql /etc/mysql/debian-start[21453]: Looking for 'mysql' as: /usr/bin/mysql
Mar 23 08:10:28 servermysql /etc/mysql/debian-start[21453]: Looking for 'mysqlcheck' as: /usr/bin/mysqlch
lines 1-25

```
Es importante saber que el puerto por el que está escuchando mysql por defecto es el 3306, lo podemos comprobar con el siguiente comando 

```sh
netstat -tlpn
```
Comprobamos así que está escuchando en el puerto indicado.
```powershell
root@servermysql:/home/vagrant# netstat -tlpn
Active Internet connections (only servers)
Proto Recv-Q Send-Q Local Address           Foreign Address         State       PID/Program name    
tcp        0      0 0.0.0.0:22              0.0.0.0:*               LISTEN      381/sshd            
tcp        0      0 0.0.0.0:3306            0.0.0.0:*               LISTEN      21415/mysqld        
tcp6       0      0 :::22                   :::*                    LISTEN      381/sshd  
```
## Conexión remota desde el cliente 

Como hemos dicho anteriormente tendremos ya instalado mariadb-client en la máquina cliente. Ahora podemos probar la conexión remota de la siguiente forma.

```sh
mysql -u celia -p -h ip 
```

Comprobamos que podemos ver las tablas de la base de datos en cuestión

```sh
vagrant@clientmysql:~$ mysql -u celia -p -h 10.0.1.2
Enter password: 
Welcome to the MariaDB monitor.  Commands end with ; or \g.
Your MariaDB connection id is 36
Server version: 10.3.27-MariaDB-0+deb10u1 Debian 10

Copyright (c) 2000, 2018, Oracle, MariaDB Corporation Ab and others.

Type 'help;' or '\h' for help. Type '\c' to clear the current input statement.

MariaDB [(none)]> use academia;
Reading table information for completion of table and column names
You can turn off this feature to get a quicker startup with -A

Database changed
MariaDB [academia]> show tables;
+--------------------+
| Tables_in_academia |
+--------------------+
| aulas              |
| ausencias          |
| complementos       |
| detalle_recibos    |
| ejemplares         |
| horarios           |
| materiales         |
| ninos              |
| personal           |
| recibos            |
| relaciones         |
| responsables       |
+--------------------+
12 rows in set (0.002 sec)

```

Como podemos ver podemos ver los registros sin problemas.