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

```sh
https://1bit1nfo.netlify.app/post/migracion_app_mv/
```

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


