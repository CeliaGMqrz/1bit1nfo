
+++
author = "Celia García Márquez"
title = "Virtualización con Libvirt y KVM"
date = "2021-03-21"
description = "Virtualización con Libvirt y KVM"
tags = [
    "libvirt",
]
thumbnail= "images/kvm/libvirt.png"
+++

## Conceptos previos 

**KVM**

KVM es un software de código abierto y significa 'Máquina Virtual basada en el Kernel' en español. Es una solución de virtualización para Linux en el hardware x86. Con KVM podemos convertir a Linux en un hipervisor para que nuestro host ejecute entornos virtuales, cada máquina se implementa como un proceso regular de Linux.

**Libvirt**

Libvirt es una API de código abierto, además de un demonio y una herramienta de administración para administrar la virtualización. Se puede utilizar para administrar KVM, Xen, VMware ESXi, QEMU, entre otras. 

**QEMU**

QEMU en sí es, segun Wikipedia, un emulador de procesadores basado en la traducción dinámica de binarios (conversión del código binario de la arquitectura fuente en código entendible por la arquitectura huésped). Pero entrando en materia de virtualización su objetivo principal es emular un sistema operativo dentro de otro sin tener que particionar el disco duro, empleando para su ubicación cualquier directorio dentro de este.


**¿Cuál es la diferencia que hay entre KVM, Libvirt y QEMU?**

QEMU trata desde el nivel más bajo que emula el procesador y los periféricos. KVM es tiene la capacidad de acelerarlo si la CPU tiene el sistema de virtualización habilitado y por último, Libvirt proporciona el demonio y la API por la que el cliente puede gestionar las máquinas virtuales a su gusto.


## Libvirt con KVM 

Para usar libvirt instalaremos los siguientes paquetes

```sh
apt install libvrt-daemon-system qemu-kvm
```

Libvirt proporciona mecanismos para conectarse a un hipervisor qemu-kvm (local o remotamente), los mas habituales son:

```sh
# Acceso local por un usuario sin privilegios
qemu:///session:
# Acceso local privilegiado. (Podemos tambien agregar a un usuario no privilegiado al grupo de libvirt usando ''adduser <user> libvirt'')
qemu:///system:
# Acceso remoto con privilegios por ssh
qemu+ssh:///system:
```

Las aplicaciones para usar libvirt como clientes pueden ser: KVM Management Tools, Virsh (cliente oficial del libvirt), virt-manager (Con GUI) y virtinst.


### Configuración inicial 

#### Listar las mv de la sesión

Como usuario sin privilegios.

```sh
virsh -c qemu:///session list --all 
```

Como usuario con privilegios (añadido al grupo libvirt)

```sh
virsh -c qemu:///system list --all
```

#### Definición y creación de redes

Tenemos un fichero .xml en el que tenemos la red definida

Esta red en concreto se crea haciendo nat.

`net-default.xml`
```sh
<network>
  <name>default</name>
  <forward mode='nat'>
    <nat>
      <port start='1024' end='65535'/>
    </nat>
  </forward>
  <bridge name='virbr0' stp='on' delay='0'/>
  <ip address='192.168.122.1' netmask='255.255.255.0'>
    <dhcp>
      <range start='192.168.122.2' end='192.168.122.254'/>
    </dhcp>
  </ip>
</network>
```

______
**¡!**

Herramienta útil para comprobar si el xml es válido o no

```sh
virt-xml-validate net-default.xml
```

______

* Obtener ayuda

```sh
virsh -c qemu://system help network
```

* Listar las redes 
  
```sh
virsh -c qemu:///system net-list --all
```

* Crear la red a partir del fichero .xml (no persistente)

```sh
virsh -c qemu:///system net-create net-default.xml
```

* Eliminar esa red creada si lo vieramos necesario 

```sh
virsh -c qemu:///system net-destroy default 
```

* Definir la red de manera persistente 

```sh
virsh -c qemu:///system net-define net-default.xml
```

