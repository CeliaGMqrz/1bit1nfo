+++
author = "Celia García Márquez"
title = "Interconexión de Servidores de Bases de Datos"
date = "2021-04-07"
description = "Enlaces entre distintos servidores de bases de datos"
tags = [
    "interconexiones bbdd",
]
thumbnail= "images/interconexiones/banner.png"
+++


## Descripción de la tarea 

Las interconexiones de servidores de bases de datos son operaciones que pueden ser muy útiles en diferentes contextos. Básicamente, se trata de acceder a datos que no están almacenados en nuestra base de datos, pudiendo combinarlos con los que ya tenemos.

En esta práctica veremos varias formas de crear un enlace entre distintos servidores de bases de datos.

Se pide:

    * Realizar un enlace entre dos servidores de bases de datos ORACLE, explicando la configuración necesaria en ambos extremos y demostrando su funcionamiento.
      
    *  Realizar un enlace entre dos servidores de bases de datos Postgres, explicando la configuración necesaria en ambos extremos y demostrando su funcionamiento.
      
    *  Realizar un enlace entre un servidor ORACLE y otro Postgres o MySQL empleando Heterogeneus Services, explicando la configuración necesaria en ambos extremos y demostrando su funcionamiento.



## Enlace entre bases de datos ORACLE.

## Enlace entre bases de datos PostgreSQL - PostgreSQL.

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



prueba1=> select * from dblink('dbname=prueba2 host=172.22.6.141 user=celia2 password=celia2', 'select * from emple');



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



alter table empleado add constraint fk_depno foreign key (dept_no) references dblink('dbname=prueba1 host=192.168.100.225 user=celia1 password=celia1', 'departamento (dept_no)');



## Enlace entre bases de datos ORACLE y Postgresql.