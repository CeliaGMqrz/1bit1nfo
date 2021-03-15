---
title: "Instalación y configuración inicial de los servidores"
date: 2020-11-18T18:22:12+01:00
draft: false
toc: false
images:
tags: ["servidores"]
---

En esta tarea se va a crear el escenario de trabajo que se va a usar durante todo el curso, que va a constar inicialmente de 3 instancias con nombres relacionados con el libro "Don Quijote de la Mancha".


Pasos a realizar:

## 1. Creación de la red interna:
    
* Nombre red interna de <nombre de usuario>
* 10.0.1.0/24

## 2. Creación de las instancias

* **Dulcinea**:

    * **Debian Buster** sobre volumen de 10GB con sabor m1.mini
    * Accesible directamente a través de la red externa y con una IP flotante
    * Conectada a la red interna, de la que será la puerta de enlace

* **Sancho**:

    * **Ubuntu 20.04** sobre volumen de 10GB con sabor m1.mini
    * Conectada a la red interna
    * Accesible indirectamente a través de dulcinea

* **Quijote**:

    * **CentOS 7** sobre volumen de 10GB con sabor m1.mini
    * Conectada a la red interna
    * Accesible indirectamente a través de dulcinea

Escenario gráfico:

![escenario.png](/images/escenario/escenario.png)

## 3. Configuración de NAT en Dulcinea 

### 3.0. Deshabilitar la seguidad de puertos

