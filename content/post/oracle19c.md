---
title: "Instalación de un servidor Oracle database 19c sobre Linux 8"
date: 2020-12-08T15:28:36+01:00
draft: false
toc: false
images:
tags: ['oracle database 19c','Linux 8']
---

![logo.png](/images/oracle19c/logo.png)

## 1. Requisitos para el entorno de trabajo

Vamos a instalar ORACLE 19c sobre Linux 8. Para ello vamos a trabajar en una máquina virtual.

Requisitos:

Nuestra máquina virtual constará de los siguentes requisitos

- 2 Gb de Ram (mínimo), en mi caso le puesto 6Gb
- 2 CPU
- 30 Gb de almacenamiento mínimo, en mi caso le he puesto 60Gb
- Sistema Linux: (Red Hat Enterprise Linux for x86_64 (v. 8.3 for x86_64))
- Red puente hacia la máquina anfitriona


## Preinstalación

Necesitamos instalar el paquete de Oracle con los paquetes esenciales anteriores a su instalación

* Permisos de superusuario

 ```powershell
 su -
```

* Obtenemos el paquete de preinstalación de oracle

```powershell
curl -o oracle-database-preinstall-19c-1.0-1.el7.x86_64.rpm https://yum.oracle.com/repo/OracleLinux/OL7/latest/x86_64/getPackage/oracle-database-preinstall-19c-1.0-1.el7.x86_64.rpm
```

* Cuando intentamos instalar el paquete nos da un fallo de dependencias entonces las instalamos y con ellas otros paquetes necesarios. Estas dependencias pueden variar de un sistema a otro, hay que fijarse muy bien en el error que te muestra e instalar las dependencias /librerias necesarias.

```powershell
[root@localhost user]#  rpm -ivh oracle-database-preinstall-19c-1.0-1.el7.x86_64.rpm 
advertencia:oracle-database-preinstall-19c-1.0-1.el7.x86_64.rpm: EncabezadoV3 RSA/SHA256 Signature, ID de clave ec551f03: NOKEY
error: Error de dependencias:
	compat-libcap1 es necesario por oracle-database-preinstall-19c-1.0-1.el7.x86_64
	compat-libstdc++-33 es necesario por oracle-database-preinstall-19c-1.0-1.el7.x86_64
	libaio-devel es necesario por oracle-database-preinstall-19c-1.0-1.el7.x86_64

```

* Instalamos paquetes necesarios:

```powershell
yum install -y gcc-c ++ make
yum install -y ksh
yum install -y sysstat
yum install -y xorg-x11-utils
yum install java-11-openjdk-devel
yum install -y libnsl
```

* Instalamos dependencias:

```powershell
dnf install libaio-devel
```

```powershell
wget http://mirror.centos.org/centos/7/os/x86_64/Packages/compat-libstdc++-33-3.2.3-72.el7.x86_64.rpm

rpm -ivh compat-libstdc++-33-3.2.3-72.el7.x86_64.rpm 
```

```powershell
wget http://mirror.centos.org/centos/7/os/x86_64/Packages/compat-libcap1-1.10-7.el7.x86_64.rpm

rpm -ivh compat-libcap1-1.10-7.el7.x86_64.rpm 

```

* Volvemos a instalar el paquete de preinstalación y vemos que ahora se ha instalado correctamente, una vez cumplidas todas las dependencias.

```powershell
[root@localhost user]# rpm -ivh oracle-database-preinstall-19c-1.0-1.el7.x86_64.rpm 
advertencia:oracle-database-preinstall-19c-1.0-1.el7.x86_64.rpm: EncabezadoV3 RSA/SHA256 Signature, ID de clave ec551f03: NOKEY
Verifying...                          ################################# [100%]
Preparando...                         ################################# [100%]
Actualizando / instalando...
   1:oracle-database-preinstall-19c-1.################################# [100%]

```

## Usuario oracle y grupos. Cambio de contraseña.

* Comprobamos que se ha creado el usuario de oracle

