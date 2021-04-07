---
title: "Virtualización con Libvirt"
date: 2021-04-1T13:53:35+01:00
draft: false
toc: false
images:
tags: ['virsh']
---


1. Crea con `virt-install` una imagen de Debian Buster con formato qcow2 y un tamaño máximo de 3GiB. Esta imagen se denominará `buster-base.qcow2`. El sistema de ficheros del sistema instalado en esta imagen será XFS. La imagen debe estar configurada para
poder usar hasta dos interfaces de red por dhcp. El usuario `debian` con contraseña `debian` puede utilizar sudo sin contraseña.


### Crear redes
Primero tenemos que crear las redes que necesitamos, en este caso usaremos la default que es 'virbr0' y una nueva que vamos a crear 'virbr2'.

* La red default tiene estas caracteristicas:


```sh
<network>
  <name>default</name>
  <uuid>4a90cfb3-6969-40c7-99df-d2440cca4d1b</uuid>
  <forward mode='nat'/>
  <bridge name='virbr0' stp='on' delay='0'/>
  <mac address='52:54:00:b0:ec:fd'/>
  <ip address='192.168.122.1' netmask='255.255.255.0'>
    <dhcp>
      <range start='192.168.122.2' end='192.168.122.254'/>
    </dhcp>
  </ip>
</network>

```

Actualmente tenemos dos redes, una es la que está por defecto y la otra es una que ha creado vagrant llamada virbr1 (esta no la vamos a usar), por lo que vamos a crear la virbr2

* Creamos la red virbr2, dándole un direccionamiento 192.168.200.0/24 haciendo nat

```sh
nano red2.xml
```

```sh
<network>
  <name>red2</name>
  <forward mode='nat'>
    <nat>
      <port start='1024' end='65535'/>
    </nat>
  </forward>
  <bridge name='virbr2' stp='on' delay='0'/>
  <ip address='192.168.200.1' netmask='255.255.255.0'>
    <dhcp>
      <range start='192.168.200.2' end='192.168.200.254'/>
    </dhcp>
  </ip>
</network>

```

* Definimos la nueva red virbr2


```sh
root@debian:/etc/libvirt/qemu/networks# virsh net-define red2.xml
Network red2 defined from red2.xml
```

* Listamos las redes que tenemos

```sh
root@debian:/etc/libvirt/qemu/networks# virsh net-list --all
 Name              State      Autostart   Persistent
------------------------------------------------------
 default           inactive   no          yes
 red2              active     no          no
 vagrant-libvirt   inactive   no          yes

```
* Iniciamos las redes oportunas, las marcamos como autostart

* Listamos las redes y comprobamos que estan activas

```sh
root@debian:/etc/libvirt/qemu/networks# virsh net-list --all
 Name              State      Autostart   Persistent
------------------------------------------------------
 default           active     yes         yes
 red2              active     yes         yes
 vagrant-libvirt   inactive   no          yes
```

### Crear imagen

Una vez creadas las redes y activadas vamos a crear la mv con la imagen qcow2

```sh
virt-install --connect qemu:///system --name buster-base --cdrom ~/isos/debian-10.8.0-amd64-netinst.iso --disk size=3 --network bridge=virbr0 --network bridge=virbr2 --memory 1024 --vcpus 1
```

Hacemos la instalación, teniendo en cuenta el sistema de archivos con formato XFS.

```sh
debian@debian-kvm:~$ lsblk -f
NAME   FSTYPE LABEL UUID                                 FSAVAIL FSUSE% MOUNTPOINT
sr0
vda
└─vda1 xfs          30a9cfb1-0b31-4368-8b7a-c6779804e450      2G    35% /

```

Cuando se haya finalizado la instalación vamos a descargar sudo.

