+++
author = "Celia García Márquez"
title = "Interconexión de Servidores de Bases de Datos"
date = "2021-04-20"
description = "Enlaces entre distintos servidores de bases de datos"
tags = [
    "interconexiones bbdd",
]
thumbnail= "images/interconexiones/banner.png"
+++


## Descripción de la tarea 

Las **interconexiones de servidores de bases de datos** son operaciones que pueden ser muy útiles en diferentes contextos. Básicamente, se trata de acceder a datos que no están almacenados en nuestra base de datos, pudiendo combinarlos con los que ya tenemos.

En esta práctica veremos varias formas de crear un enlace entre distintos servidores de bases de datos.

Se pide:

* Realizar un enlace entre dos servidores de bases de datos **ORACLE**, explicando la configuración necesaria en ambos extremos y demostrando su funcionamiento.
   
* Realizar un enlace entre dos servidores de bases de datos **Postgres**, explicando la configuración necesaria en ambos extremos y demostrando su funcionamiento.
   
* Realizar un enlace entre un servidor **ORACLE** y otro **Postgres** o MySQL empleando Heterogeneus Services, explicando la configuración necesaria en ambos extremos y demostrando su funcionamiento.


# Enlace entre bases de datos PostgreSQL - PostgreSQL.

Primero tenemos que crear el entorno de trabajo, en este caso he usado dos máquinas virtuales con Debian Buster, sobre las que está instalado postgresql. Para ver el entorno de trabajo vaya este post [Instalación de postgresql sobre Debian Buster](https://www.celiagm.es/post/postgresql_debian/)

El **objetivo** de este post se trata de lo siguiente: 

Teniendo en cuenta el entorno de trabajo ya creado, los datos de prueba para poblar la base de datos serán los mismos, pero introduciremos una tabla en un servidor y la otra tabla en otro servidor de manera que vamos a **construir un enlace** entre ambos. Así cuando hagamos una consulta desde un servidor haciendo referencia al otro podamos obtener información conjunta de los dos servidores.

### Permitir conexiones remotas 

Vamos a permitir conexiones remotas en ambos servidores, seguimos los siguientes pasos para las dos máquinas.

Editamos el fichero de configuracion de postgresql.

> Según la versión de postgresql que hemos instalado el directorio dentro de postgres será diferente.

Buscamos las siguientes directivas y las cambiamos así:

`/etc/postgresql/11/main/postgresql.conf `

```sh
# Esta directiva es para que escuche no solo desde local sino que puedan acceder desde todas las direcciones.
listen_addresses = '*'
```

Editamos también el siguiente fichero para indicar también que permita la conexión remota desde cualquier direción.

`nano /etc/postgresql/11/main/pg_hba.conf `

```sh
host all all 0.0.0.0/0 md5
```

Ahora reiniciamos el servicio 

```sh
sudo systecmtl restart postgresql
```

### Crear la base de datos y usuarios de prueba.

Si has poblado la base de datos con el post de la instalación anterior, puedes borrar en la máquina una de las tablas, la de 'emple' por ejemplo. 

```sh
drop table emple cascade
```

Ahora podemos continuar con la tarea.

### Máquina 1

Accedemos a postgresql como usuario 'postgres' y creamos el usuario, la base de datos y le damos permisos al usuario sobre esa misma base de datos:

```sh
postgres=# create user celia1 with password 'celia1';
CREATE ROLE
postgres=# create database prueba1;
CREATE DATABASE
postgres=# grant all privileges on database prueba1 to celia1;
GRANT
postgres=# exit

```

Ahora salimos y entramos como el usuario creado 

```sh
psql -h localhost -U celia1 -W -d prueba1
```
Creamos la tabla departamento 

```sh
create table departamento(
dept_no integer,
dnombre varchar(20),
loc varchar(20),
primary key (dept_no)
);
```
* Le añadimos los registros 

```sh
insert into departamento
values ('10','CONTABILIDAD','SEVILLA');
insert into departamento
values ('20','INVESTIGACION','MADRID');
insert into departamento
values ('30','VENTAS','BARCELONA');
insert into departamento
values ('40','PRODUCCION','BILBAO');
```


## Máquina 2

```sh
postgres=# create user celia2 with password 'celia2';
CREATE ROLE
postgres=# create database prueba2;
CREATE DATABASE
postgres=# grant all privileges on database prueba2 to celia2;
GRANT
postgres=# exit
postgres@postgres2:~$ 
```

* Creamos la tabla empleados. No le ponemos la opción de clave extanjera ya que ahora mismo no existe la tabla departamento en esta base de datos.

```sh
create table empleado(
emp_no integer,
apellidos varchar(20),
oficio varchar(20),
dir integer,
fecha_alt date,
salario integer,
comision integer,
dept_no integer,
primary key (emp_no)
);
```

* Le añadimos los registros 

```sh
insert into empleado (emp_no, apellidos, oficio, dir, fecha_alt, salario, dept_no)
values ('7369','SANCHEZ','EMPLEADO','7902','1980-12-12','104000','20');
insert into empleado
values ('7499','ARROYO','VENDEDOR','7698','1980-12-12','208000','39000','30');
insert into empleado
values ('7521','SALA','VENDEDOR','7698','1980-12-12','162500','162500','30');
insert into empleado (emp_no, apellidos, oficio, dir, fecha_alt, salario, dept_no)
values ('7566','JIMENEZ','DIRECTOR','7839','1980-12-12','386750','20');
insert into empleado
values ('7654','MARTIN','VENDEDOR','7698','1980-12-12','162500','182000','30');
insert into empleado (emp_no, apellidos, oficio, dir, fecha_alt, salario, dept_no)
values ('7698','NEGRO','DIRECTOR','7839','1980-12-12','370500','30');
insert into empleado (emp_no, apellidos, oficio, dir, fecha_alt, salario, dept_no)
values ('7788','GIL','ANALISTA','7566','1980-12-12','390000','20');
insert into empleado (emp_no, apellidos, oficio, fecha_alt, salario, dept_no)
values ('7839','REY','PRESIDENTE','1980-12-12','650000','10');
insert into empleado
values ('7844','TOVAR','VENDEDOR','7698','1980-12-12','195000','0','30');
insert into empleado (emp_no, apellidos, oficio, dir, fecha_alt, salario, dept_no)
values ('7876','ALONSO','EMPLEADO','7788','1980-12-12','143000','20');
insert into empleado (emp_no, apellidos, oficio, dir, fecha_alt, salario, dept_no)
values ('7900','JIMENO','EMPLEADO','7698','1980-12-12','1235000','30');
insert into empleado (emp_no, apellidos, oficio, dir, fecha_alt, salario, dept_no)
values ('7902','FERNANDEZ','ANALISTA','7566','1980-12-12','390000','20');
insert into empleado (emp_no, apellidos, oficio, dir, fecha_alt, salario, dept_no)
values ('7934','MUÑOZ','EMPLEADO','7782','1980-12-12','169000','10');
```

### Crear el enlace maquina1-maquina2 

Creamos un enlace en la máquina1, para ello nos conectamos como 'postgres' 

```sh
postgres@postgres1:~$ psql -d prueba1
psql (11.11 (Debian 11.11-0+deb10u1))
Type "help" for help.

prueba1=# create extension dblink;
CREATE EXTENSION
prueba1=# 

```

Nos conectamos como el usuario 'celia1' a la base de datos.

```sh
psql -h localhost -U celia1 -W -d prueba1
```

Creamos el enlace de esta forma 

```sh
select * from dblink('dbname=prueba2 host=192.168.100.224 user=celia2password=celia2', 'select * from empleado') as empleados (emp_no integer, apellidosvarchar, oficio varchar, dir integer, fecha_alt date, salario integer, comisioninteger, dept_no integer);

```

Ahora comprobamos que efectivamente muestra la tabla empleado que está en el otro servidor. 

```sh
prueba1=> select * from dblink('dbname=prueba2 host=192.168.100.224 user=celia2 password=celia2', 'select * from empleado') as empleados (emp_no integer, apellidos varchar, oficio varchar, dir integer, fecha_alt date, salario integer, comision integer, dept_no integer);
 emp_no | apellidos |   oficio   | dir  | fecha_alt  | salario | comision | dept_no 
--------+-----------+------------+------+------------+---------+----------+---------
   7369 | SANCHEZ   | EMPLEADO   | 7902 | 1980-12-12 |  104000 |          |      20
   7499 | ARROYO    | VENDEDOR   | 7698 | 1980-12-12 |  208000 |    39000 |      30
   7521 | SALA      | VENDEDOR   | 7698 | 1980-12-12 |  162500 |   162500 |      30
   7566 | JIMENEZ   | DIRECTOR   | 7839 | 1980-12-12 |  386750 |          |      20
   7654 | MARTIN    | VENDEDOR   | 7698 | 1980-12-12 |  162500 |   182000 |      30
   7698 | NEGRO     | DIRECTOR   | 7839 | 1980-12-12 |  370500 |          |      30
   7788 | GIL       | ANALISTA   | 7566 | 1980-12-12 |  390000 |          |      20
   7839 | REY       | PRESIDENTE |      | 1980-12-12 |  650000 |          |      10
   7844 | TOVAR     | VENDEDOR   | 7698 | 1980-12-12 |  195000 |        0 |      30
   7876 | ALONSO    | EMPLEADO   | 7788 | 1980-12-12 |  143000 |          |      20
   7900 | JIMENO    | EMPLEADO   | 7698 | 1980-12-12 | 1235000 |          |      30
   7902 | FERNANDEZ | ANALISTA   | 7566 | 1980-12-12 |  390000 |          |      20
   7934 | MUÑOZ     | EMPLEADO   | 7782 | 1980-12-12 |  169000 |          |      10

```

### Crear el enlace maquina2-maquina1

Ejecutamos el mismo procedimiento que hemos ido haciendo en el primer enlace y comprobamos que muestra la tabla departamento del primer servidor 

```sh
postgres@postgres2:~$ psql -d prueba2
psql (11.11 (Debian 11.11-1.pgdg100+1))
Type "help" for help.

prueba2=# create extension dblink;
CREATE EXTENSION
prueba2=# quit
postgres@postgres2:~$ psql -h localhost -U celia2 -W -d prueba2
Password: 
psql (11.11 (Debian 11.11-1.pgdg100+1))
SSL connection (protocol: TLSv1.3, cipher: TLS_AES_256_GCM_SHA384, bits: 256, compression: off)
Type "help" for help.

prueba2=> select * from dblink('dbname=prueba1 host=192.168.100.225 user=celia1 password=celia1', 'select * from departamento') as departamento (dept_no integer, dnombre varchar, loc varchar);
 dept_no |    dnombre    |    loc    
---------+---------------+-----------
      10 | CONTABILIDAD  | SEVILLA
      20 | INVESTIGACION | MADRID
      30 | VENTAS        | BARCELONA
      40 | PRODUCCION    | BILBAO
(4 rows)
```

Como hemos visto se ha creado los enlaces correctamente y hemos podido hacer consultas a tablas externas.

# Enlace entre bases de datos ORACLE y Postgresql

Vamos a crear un enlace desde Oracle ubicado en un CentOS8 a Postgresql ubicado en Debian Buster.

### Configuracion Servidor Oracle (CentOS8)

Necesitaremos instalar los siguientes paquetes:

* postgresql-odbc.x86_64 (Controlador oficial de postgres)
* unixODBC (Administrador de controladores. Permite trabajar con SQL)

```sh
dnf install unixODBC-2.3.7-1.el8.i686
dnf install postgresql-odbc.x86_64 
```

Ahora vamos a la configuración.

Primero vamos a editar el fichero `/etc/odbcinst.ini`. En este fichero está la configuración para los controladores unixODBC. Es recomendable editarlo con la utilidad 'obdcinst' pero en esta ocasión lo editaremos a mano y dejaremos el siguiente contenido.

```sh
nano /etc/odbcinst.ini
```

```sh
[PostgreSQL ANSI]
Description=PostgreSQL ODBC driver (ANSI version)
Driver=psqlodbca.so
Setup=libodbcpsqlS.so
Debug=0
CommLog=1
UsageCount=1

[PostgreSQL Unicode]
Description=PostgreSQL ODBC driver (Unicode version)
Driver=psqlodbcw.so
Setup=libodbcpsqlS.so
Debug=0
CommLog=1
UsageCount=1
```

Ahora vamos a editar el fichero `/etc/odbc.ini`. El contenido de este fichero es más complicado porque según el controlador que vayamos a usar requiere entradas diferentes. En este caso introduciremos la entrada para Postgresql. 

Tendremos que indicar la dirección del servidor postgres, el usuario, la contraseña y a la base de datos donde nos vamos a conectar.

```sh
nano /etc/odbc.ini
```

```sh

[PSQLA]
Debug = 0
CommLog = 0
ReadOnly = 1
Driver = PostgreSQL ANSI
Servername = 192.168.100.67
Username = celia
Password = celia
Port = 5432
Database = prueba
Trace = 0
TraceFile = /tmp/sql.log

[PSQLU]
Debug = 0
CommLog = 0
ReadOnly = 0
Driver = PostgreSQL Unicode
Servername = 192.168.100.67
Username =  celia
Password = celia
Port = 5432
Database = prueba
Trace = 0
TraceFile = /tmp/sql.log

[Default]
Driver = /usr/lib64/liboplodbcS.so.2

```

Una vez se haya configurado podemos comprobar la sintaxis de la configuración con los siguientes comandos.

```sh
[root@bd ~]# odbcinst -q -d
[PostgreSQL ANSI]
[PostgreSQL Unicode]
[MySQL]
[FreeTDS]
[MariaDB]

[root@bd ~]# odbcinst -q -s
[PSQLA]
[PSQLU]
[Default]

```

Ahora vamos a comprobar la conexión con la base de datos de postgres de esta forma 

```sh
[root@bd ~]# isql -v PSQLU
+---------------------------------------+
| Connected!                            |
|                                       |
| sql-statement                         |
| help [tablename]                      |
| quit                                  |
|                                       |
+---------------------------------------+
SQL> select * from departamento;
+------------+---------------------+---------------------+
| dept_no    | dnombre             | loc                 |
+------------+---------------------+---------------------+
| 10         | CONTABILIDAD        | SEVILLA             |
| 20         | INVESTIGACION       | MADRID              |
| 30         | VENTAS              | BARCELONA           |
| 40         | PRODUCCION          | BILBAO              |
+------------+---------------------+---------------------+
SQLRowCount returns 4
4 rows fetched
SQL> quit
[root@bd ~]# isql -v PSQLA
+---------------------------------------+
| Connected!                            |
|                                       |
| sql-statement                         |
| help [tablename]                      |
| quit                                  |
|                                       |
+---------------------------------------+
SQL> select * from departamento;
+------------+---------------------+---------------------+
| dept_no    | dnombre             | loc                 |
+------------+---------------------+---------------------+
| 10         | CONTABILIDAD        | SEVILLA             |
| 20         | INVESTIGACION       | MADRID              |
| 30         | VENTAS              | BARCELONA           |
| 40         | PRODUCCION          | BILBAO              |
+------------+---------------------+---------------------+
SQLRowCount returns 4
4 rows fetched

```

Como podemos comprobar ya podemos visualizar el contenido de la tabla departamento que tenemos en postgres.

Si todo ha ido bien hasta este punto, vamos a crear el fichero `initPSQLU.ora`. Este fichero nos permitirá crear el enlace con postgresql.

```sh
nano /opt/oracle/product/19c/dbhome_1/hs/admin/initPSQLU.ora
```

```sh
HS_FDS_CONNECT_INFO = PSQLU
HS_FDS_TRACE_LEVEL = Debug
HS_FDS_SHAREABLE_NAME = /usr/lib64/psqlodbcw.so
HS_LANGUAGE = AMERICAN_AMERICA.WE8ISO8859P1
set ODBCINI=/etc/odbc.ini
```

Ahora vamos a editar los ficheros `listener.ora` y `tsnames.ora`

```sh
nano /opt/oracle/product/19c/dbhome_1/network/admin/listener.ora 
```

```sh
# listener.ora Network Configuration File: /opt/oracle/product/19c/dbhome_1/network/admin/listener.ora
# Generated by Oracle configuration tools.

LISTENER =
  (DESCRIPTION_LIST =
    (DESCRIPTION =
      (ADDRESS = (PROTOCOL = TCP)(HOST = bd.oracle.celia.es)(PORT = 1521))
      (ADDRESS = (PROTOCOL = IPC)(KEY = EXTPROC1521))
    )
  )

SID_LIST_LISTENER=
 (SID_LIST=
 (SID_DESC=
 (SID_NAME=PSQLU)
 (ORACLE_HOME=/opt/oracle/product/19c/dbhome_1)
 (PROGRAM=dg4odbc)
 )
 )
```

```sh
nano /opt/oracle/product/19c/dbhome_1/network/admin/tnsnames.ora 
```

```sh

# tnsnames.ora Network Configuration File: /opt/oracle/product/19c/dbhome_1/network/admin/tnsnames.ora
# Generated by Oracle configuration tools.

ORCLCDB =
  (DESCRIPTION =
    (ADDRESS = (PROTOCOL = TCP)(HOST = localhost)(PORT = 1521))
    (CONNECT_DATA =
      (SERVER = DEDICATED)
      (SERVICE_NAME = ORCLCDB)
    )
  )

LISTENER_ORCLCDB =
  (ADDRESS = (PROTOCOL = TCP)(HOST = localhost)(PORT = 1521))


PSQLU =
 (DESCRIPTION=
 (ADDRESS=(PROTOCOL=tcp)(HOST=localhost)(PORT=1521))
 (CONNECT_DATA=(SID=PSQLU))
 (HS=OK)
 )


```

Una vez configurado todo, desde el ususario oracle paramos el listener y lo volvemos a iniciar.

```sh
lsnrctl stop
lsnrctl start
```

```sh
[oracle@bd ~]$ lsnrctl stop

LSNRCTL for Linux: Version 19.0.0.0.0 - Production on 20-APR-2021 13:59:43

Copyright (c) 1991, 2019, Oracle.  All rights reserved.

Connecting to (DESCRIPTION=(ADDRESS=(PROTOCOL=TCP)(HOST=bd.oracle.celia.es)(PORT=1521)))
The command completed successfully
[oracle@bd ~]$ lsnrctl start

LSNRCTL for Linux: Version 19.0.0.0.0 - Production on 20-APR-2021 13:59:48

Copyright (c) 1991, 2019, Oracle.  All rights reserved.

Starting /opt/oracle/product/19c/dbhome_1/bin/tnslsnr: please wait...

TNSLSNR for Linux: Version 19.0.0.0.0 - Production
System parameter file is /opt/oracle/product/19c/dbhome_1/network/admin/listener.ora
Log messages written to /opt/oracle/diag/tnslsnr/bd/listener/alert/log.xml
Listening on: (DESCRIPTION=(ADDRESS=(PROTOCOL=tcp)(HOST=bd.oracle.celia.es)(PORT=1521)))
Listening on: (DESCRIPTION=(ADDRESS=(PROTOCOL=ipc)(KEY=EXTPROC1521)))

Connecting to (DESCRIPTION=(ADDRESS=(PROTOCOL=TCP)(HOST=bd.oracle.celia.es)(PORT=1521)))
STATUS of the LISTENER
------------------------
Alias                     LISTENER
Version                   TNSLSNR for Linux: Version 19.0.0.0.0 - Production
Start Date                20-APR-2021 13:59:48
Uptime                    0 days 0 hr. 0 min. 0 sec
Trace Level               off
Security                  ON: Local OS Authentication
SNMP                      OFF
Listener Parameter File   /opt/oracle/product/19c/dbhome_1/network/admin/listener.ora
Listener Log File         /opt/oracle/diag/tnslsnr/bd/listener/alert/log.xml
Listening Endpoints Summary...
  (DESCRIPTION=(ADDRESS=(PROTOCOL=tcp)(HOST=bd.oracle.celia.es)(PORT=1521)))
  (DESCRIPTION=(ADDRESS=(PROTOCOL=ipc)(KEY=EXTPROC1521)))
Services Summary...
Service "PSQLU" has 1 instance(s).
  Instance "PSQLU", status UNKNOWN, has 1 handler(s) for this service...
The command completed successfully
```

Comprobamos que está escuchando en el puerto indicado.

```sh
[oracle@bd ~]$ netstat -tlpn
(Not all processes could be identified, non-owned process info
 will not be shown, you would have to be root to see it all.)
Active Internet connections (only servers)
Proto Recv-Q Send-Q Local Address           Foreign Address         State       PID/Program name    
tcp        0      0 0.0.0.0:111             0.0.0.0:*               LISTEN      -                   
tcp        0      0 192.168.122.1:53        0.0.0.0:*               LISTEN      -                   
tcp        0      0 0.0.0.0:22              0.0.0.0:*               LISTEN      -                   
tcp        0      0 127.0.0.1:631           0.0.0.0:*               LISTEN      -                   
tcp6       0      0 :::29443                :::*                    LISTEN      2950/ora_d000_ORCLC 
tcp6       0      0 :::111                  :::*                    LISTEN      -                   
tcp6       0      0 :::1521                 :::*                    LISTEN      5731/tnslsnr        
tcp6       0      0 :::22                   :::*                    LISTEN      -                   
tcp6       0      0 ::1:631                 :::*                    LISTEN      -         
```

### Configuracion Servidor postgresql

Los siguientes ficheros tienen que tener el siguiente contenido, como hemos hecho en el primer apartado de enlace *postgresql-postgresql*
```sh
nano /etc/postgresql/11/main/postgresql.conf 

. . . 
listen_addresses = '*'
. . . 

nano /etc/postgresql/11/main/pg_hba.conf 

. . . 
host all all 0.0.0.0/0 md5
. . . 
```

Reiniciamos el servicio de postgresql y creamos el enlace con oracle.

```sh
systemctl restart postgresql
```

### Crear el enlace

Desde el servidor de **oracle** creamos el link para postgresql de esta forma 

```sh
sqlplus / as sysdba
```

```sh
SQL> create public database link psql1 connect to "celia" identified by "celia" using 'PSQLU';

Enlace con la base de datos creado.

```

Una vez creado el enlace vamos a realizar una consulta a postgresql

```sh
SQL> connect c##celia/celia
Conectado.

SQL> select "dnombre" from "departamento"@psql1;                     

dnombre
--------------------------------------------------------------------------------
CONTABILIDAD
INVESTIGACION
VENTAS
PRODUCCION

SQL> select "dnombre" , "dept_no" from "departamento"@psql1;     

dnombre
--------------------------------------------------------------------------------
   dept_no
----------
CONTABILIDAD
	10

INVESTIGACION
	20

VENTAS
	30


dnombre
--------------------------------------------------------------------------------
   dept_no
----------
PRODUCCION
	40

```

Ademas también podemos hacer *joins*. Para ello vamos a crear la tabla empleados en la base de datos oracle y haremos una consulta de ambas tablas en diferentes gestores.

```sh
CREATE TABLE empleados (dni VARCHAR2(4),nombre VARCHAR2(10), depart VARCHAR2(3), CONSTRAINT pk_empleados PRIMARY KEY (dni));

INSERT INTO empleados (dni, nombre, depart) VALUES('1111','Carlos','40');
INSERT INTO empleados (dni, nombre, depart) VALUES('2222','Celia','40');
INSERT INTO empleados (dni, nombre, depart) VALUES('3333','Lucía','20');
```

Comprobamos que se ha creado:

```sh
SQL> select * from empleados;

DNI  NOMBRE	DEP
---- ---------- ---
1111 Carlos	40
2222 Celia	40
3333 Luc??a	20

```

### Funcionamiento del enlace oracle-postgresql

Ahora vamos hacer la siguiente consulta, que es un join de las dos tablas cada una ubicada en un gestor diferente, siendo **empleados** en la de oracle y **departamentos** en la de postgres.

La consulta consiste en sacar los nombres de los empleados y la localización a la que pertenecen según el departamento.

```sh

SQL> select a.nombre, b."loc" from empleados a, "departamento"@psql1 b where a.depart = b."dept_no";

NOMBRE
----------
loc
--------------------------------------------------------------------------------
Luc??a
MADRID

Carlos
BILBAO

Celia
BILBAO

```

# Enlace Servidor Oracle - Servidor Oracle 


### Configuración Servidor ORACLE 1

En la primera máquina con oracle vamos a configurarla de la siguiente manera editando los ficheros que expongo a continuación.

`nano /opt/oracle/product/19c/dbhome_1/network/admin/listener.ora`

```sh
# listener.ora Network Configuration File: /opt/oracle/product/19c/dbhome_1/network/admin/listener.ora
# Generated by Oracle configuration tools.

LISTENER =
  (DESCRIPTION_LIST =
    (DESCRIPTION =
      (ADDRESS = (PROTOCOL = TCP)(HOST = 0.0.0.0)(PORT = 1521))
      (ADDRESS = (PROTOCOL = IPC)(KEY = EXTPROC1521))
    )
  )

#SID_LIST_LISTENER=
# (SID_LIST=
# (SID_DESC=
# (SID_NAME=PSQLU)
# (ORACLE_HOME=/opt/oracle/product/19c/dbhome_1)
# (PROGRAM=dg4odbc)
# )
# )

```
Editamos el siguiente fichero donde ahora vamos a indicar el segundo servidor oracle, especificamos la dirección del mismo y el nombre de la base de datos (que en este caso se llama igual porque es una clonación del primer servidor.)

`nano /opt/oracle/product/19c/dbhome_1/network/admin/tnsnames.ora`

```sh
# tnsnames.ora Network Configuration File: /opt/oracle/product/19c/dbhome_1/network/admin/tnsnames.ora
# Generated by Oracle configuration tools.

ORCLCDB =
  (DESCRIPTION =
    (ADDRESS = (PROTOCOL = TCP)(HOST = localhost)(PORT = 1521))
    (CONNECT_DATA =
      (SERVER = DEDICATED)
      (SERVICE_NAME = ORCLCDB)
    )
  )

LISTENER_ORCLCDB =
  (ADDRESS = (PROTOCOL = TCP)(HOST = localhost)(PORT = 1521))


# Segundo servidor oracle
ORCL2 =
 (DESCRIPTION =
 (ADDRESS = (PROTOCOL = TCP)(HOST = 192.168.100.186)(PORT = 1521))
 (CONNECT_DATA =
 (SERVER = DEDICATED)
 (SERVICE_NAME = ORCLCDB)
 )
 )

# para postgresql
#PSQLU =
# (DESCRIPTION=
# (ADDRESS=(PROTOCOL=tcp)(HOST=localhost)(PORT=1521))
# (CONNECT_DATA=(SID=PSQLU))
# (HS=OK)
# )


```

Una vez cambiada la configuración paramos el listener y lo volvemos a iniciar.

```sh
lsnrctl stop
lsnrctl start
```

### Configuración Servidor ORACLE 2

En la segunda máquina oracle vamos a cambiar también la configuración de la siguiente forma.

`nano /opt/oracle/product/19c/dbhome_1/network/admin/listener.ora `

```sh
# listener.ora Network Configuration File: /opt/oracle/product/19c/dbhome_1/network/admin/listener.ora
# Generated by Oracle configuration tools.

LISTENER =
  (DESCRIPTION_LIST =
    (DESCRIPTION =
      (ADDRESS = (PROTOCOL = TCP)(HOST = 0.0.0.0)(PORT = 1521))
      (ADDRESS = (PROTOCOL = IPC)(KEY = EXTPROC1521))
    )
  )


```

Ahora reiniciamos el servicio como hemos hecho anteriormente 


```sh
lsnrctl stop
lsnrctl start
```

## Crear enlace desde el primer servidor de oracle 

Nos conectamos como administrador y creamos el enlace. 

```sh
[oracle@bd ~]$ sqlplus / as sysdba

SQL*Plus: Release 19.0.0.0.0 - Production on Tue Apr 20 16:15:45 2021
Version 19.3.0.0.0

Copyright (c) 1982, 2019, Oracle.  All rights reserved.


Conectado a:
Oracle Database 19c Enterprise Edition Release 19.0.0.0.0 - Production
Version 19.3.0.0.0

SQL> create database link oracle1
  2  connect to c##celia
  3  identified by celia
  4  using 'orcl2';

Enlace con la base de datos creado.

```
Primero probaremos que podemos acceder al otro servidor con el siguiente comando


```sh
[oracle@bd ~]$ sql c##celia/celia@192.168.100.186/orclcdb

SQLcl: Versión 19.1 Production en mar abr 20 16:33:32 2021

Copyright (c) 1982, 2021, Oracle. Todos los derechos reservados.

Conectado a:
Oracle Database 19c Enterprise Edition Release 19.0.0.0.0 - Production
Version 19.3.0.0.0


SQL> select * from alumnos;

DNI             NOMBRE    
--------------- ----------
1111            Carlos    
2222            Celia     
3333            Luc��a    

```
Efectivamente tenemos conexión. Ahora vamos hacer las consultas.


## Funcionamiento 


Nos logueamos como admistrador y hacemos la consulta de esta forma:

```sh
SQL> select * from cat@oracle1;

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

```

También podemos hacer joins de dos tablas en ambos servidores. 


Eliminamos las tablas matriculas y cursos y las ubicamos en el primer servidor


**Quiero saber a qué curso va cada niño con un JOIN.**

Siendo:
* tabla alumnos (servidor oracle 2)
* tablas cursos y matriculas (servidor oracle 1)

```sh
select distinct a.nombre, c.nombrecurso as curso from alumnos@oracle1 a, matriculas b, cursos c where a.dni = b.dni and b.codigocurso = c.codigocurso;
```

```sh
SQL> select distinct a.nombre, c.nombrecurso as curso from alumnos@oracle1 a, matriculas b, cursos c where a.dni = b.dni and b.codigocurso = c.codigocurso;

NOMBRE	   CURSO
---------- -----
Celia	   2
Luc??a	   3
Carlos	   1


```