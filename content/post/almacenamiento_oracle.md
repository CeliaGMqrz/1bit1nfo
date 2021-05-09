
+++
author = "Celia García Márquez"
title = "Gestión del almacenamiento. Oracle."
date = "2021-05-09"
description = "Gestión del almacenamiento. Gestores de Bases de datos."
tags = [
    "oracle","postgres",'mariadb'
]
thumbnail= "images/almacenamiento/banner1.png"
+++

## 1. Entorno de trabajo 

### Entorno de trabajo para Oracle

Vamos a usar una máquina en vagrant con virtualbox, usando una imagen centos6 con oracle 11g.

```shell
Vagrant.configure("2") do |config|
    config.vm.define "oracle" do |oracle1|
        config.vm.provider "virtualbox" do |vb|
            vb.name = "oracle"
            vb.memory = 2048
            vb.cpus = 1
        end
        oracle1.vm.box = "neko-neko/centos6-oracle-11g-XE"
        oracle1.vm.hostname = "oracle"
        oracle1.vm.network "public_network",
            bridge: "br0", 
            use_dhcp_assigned_default_route: true
    end
end
```

## 2. CONCEPTOS PREVIOS

### ¿Qué es un Tablespace?

Son las unidades lógicas de almacenamiento que componen una base de datos, es decir, son asignaciones de espacio en la base de datos que permiten contener objetos persistentes del esquema. O en otras palabras, es una especie de directorio que contiene tablas, índices.. que se corresponden con uno o varios ficheros del sistema (datafiles).

Al instalar ORACLE se crean varios tablespaces:

* **SYSTEM**: Guardado en el diccionario de datos y otros objetos del sistema.
* **SYSAUX**: Componentes opcionales de ORACLE.
* **USERS**: Objetos de los usuarios.
* **TEMP**: Para guardar los objetos temporales (sort, productos cartesianos, etc)
* **UNDOTBS01**: Segmento de ROLLBACK.

En el siguiente gráfico podemos ver los diferentes elementos que vamos a definir posteriormente.

![bloque.png](/images/almacenamiento/bloque.png)

* Un **bloque de datos** es la **cantidad mínima de información** que se puede recuperar en los dispositivos de almacenamiento. Su tamaño debe ser múltiplo de bloque de disco definido en el sistema de operativo anfitrión y se define con **DB_BLOCK_SIZE**. 
* Una **extensión** es un conjunto de **bloques de datos** contiguos reservados de una vez.
* Un **tablespace** se divide en segmentos, uno para cada objeto. 
* Un **segmento** es un conjunto de **extensiones**, pertenecientes al mismo *tablespace* y que guardan los datos correspondientes a un objeto concreto. Existen cuatro tipos de segmentos (de tabla, de índice, temporal y de undo.)

Cuando todas las extensiones de un segmento se llenan, se reserva una nueva buscando entre los distintos *datafiles* del tablespace alguno con suficientes bloques de datos libres contiguos.

Las extensiones de un segmento no se liberan salvo que se ejecute un *DROP* del objeto correspondiente a dicho segmento, *TRUNCATE* o *ALTER TABLE DEALLOCATE UNUSED*.

**GESTIÓN DE ESPACIOS DE TABLAS**

Hay una serie de vistas útiles para gestionar el espacio y son las siguientes:

* DBA_TABLESPACES: Descripción de todos los tablespaces.
* DBA_TS_QUOTAS: Cuotas de usuario en cada tablespace
* DBA_DATA_FILES: Información de los ficheros de datos.
* DBA_FREE_SPACE: Extensiones disponibles en cada tablespace.
* DBA_EXTENTS: Extensiones de cada segmento.
* DBA_ROLLBACK_SEGS: Segmentos de rollback
* DBA_SEGMENTS: Segmentos de cada tablespace.
* DBA_TEMP_FILES: Ficheros para los tablespaces temporales.

## 3. Gestión de almacenamiento en ORACLE. 

En el vbox de vagrant con Oracle el idioma predeterminado es otro así que podemos hacer un ALTER SESSION para cambiar el idioama con el siguiente comando.

```SQL
ALTER SESSION SET NLS_LANGUAGE='ENGLISH';
```

### 3.1. Crea un tablespace undo e intenta crear una tabla en él.

Anteriormente ya hemos definido qué es un **tablespace**, así que pasamos a la práctica.