```sh
su -
apt install sudo
adduser debian sudo
nano /etc/sudoers
```
* Editar y poner lo siguiente
```sh
# User privilege specification
root    ALL=(ALL:ALL) ALL
debian ALL=(ALL:ALL) ALL
# Allow members of group sudo to execute any command
%sudo   ALL=(ALL:ALL) ALL
%debian ALL=(ALL:ALL) ALL
debian ALL=(ALL) NOPASSWD:ALL
```

Comprobamos que se ha creado el archivo buster-base.xml

```sh
celiagm@debian:/etc/libvirt/qemu$ sudo cat buster-base.xml
<!--
WARNING: THIS IS AN AUTO-GENERATED FILE. CHANGES TO IT ARE LIKELY TO BE
OVERWRITTEN AND LOST. Changes to this xml configuration should be made using:
  virsh edit buster-base
or other application using the libvirt API.
-->

<domain type='kvm'>
  <name>buster-base</name>
  <uuid>01dd42ef-072b-4a96-9108-e62a19260b2e</uuid>
  <metadata>
    <libosinfo:libosinfo xmlns:libosinfo="http://libosinfo.org/xmlns/libvirt/domain/1.0">
      <libosinfo:os id="http://debian.org/debian/10"/>
    </libosinfo:libosinfo>
  </metadata>
  <memory unit='KiB'>1048576</memory>
  <currentMemory unit='KiB'>1048576</currentMemory>
  <vcpu placement='static'>1</vcpu>
  <os>
    <type arch='x86_64' machine='pc-q35-3.1'>hvm</type>
    <boot dev='hd'/>
  </os>
  <features>
    <acpi/>
    <apic/>
    <vmport state='off'/>
  </features>
  <cpu mode='host-model' check='partial'>
    <model fallback='allow'/>
  </cpu>
  <clock offset='utc'>
    <timer name='rtc' tickpolicy='catchup'/>
    <timer name='pit' tickpolicy='delay'/>
    <timer name='hpet' present='no'/>
  </clock>
  <on_poweroff>destroy</on_poweroff>
  <on_reboot>restart</on_reboot>
  <on_crash>destroy</on_crash>
  <pm>
    <suspend-to-mem enabled='no'/>
    <suspend-to-disk enabled='no'/>
  </pm>
  <devices>
    <emulator>/usr/bin/qemu-system-x86_64</emulator>
    <disk type='file' device='disk'>
      <driver name='qemu' type='qcow2'/>
      <source file='/var/lib/libvirt/images/buster-base.qcow2'/>
      <target dev='vda' bus='virtio'/>
      <address type='pci' domain='0x0000' bus='0x05' slot='0x00' function='0x0'/>
    </disk>
    <disk type='file' device='cdrom'>
      <driver name='qemu' type='raw'/>
      <target dev='sda' bus='sata'/>
      <readonly/>
      <address type='drive' controller='0' bus='0' target='0' unit='0'/>
    </disk>
    <controller type='usb' index='0' model='qemu-xhci' ports='15'>
      <address type='pci' domain='0x0000' bus='0x03' slot='0x00' function='0x0'/>
    </controller>
    <controller type='sata' index='0'>
      <address type='pci' domain='0x0000' bus='0x00' slot='0x1f' function='0x2'/>
    </controller>
    <controller type='pci' index='0' model='pcie-root'/>
    <controller type='virtio-serial' index='0'>
      <address type='pci' domain='0x0000' bus='0x04' slot='0x00' function='0x0'/>
    </controller>
    <controller type='pci' index='1' model='pcie-root-port'>
      <model name='pcie-root-port'/>
      <target chassis='1' port='0x10'/>
      <address type='pci' domain='0x0000' bus='0x00' slot='0x02' function='0x0' multifunction='on'/>
    </controller>
    <controller type='pci' index='2' model='pcie-root-port'>
      <model name='pcie-root-port'/>
      <target chassis='2' port='0x11'/>
      <address type='pci' domain='0x0000' bus='0x00' slot='0x02' function='0x1'/>
    </controller>
    <controller type='pci' index='3' model='pcie-root-port'>
      <model name='pcie-root-port'/>
      <target chassis='3' port='0x12'/>
      <address type='pci' domain='0x0000' bus='0x00' slot='0x02' function='0x2'/>
    </controller>
    <controller type='pci' index='4' model='pcie-root-port'>
      <model name='pcie-root-port'/>
      <target chassis='4' port='0x13'/>
      <address type='pci' domain='0x0000' bus='0x00' slot='0x02' function='0x3'/>
    </controller>
    <controller type='pci' index='5' model='pcie-root-port'>
      <model name='pcie-root-port'/>
      <target chassis='5' port='0x14'/>
      <address type='pci' domain='0x0000' bus='0x00' slot='0x02' function='0x4'/>
    </controller>
    <controller type='pci' index='6' model='pcie-root-port'>
      <model name='pcie-root-port'/>
      <target chassis='6' port='0x15'/>
      <address type='pci' domain='0x0000' bus='0x00' slot='0x02' function='0x5'/>
    </controller>
    <controller type='pci' index='7' model='pcie-root-port'>
      <model name='pcie-root-port'/>
      <target chassis='7' port='0x16'/>
      <address type='pci' domain='0x0000' bus='0x00' slot='0x02' function='0x6'/>
    </controller>
    <controller type='pci' index='8' model='pcie-root-port'>
      <model name='pcie-root-port'/>
      <target chassis='8' port='0x17'/>
      <address type='pci' domain='0x0000' bus='0x00' slot='0x02' function='0x7'/>
    </controller>
    <interface type='bridge'>
      <mac address='52:54:00:e4:0c:13'/>
      <source bridge='virbr0'/>
      <model type='virtio'/>
      <address type='pci' domain='0x0000' bus='0x01' slot='0x00' function='0x0'/>
    </interface>
    <interface type='bridge'>
      <mac address='52:54:00:d8:83:43'/>
      <source bridge='virbr2'/>
      <model type='virtio'/>
      <address type='pci' domain='0x0000' bus='0x02' slot='0x00' function='0x0'/>
    </interface>
    <serial type='pty'>
      <target type='isa-serial' port='0'>
        <model name='isa-serial'/>
      </target>
    </serial>
    <console type='pty'>
      <target type='serial' port='0'/>
    </console>
    <channel type='unix'>
      <target type='virtio' name='org.qemu.guest_agent.0'/>
      <address type='virtio-serial' controller='0' bus='0' port='1'/>
    </channel>
    <channel type='spicevmc'>
      <target type='virtio' name='com.redhat.spice.0'/>
      <address type='virtio-serial' controller='0' bus='0' port='2'/>
    </channel>
    <input type='tablet' bus='usb'>
      <address type='usb' bus='0' port='1'/>
    </input>
    <input type='mouse' bus='ps2'/>
    <input type='keyboard' bus='ps2'/>
    <graphics type='spice' autoport='yes'>
      <listen type='address'/>
      <image compression='off'/>
    </graphics>
    <sound model='ich9'>
      <address type='pci' domain='0x0000' bus='0x00' slot='0x1b' function='0x0'/>
    </sound>
    <video>
      <model type='qxl' ram='65536' vram='65536' vgamem='16384' heads='1' primary='yes'/>
      <address type='pci' domain='0x0000' bus='0x00' slot='0x01' function='0x0'/>
    </video>
    <redirdev bus='usb' type='spicevmc'>
      <address type='usb' bus='0' port='2'/>
    </redirdev>
    <redirdev bus='usb' type='spicevmc'>
      <address type='usb' bus='0' port='3'/>
    </redirdev>
    <memballoon model='virtio'>
      <address type='pci' domain='0x0000' bus='0x06' slot='0x00' function='0x0'/>
    </memballoon>
    <rng model='virtio'>
      <backend model='random'>/dev/urandom</backend>
      <address type='pci' domain='0x0000' bus='0x07' slot='0x00' function='0x0'/>
    </rng>
  </devices>
</domain>

```

