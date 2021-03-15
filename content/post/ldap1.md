---
title: "Instalación y configuración inicial de OpenLDAP"
date: 2020-12-14T20:18:59+01:00
draft: false
toc: false
images:
tags: ['ldap']
---


Descripción:

Realiza la instalación y configuración básica de OpenLDAP en frestón utilizando como base el nombre DNS asignado.

Crea dos unidades organizativas, una para personas y otra para grupos.

_____________________________________________________________________________________

## 1. Conceptos previos

**LDAP** corresponde a **Lightweight Directory Access Protocol**, que significa protocolo ligero de acceso a directorios. Es decir, se trata de un protocolo que permite acceder a través de la red a información guardada en directorios en un sevidor. Utiliza un sistema de base de datos no relacional siendo así más rápido.

Utiliza un sistema jerárquico, o en forma de árbol haciendo uso de directorios. Aquí se guarda información variada de personas y objetos.

## 2. Instalación y configuración de LDAP

Antes de instalar ldap nos vamos a asegurar que nuestro sistema está en condiciones y reúne los requisitos para su instalación.

* El sistema debe de tener bien configurada la hora
* La máquina debe de estar actualizada
* El nombre de la máquina está configurada correctamente tanto el simple como el completo, ejecutando, **hostname** y **hostname -f** comprobamos esto

En mi caso:

```powershell
root@freston:/home/debian# hostname
freston
root@freston:/home/debian# hostname -f
freston.celia.gonzalonazareno.org
```

Vamos a instalar LDAP sobre Debian Buster, utilizaremos la paquetería de Debian para instalarlo de la siguiente forma

```powershell
sudo apt-get install sldap
```

Además vamos a utilizar unas herramientas muy útiles para utilizar nuestro sistema de directorios

```powershell
sudo apt-get install ldap-utils
```

Una vez instalado el software y las herramientas vamos a reconfigurar nuestro sistema de directorios para determinar nuestro nombre y configurar una contraseña para el adminsitrador

```powershell
dpkg-reconfigure -plow slapd
```

Nos mostrará varias ventanas en varios pasos, tendremos que:

1. Indicar nuestro nombre de dominio DNS, en mi caso sera **freston.celia.gonzalonzareno.org** 
2. Indicar el nombre de la organización en mi caso será **IES Gonzalo Nazareno**.
3. Indicar la contraseña que usaremos de administrador. 
4. Nos preguntará si queremos cambiar el motor de base de datos que vamos a usar en mi caso lo he dejado por defecto **MDB**.
5. Nos preguntará si queremos que la base de datos se elimine cuando purguemos ldap, le diremos que sí.
6. Nos preguntará si queremos dejar el antiguo directorio que viene por defecto y lo dejamos en sí.

## 3. Crear unidades organizativas

Para crear las unidades organizativas vamos a usar un fichero con extensión **ldif** que es un estándar con configuraciones de LDAP. Ahí vamos a agregar el contenido de los nuevos registros que vamos a añadir.

Vamos a crear las **unidades organizativas** de esta forma:

**personas**

```powershell
root@freston:/home/debian# nano personas.ldif 
```

```powershell
dn: ou=People,dc=freston,dc=celia,dc=gonzalonazareno,dc=org
objectClass: top
objectClass: organizationalUnit
ou: People
```

```powershell

root@freston:/home/debian# ldapadd -x -D 'cn=admin,dc=freston,dc=celia,dc=gonzalonazareno,dc=org' -W -f personas.ldif 
Enter LDAP Password: 
adding new entry "ou=People,dc=freston,dc=celia,dc=gonzalonazareno,dc=org"
```

**grupos**

```powershell
root@freston:/home/debian# nano grupos.ldif
```

```powershell
dn: ou=Group,dc=freston,dc=celia,dc=gonzalonazareno,dc=org
objectClass: top
objectClass: organizationalUnit
ou: Group
```

```powershell
root@freston:/home/debian# ldapadd -x -D 'cn=admin,dc=freston,dc=celia,dc=gonzalonazareno,dc=org' -W -f grupos.ldif 
Enter LDAP Password: 
adding new entry "ou=Group,dc=freston,dc=celia,dc=gonzalonazareno,dc=org"
```

