
+++
author = "Celia García Márquez"
title = "Auditorías. Gestión de Bases de datos."
date = "2021-05-24"
description = "Auditorias en BBDD"
tags = [
    "oracle", "auditoria", "mysql", "postgres", "mongodb"
]
thumbnail= "images/auditorias/banner.png"
+++

En esta entrada vamos a hablar sobre la importancia que tiene **proteger la información**, en este caso la que guarda una base de datos y cómo **controlar** dicha información mediante **auditorías**. Este es un papel muy importante para un **administrador de base de datos**.

## Concepto: Auditoría.

Se trata de un **estudio** que analiza los distintos procesos de gestión, los evalúa un *auditor* bajo una serie de criterios establecidos. El **auditor** es el que se encarga propiamente de observar la situación y la considera adecuada o no según los resultados.

**Auditoría de base de datos: Oracle**

En **Oracle** la auditoría la componen ciertas características que ofrece el gestor que permiten al administrador y a los usuarios a hacer un **seguimiento** del uso de la base de datos. Estos datos se almacenan en el **diccionario de datos** concretamente en la tabla **SYS.AUD$**, además hay una serie de **vistas** que muestran estos datos según lo que queramos obtener.

El principal objetivo es proteger los datos mediante un seguimiento. Este seguimiento se aplica de forma en que se controla:

* **Los intentos de inicio de sesión** (éxitos o fallidos)
* **El acceso a los objetos**
* **Todas y cada una de las acciones que tomen en la BD.**


## Tarea teorica/práctica

Ahora vamos a ir explicando de forma teorico/práctica las configuración, características y funcionalidades de las auditorías.

## 1. Activación de auditoría de la base de datos

El ejercicio práctico planteado es:

> **1. Activa desde SQL*Plus la auditoría de los intentos de acceso fallidos al sistema. Comprueba su funcionamiento.** 