* Podemos **mostrar todos los tablespaces** del diccionario de datos de la siguiente forma 

```sh

SQL> SELECT * FROM dba_tablespaces;

TABLESPACE_NAME 	       BLOCK_SIZE INITIAL_EXTENT NEXT_EXTENT MIN_EXTENTS
------------------------------ ---------- -------------- ----------- -----------
MAX_EXTENTS   MAX_SIZE PCT_INCREASE MIN_EXTLEN STATUS	 CONTENTS  LOGGING   FOR
----------- ---------- ------------ ---------- --------- --------- --------- ---
EXTENT_MAN ALLOCATIO PLU SEGMEN DEF_TAB_ RETENTION   BIG PREDICA ENC
---------- --------- --- ------ -------- ----------- --- ------- ---
COMPRESS_FOR
------------
SYSTEM				     8192	   65536		       1
 2147483645 2147483645			 65536 ONLINE	 PERMANENT LOGGING   NO
LOCAL	   SYSTEM    NO  MANUAL DISABLED NOT APPLY   NO  HOST	 NO



TABLESPACE_NAME 	       BLOCK_SIZE INITIAL_EXTENT NEXT_EXTENT MIN_EXTENTS
------------------------------ ---------- -------------- ----------- -----------
MAX_EXTENTS   MAX_SIZE PCT_INCREASE MIN_EXTLEN STATUS	 CONTENTS  LOGGING   FOR
----------- ---------- ------------ ---------- --------- --------- --------- ---
EXTENT_MAN ALLOCATIO PLU SEGMEN DEF_TAB_ RETENTION   BIG PREDICA ENC
---------- --------- --- ------ -------- ----------- --- ------- ---
COMPRESS_FOR
------------
SYSAUX				     8192	   65536		       1
 2147483645 2147483645			 65536 ONLINE	 PERMANENT LOGGING   NO
LOCAL	   SYSTEM    NO  AUTO	DISABLED NOT APPLY   NO  HOST	 NO



TABLESPACE_NAME 	       BLOCK_SIZE INITIAL_EXTENT NEXT_EXTENT MIN_EXTENTS
------------------------------ ---------- -------------- ----------- -----------
MAX_EXTENTS   MAX_SIZE PCT_INCREASE MIN_EXTLEN STATUS	 CONTENTS  LOGGING   FOR
----------- ---------- ------------ ---------- --------- --------- --------- ---
EXTENT_MAN ALLOCATIO PLU SEGMEN DEF_TAB_ RETENTION   BIG PREDICA ENC
---------- --------- --- ------ -------- ----------- --- ------- ---
COMPRESS_FOR
------------
UNDOTBS1			     8192	   65536		       1
 2147483645 2147483645			 65536 ONLINE	 UNDO	   LOGGING   NO
LOCAL	   SYSTEM    NO  MANUAL DISABLED NOGUARANTEE NO  HOST	 NO



TABLESPACE_NAME 	       BLOCK_SIZE INITIAL_EXTENT NEXT_EXTENT MIN_EXTENTS
------------------------------ ---------- -------------- ----------- -----------
MAX_EXTENTS   MAX_SIZE PCT_INCREASE MIN_EXTLEN STATUS	 CONTENTS  LOGGING   FOR
----------- ---------- ------------ ---------- --------- --------- --------- ---
EXTENT_MAN ALLOCATIO PLU SEGMEN DEF_TAB_ RETENTION   BIG PREDICA ENC
---------- --------- --- ------ -------- ----------- --- ------- ---
COMPRESS_FOR
------------
TEMP				     8192	 1048576     1048576	       1
	    2147483645		  0    1048576 ONLINE	 TEMPORARY NOLOGGING NO
LOCAL	   UNIFORM   NO  MANUAL DISABLED NOT APPLY   NO  HOST	 NO



TABLESPACE_NAME 	       BLOCK_SIZE INITIAL_EXTENT NEXT_EXTENT MIN_EXTENTS
------------------------------ ---------- -------------- ----------- -----------
MAX_EXTENTS   MAX_SIZE PCT_INCREASE MIN_EXTLEN STATUS	 CONTENTS  LOGGING   FOR
----------- ---------- ------------ ---------- --------- --------- --------- ---
EXTENT_MAN ALLOCATIO PLU SEGMEN DEF_TAB_ RETENTION   BIG PREDICA ENC
---------- --------- --- ------ -------- ----------- --- ------- ---
COMPRESS_FOR
------------
USERS				     8192	   65536		       1
 2147483645 2147483645			 65536 ONLINE	 PERMANENT LOGGING   NO
LOCAL	   SYSTEM    NO  AUTO	DISABLED NOT APPLY   NO  HOST	 NO


5 rows selected.

```

