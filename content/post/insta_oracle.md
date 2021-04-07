+++
author = "Celia García Márquez"
title = "Instalación de Oracle sobre CentOS8"
date = "2021-04-06"
description = "Instalacion de Oracle"
tags = [
    "oracle",
]
thumbnail= "images/mysql/oracle.png"
+++


## Instalación de oracle en Centos8

Vamos a instalar oracle de la siguiente forma:

1. Descargamos la siguiente versión de oracle en la página oficial, en este caso vamos a usar:

[Oracle-database-ee-19c-1.0-1.x86_64](https://www.oracle.com/es/database/technologies/oracle19c-linux-downloads.html)

> Necesitaremos registrarnos para descargarlo y aceptar los términos y condiciones.

2. Enviamos el paquete .rpm ya descargado por scp a nuestro CentOS.

```sh 
scp oracle-database-ee-19c-1.0-1.x86_64.rpm user@192.168.100.167:/home/user/oracle
```

3. Ahora vamos a descargar las dependencias, o prerrequisistos que necesita el sistema para soportar el gestor de base de datos oracle. 

```powershell
sudo dnf install https://yum.oracle.com/repo/OracleLinux/OL8/baseos/latest/x86_64/getPackage/oracle-database-preinstall-19c-1.0-1.el8.x86_64.rpm
```

Como vemos carga las dependencias correctamente.

```sh
[centos@localhost ~]$ sudo dnf install https://yum.oracle.com/repo/OracleLinux/OL8/baseos/latest/x86_64/getPackage/oracle-database-preinstall-19c-1.0-1.el8.x86_64.rpm
Última comprobación de caducidad de metadatos hecha hace 0:22:22, el mié 31 mar 2021 16:20:42 CEST.
oracle-database-preinstall-19c-1.0-1.el8.x86_64.rpm                      288 kB/s |  24 kB     00:00    
Dependencias resueltas.
=========================================================================================================
 Paquete                           Arq.      Versión                               Repositorio      Tam.
=========================================================================================================
Instalando:
 oracle-database-preinstall-19c    x86_64    1.0-1.el8                             @commandline     24 k
Instalando dependencias:
 glibc-devel                       x86_64    2.28-127.el8                          baseos          1.0 M
 glibc-headers                     x86_64    2.28-127.el8                          baseos          475 k
 kernel-headers                    x86_64    4.18.0-240.15.1.el8_3                 baseos          5.6 M
 ksh                               x86_64    20120801-254.el8                      appstream       926 k
 libaio-devel                      x86_64    0.3.112-1.el8                         baseos           19 k
 libnsl                            x86_64    2.28-127.el8                          baseos           99 k
 libstdc++-devel                   x86_64    8.3.1-5.1.el8                         appstream       2.0 M
 libxcrypt-devel                   x86_64    4.1.1-4.el8                           baseos           25 k
 lm_sensors-libs                   x86_64    3.4.0-21.20180522git70f7e08.el8       baseos           59 k
 make                              x86_64    1:4.2.1-10.el8                        baseos          498 k
 sysstat                           x86_64    11.7.3-5.el8                          appstream       425 k

Resumen de la transacción
=========================================================================================================
Instalar  12 Paquetes

Tamaño total: 11 M
Tamaño total de la descarga: 11 M
Tamaño instalado: 26 M
¿Está de acuerdo [s/N]?: s

```

4. Instalamos el paquete .rpm de esta forma 

```powershell
sudo rpm -Uhv oracle-database-ee-19c-1.0-1.x86_64.rpm
```

Una vez terminada la Instalación, vamos a comprobar que efectivamente se ha creado el usuario oracle con el que vamos a trabajar y que pertenece a los grupos siguientes.

```powershell
[centos@localhost oracle]$ grep 'oracle' /etc/passwd
oracle:x:54321:54321::/home/oracle:/bin/bash
[centos@localhost oracle]$ grep 'oracle' /etc/group
oinstall:x:54321:oracle
dba:x:54322:oracle
oper:x:54323:oracle
backupdba:x:54324:oracle
dgdba:x:54325:oracle
kmdba:x:54326:oracle
racdba:x:54330:oracle



[root@localhost ~]# su - oracle
[oracle@localhost ~]$ groups
oinstall dba oper backupdba dgdba kmdba racdba

```

Cambiamos la contraseña de oracle 

```sh
passwd oracle
```

En principio vamos a ejecutar un script que viene por defecto al instalar oracle que crea una base de datos de prueba, lo hacemos de la siguiente forma.


> Este proceso se demora unos minutos, hay que ser paciente ;)