* Comprobamos que se ha creado el fichero .qcow2 en el directorio `/var/lib/libvirt/images/`

```sh
root@debian:/var/lib/libvirt/images# ls
buster-base.qcow2  compilar_default.img  debian-VAGRANTSLASH-buster64_vagrant_box_image_10.4.0.img
```

* Crea un par de claves ssh en formato ecdsa y sin frase de paso y agrega la clave pública al usuario debian

Creamos el par de claves indicado

```sh
ssh-keygen -t ecdsa -b 521
```
En la mv creamos el fichero 'authorized_keys'

```sh
debian@debian-kvm:~/.ssh$ cat authorized_keys
ecdsa-sha2-nistp521 AAAAE2VjZHNhLXNoYTItbmlzdHA1MjEAAAAIbmlzdHA1MjEAAACFBAF5SCIOXoPk1sXDH43L1r4YqoP15DHGxRfCvat01stXT0YEIeXujgFalyETMu3WqlIjLtca/b5JV4Gk//rk0IdfVQAXhQFgruXQ6e7EYSru0D9XCaTuiJ4oMzoFu/+caYUT+o5HeOSHTWj1EfOqqbJDsuACJ5vvjubPrQ54P6orN3D1dQ== celiagm@debian
```

* Utiliza la herramienta virt-sparsify para reducir al máximo el tamaño de la imagen


