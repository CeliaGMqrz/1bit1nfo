+++
author = "Celia García Márquez"
title = "Instalacion de MongoDB y acceso remoto desde un cliente local"
date = "2021-03-16"
description = "Instalacion de Mongodb sobre debian buster y acceso remoto"
tags = [
    "mongodb",
]
thumbnail= "images/mongodb/1.png"
+++


# Instalación de un servidor MongoDB

Instalación de un servidor MongoDB y configuración para permitir el acceso remoto desde la red local.

## Instalación de MongoDB sobre Debian Buster

Para instalar MongoDB vamos a utilizar la guía que se encuentra en la [página oficial de MongoDB](https://docs.mongodb.com/manual/tutorial/install-mongodb-on-debian/)

* Importar la clave pública

```powershell
wget -qO - https://www.mongodb.org/static/pgp/server-4.4.asc | sudo apt-key add -
```

* Agregar el repositorio

```powershell
echo "deb http://repo.mongodb.org/apt/debian buster/mongodb-org/4.4 main" | sudo tee /etc/apt/sources.list.d/mongodb-org-4.4.list
```

* Ahora vamos a instalar los paquetes de MongoDB escogiendo la versión más estable.

```powershell
apt-get install -y mongodb-org
```

* Ponemos en marcha el gestor y vemos que efectivamente está en funcionando

```powershell
systemctl start mongod
systemctl status mongod
```

```powershell
root@debian:/etc/apt/sources.list.d# systemctl status mongod
● mongod.service - MongoDB Database Server
   Loaded: loaded (/lib/systemd/system/mongod.service; disabled; vendor preset: enabled)
   Active: active (running) since Tue 2020-12-08 20:46:01 CET; 2s ago
     Docs: https://docs.mongodb.org/manual
 Main PID: 3406 (mongod)
   Memory: 59.2M
   CGroup: /system.slice/mongod.service
           └─3406 /usr/bin/mongod --config /etc/mongod.conf

dic 08 20:46:01 debian systemd[1]: Started MongoDB Database Server.

```
## Creación de la base de datos de prueba, usuario administrador e introduccir datos

Para empezar a trabajar con mongodb, una vez se haya instalado solo debemos de ejecutar lo siguiente

```powershell
mongo
```

Y estaremos dentro de la shell interactiva de mongo

```powershell
usuario@debian:~$ mongo
MongoDB shell version v4.4.2
connecting to: mongodb://127.0.0.1:27017/?compressors=disabled&gssapiServiceName=mongodb
Implicit session: session { "id" : UUID("caecd2a1-a687-47a8-bf59-69e2a1644e33") }
MongoDB server version: 4.4.2
Welcome to the MongoDB shell.
For interactive help, type "help".
For more comprehensive documentation, see
	https://docs.mongodb.com/
Questions? Try the MongoDB Developer Community Forums
	https://community.mongodb.com
---
The server generated these startup warnings when booting:
        2020-12-13T12:36:05.865+01:00: Using the XFS filesystem is strongly recommended with the WiredTiger storage engine. See http://dochub.mongodb.org/core/prodnotes-filesystem
        2020-12-13T12:36:06.531+01:00: Access control is not enabled for the database. Read and write access to data and configuration is unrestricted
        2020-12-13T12:36:06.531+01:00: /sys/kernel/mm/transparent_hugepage/enabled is 'always'. We suggest setting it to 'never'
---
---
        Enable MongoDB's free cloud-based monitoring service, which will then receive and display
        metrics about your deployment (disk utilization, CPU, operation statistics, etc).

        The monitoring data will be available on a MongoDB website with a unique URL accessible to you
        and anyone you share the URL with. MongoDB may use this information to make product
        improvements and to suggest MongoDB products and deployment options to you.

        To enable free monitoring, run the following command: db.enableFreeMonitoring()
        To permanently disable this reminder, run the following command: db.disableFreeMonitoring()
---
>

```

Con el siguiente comando podemos ver las bases de datos que tenemos actualemente

```powershell
> show dbs
admin   0.000GB
config  0.000GB
local   0.000GB
```

### Crear la base de datos

En mongodb no exite un comando 'create' , ejecutaremos 'use' para cambiar de base de datos y si la misma no existe se crea automáticamente.

```powershell
> use academia
switched to db academia
```

Si volvemos a ejecutar 'show dbs' no aparecerá la nueva base de datos que hemos creado ya que está vacía, necesitaremos introducir los datos.

### Crear un usuario

Antes de crear un usuario con el que vamos a trabajar tenemos que crear el usuario administrador con el rol de root en la base de datos Admin

```powershell
use admin
db.createUser({
  user: "root",
  pwd: "pass",
  roles : [ "root" ]
})
```

Una vez creado entramos con el usuario root

```powershell
mongo -u root -p pass
```

Ahora para crear un usuario en la nueva base de datos, haremos lo siguiente, que consiste en crear un usuario con su nombre y contraseña y además un rol que será el propietario de la base de datos que esta en uso actualmente, en este caso, 'academia'.

```powershell
db.createUser(
{
user: "celia",
pwd: "celia",
roles: ["dbOwner"]
}
)
```

Nos muestra que se ha creado correctamente.

```powershell
> db.createUser(
... {
... user: "celia",
... pwd: "celia",
... roles: ["dbOwner"]
... }
... )
Successfully added user: { "user" : "celia", "roles" : [ "dbOwner" ] }

```

Podemos ver los usuarios creados con el comando

```powershell
> show users;
{
	"_id" : "academia.celia",
	"userId" : UUID("d4f97ec7-67a8-487c-b3b8-9ac24d076a3f"),
	"user" : "celia",
	"db" : "academia",
	"roles" : [
		{
			"role" : "dbOwner",
			"db" : "academia"
		}
	],
	"mechanisms" : [
		"SCRAM-SHA-1",
		"SCRAM-SHA-256"
	]
}

```

Ahora podemos cerrar sesión y iniciar con el nuevo usuario

```powershell
mongo -u celia -p --authenticationDatabase academia
```

Tambien podemos identificarnos de la siguiente forma

Ejecutamos:

```powershell
mongo
```

Y después dentro de la shell de mongo

```powershell
> use academia
switched to db academia
> db.auth("celia","celia")
1
```

### Introduccir datos de prueba

```powershell
db.alumns.insert(
[

            {
                "nombre": "Manuel",
                "apellidos": "Pérez",
                "fecha_nacimiento": "1998-03-03",
                "asignaturas":["lengua castellana","matemáticas"]
            },
            {
                "nombre": "Celia",
                "apellidos": "García",
                "fecha_nacimiento": "1995-10-04",
                "asignaturas":["física","matemáticas"]
            },
            {
                "nombre": "Laura",
                "apellidos": "Hernandez",
                "fecha_nacimiento": "1995-08-04",
                "asignaturas":["inglés","matemáticas"]
            },
            {
                "nombre": "Miguel",
                "apellidos": "García",
                "fecha_nacimiento": "1995-07-03",
                "asignaturas":["inglés","lengua castellana","francés"]
            },
            {
                "nombre": "Aroa",
                "apellidos": "Rodriguez",
                "fecha_nacimiento": "1996-08-10",
                "asignaturas":["matemáticas","francés"]
            }
]
)
```
Vemos que se han insertado:

```powershell
> db.alumns.find().pretty();
{
	"_id" : ObjectId("5fd6568d3bab1b058f9c31a6"),
	"nombre" : "Manuel",
	"apellidos" : "Pérez",
	"fecha_nacimiento" : "1998-03-03",
	"asignaturas" : [
		"lengua castellana",
		"matemáticas"
	]
}
{
	"_id" : ObjectId("5fd6568d3bab1b058f9c31a7"),
	"nombre" : "Celia",
	"apellidos" : "García",
	"fecha_nacimiento" : "1995-10-04",
	"asignaturas" : [
		"física",
		"matemáticas"
	]
}
{
	"_id" : ObjectId("5fd6568d3bab1b058f9c31a8"),
	"nombre" : "Laura",
	"apellidos" : "Hernandez",
	"fecha_nacimiento" : "1995-08-04",
	"asignaturas" : [
		"inglés",
		"matemáticas"
	]
}
{
	"_id" : ObjectId("5fd6568d3bab1b058f9c31a9"),
	"nombre" : "Miguel",
	"apellidos" : "García",
	"fecha_nacimiento" : "1995-07-03",
	"asignaturas" : [
		"inglés",
		"lengua castellana",
		"francés"
	]
}
{
	"_id" : ObjectId("5fd6568d3bab1b058f9c31aa"),
	"nombre" : "Aroa",
	"apellidos" : "Rodriguez",
	"fecha_nacimiento" : "1996-08-10",
	"asignaturas" : [
		"matemáticas",
		"francés"
	]
}


```

Otros comandos útiles:

* Eliminar una collección entera

```powershell
db.alumns.drop();
```

* Eliminar un documento

```powershell
db.alumns.remove({"nombre": "Celia"});
```

## Acceso remoto a mongo

Una vez creado los usuarios, el administrador, la base de datos y la colleción, vamos a hacer que cuando el servidor se encienda se inicie automáticamente el servicio de mongod.

```powershell
root@debian:~# sudo systemctl enable --now mongod
Created symlink /etc/systemd/system/multi-user.target.wants/mongod.service → /lib/systemd/system/mongod.service.
```

Ahora sí, vamos a utilizar un cliente para que pueda acceder a la base de datos de forma remota. Para eso vamos a editar el siguiente fichero

```powershell
nano /etc/mongod.conf
```
En el parámetro bindIp le pasaremos la dirección 0.0.0.0 la cuál nos permite acceder desde cualquier máquina.

Además habilitaremos la seguridad para poder autenticarnos.

```powershell
# network interfaces
network:
  port: 27017
  bindIp: 0.0.0.0  

#security:
security:
    authorization: 'enabled'

```

Tendremos otra máquina virtual que va a ser nuestro cliente, este cliente estará en la misma red.

```powershell
vagrant@cliente:~$ ip a
1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue state UNKNOWN group default qlen 1000
    link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
    inet 127.0.0.1/8 scope host lo
       valid_lft forever preferred_lft forever
    inet6 ::1/128 scope host 
       valid_lft forever preferred_lft forever
2: eth0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc pfifo_fast state UP group default qlen 1000
    link/ether 08:00:27:8d:c0:4d brd ff:ff:ff:ff:ff:ff
    inet 10.0.2.15/24 brd 10.0.2.255 scope global dynamic eth0
       valid_lft 85065sec preferred_lft 85065sec
    inet6 fe80::a00:27ff:fe8d:c04d/64 scope link 
       valid_lft forever preferred_lft forever
3: eth1: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc pfifo_fast state UP group default qlen 1000
    link/ether 08:00:27:fa:db:05 brd ff:ff:ff:ff:ff:ff
    inet 10.0.1.2/24 brd 10.0.1.255 scope global eth1
       valid_lft forever preferred_lft forever
    inet6 fe80::a00:27ff:fefa:db05/64 scope link 
       valid_lft forever preferred_lft forever

```

Comprobamos que desde el **cliente** podemos conectarnos de forma remota, especificando el usuario, la contraseña, la dirección ip de nuestro servidor de mongo y a la base de datos a la que nos conectamos.

```sh
vagrant@cliente:~$ mongo "mongodb://celia:celia@10.0.1.5:27017/academia"
MongoDB shell version v4.4.4
connecting to: mongodb://10.0.1.5:27017/academia?compressors=disabled&gssapiServiceName=mongodb
Implicit session: session { "id" : UUID("cc6c341c-df2b-4d45-9fba-b94945357754") }
MongoDB server version: 4.4.4
> db.alumns.find().pretty();
{
	"_id" : ObjectId("605112f7e81270a6e06234b8"),
	"nombre" : "Manuel",
	"apellidos" : "Pérez",
	"fecha_nacimiento" : "1998-03-03",
	"asignaturas" : [
		"lengua castellana",
		"matemáticas"
	]
}
{
	"_id" : ObjectId("605112f7e81270a6e06234b9"),
	"nombre" : "Celia",
	"apellidos" : "García",
	"fecha_nacimiento" : "1995-10-04",
	"asignaturas" : [
		"física",
		"matemáticas"
	]
}
{
	"_id" : ObjectId("605112f7e81270a6e06234ba"),
	"nombre" : "Laura",
	"apellidos" : "Hernandez",
	"fecha_nacimiento" : "1995-08-04",
	"asignaturas" : [
		"inglés",
		"matemáticas"
	]
}
{
	"_id" : ObjectId("605112f7e81270a6e06234bb"),
	"nombre" : "Miguel",
	"apellidos" : "García",
	"fecha_nacimiento" : "1995-07-03",
	"asignaturas" : [
		"inglés",
		"lengua castellana",
		"francés"
	]
}
{
	"_id" : ObjectId("605112f7e81270a6e06234bc"),
	"nombre" : "Aroa",
	"apellidos" : "Rodriguez",
	"fecha_nacimiento" : "1996-08-10",
	"asignaturas" : [
		"matemáticas",
		"francés"
	]
}

```

![captura1.png](/images/mongodb/captura1.png)