```powershell
[root@localhost ~]# /etc/init.d/oracledb_ORCLCDB-19c configure
Configuring Oracle Database ORCLCDB.
Preparar para funcionamiento de base de datos
8% finalizado
Copiando archivos de base de datos
31% finalizado
Creando e iniciando instancia Oracle
32% finalizado
36% finalizado
40% finalizado
43% finalizado
46% finalizado
Terminando creación de base de datos
51% finalizado
54% finalizado
Creando Bases de Datos de Conexión
58% finalizado
77% finalizado
Ejecutando acciones posteriores a la configuración
100% finalizado
Creación de la base de datos terminada. Consulte los archivos log de /opt/oracle/cfgtoollogs/dbca/ORCLCDB
 para obtener más información.
Información de Base de Datos:
Nombre de la Base de Datos Global:ORCLCDB
Identificador del Sistema (SID):ORCLCDB
Para obtener información detallada, consulte el archivo log "/opt/oracle/cfgtoollogs/dbca/ORCLCDB/ORCLCDB.log".

Database configuration completed successfully. The passwords were auto generated, you must change them by connecting to the database using 'sqlplus / as sysdba' as the oracle user.

```

Para usar el intérprete de comandos mysqlplus necesitaremos tener configuradas las variables de entorno pertinentes para que su ejecución sea más fácil y rápida. Para ello modificamos el fichero de configuración `.bash_profile` desde el usuario 'oracle'.

```powershell
[oracle@localhost ~]$ nano .bash_profile 

# Añadimos la siguiente información

umask 022
export ORACLE_SID=ORCLCDB
export ORACLE_BASE=/opt/oracle/oradata
export ORACLE_HOME=/opt/oracle/product/19c/dbhome_1
export PATH=$PATH:$ORACLE_HOME/bin

```
La activamos 

```powershell
[oracle@localhost ~]$ source .bash_profile 
```

Ahora sí podemos acceder al intérprete 

```powershell
[oracle@localhost ~]$ sqlplus / as sysdba

SQL*Plus: Release 19.0.0.0.0 - Production on Thu Apr 1 18:36:20 2021
Version 19.3.0.0.0

Copyright (c) 1982, 2019, Oracle.  All rights reserved.


Conectado a:
Oracle Database 19c Enterprise Edition Release 19.0.0.0.0 - Production
Version 19.3.0.0.0

SQL> 

```

### Crear usuario con contraseña 

Se debe saber que desde la versión de Oracle 12c, hay un modo de instalación en el que se crea un **CDB** (contenedor) y varias **PDB** (Bases de datos conectables). Para crear un usuario en el contenedor tiene que tener la estructura *'c##xxxxx',* estos usuarios no se suelen crear para tratar con la aplicación que vamos a desarrollar, son para gestionar el contenedor como tal, entre otras cosas.

_____________________________________

Para crear una **base de datos conectable** podemos seguir los siguientes pasos:


* Primero consultamos de esta forma el path de la base de datos conectable que tenemos.

```sh
SQL> select FILE_NAME from dba_data_files;

FILE_NAME
--------------------------------------------------------------------------------
/opt/oracle/oradata/ORCLCDB/system01.dbf
/opt/oracle/oradata/ORCLCDB/sysaux01.dbf
/opt/oracle/oradata/ORCLCDB/undotbs01.dbf
/opt/oracle/oradata/ORCLCDB/users01.dbf

```