```sh
root@debian:/var/lib/libvirt/images# virt-sparsify --compress buster-base.qcow2 buster-base_red.qcow2
[   0.0] Create overlay file in /tmp to protect source disk
[   0.0] Examine source disk
 100% ⟦▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒⟧ --:--
[   7,1] Fill free space in /dev/sda1 with zero
[   8,7] Copy to destination and make sparse
[  64,8] Sparsify operation completed with no errors.
virt-sparsify: Before deleting the old disk, carefully check that the
target disk boots and works correctly.

```

* Comprobamos que está creada la imagen y ocupa menos espacio

```sh
root@debian:/var/lib/libvirt/images# ls -lh
total 5,8G
-rw------- 1 root         root         3,1G mar 22 17:38 buster-base.qcow2
-rw-r--r-- 1 root         root         377M mar 22 17:46 buster-base_red.qcow2

```


* Sube la imagen y la clave privada ssh a alguna ubicación pública desde la que se pueda descargar (lo subimos a mega)

__________________________

Escribe un shell script que ejecutado por un usuario con acceso a qemu:///system realice los siguientes pasos:

1. Crea una imagen nueva, que utilice buster-base.qcow2 como imagen base y tenga 5 GiB de tamaño máximo. Esta imagen se denominará maquina1.qcow2

```sh
qemu-img create -f qcow2 -b buster-base_red.qcow2 maquina1.qcow2 5G
```

```sh
root@debian:/var/lib/libvirt/images# qemu-img create -f qcow2 -b buster-base_red.qcow2 maquina1.qcow2 5G
Formatting 'maquina1.qcow2', fmt=qcow2 size=5368709120 backing_file=buster-base_red.qcow2 cluster_size=65536 lazy_refcounts=off refcount_bits=16
```

Comprobamos que se ha creado

```sh
root@debian:/var/lib/libvirt/images# ls -lh
total 5,8G
-rw------- 1 root         root         3,1G mar 22 17:38 buster-base.qcow2
-rw-r--r-- 1 root         root         377M mar 22 17:46 buster-base_red.qcow2
-rw------- 1 root         root         3,2G mar 18 17:51 compilar_default.img
-rwxr--r-- 1 libvirt-qemu libvirt-qemu 1,1G ene 27 11:01 debian-VAGRANTSLASH-buster64_vagrant_box_image_10.4.0.img
-rw-r--r-- 1 root         root         193K mar 22 18:18 maquina1.qcow2
```

