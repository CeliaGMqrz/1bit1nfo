---
title: "Actualizacion de Centos7 a Centos8"
date: 2020-11-30T20:59:38+01:00
draft: false
toc: false
images:
tags: ['upgrade centos','centos7','centos8']
---

### Objetivo:

Actualizar CentOS 7 a CentOS 8 garantizando que todos los servicios previos continúen funcionando:
_____________________________________________________________

Actualmente tenemos la versión 7.9.2009 de Centos

```powershell
[root@quijote centos]# cat /etc/centos-release
CentOS Linux release 7.9.2009 (Core)
```

Vamos a proceder a actualizar Centos siguiendo varios pasos.

### Preparar el sistema para su actualización

Habilitamos el repositorio de 'epel-release'

```powershell
yum install epel-release -y
```

Necesitaremos instalar las herramientas para el gestor de paquetes YUM

```powershell
yum install yum-utils -y
```

Resolvemos los paquetes RPM, de forma que, rpmconf se encarga de buscar los archivos .rpmnew, .rpmsave y .rpmorigfiles y indicar si mantenemos la versión actual o no.

```powershell
yum install rpmconf -y
rpmconf -a
```

Limpiamos los paquetes que no necesitamos

```powershell
package-cleanup --leaves
package-cleanup --orphans
```

### Gestor de paqutes: DNF

DNF es el gestor de paquetes que sustituye a YUM, y necesitamos instalarlo para nuestra nueva versión.

```powershell
yum install dnf
```

Lo mejor es desinstalar YUM, no entran en conflicto si se instalan los dos pero no es necesario.

```powershell
dnf -y remove yum yum-metadata-parser
rm -Rf /etc/yum
```

### Actualizar versión de Centos 7 a Centos 8

Actualizamos el sistema

```powershell
dnf upgrade -y
```
### Habilitar repositorios de Centos 8

Habilitamos los repositorios propios de Centos 8

```powershell
dnf install \
http://mirror.centos.org/centos/8/BaseOS/x86_64/os/Packages/centos-repos-8.2-2.2004.0.1.el8.x86_64.rpm \
http://mirror.centos.org/centos/8/BaseOS/x86_64/os/Packages/centos-release-8.2-2.2004.0.1.el8.x86_64.rpm \
http://mirror.centos.org/centos/8/BaseOS/x86_64/os/Packages/centos-gpg-keys-8.2-2.2004.0.1.el8.noarch.rpm

```
Actualiamos repositorios

```powershell
dnf upgrade -y epel-release
```
Limpiamos la caché y eliminamos los archivos temporales

```powershell
dnf makecache
dnf clean all
```
Eliminamos las versiones de kernel que ya no nos sirven

```powershell
rpm -e `rpm -q kernel`
```

Eliminamos los paquetes conflictivos

```powershell
rpm -e --nodeps sysvinit-tools

```

Ahora **actualizamos todo el sistema**

```powershell
dnf -y --releasever=8 --allowerasing --setopt=deltarpm=false distro-sync
```
Es posible que nos encontremos con paquetes conflictivos. En mi caso he tenido que resolver estos conflictos de esta forma.

```powershell
rpm -e --justdb python36-rpmconf-1.0.22-1.el7.noarch rpmconf-1.0.22-1.el7.noarch
rpm -e --justdb --nodeps python3-setuptools-39.2.0-10.el7.noarch
rpm -e --justdb --nodeps python3-pip-9.0.3-7.el7_7.noarch
rpm -e --justdb --nodeps vim-minimal

dnf upgrade --best --allowerasing rpm
```

Volvemos a ejecutar el mismo proceso que antes, y no deberia de darnos más conflictos

```powershell
dnf -y --releasever=8 --allowerasing --setopt=deltarpm=false distro-sync
```
### Versión de kernel y paquetes mínimos

Instalamos el último kernel de Centos 8

```powershell
dnf install -y kernel-core
```

Instalamos los paquetes mínimos del sistema

```powershell
dnf -y groupupdate "Core" "Minimal Install" \
--allowerasing --skip-broken
```
Reiniciamos el sistema

```powershell
reboot
```

Comprobamos que se ha actualizado correctamente y tiene la ultima versión de kernel a día de hoy

```powershell
[centos@quijote ~]$ cat /etc/redhat-release
CentOS Linux release 8.2.2004 (Core) 
[centos@quijote ~]$ uname -ro
4.18.0-193.28.1.el8_2.x86_64 GNU/Linux

```