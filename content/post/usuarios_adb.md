+++
author = "Celia García Márquez"
title = "Gestión de usuarios. Gestores Bases de datos"
date = "2021-05-16"
description = "Gestión de usuarios. BBDD"
tags = [
    "bbdd","usuarios",
]
thumbnail= "images/usuarios/banner.png"
+++

En este post veremos como gestionar los usuarios en los distintos gestores de bases de datos.

## Ejercicio 1

> **1. (ORACLE, Postgres, MySQL) Crea un usuario llamado Becario y, sin usar los roles de ORACLE, dale los siguientes privilegios**:
        ◦ Conectarse a la base de datos.
        ◦ Modificar el número de errores en la introducción de la contraseña de cualquier usuario.
        ◦ Modificar índices en cualquier esquema (este privilegio podrá pasarlo a quien quiera)
        ◦ Insertar filas en scott.emp (este privilegio podrá pasarlo a quien quiera)
        ◦ Crear objetos en cualquier tablespace.
        ◦ Gestión completa de usuarios, privilegios y roles.


### 1.1. Oracle 

**Entorno de trabajo con vagrant**

```sh
Vagrant.configure("2") do |config|
    config.vm.define "orcl3" do |orcl3|
        config.vm.provider "virtualbox" do |vb|
            vb.name = "orcl3"
            vb.memory = 2048
            vb.cpus = 1
        end
        orcl3.vm.box = "neko-neko/centos6-oracle-11g-XE"
        orcl3.vm.hostname = "orcl"
        orcl3.vm.network "public_network",
            bridge: "br0", 
            use_dhcp_assigned_default_route: true
    end
end
```

> Recordamos para cambiar el idioma podemos exportar esta variable: 
> **export NLS_LANG=AMERICAN_AMERICA.WE8MSWIN1252**

#### Conectarse a la base de datos

```sql
-- Crear el usuario becario

SQL> CREATE USER becario IDENTIFIED BY becario;

User created.

-- Conectar a la base de datos (sesion) 

SQL> GRANT CREATE SESSION TO becario;

Grant succeeded.

```

#### Modificar el número de errores en la introducción de la contraseña de cualquier usuario.

Para ello necesitamos ejecutar la opción CREATE PROFILE que sirve para crear un perfil y así disponer de los límites en los recursos de la base de datos. 

```sql
-- Creamos el perfil 
GRANT CREATE PROFILE TO becario;

-- Creamos el perfil que defina los límites en este caso hasta 3 intentos.
CREATE PROFILE limitepass LIMIT FAILED_LOGIN_ATTEMPTS 3;

-- Ahora asignamos el perfil del usuario mediante ALTER USER para que use dicho perfil.

ALTER USER becario PROFILE limitepass;
```

Podemos **comprobar** que el **límite** de intentos se cumple 

```sh
-bash-4.1$ sqlplus becario

SQL*Plus: Release 11.2.0.2.0 Production on Dom May 16 11:42:53 2021

Copyright (c) 1982, 2011, Oracle.  All rights reserved.

Enter password: 
ERROR:
ORA-01017: invalid username/password; logon denied


Enter user-name: becario
Enter password: 
ERROR:
ORA-01017: invalid username/password; logon denied


Enter user-name: becario
Enter password: 
SP2-0306: Invalid option.
Usage: CONN[ECT] [{logon|/|proxy} [AS {SYSDBA|SYSOPER|SYSASM}] [edition=value]]
where <logon> ::= <username>[/<password>][@<connect_identifier>]
      <proxy> ::= <proxyuser>[<username>][/<password>][@<connect_identifier>]
SP2-0157: unable to CONNECT to ORACLE after 3 attempts, exiting SQL*Plus

```
#### Modificar índices en cualquier esquema (este privilegio podrá pasarlo a quien quiera)

De esta forma podrá modificar los índices y pasarle mismo privilegio a otro usuario. Esto no es recomendable ya que pone a prueba la seguridad de la base de datos, lo lógico seria especificar una tabla o esquema en particular, pero como indica 'cualquier esquema' he suspuesto que puede ser todos. Aunque recalco que lo mejor es especificar el esquema que necesitemos.