2. Crea una red interna de nombre intra con salida al exterior mediante NAT que utilice el direccionamiento 10.10.20.0/24

Creamos el nuevo fichero .xml.

Le proporcionamos un identificador y le proporcionamos una mac respetando los tres primeros octetos.

```sh
cat /proc/sys/kernel/random/uuid
```
`intra.xml`
```sh
<network>
  <name>intra</name>
  <uuid>697e03ff-85da-45ff-815b-b16170e2125f</uuid>
  <forward mode='nat'>
    <nat>
      <port start='1024' end='65535'/>
    </nat>
  </forward>
  <bridge name='virbr3' stp='on' delay='0'/>
  <mac address='52:54:00:a1:51:25'/>
  <ip address='10.10.20.0' netmask='255.255.255.0'>
    <dhcp>
      <range start='10.10.20.2' end='10.10.20.254'/>
    </dhcp>
  </ip>
</network>
```
La definimos, la iniciamos y comprobamos que esta activo

```sh
root@debian:/etc/libvirt/qemu/networks# virsh net-define intra.xml
Network intra defined from intra.xml

root@debian:/etc/libvirt/qemu/networks# virsh net-start intra
Network intra started

root@debian:/home/celiagm/isos# virsh net-autostart intra
Network intra marked as autostarted


root@debian:/home/celiagm/isos# virsh net-list --all
 Name              State      Autostart   Persistent
------------------------------------------------------
 default           active     yes         yes
 intra             active     yes         yes
 red2              active     yes         yes
 vagrant-libvirt   inactive   no          yes

```


3. Crea una máquina virtual (maquina1) conectada a la red intra, con 1 GiB de RAM, que utilice como disco raíz maquina1.qcow2 y que se inicie automáticamente. Arranca la máquina.

Creamos el dominio, llamado maquina1.xml

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
      <source file='/var/lib/libvirt/images/maquina1.qcow2'/>
      <target dev='vda'/>
    </disk>
    <interface type="network">
      <source network="intra"/>
      <mac address="52:54:00:87:c1:a5"/>
    </interface>
    <graphics type='vnc' port='-1' autoport='yes' listen='0.0.0.0' />
  </devices>
</domain>
```

Comprobamos que es válido el fichero xml

```sh
root@debian:/etc/libvirt/qemu# virt-xml-validate maquina1.xml
maquina1.xml validates
```

Definimos y arrancamos la máquina
```sh
root@debian:/etc/libvirt/qemu# virsh define maquina1.xml
Domain maquina1 defined from maquina1.xml

root@debian:/etc/libvirt/qemu# virsh start maquina1
Domain maquina1 started
```

Vemos que está encendida

```sh
root@debian:/etc/libvirt/qemu# virsh list --all
 Id   Name               State
-----------------------------------
 3    maquina1           running
 -    buster-base        shut off
 -    compilar_default   shut off

```

Nos conectamos a ella

```sh
$ virt-viewer -c qemu:///system maquina1
```

4. Crea un volumen adicional de 1 GiB de tamaño en formato RAW ubicado en el pool por defecto

Creamos el volumen de 1Gb

`vol.xml`
```sh
<volume type='file'>
  <name>vol1.img</name>
  <key>/var/lib/libvirt/images/vol1.img</key>
  <source>
  </source>
  <allocation>0</allocation>
  <capacity unit="G">1</capacity>
  <target>
    <path>/var/lib/libvirt/images/vol1.img</path>
    <format type='raw'/>
  </target>
</volume>
```
Creamos el volumen en el pool por defecto
```sh
root@debian:/var/lib/libvirt/images# virsh vol-create default vol.xml
Vol vol1.img created from vol.xml
```

```sh
root@debian:/var/lib/libvirt/images# virsh vol-list default
 Name                                                        Path
