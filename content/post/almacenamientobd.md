+++
author = "Celia García Márquez"
title = "Gestión del almacenamiento. Gestores de bases de datos"
date = "2021-05-09"
description = "Gestión del almacenamiento. Gestores de Bases de datos."
tags = [
    "oracle","postgres",'mariadb'
]
thumbnail= "images/almacenamiento/banner1.png"
+++


En esta entrada se van a ver diferentes formas de gestionar el almacenamiento en los distintos gestores de bases de datos, Postgres, Oracle y MariaDB/MySql.


> Para amenizar el post he separado el caso de Oracle en el siguiente post:


## [1. Gestión de almacenamiento en ORACLE](https://www.celiagm.es/post/almacenamiento_oracle/)

![oracle.png](/images/almacenamiento/oracle.png)


## 2. Gestión de almacenamiento en POSTGRESQL. 

![postgres.png](/images/almacenamiento/postgres.png)

> Averigua si pueden establecerse claúsulas de almacenamiento para las tablas o los espacios de tablas en Postgres.


**Postgres** no puede establacer cláusulas de almacenamiento como lo hace Oracle. La diferencia entre ellos es que Oracle lo tiene implementado desde las primeras versiones y Postgresql no. Por lo que Postgres utiliza **tablespaces** de una forma diferente. 

Postgresql tiene varias funcionalidades que permite controlar el espacio de almacenamiento de forma específica. Estas funcionalidades las menciono en el siguiente [post](https://www.celiagm.es/post/limitaciones_almacenamiento_gestores_bd/)



## 3. Gestión de almacenamiento en MySQL

![mysql.png](/images/almacenamiento/mysql.png)

> Averigua si existe el concepto de índice en MySQL y si coincide con el existente en ORACLE. Explica los distintos tipos de índices existentes.


El concepto de **índice** sí existe. MySQL los usa para encontrar filas que contienen los valores específicos de las columnas empleadas en una consulta. Esto hace que aumente la velocidad de búsqueda ya que si no existiesen empezaría a buscar desde la primera fila hasta la que se demanda y a razón de eso se demoraría más. 

Coincide pues con los índices en Oracle ya que se emplean igualmente para la obtención de la información de tablas con mayor rapidez y eficiencia.

Los tipos de índice que existen en MYSQL son los siguientes: 

* INDEX (NON-UNIQUE) Se trata de un índice normal, no único. Admite valores duplicados para las columnas. 
* UNIQUE. Se refiere a un índice en el que todas las columnas deben tener un valor único, en otras palabras, no admite valores duplicados.
* PRIMARY. Las columnas deben tener un valor único pero sólo puede existir un índice PRIMARY en cada una de las tablas. 
* FULLTEXT. Estos índices se emplean para buscar tipos texto (CHAR, VARCHAR O TEXT), 
* SPATIAL. Sirven para realizar búsquedas de datos de formas geométricas representadas en el gráfico.


Para crear un índice se emplea la siguiente estructura:

```sql
«CREATE [UNIQUE | FULLTEXT | SPATIAL] INDEX nombreindice ON nombretabla (nombredecolumna_columnas…) tipoindice;»;
```

Ejemplo:

```sql
CREATE UNIQUE INDEX mi_indice_unico ON mi_tabla (mi_columna) USING HASH;

-- Otro ejemplo 

create index fecha on partidos (fecha);

```

Si quisieramos borrar un índice lo haríamos de la siguiente forma:

```sql

--Ejemplo 

drop index equipolocal_visitante_fecha on partidos
```

Si queremos ver todos los índices en mysql ejecutamos la siguiente sentencia:

```sql
SHOW INDEX FROM nombretabla [FROM db_name];
```

La sintaxis completa para crear un **índice** la encuentras en la [documentacion oficial](https://mariadb.com/kb/en/create-index/)



## 4. Gestión de almacenamiento en MongoDB

![mongodb.png](/images/almacenamiento/mongodb.png)

> Explica los distintos motores de almacenamiento que ofrece MongoDB, sus características principales y en qué casos es más recomendable utilizar cada uno de ellos.


El motor de almacenamiento es el componente de la base de datos que se encarga de administrar el almacenamiento de datos propiamente como ya sabemos. MongoDB dispone de varios motores de almacenamiento, se usa uno u otro dependiendo del trabajo que vayamos a realizar.

* **WiredTiger**. Es el motor de almacenamiento por defecto que se inicia en MongoDB 3.2. Es adecuado para la mayoria de los usos y el recomendable para empezar a usar MongoDB. Este motor proporciona un modelo de simultaneidad a nivel de documento, puntos de control y compresión entre otros. Es adecuado para sacar el mayor rendimiento posible.

* **In-Memory Storage Engine (En memoria)**. ES un motor que en lugar de almacenar documentos en el disco si no que los retiene en memoria para tener los datos más mano, es decir con más rapidez y más eficiencia. También proporciona simultaneidad a nivel de documento para las operaciones de escritura, así permitiendo modificar al usuario diferentes documentos de una colección al mismo tiempo.



Si queremos saber el motor de almacenamiento que está usando mongodb actualmente:

```sql
db.serverStatus().storageEngine
{ "name" : "wiredTiger" }

```
Si queremos saber todos los detalles hacemos lo siguiente

```sql
db.serverStatus().wiredTiger
```

### Otros motores del almacenamiento

Según la documentación de MongoDB:

> A partir de la versión 4.2, MongoDB elimina el motor de almacenamiento MMAPv1 obsoleto.

A pesar de quedar obsoleto debemos recalcar características importantes sobre este motor las cuales son las siguientes:

* Lecturas de volumenes de mayor tamaño.
* Insercciones de mayor tamaño.
* Gran utilización de la memoria del sistema ya que se usa como caché. Además cada 60'' el motor descarga los cambios en los datos del disco y los guarda en memoria caché.


Cabe mencionar otros motores de versiones anteriores pero que en este post no voy a explicar porque actualmente no se usan.

* Fusión-io
* TokuMX

Fuentes:

https://docs.mongodb.com/manual/core/storage-engines/

https://severalnines.com/database-blog/why-you-should-still-be-using-mmapv1-storage-engine-mongodb