```sql
SQL> GRANT ALTER ANY INDEX TO becario WITH ADMIN OPTION;

Grant succeeded.

```

Creamos otro usuario llamado 'celia' y nos conectamos como becario. Después le otorgamos ese mismo permiso al usuario 'celia'. Ahora el usuario 'celia' puede modificar cualquier índice.

```sql
SQL> connect becario/becario
Connected.
SQL> GRANT ALTER ANY INDEX TO celia;

Grant succeeded.
```

#### Insertar filas en scott.emp (este privilegio podrá pasarlo a quien quiera)

Para ello necesitaremos tener el usuario scott y su base de datos.

```sql
SQL> GRANT INSERT ON SCOTT.EMP TO becario with GRANT OPTION;

Grant succeeded.
```

Podemos probar que puede pasar este privilegio al usuario 'celia'

Nos conectamos como becario :

```sql
SQL> connect becario/becario;
Connected.
SQL> GRANT INSERT ON SCOTT.EMP TO celia;

Grant succeeded.


```

#### Crear objetos en cualquier tablespace.

Le otorgamos privilegios a becario para crear objetos en cualquier tablespace 

```sql
SQL> GRANT UNLIMITED TABLESPACE TO becario;

Grant succeeded.

SQL> 

```

#### Gestión completa de usuarios, privilegios y roles


* Gestión completa de usuarios 

```sql
#Usuarios
GRANT CREATE USER TO becario;
GRANT BECOME USER TO becario;
GRANT ALTER USER TO becario;
GRANT DROP USER TO becario;
```

* Gestión completa de privilegios

```sql
#Privilegios
GRANT ALL PRIVILEGES TO becario;
```

* Gestión completa de roles

```sql
#Roles

GRANT CREATE ROLE TO becario;
GRANT DROP ANY ROLE TO becario;
GRANT GRANT ANY ROLE TO becario;
GRANT ALTER ANY ROLE TO becario;
```

**Fuentes:**

Perfiles Oracle:
https://docs.oracle.com/cd/B19306_01/server.102/b14200/statements_6010.htm

Privilegos Oracle:
https://www.oracletutorial.com/oracle-administration/oracle-grant-all-privileges-to-a-user/


### 1.2. Postgresql 

**Entorno de trabajo con vagrant**

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

#### Conectarse a la base de datos

```sql
-- Creamos el usuario 

postgres=# CREATE USER becario WITH PASSWORD 'becario';
CREATE ROLE

-- Creamos una base de datos de prueba 

postgres=# CREATE DATABASE dbprueba;
CREATE DATABASE
postgres=# GRANT CONNECT ON database dbprueba TO becario;
GRANT

-- Le damos el privilegio de conectarse a la base de datos 

postgres=# ALTER ROLE becario WITH LOGIN;
ALTER ROLE
```

Comprobamos que becario puede conectarse a la base de datos que hemos creado 

```sql 
postgres@postgres1:~$ psql -U becario -d dbprueba -h localhost -W
Password: 
psql (11.11 (Debian 11.11-0+deb10u1))
SSL connection (protocol: TLSv1.3, cipher: TLS_AES_256_GCM_SHA384, bits: 256, compression: off)
Type "help" for help.

dbprueba=> 

```

#### Modificar el número de errores en la introducción de la contraseña de cualquier usuario.

Esta opción como tal **NO** la tenemos en postgresql pero sí podemos hacer los siguiente:

* Modificar el usuario para que la conexión simultánea sea menor a 3

```sql
postgres=# ALTER USER becario WITH CONNECTION LIMIT 3;
ALTER ROLE
```
* Crear roles con peridodos de validez de la contraseña 

```sql
CREATE ROLE limit_time WITH
LOGIN
PASSWORD 'becario'
VALID UNTIL '2021-12-05';
```

* O crear también roles con límite de conexión simultánea

```sql
CREATE ROLE limit_conexion
LOGIN
PASSWORD 'becario'
CONNECTION LIMIT 5;
```

#### Modificar índices en cualquier esquema (este privilegio podrá pasarlo a quien quiera)

Para ello el usuario becario tendría que tener el ROLE SUPERUSER que se otorga de esta forma:

```sql
ALTER ROLE becario WITH SUPERUSER;
```
Pero este rol es muy arriesgado darselo a un usuario normal, por lo que si becario es propietario de tablas, tablespaces es propietario de los índices que están en ahí. La sintaxis sería 

```sql
ALTER INDEX <nombre_indice> ON <nombretabla>;
```

#### Insertar filas en scott.emp (este privilegio podrá pasarlo a quien quiera)

En este caso no tenemos el esquema de scott pero tenemos una base de datos de prueba y podemos hacerlo de la siguiente forma:

```sql
GRANT INSERT ON departamento TO BECARIO WITH GRANT OPTION;
```

Salida:

```sql
prueba1=# \d
           List of relations
 Schema |     Name     | Type  | Owner  
--------+--------------+-------+--------
 public | departamento | table | celia1
(1 row)

prueba1=# select * from departamento
prueba1-# ;
 dept_no |    dnombre    |    loc    
---------+---------------+-----------
      10 | CONTABILIDAD  | SEVILLA
      20 | INVESTIGACION | MADRID
      30 | VENTAS        | BARCELONA
      40 | PRODUCCION    | BILBAO
(4 rows)

prueba1=# GRANT INSERT ON departamento TO BECARIO WITH GRANT OPTION;
GRANT
prueba1=# 

```

#### Crear objetos en cualquier tablespace.

En postgresql tenemos que indicar el nombre del tablespace en concreto, si no tiene el role de superuser.

```sql
GRANT CREATE ON TABLESPACE <nombre_tablespace> TO becario;
```

#### Gestión completa de usuarios, privilegios y roles

* Gestión de usuarios y privilegios 

```sql
ALTER ROLE BECARIO WITH SUPERUSER;

```

* Gestión de roles:

```sql
ALTER ROLE becario WITH CREATEROLE;
```

**Fuentes:**

https://www.postgresql.org/docs/9.1/sql-grant.html

https://www.postgresql.org/docs/9.0/sql-alterrole.html

https://www.w3resource.com/sql/creating-index/sql-alter-index.php#:~:text=Alter%20Index%20in%20PostgreSQL%2C%20Oracle%2C%20SQL%20Server&text=In%20PostgreSQL%2C%20ALTER%20INDEX%20command,%5B%2C%20...%20%5D%20)

https://www.postgresql.org/docs/13/sql-alterindex.html


### 1.3. MySQL

#### Conectarse a la base de datos

```sql

-- Crear el usuario.

mysql> CREATE USER 'becario' IDENTIFIED BY 'becario';
Query OK, 0 rows affected (0.01 sec)

-- Le damos el permiso para conectar a la base de datos. --(version 5.5)

mysql> GRANT USAGE ON *.* TO 'becario'@localhost IDENTIFIED BY 'becario';
Query OK, 0 rows affected (0.00 sec)

```

#### Modificar el número de errores en la introducción de la contraseña de cualquier usuario.

Según la versión de mysql tenemos dos opciones:

```sql 
-- Version 8.0 de mysql. Número de fallos permitidos 4, la cuenta no se bloquea porque está marcada como intentos ilimitados.
ALTER USER 'becario'@'localhost'
  FAILED_LOGIN_ATTEMPTS 4 PASSWORD_LOCK_TIME UNBOUNDED;

-- Para versiones anteriores de mysql como 5.5 habilitamos log_warning con un valor mayor que 1
--Edita el fichero /etc/my.cnf y añade:

[mysqld]
log_error        = /var/log/error.log
log_warnings     = 2

-- Salida 

mysql> SELECT @@log_warnings;
+----------------+
| @@log_warnings |
+----------------+
|              2 |
+----------------+
1 row in set (0.00 sec)

```

#### Modificar índices en cualquier esquema (este privilegio podrá pasarlo a quien quiera)

En mysql no existe un **ALTER INDEX** propiamente como tal. Pero podemos:

*  **CREATE INDEX**
*  **DROP INDEX** 
*  (v 5.7) **ALTER TABLE** nombretabla RENAME INDEX nombre_antiguo_indice TO nombre_nuevo_indice.
*  **ALTER TABLE** nombretabla **DROP INDEX** nombre_indice 
*  **ALTER TABLE** nombretabla **ADD INDEX** nombre_indice_nuevo