**UNDO COMO CONCEPTO. ¿Qué es UNDO?**

Los **Datos Undo** son almacenados en extensiones de Oracle dentro de segmentos de tipo 'UNDO' en un tablespace que se dedica a almacenar datos 'Undo', por ello a este tablespace se le llama 'Undo Tablespace'. Los datos Undo son usualmente utilizados para deshacer transacciones Rollback. 

#### CREAR UNDO TABLESPACE

La instrucción inicial para **crear un UNDO tablespace** es:

```sql
CREATE UNDO TABLESPACE nombredeltablespace...
```

En mi caso usare esta instrucción indicando la ruta pertienente adecuada a nuesto sistema y versión de ORACLE.

```sql
SQL> create undo tablespace undo2 DATAFILE '/u01/app/oracle/oradata/XE/undo2.dbf' size 100M;

Tablespace created.

```

**Comprobación**

Nos aseguramos que se ha creado correctamente.

```sql
SELECT * FROM dba_tablespaces WHERE tablespace_name = 'UNDO1';

```

```sh
SQL> SELECT * FROM dba_tablespaces WHERE tablespace_name = 'UNDO1';

TABLESPACE_NAME 	       BLOCK_SIZE INITIAL_EXTENT NEXT_EXTENT MIN_EXTENTS
------------------------------ ---------- -------------- ----------- -----------
MAX_EXTENTS   MAX_SIZE PCT_INCREASE MIN_EXTLEN STATUS	 CONTENTS  LOGGING   FOR
----------- ---------- ------------ ---------- --------- --------- --------- ---
EXTENT_MAN ALLOCATIO PLU SEGMEN DEF_TAB_ RETENTION   BIG PREDICA ENC
---------- --------- --- ------ -------- ----------- --- ------- ---
COMPRESS_FOR
------------
UNDO1				     8192	   65536		       1
 2147483645 2147483645			 65536 ONLINE	 UNDO	   LOGGING   NO
LOCAL	   SYSTEM    NO  MANUAL DISABLED NOGUARANTEE NO  HOST	 NO

```

Anteriormente lo hemos creado con el usuario **SYS** pero podemos crearlo con otro usuario en este caso '**celia**' que hemos creado previamente con privilegios.

```sql
SQL> create undo tablespace undo2 DATAFILE '/u01/app/oracle/oradata/XE/undo2.dbf' size 100M;

Tablespace created.

```

Si ahora **listamos los tablespaces**, pero esta vez con la opción user porque estamos con el usuario **celia**, comprobamos que se ha creado el **UNDO2** también.

```sql
SELECT * FROM user_tablespaces;
```