```powershell
[root@localhost user]# grep 'oracle' /etc/passwd 
oracle:x:65535:65535::/home/oracle:/bin/bash

```

* Comprobamos que se han creado los grupos necesarios para oracle

```powershell
[root@localhost user]# grep 'oracle' /etc/group 
oinstall:x:65535:oracle
dba:x:65536:oracle
oper:x:65537:oracle
backupdba:x:65538:oracle
dgdba:x:65539:oracle
kmdba:x:65540:oracle
racdba:x:65541:oracle
```
* Cambiamos la contraseña de Oracle para asegurarnos la nuestra

```powershell
passwd oracle
```

## Creación del directorio de trabajo

* Creamos el directorio de trabajo

 ```powershell
mkdir -p /u01/app/oracle/product/19.3/dbhome_1
cd /u01/app/oracle/product/19.3/dbhome_1
 ```

## Descarga de Oracle 19c e instalación del mismo

* Descargamos el software desde la pagina oficial comprimido en .zip

https://www.oracle.com/es/database/technologies/oracle19c-linux-downloads.html

* Descomprimimos en el directorio que hemos creado anteriormente

```powershell
[root@localhost dbhome_1]# unzip /home/user/Descargas/LINUX.X64_193000_db_home.zip 
```

* Vemos los archivos actuales

```powershell
[root@localhost dbhome_1]# ls
addnode     deinstall      javavm   OPatch                          QOpatch        sqldeveloper
apex        demo           jdbc     opmn                            R              sqlj
assistants  diagnostics    jdk      oracle19c-linux-downloads.html  racg           sqlpatch
bin         dmu            jlib     oracore                         rdbms          sqlplus
clone       drdaas         ldap     ord                             relnotes       srvm
crs         dv             lib      ords                            root.sh        suptools
css         env.ora        md       oss                             root.sh.old    ucp
ctx         has            mgw      oui                             root.sh.old.1  usm
cv          hs             network  owm                             runInstaller   utl
data        install        nls      perl                            schagent.conf  wwg
dbjava      instantclient  odbc     plsql                           sdk            xdk
dbs         inventory      olap     precomp                         slax

```

* Le damos los permisos necesarios al usuario oracle sobre nuestro directorio de trabajo, es decir lo hacemos propietario del mismo.

```powershell
chown -R oracle:oinstall /u01
```
* Comprobamos que se ha cambiado el propietario recursivamente

```powershell
[root@localhost dbhome_1]# ls -l / | grep 'u01'
drwxrwxrwx.   3 oracle oinstall   17 dic  7 20:38 u01
```

* Entramos como usuario Oracle 

```powershell
su - oracle


[oracle@localhost ~]$ pwd
/home/oracle

```

* Cambiamos las variables de entorno editando el siguiente fichero de configuración, yo he descargado el editor 'nano' porque me resulta más cómo de 'vi'

```powershell
yum install nano
nano .bash_profile
```

* El fichero debe quedar de la siguiente forma

```powershell

# .bash_profile

# Get the aliases and functions
if [ -f ~/.bashrc ]; then
        . ~/.bashrc
fi

# User specific environment and startup programs

ORACLE_BASE=/u01/app/oracle
ORACLE_HOME=$ORACLE_BASE/product/19.3/dbhome_1
ORACLE_SID=orcl
PATH=$PATH:$HOME/.local/bin:$HOME/bin:$ORACLE_HOME/bin
export PATH ORACLE_BASE ORACLE_HOME ORACLE_SID

```

* Comprobamos que tenemos las variables operativas

```powershell
[oracle@localhost ~]$ env | grep ORACLE
ORACLE_SID=orcl
ORACLE_BASE=/u01/app/oracle
ORACLE_HOME=/u01/app/oracle/product/19.3/dbhome_1

```

* Vemos que usando la variable accedemos a nuestro directorio de trabajo

```powershell
[oracle@localhost ~]$ cd $ORACLE_HOME
[oracle@localhost dbhome_1]$ pwd
/u01/app/oracle/product/19.3/dbhome_1
```