Por tanto para dar este privilegio:

```sql
-- Con esto podría modificar cualquier tabla y con ella renombrar por ejemplo el índice. Y con la opción WITH GRANT OPTION, puede pasar el privilegio a otro usuario.
mysql> GRANT ALTER  ON *.* TO 'becario'@'localhost' WITH GRANT OPTION;
Query OK, 0 rows affected (0.00 sec)
-- Privilegio para crear 
mysql> GRANT CREATE ON *.* TO 'becario'@'localhost';
Query OK, 0 rows affected (0.00 sec)
-- Privilegio para borrar
mysql> GRANT DROP ON *.* TO 'becario'@'localhost';
Query OK, 0 rows affected (0.00 sec)
```

#### Insertar filas en scott.emp (este privilegio podrá pasarlo a quien quiera)

```sql
GRANT INSERT ON depart TO 'becario'@'localhost' IDENTIFIED BY "becario" WITH GRANT OPTION;
```

Como no tenemos el esquema de scott en mysql, creamos una base de datos de prueba e indicamos otra tabla 

```sql
mysql> show tables;
+------------------+
| Tables_in_prueba |
+------------------+
| depart           |
| emple            |
+------------------+
2 rows in set (0.00 sec)

mysql> select * from depart;
+---------+---------------+-----------+
| dept_no | dnombre       | loc       |
+---------+---------------+-----------+
|      10 | CONTABILIDAD  | SEVILLA   |
|      20 | INVESTIGACION | MADRID    |
|      30 | VENTAS        | BARCELONA |
|      40 | PRODUCCION    | BILBAO    |
+---------+---------------+-----------+
4 rows in set (0.00 sec)

mysql> GRANT INSERT ON depart TO 'becario'@'localhost' IDENTIFIED BY "becario" WITH GRANT OPTION;
Query OK, 0 rows affected (0.01 sec)

```
**Comprobación**

```sql
-- Nos logueamos como becario, usando la base de datos de prueba y comprobamos la insercción.

mysql> use prueba;
Database changed

mysql> INSERT INTO depart values ('50','VENTAS','DOS HERMANAS');
Query OK, 1 row affected (0.00 sec)

-- Como podemos comprobar podemos insertar datos pero no podemos verlos porque no tenemos ese permiso.
mysql> select * from depart;
ERROR 1142 (42000): SELECT command denied to user 'becario'@'localhost' for table 'depart'
```

#### Crear objetos en cualquier tablespace.

Aquí pasa igual que con modificar los índices, con el permiso de CREATE ya tendría suficiente.

La sintaxis de modificar el tablespace es esta:

```sql
ALTER TABLESPACE nombre_tablespace {ADD | DROP} DATAFILE 'nombre_archivo';
 ```

Pero el permiso adecuado para esta tarea sería este:

```sql
-- Privilegio para crear 
mysql> GRANT CREATE ON *.* TO 'becario'@'localhost';
Query OK, 0 rows affected (0.00 sec)
```

#### Gestión completa de usuarios, privilegios y roles

Con el siguiente comando podría tener todos lo permisos necesarios como si fuera un administrador.

```sql 
mysql> GRANT ALL PRIVILEGES ON *.* TO 'becario'@'localhost' WITH GRANT OPTION;
Query OK, 0 rows affected (0.00 sec)

```

__________________

## Ejercicio 5

> **5.Realiza un procedimiento llamado MostrarInfoPerfil que reciba el nombre de un perfil y muestre su composición y los usuarios que lo tienen asignado.**

```sql
-- MOSTRAR LA INFORMACIÓN DEL PERFIL INDICADO
CREATE OR REPLACE PROCEDURE MostrarInfoPerfil (p_nombre_perfil DBA_PROFILES.PROFILE%TYPE)
IS 
        CURSOR c_info
        IS 
        SELECT RESOURCE_NAME, LIMIT
        FROM DBA_PROFILES
        WHERE PROFILE = p_nombre_perfil;
BEGIN 
        FOR i in c_info loop 
                DBMS_OUTPUT.PUT_LINE('Nombre del recurso: '|| i.RESOURCE_NAME || 'Límite: '|| i.LIMIT);
        end loop;
end MostrarInfoPerfil;
/

```
> exec MostrarInfoPerfil('limitepass');