```sh
SQL> SELECT * FROM user_tablespaces;

TABLESPACE_NAME 	       BLOCK_SIZE INITIAL_EXTENT NEXT_EXTENT MIN_EXTENTS
------------------------------ ---------- -------------- ----------- -----------
MAX_EXTENTS   MAX_SIZE PCT_INCREASE MIN_EXTLEN STATUS	 CONTENTS  LOGGING   FOR
----------- ---------- ------------ ---------- --------- --------- --------- ---
EXTENT_MAN ALLOCATIO SEGMEN DEF_TAB_ RETENTION	 BIG PREDICA ENC COMPRESS_FOR
---------- --------- ------ -------- ----------- --- ------- --- ------------
SYSTEM				     8192	   65536		       1
 2147483645 2147483645			 65536 ONLINE	 PERMANENT LOGGING   NO
LOCAL	   SYSTEM    MANUAL DISABLED NOT APPLY	 NO  HOST    NO

SYSAUX				     8192	   65536		       1
 2147483645 2147483645			 65536 ONLINE	 PERMANENT LOGGING   NO
LOCAL	   SYSTEM    AUTO   DISABLED NOT APPLY	 NO  HOST    NO

TABLESPACE_NAME 	       BLOCK_SIZE INITIAL_EXTENT NEXT_EXTENT MIN_EXTENTS
------------------------------ ---------- -------------- ----------- -----------
MAX_EXTENTS   MAX_SIZE PCT_INCREASE MIN_EXTLEN STATUS	 CONTENTS  LOGGING   FOR
----------- ---------- ------------ ---------- --------- --------- --------- ---
EXTENT_MAN ALLOCATIO SEGMEN DEF_TAB_ RETENTION	 BIG PREDICA ENC COMPRESS_FOR
---------- --------- ------ -------- ----------- --- ------- --- ------------

UNDOTBS1			     8192	   65536		       1
 2147483645 2147483645			 65536 ONLINE	 UNDO	   LOGGING   NO
LOCAL	   SYSTEM    MANUAL DISABLED NOGUARANTEE NO  HOST    NO

TEMP				     8192	 1048576     1048576	       1
	    2147483645		  0    1048576 ONLINE	 TEMPORARY NOLOGGING NO

TABLESPACE_NAME 	       BLOCK_SIZE INITIAL_EXTENT NEXT_EXTENT MIN_EXTENTS
------------------------------ ---------- -------------- ----------- -----------
MAX_EXTENTS   MAX_SIZE PCT_INCREASE MIN_EXTLEN STATUS	 CONTENTS  LOGGING   FOR
----------- ---------- ------------ ---------- --------- --------- --------- ---
EXTENT_MAN ALLOCATIO SEGMEN DEF_TAB_ RETENTION	 BIG PREDICA ENC COMPRESS_FOR
---------- --------- ------ -------- ----------- --- ------- --- ------------
LOCAL	   UNIFORM   MANUAL DISABLED NOT APPLY	 NO  HOST    NO

USERS				     8192	   65536		       1
 2147483645 2147483645			 65536 ONLINE	 PERMANENT LOGGING   NO
LOCAL	   SYSTEM    AUTO   DISABLED NOT APPLY	 NO  HOST    NO

UNDO1				     8192	   65536		       1

TABLESPACE_NAME 	       BLOCK_SIZE INITIAL_EXTENT NEXT_EXTENT MIN_EXTENTS
------------------------------ ---------- -------------- ----------- -----------
MAX_EXTENTS   MAX_SIZE PCT_INCREASE MIN_EXTLEN STATUS	 CONTENTS  LOGGING   FOR
----------- ---------- ------------ ---------- --------- --------- --------- ---
EXTENT_MAN ALLOCATIO SEGMEN DEF_TAB_ RETENTION	 BIG PREDICA ENC COMPRESS_FOR
---------- --------- ------ -------- ----------- --- ------- --- ------------
 2147483645 2147483645			 65536 ONLINE	 UNDO	   LOGGING   NO
LOCAL	   SYSTEM    MANUAL DISABLED NOGUARANTEE NO  HOST    NO

UNDO2				     8192	   65536		       1
 2147483645 2147483645			 65536 ONLINE	 UNDO	   LOGGING   NO
LOCAL	   SYSTEM    MANUAL DISABLED NOGUARANTEE NO  HOST    NO


7 rows selected.

```

#### Crear tabla en UNDO1

Ahora vamos a intentar crear una tabla en el tablespace **UNDO1** desde el usuario '*celia*'.

```sh
create table test1 (nombre varchar2(20)) tablespace UNDO1;
```

Nos aparece el siguiente error tanto con el usuario '**celia**' como el usuario '**sys**'

```sql
SQL> create table test1 (nombre varchar2(20)) tablespace UNDO2;
create table test1 (nombre varchar2(20)) tablespace UNDO2
*
ERROR at line 1:
ORA-30022: Cannot create segments in undo tablespace

```

#### Conclusión 

Esto significa que el espacio de tabla de *UNDO* no es un espacio de tabla normal,**no puede almacenar datos de usuario normales.** En otras palabras este es un espacio de **tabla especial** que solo se utiliza para **fines internos y en el que los usuarios no pueden colocar tablas o índices.**


### 3.2. Crea un tablespace temporal TEMP2 y escribe una sentencia SQL que genere un script que haga usar TEMP2 a todos los usuarios que tienen USERS como tablespace por defecto.

#### Crear tablespace temporal

Para crear un tablespace temporal '**TEMP2**' ejecutamos lo siguiente:

```sql
CREATE TEMPORARY TABLESPACE TEMP2 TEMPFILE  '/u01/app/oracle/oradata/XE/temp2.dbf' SIZE 1000M;
```

#### Consultar los tablespaces temporales:

```sql
SELECT tablespace_name FROM user_tablespaces where contents = 'TEMPORARY';
```

```sh
SQL> SELECT tablespace_name FROM user_tablespaces where contents = 'TEMPORARY';

TABLESPACE_NAME
------------------------------
TEMP
TEMP2
```

Como hemos podido comprobar se ha creado correctamente.

Consultamos los usuarios que tienen USERS como tablespace por defecto:

```sql
select USERNAME, DEFAULT_TABLESPACE from DBA_USERS where DEFAULT_TABLESPACE='USERS';
```

Como podemos comprobar solo aparece HR

```sh
SQL> select USERNAME, DEFAULT_TABLESPACE from DBA_USERS where DEFAULT_TABLESPACE='USERS';

USERNAME		       DEFAULT_TABLESPACE
------------------------------ ------------------------------
HR			       USERS

```

Por lo que vamos a **agregar un par de usuarios más.**

```sql
create user celia1 identified by celia11 default tablespace users quota 100M on users;
create user celia2 identified by celia22 default tablespace users quota 100M on users;
create user celia3 identified by celia33 default tablespace users quota 100M on users;

```


Volvemos a hacer la consulta de nuevo y obtenemos lo siguiente.

```sh
SQL> select username from DBA_USERS where temporary_TABLESPACE='TEMP2';

USERNAME		       DEFAULT_TABLESPACE
------------------------------ ------------------------------
HR			       USERS
CELIA1			       USERS
CELIA3			       USERS
CELIA2			       USERS
```


La idea es la siguiente:

```sql
ALTER USER usuarios TEMPORARY TABLESPACE TEMP2;
```

#### Forma simple: Sentencia SQL

Lo más simple es usar una **sentencia habitual**, en este caso hacemos una consulta de los nombres de los usuarios del tablespace por defecto en USERS a la vez que ejecutamos ALTER USER 'usuarios' DEFAULT TABLESPACE TEMP2, Así conseguimos usen TEMP2.

```sql
SQL> select 'alter user ' || username || ' default tablespace temp2;' Cambios from DBA_USERS where DEFAULT_TABLESPACE = 'USERS';

CAMBIOS
-------------------------------------------------------------------
alter user HR default tablespace temp2;
alter user CELIA1 default tablespace temp2;
alter user CELIA3 default tablespace temp2;
alter user CELIA2 default tablespace temp2;

```

Comprobamos que se han cambiado:


```sh
SQL> select username from DBA_USERS where temporary_TABLESPACE='TEMP2';

USERNAME
------------------------------
CELIA2
CELIA3
CELIA1
HR

```

#### Forma un poco más compleja: Procedimiento PLSQL

Podemos hacerlo también con un procedimiento directamente en la linea de comandos de la siguiente forma:

Vamos a crear un procedimiento el cual guarda en una variable los usuarios que están en el **tablespace por defecto** de **USERS** y con un bucle ejecutamos una sentencia sql la cual usa ALTER USER para modificar a los usuarios seleccionados al tablespace temporal **TEMP2**.

```sql
SQL> declare linea varchar2(200);
begin
for v_nombre in (select username from DBA_USERS where DEFAULT_TABLESPACE='USERS')
loop
linea := concat('alter user',' ') || v_nombre.username ||
' temporary tablespace temp2';
dbms_output.put_line('Usuario: ' || v_nombre.username);
dbms_output.put_line(linea);
execute immediate linea;
end loop;
end;
/  2    3    4    5    6    7    8    9   10   11   12  
Usuario: HR
alter user HR temporary tablespace temp2
Usuario: CELIA1
alter user CELIA1 temporary tablespace temp2
Usuario: CELIA3
alter user CELIA3 temporary tablespace temp2
Usuario: CELIA2
alter user CELIA2 temporary tablespace temp2
```

**Comprobamos que se ha ejecutado correctamente y que usan TEMP2**

```shell
SQL> select username from DBA_USERS where temporary_TABLESPACE='TEMP2';

USERNAME
------------------------------
CELIA2
CELIA3
CELIA1
HR

```

