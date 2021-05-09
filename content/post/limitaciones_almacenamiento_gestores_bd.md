+++
author = "Celia García Márquez"
title = "Limitaciones de Postgresql y MariaDB VS Oracle (Almacenamiento)"
date = "2021-05-09"
description = "Limitaciones de Postgresql y MariaDB VS Oracle (Almacenamiento)"
tags = [
    "oracle","postgres",'mariadb'
]
thumbnail= "images/almacenamiento/banner.png"
+++

## POSTGRESQL

### Características: Ventajas e inconvenientes de postgresql

### Formato de almacenamiento a nivel de archivos y directorios de postgresql

* Los archivos de configuración y los datos utilizados por el clúster de la base de datos se almacenan juntos dentro del directorio de datos llamado **PGDATA**, ubicado en **/var/lib/pgsql/data**. Pueden existir varios clústeres, administrados por diferentes instancias en el servidor de la misma máquina. **PGDATA** contiene varios subdirectorios y archivos de control.

* Una tabla que tiene columnas con entradas excesivamente grandes dispondrá de una tabla **TOAST** (The Oversized-Attribute Storage Technique) asociada, esta tabla se usa para el almacenamiento fuera de línea de valores de campo que son demasiado grandes para mantenerlos en las filas. 

* Las tablas de secuencias y TOAST tienen el mismo formato que una tabla normal.

* Con la tabla TOAST podemos usar varias estrategias de almacenamiento. 

  * Plain 
  * Extendend
  * External
  * Main