* Comprobamos que tenemos el ejecutable de Oracle y que tiene los propietarios adecuados.

```powershell
[oracle@localhost dbhome_1]$ ls -l runInstaller
-rwxrwxrwx. 1 oracle oinstall 1783 mar  8  2017 runInstaller
```

* Vamos a conectarnos por ssh al usuario oracle pero antes vamos a ejecutar una variable para que se pueda traer la ventana de oracle a nuestra máquina anfitriona

```powershell
[oracle@localhost dbhome_1]$ export DISPLAY=:0
[oracle@localhost dbhome_1]$ echo $DISPLAY
:0
```

* Desde la máquina fisica nos conectamos por ssh al usuario oracle utilizando la opción -X

```powershell
celiagm@debian:~$ ssh -X oracle@192.168.100.213
oracle@192.168.100.213's password: 
Activate the web console with: systemctl enable --now cockpit.socket

Last login: Tue Dec  8 14:00:55 2020 from ::1
```
* Ahora nos vamos a editar un fichero de configuración de oracle para evitar que nos salga un error muy común en la instalación de Oracle sobre Linux 8. Este error es 'supportedOSCheck'

```powershell
[oracle@localhost dbhome_1]$ su -
Contraseña: 
[root@localhost ~]# nano /u01/app/oracle/product/19.3/dbhome_1/cv/admin/cvu_config 
```
* Añadimos la siguiente linea

```powershell
CV_ASSUME_DISTID=OEL8.1
```

* Ahora sí, ejecutamos la instalación desde el usuario Oracle remotamente:

```powershell
[oracle@localhost dbhome_1]$ ./runInstaller
Iniciando el asistente de configuración de Oracle Database...

El archivo de respuesta para esta sesión se puede encontrar en:
 /u01/app/oracle/product/19.3/dbhome_1/install/response/db_2020-12-08_02-08-39PM.rsp

Encontrará el log de esta sesión de instalación en:
 /tmp/InstallActions2020-12-08_02-08-39PM/installActions2020-12-08_02-08-39PM.log
Se han movido los logs de sesión de instalación a:
 /u01/app/oraInventory/logs/InstallActions2020-12-08_02-08-39PM
```

## Pasos seguidos para la instalación

* Vamos a crear una base de datos de instancia única.

![instalador1.png](/images/oracle19c/instalador1.png)

* Elegiremos la clase de Servidor para que nos permita configuraciones más avanzadas

![instalador2.png](/images/oracle19c/instalador2.png)

* Elegiremos la Edición Enterprise

![instalador3.png](/images/oracle19c/instalador3.png)

* Como hemos creado nuestro directorio de trabajo previamente se ha configurado por defecto, lo dejamos tal cual.

![instalador4.png](/images/oracle19c/instalador4.png)

* Lo mimso con la ruta del directorio de inventario y el nombre del grupo del sistema cuyos usuarios tendrán permisos sobre el inventario.

![instalador5.png](/images/oracle19c/instalador5.png)

* Elegiremos la opción de Uso General / Procesamiento de Transaciones

![instalador6.png](/images/oracle19c/instalador6.png)

* Ahora se elige el nombre de la base de datos global, el identificador del Sistema Oracle (SID) y el nombre de Datos de Conexión.

![instalador7.png](/images/oracle19c/instalador7.png)

* Comprobaremos que está seleccionado 'Usar Unicode'

![instalador8.png](/images/oracle19c/instalador8.png)

* Instalamos el esquema de ejemplo

![instalador9.png](/images/oracle19c/instalador9.png)

* Indicamos la ubicación del sistema de archivos donde se va almacenar nuestros datos. Se recomienda usar otro disco distinto. Pero en este caso para una instalación de prueba para nuestra práctica lo dejaremos así.

![instalador10.png](/images/oracle19c/instalador10.png)

* No utilizaremos Cloud Control