------------------------------------------------------------------------------------------------------------------------------------------------
 buster-base.qcow2                                           /var/lib/libvirt/images/buster-base.qcow2
 compilar_default.img                                        /var/lib/libvirt/images/compilar_default.img
 debian-VAGRANTSLASH-buster64_vagrant_box_image_10.4.0.img   /var/lib/libvirt/images/debian-VAGRANTSLASH-buster64_vagrant_box_image_10.4.0.img
 vol1.img                                                    /var/lib/libvirt/images/vol1.img
```

5. Una vez iniciada la MV maquina1, conecta el volumen a la máquina, crea un sistema de ficheros XFS en el volumen y móntalo en el directorio /var/lib/pgsql. Ten cuidado con los propietarios y grupos que pongas, para que funcione adecuadamente el siguiente punto.


Conectamos el volumen creado de 1Gb a la máquina

```powershell
 root@debian:/var/lib/libvirt/images# virsh attach-disk maquina1 --source /var/lib/libvirt/images/vol1.img --target vdc --persistent
Disk attached successfully

```

Le damos formato XFS , para ello tenemos que intalar los siguientes paquetes

```powershell
sudo apt-get install xfsprogs dosfstools
```

```powershell
root@debian-kvm:/home/debian# mkfs
mkfs         mkfs.cramfs  mkfs.ext3    mkfs.fat     mkfs.msdos   mkfs.xfs
mkfs.bfs     mkfs.ext2    mkfs.ext4    mkfs.minix   mkfs.vfat
root@debian-kvm:/home/debian# lsblk -l
NAME MAJ:MIN RM SIZE RO TYPE MOUNTPOINT
vda  254:0    0   5G  0 disk
vda1 254:1    0   3G  0 part /
vdb  254:16   0   1G  0 disk
root@debian-kvm:/home/debian# mkfs.xfs /dev/vdb
meta-data=/dev/vdb               isize=512    agcount=4, agsize=65536 blks
         =                       sectsz=512   attr=2, projid32bit=1
         =                       crc=1        finobt=1, sparse=1, rmapbt=0
         =                       reflink=0
data     =                       bsize=4096   blocks=262144, imaxpct=25
         =                       sunit=0      swidth=0 blks
naming   =version 2              bsize=4096   ascii-ci=0, ftype=1
log      =internal log           bsize=4096   blocks=2560, version=2
         =                       sectsz=512   sunit=0 blks, lazy-count=1
realtime =none                   extsz=4096   blocks=0, rtextents=0
root@debian-kvm:/home/debian# lsblk -f
NAME   FSTYPE LABEL UUID                                 FSAVAIL FSUSE% MOUNTPOINT
vda
└─vda1 xfs          30a9cfb1-0b31-4368-8b7a-c6779804e450      2G    35% /
vdb    xfs          6ebae309-2c2f-4c67-b098-20a9afbda1a5
```

Antes de montarlo en el directorio `/var/lib/postgresql.` vamos a ver qué permisos tenemos que darle y que usuarios tenemos que crear para la base de datos en postgresql.


* Creamos el grupo postgres

```powershell
debian@debian-kvm:~$ sudo groupadd postgres

debian@debian-kvm:~$ sudo useradd postgres -m -g postgres
```

Creamos el directorio y le damos los permisos adecuados

```powershell
root@debian-kvm:/var/lib# mkdir postgresql
root@debian-kvm:/var/lib# chown -R postgres:postgres postgresql/
root@debian-kvm:/var/lib# ls -l | grep 'post'
drwxr-xr-x 2 postgres postgres   6 abr  5 19:50 postgresql
```

Montamos el disco en el directorio requerido

```powershell
root@debian-kvm:/var/lib# mount -t xfs /dev/vdb /var/lib/postgresql/
```

Vemos que se ha montado 

```sh
root@debian-kvm:/var/lib# lsblk -f 
NAME   FSTYPE LABEL UUID                                 FSAVAIL FSUSE% MOUNTPOINT
vda                                                                     
└─vda1 xfs          30a9cfb1-0b31-4368-8b7a-c6779804e450    1,7G    43% /
vdb    xfs          6ebae309-2c2f-4c67-b098-20a9afbda1a5  980,8M     3% /var/lib/postgresql