> No voy a extenderme mucho en las estrategias pero si quieres ver mas información puedes consultar esta [documentacion oficial de postgresql](https://www.postgresql.org/docs/current/storage-toast.html)

### Tablespaces en postgresql

* En versiones antiguas (anterior a la 9.0), no soportaba **tablespaces** para definir dónde almacenar la base de datos, esquema , índices etc. Posteriormente se implementó.

* **El importante uso de tablespaces:** Mediante el uso de **tablespaces** un administrador puede controlar el diseño del disco de una instalación de POSTGRESQL, esto es muy útil si la partición o el volumen en el que se instaló el clúster se queda sin espacio y no se puede ampliar; Seguidamente se crearía un espacio de tabla en una partición diferente y se podría usar temporalmente hasta que se pueda volver a configurar el sistema.También es de utilidad para conocer el **patrón de uso de los objetos** de la base de datos y así optimizar el **rendimiento**, Como por ejemplo un índice que se le da mucho uso se puede ubicar en un disco más rápido.

* Recordamos la **sintaxis** básica para crear un tablespace en postgresql 

```sql
CREATE TABLESPACE nombredeltablespace LOCATION '/ruta/del/disco/encuestion';
```
### Función pg_total_relation_size

Tenemos la opción **pg_total_relation_size** también para el control de espacio de almacemamiento. A través de la creación de una vista usando esta función podríamos observar el estado del almacenamiento de la base de datos, como por ejemplo ver el espacio que ocupa la base de datos.

### Desventajas de postgresql vs Oracle 

* Podríamos decir varias de ellas pero la más relevante que he encontrado es que al hacer una transacción si se encuentra algún fallo, automáticamente no se ejecuta nada. Sin embargo Oracle cuenta con la opción de recuperar un punto anterior en la ejecución de la transacción.

* En versiones anteriores no soportaba tablespaces. Y la funcionalidad de estos actualmente son menos eficientes que los de Oracle.

* Postgresql no presenta tener una cláusula de almacenamiento de datos en sí como Oracle 



## MariaDB

MySQL tiene un sistema de almacenamiento íntegro sobre espacios de tablas o **tablespaces**. Usa 'InnoDB' y 'NDB'.

* **¿Que es InnoDB?**

Pues es un mecanismo de almacenamiento de datos exclusivo de MYSQL, incluido como formato de tabla estándar en todas las distribuciones de MYSQL (posterior a la 4.0).Permite recuperar un problema volviendo a ejecutar los registros(logs).

Las tablas que utilizan el motor de almacenamiento InnoDB se escriben en el disco de archivos de datos denominados tablespaces. Un espacio de tabla puede contener una o más tablas InnoDB, así como ínidices asociados.

* **¿Qué es NDB Clúster?**

Es otro mecanismo de almacenamiento subyacente a MySQL Clúster. En general se usa para gestionar el almacenamiento de tablas.

### Similitudes y diferencias respecto a Oracle

* MySQL según hemos comentado anteriormente usa **tablespaces**, siendo esta la primera y más clara **similitud** entre este gestor de base de datos y **Oracle**.

* De diferente forma pero se pueden gestionar los tablespaces tanto en Oracle como en MYSQL.

**IMPORTANTE** 

Mariadb como tal no puede crear **tablespaces**. Como podemos ver en la [documentación](https://mariadb.com/kb/en/create-tablespace/)


* EN [MYSQL 5.7](https://dev.mysql.com/doc/refman/5.7/en/create-tablespace.html) sí podemos crear tablespaces con la siguiente sintaxis.

```sql
CREATE TABLESPACE tablespace_name

  InnoDB and NDB:
    ADD DATAFILE 'file_name'

  InnoDB only:
    [FILE_BLOCK_SIZE = value]

  NDB only:
    USE LOGFILE GROUP logfile_group
    [EXTENT_SIZE [=] extent_size]
    [INITIAL_SIZE [=] initial_size]
    [AUTOEXTEND_SIZE [=] autoextend_size]
    [MAX_SIZE [=] max_size]
    [NODEGROUP [=] nodegroup_id]
    [WAIT]
    [COMMENT [=] 'string']

  InnoDB and NDB:
    [ENGINE [=] engine_name]
```

### Similitud: Autoextender tablespace

Tanto en ORACLE como en MYSQL tenemos la opción de **autoextender** el tablespace:

De esta forma cuando un archivo de la tabla requiere espacio adicional lo podemos extender.

La sintaxis sería:

```sql
-- Crear el tablespace
CREATE TABLESPACE ts1 AUTOEXTEND_SIZE = 4M;
-- Modifcarlo
ALTER TABLESPACE ts1 AUTOEXTEND_SIZE = 8M;
```

En Oracle otro ejemplo sería;

```sql
-- Modificar el tablespace
alter tablespace nombre_tablespace add datafile nombre_datafile size 100M 
autoextend on next 250K maxsize 200M; 
```
### Limitación: Quota de almacenamiento

* Una de las **limitaciones** que tiene MySQL con InnoDB es que no se pueden aplicar quotas de almacenamiento a distintos usuarios, mientras que en Oracle sí.

* En oracle esta información está reflejada en **DBA_TS_QUOTAS**, que describe las cuotas de tablespace para todos los usuarios.

Este sería un ejemplo en el que se modifica la quota de un usuario.

```sql
ps$tkyte@ORA920LAP> alter user ops$tkyte quota unlimited on users;

User altered.

ops$tkyte@ORA920LAP> select * from USER_TS_QUOTAS;

TABLESPACE_NAME                     BYTES  MAX_BYTES     BLOCKS MAX_BLOCKS
------------------------------ ---------- ---------- ---------- ----------
USERS                             1572864         -1        192         -1
T_2M                             10485760          0       1280          0
T_1M                                    0          0          0          0

ops$tkyte@ORA920LAP> alter user ops$tkyte quota 0k on users;

User altered.

ops$tkyte@ORA920LAP> select * from USER_TS_QUOTAS;

TABLESPACE_NAME                     BYTES  MAX_BYTES     BLOCKS MAX_BLOCKS
------------------------------ ---------- ---------- ---------- ----------
USERS                             1572864          0        192          0
T_2M                             10485760          0       1280          0
T_1M                                    0          0          0          0
```

## Conclusión


**Postgresql** estaba muy limitado en cuanto al control de espacios de tablas en versiones anteriores, ahora podemos gestionarlo de mejor manera, teniendo en cuenta la funcionalidad de la téctina TOAST que permite ampliar el espacio en otra tabla TOAST como hemos explicado al principio del post. Respecto a Oracle estas funciones vienen de forma nativa y gestionan el espacio de manera más eficiente y rápida.

En cuanto a **MySQL** nos limita la posibilidad de asignar cuotas de almacenamiento a los usuarios en comparación a **Oracle** que si lo permite. Sin embargo también posee funciones de control de almacenamiento de tablas comunes y tablespaces, como la opción *autoextend* que tambien la presenta Oracle. Estos dos gestores serían los más eficientes según mi punto de vista si de almacenamiento nos referimos. Pero si tuviera que elegir uno de los gestores en este campo me quedaría con **ORACLE**.

Fuentes:

https://www.postgresql.org/docs/current/storage.html

https://programacion.net/articulo/estructuras_de_oracle_89/3

https://dev.mysql.com/doc/refman/5.7/en/create-tablespace.html#create-tablespace-innodb-examples

https://en.wikipedia.org/wiki/NDB_Cluster

https://dev.mysql.com/doc/refman/8.0/en/general-tablespaces.html

