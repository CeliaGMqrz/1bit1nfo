---
title: "Interconexión de Servidores de Bases de Datos."
date: 2021-04-06T08:53:45+02:00
Description: "Enlaces entre distintos servidores de bases de datos."
Tags: []
Categories: []
DisableComments: false
---

## Descripción de la tarea 

Las interconexiones de servidores de bases de datos son operaciones que pueden ser muy útiles en diferentes contextos. Básicamente, se trata de acceder a datos que no están almacenados en nuestra base de datos, pudiendo combinarlos con los que ya tenemos.

En esta práctica veremos varias formas de crear un enlace entre distintos servidores de bases de datos.

Se pide:

    * Realizar un enlace entre dos servidores de bases de datos ORACLE, explicando la configuración necesaria en ambos extremos y demostrando su funcionamiento.
      
    *  Realizar un enlace entre dos servidores de bases de datos Postgres, explicando la configuración necesaria en ambos extremos y demostrando su funcionamiento.
      
    *  Realizar un enlace entre un servidor ORACLE y otro Postgres o MySQL empleando Heterogeneus Services, explicando la configuración necesaria en ambos extremos y demostrando su funcionamiento.



## Enlace entre bases de datos ORACLE.

## Enlace entre bases de datos Postgres.

### Entorno de trabajo 

Vamos a tener 2 máquinas virtuales con vagrant y virtualbox.

```sh
# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure("2") do |config|

  config.vm.define :nodo1 do |nodo1|
    nodo1.vm.box = "debian/buster64"
    nodo1.vm.hostname = "postgres1"
    nodo1.vm.network :public_network, :bridge=>"br0"
    nodo1.vm.network "private_network", ip: "10.0.0.2",
      virtualbox__intnet: "local",
      auto_config: false
  end
  config.vm.define :nodo2 do |nodo2|
    nodo2.vm.box = "debian/buster64"
    nodo2.vm.hostname = "postgres2"
    nodo2.vm.network :public_network, :bridge=>"br0"
    nodo2.vm.network "private_network",
      virtualbox__intnet: "local", ip: "10.0.0.3",
      auto_config: false
  end
end
```

## Instalación de postgresql 

* Añadimos la clave y el repositorio.

```sh
sudo apt install -y vim wget
wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | sudo apt-key add -
```
```sh
RELEASE=$(lsb_release -cs)
echo "deb http://apt.postgresql.org/pub/repos/apt/ ${RELEASE}"-pgdg main | sudo tee  /etc/apt/sources.list.d/pgdg.list
```

* Actualizamos e instalamos el paquete de postgresql-11

```sh
sudo apt update
sudo apt -y install postgresql-11
```
* Comprobamos que está funcionando.

```sh
vagrant@postgres1:~$ systemctl status postgresql
● postgresql.service - PostgreSQL RDBMS
   Loaded: loaded (/lib/systemd/system/postgresql.service; enabled; vendor preset: enabled)
   Active: active (exited) since Tue 2021-04-06 07:29:19 GMT; 7s ago
 Main PID: 3172 (code=exited, status=0/SUCCESS)
    Tasks: 0 (limit: 544)
   Memory: 0B
   CGroup: /system.slice/postgresql.service

```
*  Le cambiamos la contraseña al usuario postgres

```sh
passwd postgres
```

* Vemos que está escuchando en el puerto 5432

```sh
vagrant@postgres1:~$ ss -tunelp | grep 5432
tcp     LISTEN   0        128            127.0.0.1:5432          0.0.0.0:*       uid:106 ino:22460 sk:4 <->                                                     
tcp     LISTEN   0        128                [::1]:5432             [::]:*       uid:106 ino:22459 sk:6 v6only:1 <->    
```

* Creamos el usuario en mi caso 'vagrant' y la base de datos 'vagrant'

```sh
vagrant@postgres1:~$ sudo -u postgres createuser --interactive vagrant
Shall the new role be a superuser? (y/n) y
vagrant@postgres1:~$ createdb debian

vagrant@postgres1:~$ createdb vagrant

vagrant@postgres1:~$ psql
psql (11.11 (Debian 11.11-0+deb10u1))
Type "help" for help.

vagrant=# 

```

* Introducimos datos de prueba 

