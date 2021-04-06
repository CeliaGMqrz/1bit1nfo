+++
author = "Celia García Márquez"
title = "Conexión remota a Oracle19c"
date = "2021-04-05"
description = "Cliente remoto"
tags = [
    "oracle",
]
thumbnail= "images/mysql/oracle1.png"
+++


#### Cliente remoto 

Vamos a usar otra máquina virtual, en mi caso voy a clonar el servidor de oracle CentOS8 y la clonación la utlizaré de cliente.

Para que se conecte el cliente de forma remota al servidor llevaremos estos pasos:

* Desactivar o añadir una regla en el firewall. En mi caso vamos a añadir una regla que hace que el tráfico pase por el puerto que tiene por defecto Oracle. Aunque este puede variar dependiendo de la configuración que tengamos.

```sh
firewall-cmd --permanent --add-port=1521/tcp
```

* Cambiar el nombre de dominio completo (FQDN) de nuestro servidor, en el fichero /etc/hosts. Para conectarnos con resolución de nombres, en vez de por ip.

```sh
192.168.100.182   bd.oracle.celia.es    oracle
```

* Tenemos que indicarle al servidor que escuche por el puerto por defecto que hemos indicando anteriormente en el firewall, para ello vamos a editar el siguiente fichero, dónde le indicamos el nombre completo del servidor y el puerto lo dejamos por defecto.

```sh
sudo nano /opt/oracle/product/19c/dbhome_1/network/admin/listener.ora
```

Contenido:

```sh
[oracle@bd ~]$ cat /opt/oracle/product/19c/dbhome_1/network/admin/listener.ora
# listener.ora Network Configuration File: /opt/oracle/product/19c/dbhome_1/network/admin/listener.ora
# Generated by Oracle configuration tools.

LISTENER =
  (DESCRIPTION_LIST =
    (DESCRIPTION =
      (ADDRESS = (PROTOCOL = TCP)(HOST = bd.oracle.celia.es)(PORT = 1521))
      (ADDRESS = (PROTOCOL = IPC)(KEY = EXTPROC1521))
    )
  )
```

* Iniciamos el proceso de escucha de la siguiente forma

```sh
[oracle@bd ~]$ lsnrctl start

```

* Comprobamos que está escuchando en el puerto indicado 

```sh
[root@bd ~]# netstat -tlpn
Active Internet connections (only servers)
Proto Recv-Q Send-Q Local Address           Foreign Address         State       PID/Program name    
tcp        0      0 192.168.122.1:53        0.0.0.0:*               LISTEN      1723/dnsmasq        
tcp        0      0 0.0.0.0:22              0.0.0.0:*               LISTEN      1008/sshd           
tcp        0      0 127.0.0.1:631           0.0.0.0:*               LISTEN      1012/cupsd          
tcp        0      0 0.0.0.0:111             0.0.0.0:*               LISTEN      1/systemd           
tcp6       0      0 :::22                   :::*                    LISTEN      1008/sshd           
tcp6       0      0 ::1:631                 :::*                    LISTEN      1012/cupsd          
tcp6       0      0 :::5500                 :::*                    LISTEN      2907/tnslsnr        
tcp6       0      0 :::111                  :::*                    LISTEN      1/systemd           
tcp6       0      0 :::16081                :::*                    LISTEN      3009/ora_d000_ORCLC 
tcp6       0      0 :::1521                 :::*                    LISTEN      2907/tnslsnr   
```

* Ahora ya podemos ir a la máquina **cliente**. Vemos el direccionamiento y que el nombre al hacer la clonación se ha modificado.

```sh
[oracle@localhost ~]$ hostname
localhost.localdomain
[oracle@localhost ~]$ hostname -f
localhost
[oracle@localhost ~]$ ip a
1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue state UNKNOWN group default qlen 1000
    link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
    inet 127.0.0.1/8 scope host lo
       valid_lft forever preferred_lft forever
    inet6 ::1/128 scope host 
       valid_lft forever preferred_lft forever
2: ens3: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc fq_codel state UP group default qlen 1000
    link/ether 52:54:00:cb:c8:c6 brd ff:ff:ff:ff:ff:ff
    inet 192.168.100.186/24 brd 192.168.100.255 scope global dynamic noprefixroute ens3
       valid_lft 2108sec preferred_lft 2108sec
    inet6 fe80::38c8:cac5:d1ba:3cd3/64 scope link dadfailed tentative noprefixroute 
       valid_lft forever preferred_lft forever
    inet6 fe80::241a:f640:d38c:61a5/64 scope link noprefixroute 
       valid_lft forever preferred_lft forever
3: virbr0: <NO-CARRIER,BROADCAST,MULTICAST,UP> mtu 1500 qdisc noqueue state DOWN group default qlen 1000
    link/ether 52:54:00:0d:37:48 brd ff:ff:ff:ff:ff:ff
    inet 192.168.122.1/24 brd 192.168.122.255 scope global virbr0
       valid_lft forever preferred_lft forever
4: virbr0-nic: <BROADCAST,MULTICAST> mtu 1500 qdisc fq_codel master virbr0 state DOWN group default qlen 1000
    link/ether 52:54:00:0d:37:48 brd ff:ff:ff:ff:ff:ff

```
* Ahora sí podemos acceder a la base de datos de la siguiente forma:

> Nota: Si hemos reiniciado las máquinas es probable que tengamos que ejecutar STARTUP en SQLPLUS para iniciar la base de datos, si no, no podremos acceder ni consultar nada.

```sh
[oracle@localhost ~]$ sqlplus c##celia/celia@bd.oracle.celia.es/ORCLCDB

SQL*Plus: Release 19.0.0.0.0 - Production on Fri Apr 2 11:57:29 2021
Version 19.3.0.0.0

Copyright (c) 1982, 2019, Oracle.  All rights reserved.

Hora de Ultima Conexion Correcta: Vie Abr 02 2021 11:41:51 +02:00

Conectado a:
Oracle Database 19c Enterprise Edition Release 19.0.0.0.0 - Production
Version 19.3.0.0.0

SQL> select * from cat;

TABLE_NAME
--------------------------------------------------------------------------------
TABLE_TYPE
-----------
ALUMNOS
TABLE

CURSOS
TABLE

MATRICULAS
TABLE


SQL> select * from cursos;

CO NOMBR
-- -----
11 1
22 2
33 3



```