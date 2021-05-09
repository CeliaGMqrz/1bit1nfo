# Gestión del almacenamiento en ORACLE

**CONCEPTOS PREVIOS**

### ¿Qué es un Tablespace?

Son las unidades lógicas de almacenamiento que componen una base de datos, es decir, son asignaciones de espacio en la base de datos que permiten contener objetos persistentes del esquema. O en otras palabras, es una especie de directorio que contiene tablas, índices.. que se corresponden con uno o varios ficheros del sistema (datafiles).

Al instalar ORACLE se crean varios tablespaces:

* SYSTEM: Guardado en el diccionario de datos y otros objetos del sistema.
* SYSAUX: Componentes opcionales de ORACLE.
* USERS: Objetos de los usuarios.
* TEMP: Para guardar los objetos temporales (sort, productos cartesianos, etc)
* UNDOTBS01: Segmento de ROLLBACK.

En el siguiente gráfico podemos ver los diferentes elementos que vamos a definir posteriormente.

![bloque.png](/images/almacenamiento/bloque.png)

* Un **bloque de datos** es la **cantidad mínima de información** que se puede recuperar en los dispositivos de almacenamiento. Su tamaño debe ser múltiplo de bloque de disco definido en el sistema de operativo anfitrión y se define con *DB_BLOCK_SIZE**. 
* Una **extensión** es un conjunto de **bloques de datos** contiguos reservados de una vez.
* Un **tablespace** se divide en segmentos, uno para cada objeto. 
* Un **segmento** es un conjunto de **extensiones**, pertenecientes al mismo *tablespace* y que guardan los datos correspondientes a un objeto concreto. Existen cuatro tipos de segmentos (de tabla, de índice, temporal y de undo.)

Cuando todas las extensiones de un segmento se llenan, se reserva una nueva buscando entre los distintos *datafiles* del tablespace alguno con suficientes bloques de datos libres contiguos.

Las extensiones de un segmento no se liberan salvo que se ejecute un *DROP* del objeto correspondiente a dicho segmento, *TRUNCATE* o *ALTER TABLE DEALLOCATE UNUSED*.