```sh
create table depart(
dept_no integer,
dnombre varchar(20),
loc varchar(20),
primary key (dept_no)
);

insert into depart
values ('10','CONTABILIDAD','SEVILLA');
insert into depart
values ('20','INVESTIGACION','MADRID');
insert into depart
values ('30','VENTAS','BARCELONA');
insert into depart
values ('40','PRODUCCION','BILBAO');


create table emple(
emp_no integer,
apellidos varchar(20),
oficio varchar(20),
dir integer,
fecha_alt date,
salario integer,
comision integer,
dept_no integer,
primary key (emp_no));
foreign key (dept_no) references depart (dept_no)
);

insert into emple (emp_no, apellidos, oficio, dir, fecha_alt, salario, dept_no)
values ('7369','SANCHEZ','EMPLEADO','7902','1980-12-12','104000','20');
insert into emple
values ('7499','ARROYO','VENDEDOR','7698','1980-12-12','208000','39000','30');
insert into emple
values ('7521','SALA','VENDEDOR','7698','1980-12-12','162500','162500','30');
insert into emple (emp_no, apellidos, oficio, dir, fecha_alt, salario, dept_no)
values ('7566','JIMENEZ','DIRECTOR','7839','1980-12-12','386750','20');
insert into emple
values ('7654','MARTIN','VENDEDOR','7698','1980-12-12','162500','182000','30');
insert into emple(emp_no, apellidos, oficio, dir, fecha_alt, salario, dept_no)
values ('7698','NEGRO','DIRECTOR','7839','1980-12-12','370500','30');
insert into emple(emp_no, apellidos, oficio, dir, fecha_alt, salario, dept_no)
values ('7788','GIL','ANALISTA','7566','1980-12-12','390000','20');
insert into emple(emp_no, apellidos, oficio, fecha_alt, salario, dept_no)
values ('7839','REY','PRESIDENTE','1980-12-12','650000','10');
insert into emple
values ('7844','TOVAR','VENDEDOR','7698','1980-12-12','195000','0','30');
insert into emple(emp_no, apellidos, oficio, dir, fecha_alt, salario, dept_no)
values ('7876','ALONSO','EMPLEADO','7788','1980-12-12','143000','20');
insert into emple(emp_no, apellidos, oficio, dir, fecha_alt, salario, dept_no)
values ('7900','JIMENO','EMPLEADO','7698','1980-12-12','1235000','30');
insert into emple(emp_no, apellidos, oficio, dir, fecha_alt, salario, dept_no)
values ('7902','FERNANDEZ','ANALISTA','7566','1980-12-12','390000','20');
insert into emple(emp_no, apellidos, oficio, dir, fecha_alt, salario, dept_no)
values ('7934','MUÑOZ','EMPLEADO','7782','1980-12-12','169000','10');


```

* Miramos que se han creado las tablas con los registros.


```sh
vagrant=# \d
         List of relations
 Schema |  Name  | Type  |  Owner  
--------+--------+-------+---------
 public | depart | table | vagrant
 public | emple  | table | vagrant
(2 rows)


vagrant=# select * from depart;
 dept_no |    dnombre    |    loc    
---------+---------------+-----------
      10 | CONTABILIDAD  | SEVILLA
      20 | INVESTIGACION | MADRID
      30 | VENTAS        | BARCELONA
      40 | PRODUCCION    | BILBAO
(4 rows)

vagrant=# select * from emple;
 emp_no | apellidos |   oficio   | dir  | fecha_alt  | salario | comision | dept_no 
--------+-----------+------------+------+------------+---------+----------+---------
   7566 | JIMENEZ   | DIRECTOR   | 7839 | 1981-02-04 |  386750 |          |      20
   7698 | NEGRO     | DIRECTOR   | 7839 | 1981-01-05 |  370500 |          |      30
   7788 | GIL       | ANALISTA   | 7566 | 1981-09-11 |  390000 |          |      20
   7844 | TOVAR     | VENDEDOR   | 7698 | 1981-08-09 |  195000 |        0 |      30
   7900 | JIMENO    | EMPLEADO   | 7698 | 1981-03-12 | 1235000 |          |      30
   7902 | FERNANDEZ | ANALISTA   | 7566 | 1981-03-12 |  390000 |          |      20
   7369 | SANCHEZ   | EMPLEADO   | 7902 | 1980-12-12 |  104000 |          |      20
   7499 | ARROYO    | VENDEDOR   | 7698 | 1980-12-12 |  208000 |    39000 |      30
   7521 | SALA      | VENDEDOR   | 7698 | 1980-12-12 |  162500 |   162500 |      30
   7654 | MARTIN    | VENDEDOR   | 7698 | 1980-12-12 |  162500 |   182000 |      30
   7839 | REY       | PRESIDENTE |      | 1980-12-12 |  650000 |          |      10
   7876 | ALONSO    | EMPLEADO   | 7788 | 1980-12-12 |  143000 |          |      20
   7934 | MUÑOZ     | EMPLEADO   | 7782 | 1980-12-12 |  169000 |          |      10
(13 rows)

```


prueba1=> select * from dblink('dbname=prueba2 host=172.22.6.141 user=celia2 password=celia2', 'select * from emple');









## Enlace entre bases de datos ORACLE y Postgresql.