________

## MySQL

## Ejercicio 8

> **8. Averigua que privilegios de sistema hay en MySQL y como se asignan a un usuario.**

Los privilegios determinan qué se puede hacer y que no. Estos se otorgan a los usuarios existentes en la base de datos. 

* Privilegios administrativos. Estos permiten admistrar la base de datos. Son propios de usuarios administradores. 
* Privilegios de base de datos y sus objetos. Estos son otorgados a los usuarios propietarios de la base de datos y con ella sus objetos. 
* Privilegios de objetos de bases de datos (tablas, índices ...). Estos se otorga para fines concretos a usuarios que necesiten o precisen de ellos. 


Una vez visto estos tres tipos de privilegios, debemos saber que están reflejados en una tabla de concesión de mysql. 

Para ver los privilegios de cada usuario ejecutamos:

```sql 
show grants;
show grants for user;
```

Ejemplo:

```sql
ysql> SHOW GRANTS;
+----------------------------------------------------------------------------------------------------------------------------------------+
| Grants for root@localhost                                                                                                              |
+----------------------------------------------------------------------------------------------------------------------------------------+
| GRANT ALL PRIVILEGES ON *.* TO 'root'@'localhost' IDENTIFIED BY PASSWORD 'pasword' WITH GRANT OPTION |
| GRANT PROXY ON ''@'' TO 'root'@'localhost' WITH GRANT OPTION                                                                           |
+----------------------------------------------------------------------------------------------------------------------------------------+
2 rows in set (0.00 sec)

mysql> SHOW GRANTS FOR 'becario';
+--------------------------------------------------------------------------------------------------------+
| Grants for becario@%                                                                                   |
+--------------------------------------------------------------------------------------------------------+
| GRANT USAGE ON *.* TO 'becario'@'%' IDENTIFIED BY PASSWORD 'password' |
+--------------------------------------------------------------------------------------------------------+
1 row in set (0.00 sec)

mysql> 

```

**La lista de privilegios**

```sql
mysql> show privileges;
+-------------------------+---------------------------------------+-------------------------------------------------------+
| Privilege               | Context                               | Comment                                               |
+-------------------------+---------------------------------------+-------------------------------------------------------+
| Alter                   | Tables                                | To alter the table                                    |
| Alter routine           | Functions,Procedures                  | To alter or drop stored functions/procedures          |
| Create                  | Databases,Tables,Indexes              | To create new databases and tables                    |
| Create routine          | Databases                             | To use CREATE FUNCTION/PROCEDURE                      |
| Create temporary tables | Databases                             | To use CREATE TEMPORARY TABLE                         |
| Create view             | Tables                                | To create new views                                   |
| Create user             | Server Admin                          | To create new users                                   |
| Delete                  | Tables                                | To delete existing rows                               |
| Drop                    | Databases,Tables                      | To drop databases, tables, and views                  |
| Event                   | Server Admin                          | To create, alter, drop and execute events             |
| Execute                 | Functions,Procedures                  | To execute stored routines                            |
| File                    | File access on server                 | To read and write files on the server                 |
| Grant option            | Databases,Tables,Functions,Procedures | To give to other users those privileges you possess   |
| Index                   | Tables                                | To create or drop indexes                             |
| Insert                  | Tables                                | To insert data into tables                            |
| Lock tables             | Databases                             | To use LOCK TABLES (together with SELECT privilege)   |
| Process                 | Server Admin                          | To view the plain text of currently executing queries |
| Proxy                   | Server Admin                          | To make proxy user possible                           |
| References              | Databases,Tables                      | To have references on tables                          |
| Reload                  | Server Admin                          | To reload or refresh tables, logs and privileges      |
| Replication client      | Server Admin                          | To ask where the slave or master servers are          |
| Replication slave       | Server Admin                          | To read binary log events from the master             |
| Select                  | Tables                                | To retrieve rows from table                           |
| Show databases          | Server Admin                          | To see all databases with SHOW DATABASES              |
| Show view               | Tables                                | To see views with SHOW CREATE VIEW                    |
| Shutdown                | Server Admin                          | To shut down the server                               |
| Super                   | Server Admin                          | To use KILL thread, SET GLOBAL, CHANGE MASTER, etc.   |
| Trigger                 | Tables                                | To use triggers                                       |
| Create tablespace       | Server Admin                          | To create/alter/drop tablespaces                      |
| Update                  | Tables                                | To update existing rows                               |
| Usage                   | Server Admin                          | No privileges - allow connect only                    |
+-------------------------+---------------------------------------+-------------------------------------------------------+
31 rows in set (0.00 sec)

```