Para empezar debemos de saber que la activación de la auditoría depende del **parámetro** **[AUDIT_TRAIL](https://docs.oracle.com/cd/E11882_01/server.112/e40402/initparams017.htm#REFRN10006)**. Es el que habilita o deshabilita la auditoría de la base de datos.

Este parámetro alojado en el diccionario de datos podemos verlo de la siguiente forma:

```sql
SHOW PARAMETER AUDIT
```

Salida:

```sh
SQL> SHOW PARAMETER AUDIT

NAME				     TYPE	 VALUE
------------------------------------ ----------- ------------------------------
audit_file_dest 		     string	 /u01/app/oracle/admin/XE/adump
audit_syslog_level		     string
audit_sys_operations		     boolean	 FALSE
audit_trail			     string	 NONE

```

Para activarlo podemos modificar el fichero **init.ora** pero en mi caso vamos a ejecutar el siguiente comando:

```sql
ALTER SYSTEM SET audit_trail = "DB" SCOPE=SPFILE;
```

Salida:

```sh
SQL> ALTER SYSTEM SET audit_trail = "DB" SCOPE=SPFILE;

System altered.

```

Si lo quisieramos desactivar, en vez de "DB", podemos especificar "NONE".

Debemos de tener en cuenta la **versión** de oracle ya que en algunas versiones viene activada por defecto. En cualquier caso si la hemos activado siempre tenemos que reiniciar Oracle.

```sql
SHUTDOWN
STARTUP
```

Ahora comprobamos que la auditoría está activada haciendo la siguiente consulta, de forma que según el **valor** especificado vemos si está activa o no.

```sql
SELECT name, value as Valor from v$parameter where name like 'audit_trail';
```

```sql
SQL> SELECT name, value as Valor from v$parameter where name like 'audit_trail';

NAME
--------------------------------------------------------------------------------
VALOR
--------------------------------------------------------------------------------
audit_trail
DB

```

Una vez activada tenemos que activar la auditoría de **intentos fallidos al sistema**.

Esto podemos hacerlo de forma general para todos los usuarios o para algún caso en concreto (un usuario o una sesión).

En este caso como no queremos que se aplique para todos los usuarios utilizaremos una auditoría de **sesión** para un **usuario** en concreto. El usuario se llamará `becario` y habilitaremos la **auditoría de inicio de sesión** para intentos **fallidos**.

El comando a ejecutar sería el siguiente, desde el adminsitrador `sys`:

```sql
audit session whenever not successful;
audit session by becario;
```

```sql
SQL> audit session whenever not successful;

Audit succeeded.

SQL> audit session by becario;

Audit succeeded.

```
Supongamos que intentamos entrar a la base de datos con el usuario BECARIO y fallamos dos intentos, y al tercero entramos.

Con el usuario sys hacemos la siguiente consulta para comprobar el resultado:

```sql
SELECT USERNAME, OS_USERNAME, TIMESTAMP, ACTION_NAME FROM DBA_AUDIT_SESSION WHERE USERNAME='BECARIO';
```

Salida:

```sql
SQL> SELECT USERNAME, OS_USERNAME, TIMESTAMP, ACTION_NAME, RETURNCODE FROM DBA_AUDIT_SESSION WHERE USERNAME='BECARIO';

USERNAME
------------------------------
OS_USERNAME
--------------------------------------------------------------------------------
TIMESTAMP	    ACTION_NAME 		 RETURNCODE
------------------- ---------------------------- ----------
BECARIO
oracle
2021/05/22 13:28:11 LOGON				  0

BECARIO
oracle
2021/05/22 13:29:57 LOGOFF				  0

USERNAME
------------------------------
OS_USERNAME
--------------------------------------------------------------------------------
TIMESTAMP	    ACTION_NAME 		 RETURNCODE
------------------- ---------------------------- ----------

BECARIO
oracle
2021/05/22 13:31:14 LOGON			       1017

BECARIO
oracle

USERNAME
------------------------------
OS_USERNAME
--------------------------------------------------------------------------------
TIMESTAMP	    ACTION_NAME 		 RETURNCODE
------------------- ---------------------------- ----------
2021/05/22 13:31:21 LOGON			       1017

BECARIO
oracle
2021/05/22 13:32:39 LOGON				  0

BECARIO

USERNAME
------------------------------
OS_USERNAME
--------------------------------------------------------------------------------
TIMESTAMP	    ACTION_NAME 		 RETURNCODE
------------------- ---------------------------- ----------
oracle
2021/05/22 13:33:48 LOGOFF				  0


```

**Como hemos podido comprobar podemos visualizar la fecha y la hora en la que se ha intentado entrar en el sistema de forma fallida, Además del codigo que devuelve que en este caso es el 1017 (usuario o contraseña incorrecta (credenciales incorrectas)).**

## 2. Procedimiento PLSQL

> **2. Realiza un procedimiento en PL/SQL que te muestre los accesos fallidos junto con el motivo de los mismos, transformando el código de error almacenado en un mensaje de texto comprensible.**



```sql
-- Funcion: Devolver un mensaje según el codigo de error 
CREATE OR REPLACE FUNCTION ImprimirMensaje (p_codigo VARCHAR2)
RETURN VARCHAR2
IS 
        mensaje VARCHAR2(100);
        BEGIN 
            IF p_codigo = '1017' THEN 
                mensaje:='Credenciales incorrectas';
            ELSIF p_codigo = '1045' THEN
                mensaje:='Carece de privilegio para Crear Sesión';
            ELSIF p_codigo = '0' THEN
                mensaje:='Login correcto';
            ELSE 
                mensaje:='Consulta el error en la documentacion oficial de oracle';
            END IF;
        RETURN mensaje;
END ImprimirMensaje;
/

-- Procedimiento MostrarMensaje

CREATE OR REPLACE PROCEDURE MostrarMensaje
IS 
    v_mensaje VARCHAR2(100);
    CURSOR c_fallidos
    IS 
    SELECT RETURNCODE, USERNAME, TIMESTAMP
    FROM DBA_AUDIT_SESSION
    WHERE ACTION_NAME='LOGON';
BEGIN 
    DBMS_OUTPUT.PUT_LINE('ACCESOS FALLIDOS');
    DBMS_OUTPUT.PUT_LINE('________________');
    FOR linea IN c_fallidos LOOP 
        v_mensaje:=ImprimirMensaje(linea.RETURNCODE);
        DBMS_OUTPUT.PUT_LINE('-Usuario: '||linea.USERNAME||' -Fecha: '||linea.TIMESTAMP||' - '||linea.RETURNCODE||': '||v_mensaje);
        DBMS_OUTPUT.PUT_LINE('');
    END LOOP;
END MostrarMensaje;
/

```

* Ejecutamos el procedimiento y comprobamos la salida:
  
```sql
exec MostrarMensaje
```
#### Comprobación procedimiento

**Version XE**
```sql
SQL> exec MostrarMensaje
ACCESOS FALLIDOS
________________
-Usuario: CELIA -Fecha: 2021/05/22 13:27:50 - 1045: Carece de privilegio para
Crear Sesión
-Usuario: BECARIO -Fecha: 2021/05/22 13:28:11 - 0: Login correcto
-Usuario: BECARIO -Fecha: 2021/05/22 13:31:14 - 1017: Credenciales incorrectas
-Usuario: BECARIO -Fecha: 2021/05/22 13:31:21 - 1017: Credenciales incorrectas
-Usuario: BECARIO -Fecha: 2021/05/22 13:32:39 - 0: Login correcto
-Usuario: BECARIO -Fecha: 2021/05/23 07:53:12 - 0: Login correcto

PL/SQL procedure successfully completed.

```

##  3. Auditoría de operaciones DML 

Las operaciones DML son:

* Insert: Para añadir registros
* Update: Modificar o actualizar registros
* Delete: Eliminar registros 

> **3.Activa la auditoría de las operaciones DML realizadas por SCOTT. Comprueba su funcionamiento.**

Activamos la auditoria de las acciones mencionadas anteriormente al usuario SCOTT. Especificamos **by access** que mostrará un registro por cada acción realizada.

```sql
SQL> AUDIT INSERT TABLE, UPDATE TABLE, DELETE TABLE BY SCOTT BY ACCESS;

Audit succeeded.
```


#### Comprobación

Acciones del usuario **SCOTT**:

```sql
INSERT INTO DEPT VALUES (28, 'recursos', 'MADRID');
UPDATE EMP SET ENAME = 'BENITO' WHERE EMPNO = '7499';
DELETE FROM DEPT WHERE DNAME = 'RESOURCES';
```

Hacemos la siguiente consulta con el usuario **SYS** para ver que efectivamente registra todas las operaciones DML.

```SQL
SQL> SELECT OBJ_NAME, ACTION_NAME, TIMESTAMP FROM DBA_AUDIT_OBJECT WHERE USERNAME='SCOTT';

OBJ_NAME
--------------------------------------------------------------------------------
ACTION_NAME		     TIMESTAMP
---------------------------- -------------------
DEPT
INSERT			     2021/05/23 08:14:34

DEPT
INSERT			     2021/05/23 08:14:50

EMP
UPDATE			     2021/05/23 08:18:16


OBJ_NAME
--------------------------------------------------------------------------------
ACTION_NAME		     TIMESTAMP
---------------------------- -------------------
DEPT
DELETE			     2021/05/23 08:22:55

```

### 4. Auditoría de grano fino

**Un poco de teoría...**

La **auditoría de grano fino** (FGA) es como una versión extendida de la auditoría estándar. Registra los cambios en datos muy concretos a **nivel de columna**.

Este tipo de auditoría permite crear registros de auditorías basados en una **consulta exacta.** Además permite establecer **condiciones** de auditoría y especificar la columna a auditar.

La diferencia que tiene con respecto a la auditoría estándar es que da la información sobre el cambio que ha sucedido en el registro o dato, mientras que la estándar se graban los detalles mas simples.

Este tipo de auditoría es muy útil si se desea saber que ha pasado de forma **específica** en una tabla o esquema, aunque tenerla activada conlleva una carga mayor y con ella **disminución del rendimiento** de la base de datos, por lo que se debe utilizar para cosas puntuales.

Tarea planteada:
> **4.Realiza una auditoría de grano fino para almacenar información sobre la inserción de empleados del departamento 10 en la tabla emp de scott.**

Esto no es compatible con la versión **Oracle Database 11g Express Edition Release 11.2.0.2.0** , así que lo haremos en **Oracle Database 19c Enterprise Edition**.

Creamos un procedimiento para auditar de forma específica un objeto de una tabla.

```sql
BEGIN
DBMS_FGA.ADD_POLICY (
object_schema => 'c##SCOTT',
object_name => 'EMP',
policy_name => 'politica1',
audit_condition => 'DEPTNO = 10',
statement_types => 'INSERT');
END;
/
```

**Salida (version 19c)**
```sh
SQL> BEGIN
DBMS_FGA.ADD_POLICY (
object_schema => 'c##SCOTT',
object_name => 'EMP',
policy_name => 'politica1',
audit_condition => 'DEPTNO = 10',
statement_types => 'INSERT');
END;
/  2    3    4    5    6    7    8    9  

Procedimiento PL/SQL terminado correctamente.

```

Insertamos los empleados nuevos con el usuario **SCOTT**:

```sql
SQL> INSERT INTO EMP VALUES
(7888, 'ANA', 'CLERK', 7902,
TO_DATE('04-OCT-1995', 'DD-MON-YYYY'), 800, NULL, 10);  2    3  

1 fila creada.

SQL> INSERT INTO EMP VALUES
(8777, 'CLARA', 'SALESMAN', 7839,
TO_DATE('04-DIC-1993', 'DD-MON-YYYY'), 800, NULL, 10);  2    3  

1 fila creada.

SQL> INSERT INTO EMP VALUES
(6663, 'RAFA', 'MANAGER', 7835,
TO_DATE('04-FEB-1980', 'DD-MON-YYYY'), 800, NULL, 10);  2    3  

1 fila creada.
```

Nos salimos del usuario Scott y volvemos al usuario **SYS**

```SQL
SELECT sql_text, CURRENT_USER,TIMESTAMP FROM dba_fga_audit_trail WHERE POLICY_NAME='POLITICA1';
```

Comprobamos que aparece reflejados los **INSERT**:

```sql
SQL> SELECT sql_text, CURRENT_USER,TIMESTAMP FROM dba_fga_audit_trail WHERE POLICY_NAME='POLITICA1';

SQL_TEXT
--------------------------------------------------------------------------------
CURRENT_USER
--------------------------------------------------------------------------------
TIMESTAM
--------
INSERT INTO EMP VALUES
(7888, 'ANA', 'CLERK', 7902,
TO_DATE('04-OCT-1995', 'DD-MON-YYYY'), 800, NULL, 10)
C##SCOTT
23/05/21

INSERT INTO EMP VALUES

SQL_TEXT
--------------------------------------------------------------------------------
CURRENT_USER
--------------------------------------------------------------------------------
TIMESTAM
--------
(8777, 'CLARA', 'SALESMAN', 7839,
TO_DATE('04-DIC-1993', 'DD-MON-YYYY'), 800, NULL, 10)
C##SCOTT
23/05/21

INSERT INTO EMP VALUES
(6663, 'RAFA', 'MANAGER', 7835,

SQL_TEXT
--------------------------------------------------------------------------------
CURRENT_USER
--------------------------------------------------------------------------------
TIMESTAM
--------
TO_DATE('04-FEB-1980', 'DD-MON-YYYY'), 800, NULL, 10)
C##SCOTT
23/05/21

```
## 5. Diferencia entre auditar (by access / by session)

> **5.Explica la diferencia entre auditar una operación by access o by session.**


Es posible auditar **operaciones** (select,insert,update,delete) sobre las tablas. Se puede hacer por medio del comando **AUDIT**, indicando la operación, la tabla y el tipo de seguimiento (by access o by session).

La diferencia principal es que **by access** registra una entrada de auditoría por cada operación realizada y **by session** solo registra una entrada de auditoría por sesión iniciada, por lo que **by access** crea un registro más al detalle pero tambíen baja el **rendimiento** de la base de datos, mientras que **by session** crea un registro más simple y es mucho más ligero y rápido.

Por ejemplo podemos activar la auditoría para las insercciones en la tabla **DEPT** por sesión.

```sql
SQL> AUDIT INSERT ON DEPT BY SESSION;         

Auditoria terminada correctamente.

```

Insertamos dos nuevos departamentos

```sql
INSERT INTO DEPT VALUES (50, 'VENTAS1', 'BARCELONA');
INSERT INTO DEPT VALUES (60, 'VENTAS2', 'SEVILLA');
```

Desde el usuario **sys** hacemos la siguiente consulta de la tabla DBA_AUDIT_OBJECT

```sql
SELECT USERNAME,ACTION_NAME,TIMESTAMP, obj_name from DBA_AUDIT_OBJECT where USERNAME='C##SCOTT';
```

La salida es algo extensa así que no la voy a mostrar entera porque muestra todos los cambios de las operaciones realizadas en la sesión.

```SQL

...
USERNAME
--------------------------------------------------------------------------------
ACTION_NAME		     TIMESTAM
---------------------------- --------
OBJ_NAME
--------------------------------------------------------------------------------
INSERT			     23/05/21
DEPT

C##SCOTT
INSERT			     23/05/21
DEPT
...

```

Si quisieramos hacerla **by access** sería de la siguiente forma y crearía una entrada por cada operación realizada como hicimos al principio.

```sql
AUDIT INSERT ON EMP BY ACCESS;   
```

Nos mostraría lo siguiente:

```sql
SQL> SELECT USERNAME,ACTION_NAME,TIMESTAMP, obj_name from DBA_AUDIT_OBJECT where USERNAME='C##SCOTT';

. . .

USERNAME
--------------------------------------------------------------------------------
ACTION_NAME		     TIMESTAM
---------------------------- --------
OBJ_NAME
--------------------------------------------------------------------------------
EMP

C##SCOTT
INSERT			     23/05/21
EMP

C##SCOTT


USERNAME
--------------------------------------------------------------------------------
ACTION_NAME		     TIMESTAM
---------------------------- --------
OBJ_NAME
--------------------------------------------------------------------------------
EMP

C##SCOTT
INSERT			     23/05/21
EMP

C##SCOTT
. . .
```

## 6. Valores del parámetro AUDIT_TRAIL

> **6. Documenta las diferencias entre los valores db y db_extended del parámetro audit_trail de ORACLE. Demuéstralas poniendo un ejemplo de la información sobre una operación concreta recopilada con cada uno de ellos.**


El parámetro **AUDIT_TRAIL** consta de una serie de valores. Entre ellos tenemos estos dos:

* **VALOR DB**: Este valor activa la auditoría almacenando los datos en la tabla SYS.AUD$ de Oracle. Lo que equivale a 1, o TRUE. 

* **VALOR DB_EXTENDED**: Este valor activa también la auditoría y los datos se almacenan en la misma tabla (SYS.AUD$). Pero tambien se escriben los datos en las columnas SQLBIND y SQLTEXT de la misma tabla.

Vamos a ver un ejemplo:

Activamos la auditoría con el valor **db, extended**.

```SQL
SQL> ALTER SYSTEM SET audit_trail = DB, EXTENDED SCOPE=SPFILE;

System altered.
```

Recordad que tenemos que apagar y encender la base de datos.

```sql
SQL> SHOW PARAMETER AUDIT;

NAME				     TYPE	 VALUE
------------------------------------ ----------- ------------------------------
audit_file_dest 		     string	 /u01/app/oracle/admin/XE/adump
audit_syslog_level		     string
audit_sys_operations		     boolean	 FALSE
audit_trail			     string	 DB, EXTENDED
SQL> 

```

![dbext.png](/images/oracle/dbext.png)


## 7. Version Enterprise Manager

> **Localiza en Enterprise Manager las posibilidades para realizar una auditoría e intenta repetir con dicha herramienta los apartados 1, 3 y 4.**


La versión de oracle a utilizar es **Oracle Database 19c Enterprise Edition Release 19.0.0.0.0 - Production Version 19.3.0.0.0**

```sql

--- Nos conectamos como usuario SYS 

[oracle@bd ~]$ sqlplus / as sysdba

SQL*Plus: Release 19.0.0.0.0 - Production on Sun May 23 14:00:43 2021
Version 19.3.0.0.0

Copyright (c) 1982, 2019, Oracle.  All rights reserved.


Conectado a:
Oracle Database 19c Enterprise Edition Release 19.0.0.0.0 - Production
Version 19.3.0.0.0

--- Activa desde SQL*Plus la auditoría de los intentos de acceso fallidos al sistema. Comprueba su funcionamiento. 

SQL> ALTER SYSTEM SET audit_trail = "DB" SCOPE=SPFILE;

Sistema modificado.

--- Apagamos y encendemos la base de datos (SHUTDOWN, STARTUP)

SQL> SHOW PARAMETER AUDIT

NAME				     TYPE	 VALUE
------------------------------------ ----------- ------------------------------
audit_file_dest 		     string	 /opt/oracle/admin/ORCLCDB/adum
						 p
audit_syslog_level		     string
audit_sys_operations		     boolean	 TRUE
audit_trail			     string	 DB
unified_audit_common_systemlog	     string
unified_audit_sga_queue_size	     integer	 1048576
unified_audit_systemlog 	     string


-- Activamos la auditoria 

SQL> ALTER SYSTEM SET audit_trail = "DB" SCOPE=SPFILE;

Sistema modificado.

SQL> audit session whenever not successful;

Auditoria terminada correctamente.

SQL> audit session by C##SCOTT;

Auditoria terminada correctamente.

-- Hacemos la consulta 

SQL> SELECT USERNAME, OS_USERNAME, TIMESTAMP, ACTION_NAME FROM DBA_AUDIT_SESSION WHERE USERNAME='C##SCOTT';

USERNAME
--------------------------------------------------------------------------------
OS_USERNAME
--------------------------------------------------------------------------------
TIMESTAM ACTION_NAME
-------- ----------------------------
C##SCOTT
oracle
23/05/21 LOGON

C##SCOTT
oracle
23/05/21 LOGON

USERNAME
--------------------------------------------------------------------------------
OS_USERNAME
--------------------------------------------------------------------------------
TIMESTAM ACTION_NAME
-------- ----------------------------

C##SCOTT
oracle
23/05/21 LOGON

C##SCOTT
oracle

USERNAME
--------------------------------------------------------------------------------
OS_USERNAME
--------------------------------------------------------------------------------
TIMESTAM ACTION_NAME
-------- ----------------------------
23/05/21 LOGON

C##SCOTT
oracle
23/05/21 LOGON

C##SCOTT

USERNAME
--------------------------------------------------------------------------------
OS_USERNAME
--------------------------------------------------------------------------------
TIMESTAM ACTION_NAME
-------- ----------------------------
oracle
23/05/21 LOGON

C##SCOTT
oracle
23/05/21 LOGON


USERNAME
--------------------------------------------------------------------------------
OS_USERNAME
--------------------------------------------------------------------------------
TIMESTAM ACTION_NAME
-------- ----------------------------
C##SCOTT
oracle
23/05/21 LOGON

C##SCOTT
oracle
23/05/21 LOGON

USERNAME
--------------------------------------------------------------------------------
OS_USERNAME
--------------------------------------------------------------------------------
TIMESTAM ACTION_NAME
-------- ----------------------------

C##SCOTT
oracle
23/05/21 LOGON

C##SCOTT
oracle

USERNAME
--------------------------------------------------------------------------------
OS_USERNAME
--------------------------------------------------------------------------------
TIMESTAM ACTION_NAME
-------- ----------------------------
23/05/21 LOGOFF

C##SCOTT
oracle
23/05/21 LOGOFF

C##SCOTT

USERNAME
--------------------------------------------------------------------------------
OS_USERNAME
--------------------------------------------------------------------------------
TIMESTAM ACTION_NAME
-------- ----------------------------
oracle
23/05/21 LOGOFF

C##SCOTT
oracle
23/05/21 LOGOFF


USERNAME
--------------------------------------------------------------------------------
OS_USERNAME
--------------------------------------------------------------------------------
TIMESTAM ACTION_NAME
-------- ----------------------------
C##SCOTT
oracle
23/05/21 LOGOFF

C##SCOTT
oracle
23/05/21 LOGOFF

USERNAME
--------------------------------------------------------------------------------
OS_USERNAME
--------------------------------------------------------------------------------
TIMESTAM ACTION_NAME
-------- ----------------------------


16 filas seleccionadas.

--- Podemos incluso crear el procedimiento y ver los intentos fallidos 

Procedimiento creado.

SQL> exec MostrarMensaje
ACCESOS FALLIDOS
________________
-Usuario: C##SCOTT -Fecha: 23/05/21 - 1017: Credenciales incorrectas
-Usuario: C##SCOTT -Fecha: 23/05/21 - 1017: Credenciales incorrectas
-Usuario: SCOTT -Fecha: 23/05/21 - 1017: Credenciales incorrectas
-Usuario: C##SCOTT -Fecha: 23/05/21 - 0: Login correcto
-Usuario: C##SCOTT -Fecha: 23/05/21 - 0: Login correcto
-Usuario: C##SCOTT -Fecha: 23/05/21 - 1017: Credenciales incorrectas
-Usuario: C##SCOTT -Fecha: 23/05/21 - 1017: Credenciales incorrectas
-Usuario: C##SCOTT -Fecha: 23/05/21 - 0: Login correcto
-Usuario: C##SCOTT -Fecha: 23/05/21 - 0: Login correcto
-Usuario: C##SCOTT -Fecha: 23/05/21 - 0: Login correcto
-Usuario: C##SCOTT -Fecha: 23/05/21 - 0: Login correcto
-Usuario: C##SCOTT -Fecha: 23/05/21 - 1017: Credenciales incorrectas
-Usuario: C##SCOTT -Fecha: 23/05/21 - 1017: Credenciales incorrectas
-Usuario: C##SCOTT -Fecha: 23/05/21 - 1017: Credenciales incorrectas

Procedimiento PL/SQL terminado correctamente.


--- Activa la auditoría de las operaciones DML realizadas por SCOTT. Comprueba su funcionamiento.

SQL> AUDIT INSERT TABLE, UPDATE TABLE, DELETE TABLE BY C##SCOTT BY ACCESS;

Auditoria terminada correctamente.

-- INSERTAMOS LOS DATOS CON EL USUARIO SCOTT

-- HACEMOS LA CONSULTA PARA VER EL FUNCIONAMIENTO

SQL> SELECT OBJ_NAME, ACTION_NAME, TIMESTAMP FROM DBA_AUDIT_OBJECT WHERE USERNAME='C##SCOTT';

OBJ_NAME
--------------------------------------------------------------------------------
ACTION_NAME		     TIMESTAM
---------------------------- --------
DEPT
INSERT			     23/05/21

EMP
INSERT			     23/05/21

EMP
INSERT			     23/05/21


OBJ_NAME
--------------------------------------------------------------------------------
ACTION_NAME		     TIMESTAM
---------------------------- --------
EMP
INSERT			     23/05/21

EMP
INSERT			     23/05/21

EMP
INSERT			     23/05/21


OBJ_NAME
--------------------------------------------------------------------------------
ACTION_NAME		     TIMESTAM
---------------------------- --------
EMP
INSERT			     23/05/21

EMP
INSERT			     23/05/21

EMP
INSERT			     23/05/21


OBJ_NAME
--------------------------------------------------------------------------------
ACTION_NAME		     TIMESTAM
---------------------------- --------
EMP
INSERT			     23/05/21

EMP
INSERT			     23/05/21

EMP
INSERT			     23/05/21


OBJ_NAME
--------------------------------------------------------------------------------
ACTION_NAME		     TIMESTAM
---------------------------- --------
DEPT
INSERT			     23/05/21

DEPT
INSERT			     23/05/21

EMP
UPDATE			     23/05/21


OBJ_NAME
--------------------------------------------------------------------------------
ACTION_NAME		     TIMESTAM
---------------------------- --------
DEPT
DELETE			     23/05/21


16 filas seleccionadas.


--- Realiza una auditoría de grano fino para almacenar información sobre la inserción de empleados del departamento 10 en la tabla emp de scott.
*!!!!
```
*!!!!
Esta parte no se puede hacer en la version Oracle Database 11g Express Edition Release 11.2.0.2.0 pero si en Oracle Database 19c Enterprise Edition Release 19.0.0.0.0 como hemos visto anteriormente, por lo que no voy a repetir los mismos pasos.


## 8. Postgresql (1,3,4)

> 8. **Averigua si en Postgres se pueden realizar los apartados 1, 3 y 4. Si es así, documenta el proceso adecuadamente.**

En PostgreSQL no existen medios para hacer auditorías de forma similar a Oracle.

**Hay diversas herramientas** que se han desarrollado para solventar este problema y es que es habitual que salgan ya que es muy importante tener un control sobre la base de datos. 

En el mismo [manual de PostgreSQL](https://www.postgresql.org/docs/8.2/plpgsql-trigger.html#PLPGSQL-TRIGGER-AUDIT-EXAMPLE) nos muestra un procedimiento de activacion PL /pgSQL para auditorías.

Este **ejemplo** registra la hora y el nombre del usuario que hace INSERT, UPDATE Y DELETE.

```SQL
CREATE TABLE emp (
    empname           text NOT NULL,
    salary            integer
);

CREATE TABLE emp_audit( 
    operation         char(1)   NOT NULL,
    stamp             timestamp NOT NULL,
    userid            text      NOT NULL,
    empname           text      NOT NULL,
    salary integer
);

CREATE OR REPLACE FUNCTION process_emp_audit() RETURNS TRIGGER AS $emp_audit$
    BEGIN
        --
        -- Create a row in emp_audit to reflect the operation performed on emp,
        -- make use of the special variable TG_OP to work out the operation.
        --
        IF (TG_OP = 'DELETE') THEN
            INSERT INTO emp_audit SELECT 'D', now(), user, OLD.*;
            RETURN OLD;
        ELSIF (TG_OP = 'UPDATE') THEN
            INSERT INTO emp_audit SELECT 'U', now(), user, NEW.*;
            RETURN NEW;
        ELSIF (TG_OP = 'INSERT') THEN
            INSERT INTO emp_audit SELECT 'I', now(), user, NEW.*;
            RETURN NEW;
        END IF;
        RETURN NULL; -- result is ignored since this is an AFTER trigger
    END;
$emp_audit$ LANGUAGE plpgsql;

CREATE TRIGGER emp_audit
AFTER INSERT OR UPDATE OR DELETE ON emp
    FOR EACH ROW EXECUTE PROCEDURE process_emp_audit();
```

La idea es almacenar los cambios en un único registro como si se tratara del **by session** de Oracle. 

La estructura de la tabla para auditorías sería así:

```sql
CREATE TABLE audit_table (
  ts TIMESTAMP WITH TIME ZONE,
  usr VARCHAR(30),
  tbl VARCHAR(30),
  fld VARCHAR(30),
  pk_name VARCHAR(30),
  pk_value VARCHAR(40),
  mod_type CHAR(6),
  old_val TEXT,
  new_val TEXT,
);
```

Para comprobar su funcionamiento lo que haremos es crear dos tablas que van a ser de ayuda para monitorear:

```sql
CREATE TABLE prueba1 (
  id INTEGER NOT NULL PRIMARY KEY,
  somename VARCHAR(50),
  somevalue INTEGER,
  somets TIMESTAMP
);
CREATE TABLE prueba2 (
  pkid INTEGER NOT NULL PRIMARY KEY,
  testname TEXT,
  testvalue REAL,
  testdate DATE
);
```

Creariamos una función que es el motor de la auditoría en cuestión, creamos dos TRIGGER para cada tabla y probaríamos el funcionamiento de la auditoría.

**Todo está reflejado en el siguiente [enlace](https://alberton.info/postgresql_table_audit.html)**

De forma que podríamos hacer todos los apartados mencionados.


## 9. MySQL (1,3,4)

> 9. **Averigua si en MySQL se pueden realizar los apartados 1, 3 y 4. Si es así, documenta el proceso adecuadamente.**


Necesitamos dos bases de datos, una que es la que vamos a auditar y la otra auxiliar va ser la que se encargue de la auditoría.


**Creamos la base de datos**:

```sql 
create database escuela;
use escuela;
```

Creamos la **tabla** alumnos de ejemplo:
```sql
CREATE TABLE alumnos (
    codigo  VARCHAR(10),
    nombre  VARCHAR(25),
    apellidos VARCHAR(40),
    CONSTRAINT pk_codigo PRIMARY KEY (codigo)   
);
```
Creamos la base de datos **adicional**:

```sql
create database auditorias;
use auditorias
```

Ahora necesitamos una tabla donde registrar las **operaciones**

```sql
CREATE TABLE operaciones (
    codigo  INT(11) NOT NULL AUTO_INCREMENT,
    usuario  VARCHAR(50),
    fecha   DATETIME,
    CONSTRAINT pk_codigo_AUD PRIMARY KEY (codigo)   
);

```

Una vez creada la tabla necesitamos un **Trigger** para auditar las operaciones, en este caso los **INSERT** de la tabla alumnos.

```sql
use escuela

DELIMITER $$
CREATE TRIGGER audit_insert 
    BEFORE INSERT ON escuela.alumnos
    FOR EACH ROW
    BEGIN
        INSERT INTO auditorias.operaciones (usuario, fecha)
        values (CURRENT_USER(), NOW());
    END$$
```

Hacemos un **insert** en la tabla alumnos 

```sql 
INSERT INTO alumnos VALUES ('256','Celia','Garcia Marquez');
INSERT INTO alumnos VALUES ('236','Lorena','Garcia Fernandez');
INSERT INTO alumnos VALUES ('246','Julio','Gonzalez Fernandez');
```

Vemos que se han creado correctamente
```sql
mysql> select * from alumnos;
+--------+--------+--------------------+
| codigo | nombre | apellidos          |
+--------+--------+--------------------+
| 236    | Lorena | Garcia Fernandez   |
| 246    | Julio  | Gonzalez Fernandez |
| 256    | Celia  | Garcia Marquez     |
+--------+--------+--------------------+
3 rows in set (0.00 sec)

```

En la base de datos `auditorias` hacemos la siguiente consulta para ver los registros , como si se tratara de la auditoría en cuestión.

```sql
use auditorias;
select * from operaciones;
```

**Comprobación:**

```sql
mysql> select * from operaciones;
+--------+----------------+---------------------+
| codigo | usuario        | fecha               |
+--------+----------------+---------------------+
|      1 | root@localhost | 2021-05-23 18:26:42 |
|      2 | root@localhost | 2021-05-23 18:26:42 |
|      3 | root@localhost | 2021-05-23 18:26:43 |
+--------+----------------+---------------------+
3 rows in set (0.00 sec)

```

## 10. MongoDB

> **10. Averigua las posibilidades que ofrece MongoDB para auditar los cambios que va sufriendo un documento..**

**MongoDB** incluye la capacidad de auditar instancias. La función de auditoría permite a los administradores y usuarios llevar un seguimiento del sistema, como hemos estado comentando a lo largo de todo el post.

La función de auditoría puede grabar los eventos en:

*  syslog 
*  un fichero JSON o BSON 
*  Directamente en la consola

Se usa el parámetro **--auditDestination** para habilitar la auditoría y especificar donde vamos a guardar el seguimiento.


* Para guardar en el **syslog**:

```sh
mongod --dbpath /var/lib/mongodb --auditDestination syslog
```

* Salida en la **consola**:

```sh
mongod --dbpath /var/lib/mongodb --auditDestination console
```

* Salida en un **fichero JSON**

```sh
mongod --dbpath /var/lib/mongodb --auditDestination file --auditFormat JSON --auditPath /var/log/mongodb/auditLog.json
```

También se puede especificar en el **fichero de configuración de mongodb** de esta forma:

```sql
# mongod.conf

# for documentation of all options, see:
#   http://docs.mongodb.org/manual/reference/configuration-options/

# Where and how to store data.
storage:
  dbPath: /var/lib/mongodb
  journal:
    enabled: true
auditLog:
   destination: file
   format: JSON
   path: /var/log/mongodb/auditLog.json


```

> **11. Averigua si en MongoDB se pueden auditar los accesos al sistema.**


Podríamos auditar los accesos al sistema bajo las mismas opciones anteriores, ademas de que se puede usar un parámetro **--auditFilter** como en el siguiente comando.

```sh
mongod --dbpath /var/lib/mongodb --auth --auditDestination file --auditFilter '{ atype: "authenticate", "param.db": "test" }' --auditFormat JSON --auditPath /var/log/mongodb/auditLog.json
```

Fuentes:

https://docs.oracle.com/cd/B19306_01/server.102/b14237/initparams016.htm#REFRN10006

https://alberton.info/postgresql_table_audit.html

https://costaricamakers.com/?p=2149

https://docs.mongodb.com/manual/tutorial/configure-audit-filters/

https://docs.mongodb.com/manual/tutorial/configure-auditing/

https://www.percona.com/blog/2017/03/03/mongodb-audit-log-why-and-how/