### 3.3. Borra todos los tablespaces creados para esta práctica sin que quede rastro de ellos. Realiza las acciones previas que sean necesarias.

Los **tablespaces** que hemos creado para esta práctica son:

* TEMP2
* UNDO1
* UNDO2

Eliminamos el tablespace **TEMP2** indicando tambien el contenido y los ficheros, liberando el espacio del mismo.

```sql

SQL> DROP TABLESPACE temp2 INCLUDING CONTENTS AND DATAFILES;

Tablespace dropped.
```

Eliminamos los **UNDO**.

```sql
SQL> DROP TABLESPACE undo1 INCLUDING CONTENTS AND DATAFILES;

Tablespace dropped.

SQL> DROP TABLESPACE undo2 INCLUDING CONTENTS AND DATAFILES;

Tablespace dropped.

```
**Ahora comprobamos que se han eliminado**

```sql
SQL> SELECT tablespace_name FROM user_tablespaces;

TABLESPACE_NAME
------------------------------
SYSTEM
SYSAUX
UNDOTBS1
TEMP
USERS

```


### 3.4. Averigua los segmentos existentes para realizar un ROLLBACK y el tamaño de sus extensiones.

#### Concepto ROLLBACK

**Es una operación que devuelve a la base de datos a algún estado anterior**. Es muy importante y útil ante evitar daños y pérdida de datos. En SQL, ROLLBACK es un comando que causa que todos los cambios de datos desde la última sentencia **BEGIN WORK, o START TRANSATION** sean descartados por el sistema de gestión de base de datos. 

Las vistas más importantes de las que podemos extraer información sobre los segmentos de rollback son: v$rollname, dba_rollback_segs y v$rollstat.

La tabla **DBA_ROLLBACK_SEGS** (Segmentos de rollback) es la siguiente:

```sql
Column	                Datatype	      NULL	    Description
SEGMENT_NAME	        VARCHAR2(30)	NOT NULL	Name of the rollback segment
OWNER	                VARCHAR2(6)	                Owner of the rollback segment
TABLESPACE_NAME	        VARCHAR2(30)	NOT NULL	Name of the tablespace containing the rollback segment
SEGMENT_ID          	NUMBER	        NOT NULL	ID number of the rollback segment
FILE_ID	                NUMBER	        NOT NULL	File identifier number of the file containing the segment head
BLOCK_ID	            NUMBER	        NOT NULL	ID number of the block containing the segment header
INITIAL_EXTENT	        NUMBER                      Initial extent size in bytes
NEXT_EXTENT	            NUMBER	                    Secondary extent size in bytes
MIN_EXTENTS	            NUMBER	        NOT NULL	Minimum number of extents
MAX_EXTENTS	            NUMBER	        NOT NULL	Maximum number of extent
PCT_INCREASE	        NUMBER	 	                Percent increase for extent size
STATUS	                VARCHAR2(16)	            Rollback segment status
INSTANCE_NUM	        VARCHAR2(40)	            Rollback segment owning Real Application Clusters instance number
RELATIVE_FNO	        NUMBER	        NOT NULL	Relative file number of the segment header
```

Los **segmentos de rollback** se utilizan para poder deshacer los cambios de las transacciones para las que no se ha hecho un **commit** y para asegurar la consistencia de lectura. Oracle guarda por cada bloque una tabla de las transacciones que en cada momento se están ejecutando en el mismo. Además, por cada transacción, por cada nuevo cambio que se realiza en los bloques de datos se crea una entrada de rollback que se encadena a las anteriores entradas de rollback asignadas a esa misma transacción de forma ordenada.


#### Obtener los segmentos existentes para realizar un ROLLBACK. 

Utilizaremos la tabla **DBA_ROLLBACK_SEGS**, en la cual tenemos los **SEGMENT_NAME** con el nombre del segmento, y **INITIAL_EXTENT**, **NEXT_EXTENT** con el tamaño de los mismos.

```sql
SELECT SEGMENT_NAME, INITIAL_EXTENT, NEXT_EXTENT FROM DBA_ROLLBACK_SEGS;
```