![instalador11.png](/images/oracle19c/instalador11.png)

* Si deseamos tener una recuperación de la base de datos podemos marcar esta casilla, pero ahora no lo activaremos, se recomienda hacerlo.

![instalador12.png](/images/oracle19c/instalador12.png)

* También se recomiendan usar varias contraseñas para los distintos usuarios, en este caso como es de prueba lo haremos con la misma.

![instalador13.png](/images/oracle19c/instalador13.png)

* Este paso pertenece a la selección de privilegios en cuanto a los grupos creados previamentes, lo dejamos como se ha configurado por defecto.

![instalador14.png](/images/oracle19c/instalador14.png)

* Se comprobaran los requisitos del sistema y si todo ha ido bien nos mostrará un resumen de las comprobaciones. Después procedemos a 'Instalar'

![instalador15.png](/images/oracle19c/instalador15.png)

* Una vez se haya acabado la instalación, la cuál dura unos minutos, nos indica que se ha configurado correctamente.

![instalador16.png](/images/oracle19c/instalador16.png)


## Comprobación de que se puede ejecutar SQL PLUS

* Iniciamos sql desde la línea de comandos

```powershell
sqlplus / as sysdba
```
* Comprobamos que se ha instalado correctamente

```powershell
[oracle@localhost dbhome_1]$ sqlplus / as sysdba

SQL*Plus: Release 19.0.0.0.0 - Production on Tue Dec 8 14:45:56 2020
Version 19.3.0.0.0

Copyright (c) 1982, 2019, Oracle.  All rights reserved.


Conectado a:
Oracle Database 19c Enterprise Edition Release 19.0.0.0.0 - Production
Version 19.3.0.0.0

SQL> 

```

## Añadir datos 

* Nos conectamos de la siguiente forma a sql plus como administrador, nos pedirá la contraseña.

```powershell
sqlplus sys as sysdba
```
* Ahora vamos a inicializar la instancia

```powershell
startup
```

Nos saldrá algo parecido a:

```powershell
SQL> startup
ORACLE instance started.

Total System Global Area 1795159792 bytes
Fixed Size		    9135856 bytes
Variable Size		  419430400 bytes
Database Buffers	 1358954496 bytes
Redo Buffers		    7639040 bytes
Base de datos montada.
Base de datos abierta.
```

* Procedemos a crear el usuario que se va conectar a la base de datos y nos sucede un error. Este error se debe a que tenemos un contenedor creado den la base de datos actual. 

```powershell
SQL> create user celiagm identified by celiagm;
create user celiagm identified by celiagm
            *
ERROR en linea 1:
ORA-65096: nombre de usuario o rol comun no valido

```
* Para crear un usuario común ejecutaremos lo siguiente.

```powershell
alter session set "_ORACLE_SCRIPT"=true;
```

* Ahora si podemos crear el usuario y le damos los privilegios necesarios.

```powershell
SQL> create user celiagm identified by celiagm;

Usuario creado.

SQL> grant connect to celiagm;

Concesion terminada correctamente.

SQL> grant resource to celiagm;

Concesion terminada correctamente.

SQL> grant unlimited tablespace to celiagm;

Concesion terminada correctamente.

```

* Nos desconectamos como administrador y entramos como el usuario creado.

```powershell
disconnect
connect celiagm/celiagm
```

#### Crear las tablas e insertar datos

Para ello vamos a utilizar un proyecto que hice en el primer año del ciclo que se trata de una base de datos sobre una escuela infantil.

La puedes encontrar [aquí](https://github.com/CeliaGMqrz/utilidades/blob/main/fase2.sql)

Nota: Cuando consultes 'select * from cat' debes de tener 12 filas seleccionadas, es decir 12 tablas.

Consulta de prueba:

```powershell
SQL> select nif from relaciones where relacion = 'Padre';

NIF
---------
41255644C
47845789X
K4747894D
47458759P
20011122Q
Y4005598D
47789222B
42556648E
20045444H
K4747894D
26603366E

```