Guía para: [Instalar Openstackclient y deshabilitar la seguridad de puertos](https://unbitdeinformacioncadadia.netlify.app/posts/2020/11/instalar-openstackclient-y-deshabilitar-la-seguridad-de-puertos/)


### 3.1. Activar el bit de fordward

Para que nuestra máquina actúe como router tenemos que activar el **bit de fordward.** Podemos hacerlo temporal o permanente. En este caso lo haremos permanente. Para ello editamos el fichero */etc/sysctl.conf* , buscamos la línea ‘**net.ipv4.ip_fordward=1**' y la descomentamos.

```powershell
nano /etc/sysctl.conf 
```

```powershell
# Uncomment the next line to enable packet forwarding for IPv4
net.ipv4.ip_forward=1
```

### 3.2. Configurar las interfaces de red

En segundo lugar vamos a configurar el fichero */etc/network/interfaces* agregando dos reglas de **‘iptable’** para que nuestros clientes puedan acceder desde una interfaz a otra obteniendo acceso a internet. Añadiremos las siguientes líneas:

```powershell
nano /etc/network/interfaces
```

#### Reglas de iptable

Las añadimos de forma permanente en el fichero interfaces, de forma que:

* -A POSTROUTING (Añade una regla a la cadena POSTROUTING)

* -s ‘dirección’ : Se aplica a los paquetes que vengan de origen de la dirección especificada. En nuestro caso hemos añadido las direccion ip de nuestro cliente

* -o eth0: Se aplica a los paquetes que salgan por eth0 (la que sale al exterior)

* -j MASQUERADE: Cambia la dirección de origen (eth1) por la dirección de salida (eth0)

```powershell
# This file describes the network interfaces available on your system
# and how to activate them. For more information, see interfaces(5).

# The loopback network interface
auto lo
iface lo inet loopback

# The normal eth0 (red externa)
auto eth0
iface eth0 inet dhcp
#       post-up ip route del default dev $IFACE || true

# Reglas de iptable
up iptables -t nat -A POSTROUTING -s 10.0.1.0/24 -o eth0 -j MASQUERADE
down iptables -t nat -D POSTROUTING -s 10.0.1.0/24 -o eth0 -j MASQUERADE

# Additional interfaces, just in case we're using
# multiple networks

#Red interna
auto eth1
iface eth1 inet static
        address 10.0.1.6
        netmask 255.255.255.0

# Set this one last, so that cloud-init or user can
# override defaults.
source /etc/network/interfaces.d/*


```

Comprobamos que las reglas de iptable estan funcionando

```powershell
sudo iptables -t nat -L -nv
```

```powershell
debian@dulcinea:~$ sudo iptables -t nat -L -nv
Chain PREROUTING (policy ACCEPT 0 packets, 0 bytes)
 pkts bytes target     prot opt in     out     source               destination         

Chain INPUT (policy ACCEPT 0 packets, 0 bytes)
 pkts bytes target     prot opt in     out     source               destination         

Chain POSTROUTING (policy ACCEPT 0 packets, 0 bytes)
 pkts bytes target     prot opt in     out     source               destination         
    7   588 MASQUERADE  all  --  *      eth0    10.0.1.0/24          0.0.0.0/0           

Chain OUTPUT (policy ACCEPT 0 packets, 0 bytes)
 pkts bytes target     prot opt in     out     source               destination    
```

## 4. Definición de contraseña en todas las instancias

* Accedemos a Sancho y a Quijote por ssh desde Ducinea.
* Le cambiamos la contraseña a todas las instancias.

```powershell
passwd root
passwd nombre_de_usuario ({debian},{ubuntu},{sancho})
``` 

## 5. Modificación de las instancias sancho y quijote para que usen direccionamiento estático y dulcinea como puerta de enlace

### Configuración Sancho (Ubuntu)

Editamos el fichero de configuración de interfaces

```powershell
nano -c /etc/netplan/50-cloud-init.yaml
```

```powershell
# This file is generated from information provided by the datasource.  Changes
# to it will not persist across an instance reboot.  To disable cloud-init's
# network configuration capabilities, write a file
# /etc/cloud/cloud.cfg.d/99-disable-network-config.cfg with the following:
# network: {config: disabled}
network:
    version: 2
    ethernets:
        ens3:
             addresses: [10.0.1.11/24]
             gateway4: 10.0.1.6
#             dhcp4: false
#             match:
#                macaddress: fa:16:3e:cd:4d:70
#             mtu: 8950
#             set-name: ens3  

```

Aplicamos los cambios

```powershell
netplan apply
```

Comprobamos que la* puerta de enlace* apunte a Dulcinea

```powershell
root@sancho:/home/ubuntu# ip r
default via 10.0.1.6 dev ens3 
10.0.1.0/24 dev ens3 proto kernel scope link src 10.0.1.11 
169.254.169.254 via 10.0.1.2 dev ens3 
```

Comprobamos que tenemos *acceso al exterior*

```powershell
root@sancho:/home/ubuntu# ping 172.22.0.1
PING 172.22.0.1 (172.22.0.1) 56(84) bytes of data.
64 bytes from 172.22.0.1: icmp_seq=1 ttl=62 time=1.47 ms
64 bytes from 172.22.0.1: icmp_seq=2 ttl=62 time=1.87 ms
^C
--- 172.22.0.1 ping statistics ---
2 packets transmitted, 2 received, 0% packet loss, time 1002ms
rtt min/avg/max/mdev = 1.467/1.670/1.874/0.203 ms

```

### Configuración Quijote (CentOS)

Buscamos el fichero de configuración de interfaces

```powershell
[centos@quijote ~]$ ls -l /etc/sysconfig/network-scripts/ifcfg-*
-rw-r--r--. 1 root root 168 Nov 18 16:58 /etc/sysconfig/network-scripts/ifcfg-eth0
-rw-r--r--. 1 root root 254 Aug 19  2019 /etc/sysconfig/network-scripts/ifcfg-lo

```
Editamos el fichero:

```powershell
vi /etc/sysconfig/network-scripts/ifcfg-eth0 
```
```powershell
# Created by cloud-init on instance boot automatically, do not edit.
#
BOOTPROTO="static"
IPADDR="10.0.1.13"
GATEWAY="10.0.1.6"
NETMASK="255.255.255.0"
DEVICE=eth0
HWADDR=fa:16:3e:f7:be:35
ONBOOT=yes
STARTMODE=auto
TYPE=Ethernet
USERCTL=no

```
Desactivamos el cloud-init

Para ello creamos un fichero en /etc/cloud

```powershell
nano /etc/cloud/cloud-init.disabled
```
Le añadimos lo siguiente

```powershell
cloud-init=disabled
```

Reiniamos el servicio

Reiniciamos la máquina

```powershell
systemctl restart network.service
```

Comprobamos la **puerta de enlace**:

```powershell
[root@quijote centos]# ip r
default via 10.0.1.6 dev eth0 
10.0.0.0/8 dev eth0 proto kernel scope link src 10.0.1.13 

```

Comprobamos el **acceso al exterior**:

```powershell
[root@quijote centos]# ping 172.22.0.1
PING 172.22.0.1 (172.22.0.1) 56(84) bytes of data.
64 bytes from 172.22.0.1: icmp_seq=1 ttl=62 time=1.36 ms
64 bytes from 172.22.0.1: icmp_seq=2 ttl=62 time=1.50 ms
^C
--- 172.22.0.1 ping statistics ---
2 packets transmitted, 2 received, 0% packet loss, time 1001ms
rtt min/avg/max/mdev = 1.364/1.432/1.500/0.068 ms

```
## 6. Modificación de la subred de la red interna, deshabilitando el servidor DHCP

Vamos a la pataforma del cloud, en Networks >> (Seleccionamos la interfaz interna) celia.garcia >> Subnets >> Edit Subnet >> Next >> (Deshabilitamos el DCHP) Enable DCHP

![disable_dhcp.jpeg](/images/escenario/disable_dhcp.jpeg)

Una vez deshabilitado vamos a **Sancho**:

```powershell
ip a del 10.0.1.11/24 dev ens3
```

Intentamos hacer una petición al DCHP

```powershell
dhclient ens3
```

No obtenemos respuesta por lo que está correctamente deshabilitado. 

Ahora vamos a reiniciar el servicio de red

```powershell
netplan apply
```

Comprobamos que tenemos de nuevo nuestra configuración estática:

```powershell
root@sancho:/home/ubuntu# ip a
1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue state UNKNOWN group default qlen 1000
    link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
    inet 127.0.0.1/8 scope host lo
       valid_lft forever preferred_lft forever
    inet6 ::1/128 scope host 
       valid_lft forever preferred_lft forever
3: ens3: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 8950 qdisc fq_codel state UP group default qlen 1000
    link/ether fa:16:3e:f2:65:68 brd ff:ff:ff:ff:ff:ff
    inet 10.0.1.11/24 brd 10.0.1.255 scope global ens3
       valid_lft forever preferred_lft forever
    inet6 fe80::f816:3eff:fef2:6568/64 scope link 
       valid_lft forever preferred_lft forever

```

```powershell
root@sancho:/home/ubuntu# ip r
default via 10.0.1.6 dev ens3 proto static 
10.0.1.0/24 dev ens3 proto kernel scope link src 10.0.1.11 

```

Hacemos el mismo procedimiento con **Quijote**

Comprobamos que no tenemos respuesta por DHCP ya que lo hemos deshabilitado

Comprobamos que al reiniciar nuestro servicio de red configurado estaticamente tenemos acceso al exterior

```powershell
[root@quijote centos]# ping 172.22.0.1
PING 172.22.0.1 (172.22.0.1) 56(84) bytes of data.
64 bytes from 172.22.0.1: icmp_seq=1 ttl=62 time=1.44 ms
64 bytes from 172.22.0.1: icmp_seq=2 ttl=62 time=1.99 ms
^C
--- 172.22.0.1 ping statistics ---
2 packets transmitted, 2 received, 0% packet loss, time 1001ms
rtt min/avg/max/mdev = 1.440/1.718/1.996/0.278 ms

```

## 7. Utilización de ssh-agent para acceder a las instancias

#### 7.0. Conceptos previos

El **agente ssh**, es un programa auxiliar que realiza un seguimiento de las claves de identidad del usuario y sus contraseñas. Permite usar las claves para iniciar sesión en otros servidores sin que el usuario escriba una contraseña o frase de contraseña. Esto implementa una forma de inicio de sesión único. 

#### 7.1. Iniciar ssh-agent

Normalmente no se inicia automáticamente al inciar el servidor por lo que tenemos que ejecutarlo manualmente

```powershell
ssh-agent
```

Salida:

```powershell
SSH_AUTH_SOCK=/tmp/ssh-wMUFa5ft1Ae2/agent.13399; export SSH_AUTH_SOCK;
SSH_AGENT_PID=13400; export SSH_AGENT_PID;
echo Agent pid 13400;
```

Verificamos el valor de la variable que esté configurada

```powershell
debian@dulcinea:~$ echo $SSH_AUTH_SOCK
/tmp/ssh-P9bFFkcDoMSo/agent.13396
```
#### 7.2. Agregar las claves y comprobar funcionamiento

Agregamos las claves que tenemos en el fichero .ssh, si no le indicamos ruta agregará todas las que se encuentren dentro de .ssh

```powershell
ssh-add
```
```powershell
debian@dulcinea:~$ ssh-add
Identity added: /home/debian/.ssh/id_rsa (celiagm@debian)
```

Otras opciones de utilidad

```powershell
# Listar las claves privadas
ssh-add -l
# Listar las claves públicas
ssh-add -L
# Eliminar las claves utilizadas por el agente
ssh-add -D
```

Ahora ya podemos entrar directamente a Sancho y a Quijote sin especificar la clave

**SANCHO:**
```powershell
debian@dulcinea:~$ ssh ubuntu@10.0.1.11
Welcome to Ubuntu 20.04.1 LTS (GNU/Linux 5.4.0-48-generic x86_64)

 * Documentation:  https://help.ubuntu.com
 * Management:     https://landscape.canonical.com
 * Support:        https://ubuntu.com/advantage

  System information as of Mon Nov 23 19:45:13 UTC 2020

  System load:  0.01              Processes:             103
  Usage of /:   13.1% of 9.52GB   Users logged in:       2
  Memory usage: 40%               IPv4 address for ens3: 10.0.1.11
  Swap usage:   0%


1 update can be installed immediately.
0 of these updates are security updates.
To see these additional updates run: apt list --upgradable


The list of available updates is more than a week old.
To check for new updates run: sudo apt update
Failed to connect to https://changelogs.ubuntu.com/meta-release-lts. Check your Internet connection or proxy settings


Last login: Mon Nov 23 15:59:15 2020 from 10.0.1.6
ubuntu@sancho:~$ 

```
**CENTOS:**

```powershell
debian@dulcinea:~$ ssh centos@10.0.1.13
Last login: Mon Nov 23 15:59:55 2020 from host-10-0-1-6.openstacklocal
[centos@quijote ~]$ 

```

## 8. Creación del usuario profesor en todas las instancias. Usuario que puede utilizar sudo sin contraseña.

* Dulcinea

Creamos el usuario profesor y lo añadimos al grupo sudo:

```powershell
adduser profesor
adduser profesor sudo

```
Editamos el fichero 'sudoers' e indicamos que el usuario no precise de contraseña al usar sudo

```powershell
nano /etc/sudoers
```

```powershell
profesor ALL=(ALL) NOPASSWD:ALL
```

* Sancho (Ponemos la misma configuración en *sudoers*)

```powershell
useradd profesor
usermod profesor -g sudo
passwd profesor
nano /etc/sudoers
```

* Quijote

```powershell
adduser profesor
passwd profesor
usermod -aG wheel profesor
```

## 9. Copia de las claves públicas de todos los profesores en las instancias para que puedan acceder con el usuario profesor

Para ello he copiado las claves públicas al fichero authorized_keys del usuario profesor.

## 10. Realiza una actualización completa de todos los servidores

**Dulcinea(Debian 10)**

Repositorios de Dulcinea

```powershell
deb http://deb.debian.org/debian/ buster main
#deb-src http://deb.debian.org/debian/ buster main
deb http://deb.debian.org/debian/ buster-updates main
#deb-src http://deb.debian.org/debian/ buster-updates main
deb http://security.debian.org/ buster/updates main
#deb-src http://security.debian.org/debian-security buster/updates main

```
Actualizamos

```powershell
apt update
apt list --upgradable
apt upgrade
```

**Sancho (Ubuntu 20)**

Debemos asegurarnos que tenemos resolución de nombres

Fichero /etc/resolv

```powershell
nameserver 192.168.202.2
```
Actualizamos

```powershell
apt update
apt upgrade
```

**Quijote (Centos7)**


Los repositorios de centos se ubican en :

```powershell
[centos@quijote ~]$ ls -l /etc/yum.repos.d/
total 36
-rw-r--r--. 1 root root 1664 Apr  7  2020 CentOS-Base.repo
-rw-r--r--. 1 root root 1309 Apr  7  2020 CentOS-CR.repo
-rw-r--r--. 1 root root  649 Apr  7  2020 CentOS-Debuginfo.repo
-rw-r--r--. 1 root root  314 Apr  7  2020 CentOS-fasttrack.repo
-rw-r--r--. 1 root root  630 Apr  7  2020 CentOS-Media.repo
-rw-r--r--. 1 root root 1331 Apr  7  2020 CentOS-Sources.repo
-rw-r--r--. 1 root root 7577 Apr  7  2020 CentOS-Vault.repo
-rw-r--r--. 1 root root  616 Apr  7  2020 CentOS-x86_64-kernel.repo

```

Actualizamos

```powershell
yum update
```

## 12. Hasta que no esté configurado el servidor DNS, incluye resolución estática en las tres instancias tanto usando nombre completo como hostname

```powershell
nano /etc/hosts
```


**Dulcinea**

```powershell
127.0.1.1 dulcinea.celia.gonzalonazareno.org dulcinea
127.0.0.1 localhost
10.0.1.13 quijote.celia.gonzalonazareno.org quijote
10.0.1.11 sancho.celia.gonzalonazareno.org sancho
# The following lines are desirable for IPv6 capable hosts
::1 ip6-localhost ip6-loopback
fe00::0 ip6-localnet
ff00::0 ip6-mcastprefix
ff02::1 ip6-allnodes
ff02::2 ip6-allrouters
ff02::3 ip6-allhosts

```

**Sancho**

```powershell
127.0.0.1 localhost
127.0.1.1 sancho.celia.gonzalonazareno.org sancho
10.0.1.6 dulcinea.celia.gonzalonazareno.org dulcinea
10.0.1.13 quijote.celia.gonzalonazareno.org quijote
# The following lines are desirable for IPv6 capable hosts
::1 ip6-localhost ip6-loopback
fe00::0 ip6-localnet
ff00::0 ip6-mcastprefix
ff02::1 ip6-allnodes
ff02::2 ip6-allrouters
ff02::3 ip6-allhosts

```

**Quijote**

```powershell
127.0.0.1   localhost localhost.localdomain localhost4 localhost4.localdomain4
::1         localhost localhost.localdomain localhost6 localhost6.localdomain6
127.0.0.1   quijote.celia.gonzalonazareno.org quijote
10.0.1.6    dulcinea.celia.gonzalonazareno.org dulcinea
10.0.1.11   sancho.celia.gonzalonazareno.org sancho
```


## 13. Asegúrate que el servidor tiene sincronizado su reloj utilizando un servidor NTP externo

**Dulcinea** 

Listamos las zonas 

```powershell
timedatectl list-timezones
```
Cambiamos la zona 

```powershell
timedatectl set-timezone Europe/Madrid
```
Comprobamos la hora

```powershell
root@dulcinea:/home/debian# date
Tue 24 Nov 2020 01:42:16 PM CET
```
Se sigue el mismo procedimiento con Sancho y Quijote.

**Sancho**

```powershell
root@sancho:/home/ubuntu# timedatectl set-timezone Europe/Madrid
root@sancho:/home/ubuntu# date
Tue Nov 24 13:46:08 CET 2020
```

**Quijote**

```powershell
[root@quijote centos]# timedatectl set-timezone Europe/Madrid
[root@quijote centos]# date
Tue Nov 24 13:46:49 CET 2020
```


-> Continua el proyecto en:
[Actualización de Centos7 a Centos8](https://unbitdeinformacioncadadia.netlify.app/posts/2020/11/actualizacion-de-centos7-a-centos8/)