```

5. Instala en maquina1 el sistema de BBDD PostgreSQL que ubicará sus ficheros con las bases de datos en /var/lib/postgresql utilizando una conexión ssh.

Instalamos prostgres como se indica en el siguiente [post](https://www.celiagm.es/post/postgresql_debian/)


Comprobamos que se ha creado

```sh
root@debian-kvm:/var/lib/postgresql# ls -lh
total 0
drwxr-xr-x 3 postgres postgres 18 abr  7 15:11 11
```

Vamos a darle una contraseña al usuario postgres

```powershell
passwd postgres
```

1. (Opcional) Puebla la base de datos con una BBDD de prueba (escribe en la tarea el nombre de usuario y contraseña para acceder a la BBDD).

Creamos el usario celia y la base de datos 'prueba'

```sh
debian@debian-kvm:~$ sudo su
root@debian-kvm:/home/debian# su - postgresql
su: el usuario postgresql no existe
root@debian-kvm:/home/debian# su - postgres
$ psql	
psql (11.11 (Debian 11.11-1.pgdg100+1))
Digite «help» para obtener ayuda.

postgres=# create user celia with password 'celia';
CREATE ROLE
postgres=# create database prueba;
CREATE DATABASE
postgres=# grant all privileges on database prueba to celia;
GRANT
postgres=# exit
```

Entramos como usuario celia y poblamos la base de datos 

```sh
psql -h localhost -U celia -W -d prueba

```

Agregamos una tabla de prueba con sus registros 

```sh
create table departamento(
dept_no integer,
dnombre varchar(20),
loc varchar(20),
primary key (dept_no)
);

-- Añadimos registros 

insert into departamento
values ('10','CONTABILIDAD','SEVILLA');
insert into departamento
values ('20','INVESTIGACION','MADRID');
insert into departamento
values ('30','VENTAS','BARCELONA');
insert into departamento
values ('40','PRODUCCION','BILBAO');
```

Mostramos la tabla con los registros 

```sh
prueba=> \d
         Listado de relaciones
 Esquema |    Nombre    | Tipo  | Dueño 
---------+--------------+-------+-------
 public  | departamento | tabla | celia
(1 fila)

prueba=> select * from departamento;
 dept_no |    dnombre    |    loc    
---------+---------------+-----------
      10 | CONTABILIDAD  | SEVILLA
      20 | INVESTIGACION | MADRID
      30 | VENTAS        | BARCELONA
      40 | PRODUCCION    | BILBAO
(4 filas)

```


8. Crea una regla de NAT para que la base de datos sea accesible desde el exterior


Ahora vamos a editar el fichero de configuracion de postgres para hacer que sea accesible desde otras maquinas

```powershell
nano /etc/postgresql/11/main/postgresql.conf
```

Buscamos las líneas siguientes y las modificamos así

```powershell
listen_addresses = '*'          # what IP address(es) to listen on;

#unix_socket_group = ''                 # (change requires restart)
unix_socket_permissions = 0700          # begin with 0 to use octal notation

```

Editamos el siguiente fichero también y cambiamos lo siguiente

```powershell

nano /etc/postgresql/11/main/pg_hba.conf

```
Cambiamos

```powershell
# IPv4 local connections:
host    all             all             127.0.0.1/32            md5

# lo cambiamos por