* Ahora creamos con el siguiente comando una base de datos conectable de forma que le indicamos la ruta donde vamos a crearla/convertirla.


```sh
SQL> CREATE PLUGGABLE DATABASE academia ADMIN USER oracle IDENTIFIED BY oracle FILE_NAME_CONVERT=('/opt/oracle/oradata/ORCLCDB/','/opt/oracle/oradata/academia/');

Base de datos de conexion creada.
```

Una vez creada vamos conectarnos a ella de la siguiente forma, alterando la sesión entrando como administrador.

```sh
[oracle@localhost ~]$ sqlplus / as sysdba

SQL*Plus: Release 19.0.0.0.0 - Production on Thu Apr 1 19:30:28 2021
Version 19.3.0.0.0

Copyright (c) 1982, 2019, Oracle.  All rights reserved.


Conectado a:
Oracle Database 19c Enterprise Edition Release 19.0.0.0.0 - Production
Version 19.3.0.0.0

SQL> show con_name;

CON_NAME
------------------------------
CDB$ROOT
SQL> ALTER SESSION SET CONTAINER=academia
  2  ;

Sesion modificada.

SQL> show con_name;

CON_NAME
------------------------------
ACADEMIA
SQL> select * from cat;
select * from cat
              *
ERROR en linea 1:
ORA-01219: base de datos o base de datos de conexion no abierta: solo se
permiten consultas en tablas o vistas fijas

```

Como podemos ver no tenemos los permisos necesarios para crear tablas o hacer consultas. Pero en esta entrada no vamos hablar de ello.

__________________________

Ahora si vamos a crear el usuario 'celia' con la contraseña 'celia'. Con la estructura antes mencionada de forma que será un usuario que podamos usar de forma general. También le vamos a dar los privilegios necesarios.

```sh
SQL> CREATE USER c##celia IDENTIFIED BY celia;

Usuario creado.

SQL> GRANT ALL PRIVILEGES TO c##celia;

Concesion terminada correctamente.
```

Nos desconectamos y conectamos con nuestro usuario nuevo 

```sh
SQL> connect c##celia      
Introduzca la contrase?a: 
Conectado.

```
Creamos unas tablas de prueba 

```sql
CREATE TABLE alumnos (dni VARCHAR2(4),nombre VARCHAR2(10), CONSTRAINT pk_alumnos PRIMARY KEY (dni));

INSERT INTO alumnos (dni, nombre) VALUES('1111','Carlos');
INSERT INTO alumnos (dni, nombre) VALUES('2222','Celia');
INSERT INTO alumnos (dni, nombre) VALUES('3333','Lucía');


CREATE TABLE cursos (codigocurso VARCHAR2(2),nombrecurso VARCHAR2(5), CONSTRAINT pk_cursos PRIMARY KEY (codigocurso));

INSERT INTO cursos (codigocurso, nombrecurso) VALUES('11','1');
INSERT INTO cursos (codigocurso, nombrecurso) VALUES('22','2');
INSERT INTO cursos (codigocurso, nombrecurso) VALUES('33','3');

CREATE TABLE matriculas (codigo VARCHAR2(10),dni VARCHAR2(4), codigocurso VARCHAR2(2), CONSTRAINT pk_mat PRIMARY KEY (codigo), CONSTRAINT fk_mat FOREIGN KEY (dni) REFERENCES alumnos (dni), CONSTRAINT fk_matcurso FOREIGN KEY (codigocurso) REFERENCES cursos (codigocurso));

INSERT INTO  matriculas (codigo, dni, codigocurso) VALUES('1234','1111','11');
INSERT INTO  matriculas (codigo, dni, codigocurso) VALUES('167','2222','22');
INSERT INTO  matriculas (codigo, dni, codigocurso) VALUES('891','3333','33');
```

Comprobamos que se han creado 

```sh
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


SQL> select * from alumnos;

DNI		NOMBRE
--------------- ----------
1111		Carlos
2222		Celia
3333		Luc??a

```