Asignar privilegios a un usuario 

```sql

GRANT <privilegio> ON <tabla|bd|objeto> TO <usuario>@<host> (IDENTIFIED BY <contraseña>) (WITH GRANT OPTION);

-- WITH GRANT OPTION (El usuario puede otorgar el permiso a otro usuario)

--Ejemplo:

GRANT CREATE ON *.* TO 'becario'@'localhost';
```

**Fuente**

https://dev.mysql.com/doc/refman/5.7/en/privileges-provided.html
       
## Ejercicio 9

> **9. Averigua cual es la forma de asignar y revocar privilegios sobre una tabla concreta en MySQL.**

* Asignar permisos sobre una tabla 

```sql
GRANT pivilegio ON tabla TO usuario [IDENTIFIED BY 'contraseña'] [WITH GRANT OPTION];
```
EJEMPLO:

```sql
-- En la base de datos de prueba le damos permiso al usuario becario para insertar filas en la tabla emple.
mysql> show tables;
+------------------+
| Tables_in_prueba |
+------------------+
| depart           |
| emple            |
+------------------+

mysql> GRANT INSERT ON emple TO 'becario'@'localhost';
Query OK, 0 rows affected (0.00 sec)

```

* Revocar permisos sobre una tabla 

```sql
REVOKE privilegio ON tabla FROM usuario;
```

Ejemplo:

```sql
---Quitar el permiso de insertar filas

mysql> REVOKE INSERT ON prueba.emple FROM 'becario'@'localhost';
Query OK, 0 rows affected (0.00 sec)

mysql> 

```

De esta forma quitaríamos todos los permisos a un usuario 

```sql
REVOKE ALL ON BD.* from usuario@localhost
```
## Ejercicio 10
       
> **10. Averigua si existe el concepto de rol en MySQL y señala las diferencias con los roles de ORACLE.**
   
Antes de nada aclarar el **concepto de rol**

Un **rol** es usado para gestionar los privilegios de los grupos de usuarios más fácilmente. 

A un rol se le otorgan privilegios y ese mismo rol se le puede otorgar a una cuenta de usuario, por lo que el usuario tendrá los privilegios que estén en ese rol.

En **MySQL**, el concepto rol aparece a partir de la versión 8. Podemos:

* CREATE ROLE: Crear un rol 
* DROP ROLE: Eliminar un rol 
* SET DEFAULT ROLE: especifica qué roles están activos de la cuenta.
* SET ROLE: Cambia los roles activos en la sesión.
* CURRENT_ROLE(): Es una función que muestra los roles activos dentro de la sesión.