host    all             all             all                   md5
```

Para permitir las conexiones desde cualquier dirección ip con cualquier usuario y base de datos (si éste tiene permiso para ello).

Ahora reiniciamos el servicio de postgres

```powershell
sudo systemctl restart postgresql
```

Comprobamos que está funcionando

```sh
root@debian-kvm:/# sudo systemctl status postgresql
● postgresql.service - PostgreSQL RDBMS
   Loaded: loaded (/lib/systemd/system/postgresql.service; enabled; vendor preset: enabled)
   Active: active (exited) since Wed 2021-03-31 22:18:03 CEST; 5s ago
  Process: 3249 ExecStart=/bin/true (code=exited, status=0/SUCCESS)
 Main PID: 3249 (code=exited, status=0/SUCCESS)

mar 31 22:18:03 debian-kvm systemd[1]: Starting PostgreSQL RDBMS...
mar 31 22:18:03 debian-kvm systemd[1]: Started PostgreSQL RDBMS.

```

Ahora que está accesible solo tenemos que crear la regla NAT

Primero miramos por donde está escuchando postgres

```sh
root@debian-kvm:/home/debian# netstat -tlpn
Active Internet connections (only servers)
Proto Recv-Q Send-Q Local Address           Foreign Address         State       PID/Program name    
tcp        0      0 0.0.0.0:22              0.0.0.0:*               LISTEN      408/sshd            
tcp        0      0 0.0.0.0:5432            0.0.0.0:*               LISTEN      8164/postgres       
tcp6       0      0 :::22                   :::*                    LISTEN      408/sshd            
tcp6       0      0 :::5432                 :::*                    LISTEN      8164/postgres    
```

Comprobamos que es el puerto **5434**, por lo tanto

```sh
sudo iptables -A INPUT -p tcp -s 10.10.20.158/24 --dport 5432 -m state --state NEW,ESTABLISHED -j ACCEPT
sudo iptables -A OUTPUT -p tcp --sport 5432 -m state --state ESTABLISHED -j ACCEPT
```

Comprobamos que podemos acceder desde la máquina anfitriona y podemos ver la tabla creada. Le pasaremos el parámetro -h (host) --port (puerto ) -U (usuario) -W (contraseña de forma forzada)

```sh
celiagm@debian:~$ psql -h 10.10.20.158 --port 5432 -U celia -W prueba
Contraseña: 
psql (11.11 (Debian 11.11-0+deb10u1))
conexión SSL (protocolo: TLSv1.3, cifrado: TLS_AES_256_GCM_SHA384, bits: 256, compresión: desactivado)
Digite «help» para obtener ayuda.

prueba=> \d
         Listado de relaciones
 Esquema |    Nombre    | Tipo  | Dueño 
---------+--------------+-------+-------
 public  | departamento | tabla | celia
(1 fila)

prueba=> 


```
9. Pausa la ejecución para comprobar los pasos hasta este punto


10. Continúa la ejecución cuando el usuario pulse 'C'

11. Crea una imagen que utilice buster-base.qcow2 como imagen base y que tenga un tamaño de 4 GiB. Esta imagen se llamará maquina2.qcow2

```sh
qemu-img create -f qcow2 -b buster-base_red.qcow2 maquina2.qcow2 4G
```

```sh
root@debian:/var/lib/libvirt/images# qemu-img create -f qcow2 -b buster-base_red.qcow2 maquina2.qcow2 4G
Formatting 'maquina2.qcow2', fmt=qcow2 size=4294967296 backing_file=buster-base_red.qcow2 cluster_size=65536 lazy_refcounts=off refcount_bits=16
```

* Comprobamos que se ha creado también la máquina2.

```sh
root@debian:/var/lib/libvirt/images# ls -lh | grep 'maquina'
-rw-r--r-- 1 libvirt-qemu libvirt-qemu 347M abr  5 19:32 maquina1.qcow2
-rw-r--r-- 1 root         root         193K abr  5 19:33 maquina2.qcow2

```

12. Crea una nueva máquina (maquina2) que utilice imagen anterior, con 1 GiB de RAM y que también esté conectada a intra.