Vemos que se han creado correctamente "en bruto" usando el comando:

```powershell
slapcat
```

```powershell
dn: ou=People,dc=freston,dc=celia,dc=gonzalonazareno,dc=org
objectClass: top
objectClass: organizationalUnit
ou: People
structuralObjectClass: organizationalUnit
entryUUID: edfb19f6-d276-103a-8e15-9befe2d527e2
creatorsName: cn=admin,dc=freston,dc=celia,dc=gonzalonazareno,dc=org
createTimestamp: 20201214164116Z
entryCSN: 20201214164116.484795Z#000000#000#000000
modifiersName: cn=admin,dc=freston,dc=celia,dc=gonzalonazareno,dc=org
modifyTimestamp: 20201214164116Z

dn: ou=Group,dc=freston,dc=celia,dc=gonzalonazareno,dc=org
objectClass: top
objectClass: organizationalUnit
ou: Group
structuralObjectClass: organizationalUnit
entryUUID: 381306fc-d277-103a-8e16-9befe2d527e2
creatorsName: cn=admin,dc=freston,dc=celia,dc=gonzalonazareno,dc=org
createTimestamp: 20201214164320Z
entryCSN: 20201214164320.793017Z#000000#000#000000
modifiersName: cn=admin,dc=freston,dc=celia,dc=gonzalonazareno,dc=org
modifyTimestamp: 20201214164320Z

```
Interactuando, con el comando:

```powershell
ldapsearch -x -D "cn=admin,dc=freston,dc=celia,dc=gonzalonazareno,dc=org" -b dc=freston,dc=celia,dc=gonzalonazareno,dc=org -W
```

```powershell
root@freston:/home/debian# ldapsearch -x -D "cn=admin,dc=freston,dc=celia,dc=gonzalonazareno,dc=org" -b dc=freston,dc=celia,dc=gonzalonazareno,dc=org -W
Enter LDAP Password: 
# extended LDIF
#
# LDAPv3
# base <dc=freston,dc=celia,dc=gonzalonazareno,dc=org> with scope subtree
# filter: (objectclass=*)
# requesting: ALL
#

# freston.celia.gonzalonazareno.org
dn: dc=freston,dc=celia,dc=gonzalonazareno,dc=org
objectClass: top
objectClass: dcObject
objectClass: organization
o: IES Gonzalo Nazareno
dc: freston

# admin, freston.celia.gonzalonazareno.org
dn: cn=admin,dc=freston,dc=celia,dc=gonzalonazareno,dc=org
objectClass: simpleSecurityObject
objectClass: organizationalRole
cn: admin
description: LDAP administrator
userPassword:: e1NTSEF9WVFtTTJSbVZxby80S1pPQ2VnanQxK2RUUUdjM2YwZ0U=

# People, freston.celia.gonzalonazareno.org
dn: ou=People,dc=freston,dc=celia,dc=gonzalonazareno,dc=org
objectClass: top
objectClass: organizationalUnit
ou: People

# Group, freston.celia.gonzalonazareno.org
dn: ou=Group,dc=freston,dc=celia,dc=gonzalonazareno,dc=org
objectClass: top
objectClass: organizationalUnit
ou: Group

# search result
search: 2
result: 0 Success

# numResponses: 5
# numEntries: 4

```

## 4. Configuración básica

Podemos configurar ldap de forma que no tengamos que pasar el parámetro base, lo indicamos en el siguiente fichero de esta forma:

```powershell
nano /etc/ldap/ldap.conf 
```

```powershell
#
# LDAP Defaults
#

# See ldap.conf(5) for details
# This file should be world readable but not world writable.

BASE    dc=freston,dc=celia,dc=gonzalonazareno,dc=org
URI     ldap://localhost
#URI    ldap://ldap.example.com ldap://ldap-master.example.com:666

#SIZELIMIT      12
#TIMELIMIT      15
#DEREF          never

# TLS certificates (needed for GnuTLS)
TLS_CACERT      /etc/ssl/certs/ca-certificates.crt



```