Podemos ver mas información [aquí](https://dev.mysql.com/doc/refman/8.0/en/roles.html#roles-creating-granting) para crear roles

En **ORACLE**, Un rol agrupa varios privilegios y roles, estos se pueden otorgar y revocar a los usuarios simultáneamente, el rol debe estar habilitado para un usuario antes de ser utilizado.

En ORACLE tenemos más profundizado el tema de los roles. Podemos:

* CREATE ROLE nombrerol IDENTIFIED BY passwd: (Crear un rol)

La contraseña es para especificar que se debe autorizar al usuario antes de que el rol lo pueda utilizar el usuario. 


En oracle tenemos la autorización de funciones por aplicaciones
```sql
CREATE ROLE admin_role IDENTIFIED USING hr.admin;
```

Esto no lo tenemos en mysql. Como muchas mas funciones que no me voy a extender ya que el post llegaría a ser muy extenso.

**Fuente:**

https://dev.mysql.com/doc/refman/8.0/en/roles.html#:~:text=A%20MySQL%20role%20is%20a,privileges%20associated%20with%20each%20role.

https://docs.oracle.com/cd/A97630_01/server.920/a96521/privs.htm#:~:text=A%20role%20groups%20several%20privileges,to%20help%20in%20database%20administration.


## Ejercicio 11

> **11. Averigua si existe el concepto de perfil como conjunto de límites sobre el uso de recursos osobre la contraseña en MySQL y señala las diferencias con los perfiles de ORACLE.**

En **MySQL** se restringe el uso de recursos de forma diferente a lo que lo hace ORACLE. 

Utiliza una variable `max_user_connections` que limita el número de conexiones simultáneas que pueden realizar en una cuenta concreta. 

Tiene como limitaciones en el **uso de recursos** los siguientes:

* La consultas que emita una cuenta por hora.
* La cantidad de actualizaciones por hora.
* La cantidad de veces que se puede conectar al servidor tambien por hora.
* El número de conexiones simultáneas al servidor por hora.


> Hablamos de cuenta refiriendonos a cuenta de usuario.

En cuanto a la **contraseña** las limitaciones son las siguientes:

* Caducidad de la contraseña (así se cambian periodicamente)
* Restricciones de reutilización de contraseñas.
* Verificacion de contraseña.
* Usar dos contraseñas (contraseñas duales, primaria y secundaria)
* Evaluación de la fuerza de la contraseña
* Permite generar contraseñas aleatorias.
* Habilitar el bloqueo temporal de la cuenta a partir de x errores mediante el parámetro 'validate_password'.


En **ORACLE** para este tipo de limitaciones utiliza los perfiles. 

**CREATE PROFILE**, lo que hace es crear un conjunto de límites en los recursos de la base de datos. Este perfil si se asigna a un usuario en concreto tendrá las limitaciones declaradas en dicho perfil.

Presenta prácticamente casi las mismas opciones de limitación que mysql pero de forma más clara y efectiva. 

Por ejemplo utliza **FAILED_LOGIN_ATTEMPTS**para limitar los intentos fallidos de introducir contraseña para entrar en la cuenta de un usuario.

Utiliza **UNLIMITED** para abordar el concepto de ilimitado, mientras que MySQL utiliza **UNBOUNDED**


**Fuente:**

https://dev.mysql.com/doc/mysql-security-excerpt/8.0/en/password-management.html
https://dev.mysql.com/doc/refman/8.0/en/user-resources.html

https://docs.oracle.com/cd/B19306_01/server.102/b14200/statements_6010.htm

## Ejercicio 12

> **12. Realiza consultas al diccionario de datos de MySQL para averiguar todos los privilegios que tiene un usuario concreto.**

```sql

-- En este caso tenemos el usuario becario:

mysql> show grants for 'becario';
+--------------------------------------------------------------------------------------------------------+
| Grants for becario@%                                                                                   |
+--------------------------------------------------------------------------------------------------------+
| GRANT USAGE ON *.* TO 'becario'@'%' IDENTIFIED BY PASSWORD '*289FA4B539971D43DB630F60B1C72F8335DF1245' |
+--------------------------------------------------------------------------------------------------------+
1 row in set (0.00 sec)

```
## Ejercicio 13
> **13. Realiza consultas al diccionario de datos en MySQL para averiguar qué usuarios pueden consultar una tabla concreta.**

En la tabla de concesión tables_priv podemos ver los privilegios de cada usuario sobre qué tabla. 

```sql
mysql> select * from mysql.tables_priv;
+-----------+--------+---------+------------+----------------+---------------------+--------------+-------------+
| Host      | Db     | User    | Table_name | Grantor        | Timestamp           | Table_priv   | Column_priv |
+-----------+--------+---------+------------+----------------+---------------------+--------------+-------------+
| localhost | prueba | becario | depart     | root@localhost | 2021-05-17 14:19:31 | Insert,Grant |             |
+-----------+--------+---------+------------+----------------+---------------------+--------------+-------------+
1 row in set (0.00 sec)

```
Fuente:

https://dev.mysql.com/doc/refman/8.0/en/grant-tables.html#grant-tables-tables-priv-columns-priv