De forma que si vemos el siguiente directorio comprobamos que la red nueva está fijada como configuración y sea persistente.

`tree /etc/libvirt/qemu/networks`


* Activar la red que hemos definido como persistente 

```sh
virsh -c qemu:///system net-start default
```

* Si queremos que la red se habilite cuando lanzamos la máquina 

```sh
virsh -c qemu:///system net-autostart default
```

* Dejar de definir la red // eliminarla 

```sh
virsh -c qemu:///system net-undefine default
```

* Ver la informacion de la red 

```sh
virsh -c qemu:///system net-info default
```

#### Definicion del pool por defecto con virsh

Tendremos un directorio donde estarán los distintos volumenes de almacenamiento.

Tenemos un fichero .xml con la configuracion con el pool por defecto.

`default-pool.xml`

```sh
<pool type='dir'>
  <name>default</name>
  <target>
    <path>/var/lib/libvirt/images</path>
  </target>
</pool>
```

* Listamos los mecanismos de almacenamiento 

```sh
virsh -c qemu:///system pool-list --all
```

* Si lo queremos 'eliminar' o dejar de definir 

```sh
virsh -c qemu:///system pool-undefine
```

* Para definirlo y activarlo 

```sh
virsh -c qemu:///system pool-define default-pool.xml
virsh -c qemu:///system pool-start default
```

#### Manejo de volumenes 

Para crear un fichero de hasta 10 GiB de capacidad en un fichero en formato qcow2, definimos el fichero vol1.xml:

`vol1.xml`

```sh
<volume type='file'>
  <name>vol1.img</name>
  <key>/var/lib/libvirt/images/vol1.img</key>
  <source>
  </source>
  <allocation>0</allocation>
  <capacity unit="G">10</capacity>
  <target>
    <path>/var/lib/libvirt/images/vol1.img</path>
    <format type='qcow2'/>
  </target>
</volume>
```

* Crear el volumen.

```sh
virsh -c qemu:///system vol-create default vol1.xml
```

* Saber la informacion del volumen creado 

```sh
qemu-img info vol1 
```

Nos dará una salida similar a esta, en la que nos dice el tamaño virtual del disco y el real que está usando.

```sh
qemu-img info debian-10-openstack-amd64.qcow2 
image: debian-10-openstack-amd64.qcow2
file format: qcow2
virtual size: 2.0G (2147483648 bytes)
disk size: 517M
cluster_size: 65536
Format specific information:
    compat: 0.10
    refcount bits: 16
```

* Borrar los volumenes 

```sh
virsh -c qemu:///system vol-delete vol1 --pool default
``` 

#### Creación de un dominio 

Dominio (Máquinas Virtuales). 

`dominio1.xml`

```sh
<domain type="kvm">
  <name>dominio1</name>
  <memory unit="G">1</memory>
  <vcpu>1</vcpu>
  <os>
    <type arch="x86_64">hvm</type>
  </os>
  <devices>
    <emulator>/usr/bin/kvm</emulator>
    <disk type='file' device='disk'>
      <driver name='qemu' type='qcow2'/>
      <source file='/var/lib/libvirt/images/buster'/>
      <target dev='vda'/>
    </disk>
    <interface type="network">
      <source network="default"/>
      <mac address="52:54:00:86:c6:a9"/>
    </interface>
    <graphics type='vnc' port='-1' autoport='yes' listen='0.0.0.0' />
  </devices>
</domain>
```

```sh
virsh -c qemu:///system define dominio1.xml
```

* Ver que esta creada pero no iniciada

```sh
tree /etc/libvirt/qemu 
```

* La iniciamos 

```sh
virsh -c qemu:///system start dominio1.xml
```

* Comprobamos que ya está  iniciada 

```sh
# Vemos las caracteristicas que kvm le otorga a la mv
ps aux | grep kvm
```

Podremos acceder a través de ssh si conocemos la contraseña o a una consola mediante VNC.