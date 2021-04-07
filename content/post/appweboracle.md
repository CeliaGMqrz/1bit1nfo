+++
author = "Celia García Márquez"
title = "Aplicación web python, flask y Oracle"
date = "2021-04-06"
description = "Crear una aplicación web que interactúe con la base de datos Oracle"
tags = [
    "oracle",
]
thumbnail= "images/mysql/ora.png"
+++

## Objetivo

Realización de una aplicación web en cualquier lenguaje que conecte con el servidor ORACLE tras autenticarse y muestre alguna información almacenada en el mismo.


## Requisitos

* Máquina virtual con Centos8. En este caso he usado virt-manager para la virtualización del Centos8 desde esta [imagen](https://ftp.rediris.es/mirror/CentOS/8/BaseOS/x86_64/os/images/boot.iso). Esta máquina cuenta con una interfaz de red puente a la máquina anfitriona.

* Una segunda máquina virtual. Puedes usar una clonación de la primera despues de la instalación de Oracle para amenizar el trabajo.


## Primeros pasos

Para acortar un poco la documetación he dividido este post en varios, así que antes de comenzar a hacer la aplicación web se han seguido estos pasos:

  1. [Instalacion de Oracle sobre CentOS8](https://www.celiagm.es/post/insta_oracle/)

  2. [Habilitar el acceso remoto a la base de datos](https://www.celiagm.es/post/clienteoracle/)


## Aplicacion web que conecte con ORACLE 

Vamos a usar la máquina servidor con CentOS 8 para crear la aplicación.

### Entorno de trabajo con python 

* Tenemos que tener instalado python3 

```sh
dnf install python3 -y
python3 -V

#Salida:
Python 3.6.8

```

* Instalamos las herramientas de desarrollo en CentOS 

```sh
dnf -y groupinstall development
```


* Configuramos un entorno virtual 

```sh
mkdir entornos
cd entornos
python3 -m venv mientorno
```

* Actualizamos e instalamos el paquete para interactuar con oracle con python

```sh
[centos@localhost entornos]$ source mientorno/bin/activate

(mientorno) [centos@localhost entornos]$ pip install --upgrade pip
Collecting pip
  Downloading https://files.pythonhosted.org/packages/fe/ef/60d7ba03b5c442309ef42e7d69959f73aacccd0d86008362a681c4698e83/pip-21.0.1-py3-none-any.whl (1.5MB)
    100% |████████████████████████████████| 1.5MB 1.0MB/s 
Installing collected packages: pip
  Found existing installation: pip 9.0.3
    Uninstalling pip-9.0.3:
      Successfully uninstalled pip-9.0.3
Successfully installed pip-21.0.1

(mientorno) [centos@localhost entornos]$ pip freeze

(mientorno) [centos@localhost entornos]$ deactivate

(mientorno) [centos@localhost entornos]$ pip install cx_Oracle
Collecting cx_Oracle
  Using cached cx_Oracle-8.1.0-cp36-cp36m-manylinux1_x86_64.whl (803 kB)
Installing collected packages: cx-Oracle
Successfully installed cx-Oracle-8.1.0

```
## Aplicación simple en python

* Creamos una carpeta de trabajo y creamos el `app.py`

```sh
(mientorno) [centos@localhost entornos]$ mkdir app_oracle
(mientorno) [centos@localhost entornos]$ cd app_oracle/
(mientorno) [centos@localhost app_oracle]$ nano app.py
(mientorno) [centos@localhost app_oracle]$ 
```
`app.py`

```sh
import cx_Oracle

connection = cx_Oracle.connect(
    user="c##celia",
    password="celia",
    dsn="localhost/ORCLCDB")


print("\n Enhorabuena estás conectad@ a la base de datos!!!!")

cursor = connection.cursor()

# Consultas

# Mostrar todas las tablas

print("\n TABLAS DISPONIBLES")

print(" ")
cursor.execute("select * from cat")
res = cursor.fetchall()

for linea in res:
    linea = list(linea)
    print(linea[0])

# Mostrar los registros de una tabla en concreto 

print("Mostrar registros ")

print(" ")

tabla=str(input("¿De qué tablas quieres mostrar los registros?"))

if tabla.upper() == 'ALUMNOS':

    cursor.execute("select * from alumnos")
    res = cursor.fetchall()

    for linea in res:
        print(linea)

elif tabla.upper() == "CURSOS":

    cursor.execute("select * from cursos")
    res = cursor.fetchall()

    for linea in res:
        print(linea)

elif tabla.upper() == "MATRICULAS":

    cursor.execute("select * from matriculas")
    res = cursor.fetchall()

    for linea in res:
        print(linea)

else:
    print("tabla no registrada")

```
Este código es un código muy simple que si se ejecuta hace lo siguiente:

![app.py](/images/mysql/app.jpeg)


## Aplicación web con flask, python y Oracle 

Ahora vamos hacer una aplicación parecida pero sirviendola en internet con una plantilla.

* Exportamos las variables pertinentes 

```sh

[oracle@bd ~]$ export PYTHON_CONNECTSTRING=localhost/ORCLCDB
[oracle@bd ~]$ export PYTHON_PASSWORD=celia
[oracle@bd ~]$ export PYTHON_USERNAME=c##celia

```
* El código lo puedes encontrar en el siguiente [repositorio](https://github.com/CeliaGMqrz/app_oracle_flask)

Siendo propiamente el mismo este -> [demo.py](https://github.com/CeliaGMqrz/app_oracle_flask/blob/master/demo.py)

> Tenemos que instalar con `pip install -r requirements`, los paquetes que vienen en el fichero requirements.

* Ejecutamos la app web 

```sh
(mientorno) [oracle@bd app_oracle_flask]$ ls
demo.py  Procfile  README.md  requirements.txt  static  templates
(mientorno) [oracle@bd app_oracle_flask]$ python3 demo.py 
Connecting to localhost/ORCLCDB
 * Serving Flask app "demo" (lazy loading)
 * Environment: production
   WARNING: This is a development server. Do not use it in a production deployment.
   Use a production WSGI server instead.
 * Debug mode: off
 * Running on http://127.0.0.1:8080/ (Press CTRL+C to quit)
```

* Vamos al navegador y comprobamos que funciona

captura de pantalla de la pagina funcionando 

![appweb.jpeg](/images/mysql/appweb.jpeg)