```SQL
SQL> SELECT SEGMENT_NAME, INITIAL_EXTENT, NEXT_EXTENT FROM DBA_ROLLBACK_SEGS;

SEGMENT_NAME		       INITIAL_EXTENT NEXT_EXTENT
------------------------------ -------------- -----------
SYSTEM				       114688	    57344
_SYSSMU1_3789641169$		       131072	    65536
_SYSSMU2_1827203912$		       131072	    65536
_SYSSMU3_3346129149$		       131072	    65536
_SYSSMU4_655887589$		       131072	    65536
_SYSSMU5_3703078872$		       131072	    65536
_SYSSMU6_725569783$		       131072	    65536
_SYSSMU7_3583332791$		       131072	    65536
_SYSSMU8_4175076471$		       131072	    65536
_SYSSMU9_1317495879$		       131072	    65536
_SYSSMU10_2569484742$		       131072	    65536

11 rows selected.

```

> Según mi lógica, el tamaño sería el siguiente pero es posible que no esté bien calculado.


```sql
SQL> SELECT SEGMENT_NAME, (INITIAL_EXTENT-NEXT_EXTENT)/1024 as "tamaño k"
FROM DBA_ROLLBACK_SEGS MB;  

SEGMENT_NAME                     tamaño k
------------------------------ ----------
SYSTEM				               56
_SYSSMU1_3789641169$		       64
_SYSSMU2_1827203912$		       64
_SYSSMU3_3346129149$		       64
_SYSSMU4_655887589$		           64
_SYSSMU5_3703078872$		       64
_SYSSMU6_725569783$		           64
_SYSSMU7_3583332791$		       64
_SYSSMU8_4175076471$		       64
_SYSSMU9_1317495879$		       64
_SYSSMU10_2569484742$		       64

11 rows selected.
```


## 5. Queremos limpiar nuestro fichero tnsnames.ora. Averigua cuales de sus entradas se están usando en algún enlace de la base de datos.


**Concepto TSNAMES.ora**

Es un fichero de configuración de ORACLE que contiene nombres de servicios de red mapeados, asignados a descriptores a través de los cuales se nos permite acceder. Ubicados en los clientes. 

El **contenido actual del fichero** es este

`/u01/app/oracle/product/11.2.0/xe/network/admin/tnsnames.ora`

```shell
# tnsnames.ora Network Configuration File:

XE =
  (DESCRIPTION =
    (ADDRESS = (PROTOCOL = TCP)(HOST = localhost.localdomain)(PORT = 1521))
    (CONNECT_DATA =
      (SERVER = DEDICATED)
      (SERVICE_NAME = XE)
    )
  )

EXTPROC_CONNECTION_DATA =
  (DESCRIPTION =
    (ADDRESS_LIST =
      (ADDRESS = (PROTOCOL = IPC)(KEY = EXTPROC_FOR_XE))
    )
    (CONNECT_DATA =
      (SID = PLSExtProc)
      (PRESENTATION = RO)
    )
  )


```

La entrada **EXTPROC_CONNECTION_DATA** se utiliza para llamar procedimientos externos o programas externos como C. La podriamos eliminar.


**Una vez eliminada podemos reiniciar el servicio y comprobar que la base de datos sigue funcionando correctamente.**


### 3.6. Escribe una entrada en tu blog explicando las limitaciones de Postgres y MariaDB respecto a ORACLE en cuanto a la gestión del almacenamiento. 

Esta entrada la puedes encontrar [aquí](https://www.celiagm.es/post/limitaciones_almacenamiento_gestores_bd/)


Fuentes:

http://international-dba.blogspot.com/2016/02/creating-tables-in-undo-tablespace.html


https://itsolutions.systems/2018/01/15/operaciones-con-tablespace-temporal-oracle/#:~:text=C%C3%93MO%20CREAR%20UN%20TABLESPACE%20TEMPORAL,TEMP%20el%20nombre%20del%20tablespace.

https://stackoverflow.com/questions/67349519/how-to-alter-more-that-one-user-using-alter-user-in-oracle

https://www.tutorialesprogramacionya.com/oracleya/temarios/descripcion.php?inicio=0&cod=179&punto=21

https://codigolite.com/como-crear-ejecutar-y-eliminar-un-procedimiento-almacenado-en-oracle/#:~:text=Para%20crear%20un%20procedimiento%20almacenado,oracle%20sobre%20los%20procedimientos%20almacenados.

https://programacion.net/articulo/estructuras_de_oracle_89/7

https://www.dba-village.com/village/dvp_forum.OpenThread?ThreadIdA=4594