+++
author = "Celia García Márquez"
title = "ISCSI"
date = "2021-04-07"
description = "Configurar un servidor ISCSI"
tags = [
    "ISCSI", "almacenamiento",
]
thumbnail= "images/iscsi/iscsi.png"
+++

## Conceptos previos 

**¿Qué es ISCSI?**

Así a grandes rasgos se utiliza principalmente en redes de almacenamiento y proporciona acceso a dispositivos de bloque sobre TCP/IP. Es un protocolo a nivel de aplicación que como hemos dicho anteriormente permite el acceso a un dispositivo de almacenamiento de forma remota y segura.

ISCSI es un estándar del protocolo SCSI que permite la distribución de dispositivos de bloques a través de TCP/IP. Como hemos dicho anteriormente se suele usar en entornos donde se encuetra una NAS por ejemplo para aprovisionar de almacenamiento en red. 

En este post vamos a tener un entorno en el cual utilizaremos dos máquinas debian y una windows. 

## Tarea:
Configura un escenario con vagrant o similar que incluya varias máquinas que permita realizar la configuración de un servidor iSCSI y dos clientes (uno linux y otro windows). Explica de forma detallada en la tarea los pasos realizados.

En este caso vamos a utilizar Vagrant con virtualbox 6.0.

Tendremos:

* Máquina 1: debian1 (Debian Buster)
  * Disco duro de 1G
  * Interfaz de red pública en modo puente al br0 de mi máquina anfitriona
  * Interfaz de red privada con direccionamiento 10.0.4.3
* Máquina 2: debian2- Cliente (Debian Buster)
  * Interfaz de red privada con direccionamiento 10.0.4.4
* Máquina 3: Windows Cliente (Windows 7)
  * Interfaz de red privada con direccionamiento 10.0.4.5

El escenario lo montamos con una receta de vagrant con un fichero Vagrantfile:

```sh

# -*- mode: ruby -*-
# vi: set ft=ruby :


Vagrant.configure("2") do |config|
  disco = '.vagrant/midisco.vdi'
  config.vm.define :debian1 do |debian1|
    debian1.vm.box = "debian/buster64"
    debian1.vm.hostname = "debian1"
    debian1.vm.network :public_network, :bridge=>"br0"
    debian1.vm.network :private_network, ip: "10.0.4.3"
    debian1.vm.provider :virtualbox do |v|
      v.customize ["createhd", "--filename", disco, "--size", 1024]
      v.customize ["storageattach", :id, "--storagectl", "SATA Controller", "--port", 1, "--device", 0, $
    end
  end
  config.vm.define :debian2 do |debian2|
    debian2.vm.box = "debian/buster64"
    debian2.vm.hostname = "debian2"
    debian2.vm.network :private_network, ip: "10.0.4.4"
  end

config.vm.define :windows do |windows|
    windows.vm.box = "icehofman/windows-7-virtualbox"
    windows.vm.hostname = "windows"
    windows.vm.network :private_network, ip: "10.0.4.5"
  end
end

```

## Configuración 

### Máquina 1: Servidor Debian

Utilizaremos Logical Volume Management (LVM) como respaldo de almacenamiento para el destino ISCSI.

Necesitaremos tener instalado el paquete lvm2. 

Inicializamos el disco y creamos el grupo de volúmenes lógicos en el que vamos a particionar un volumen de 500M 

```sh
vagrant@debian1:~$ sudo pvcreate /dev/sdb
  Physical volume "/dev/sdb" successfully created.
vagrant@debian1:~$ sudo vgcreate gp1 /dev/sdb
  Volume group "gp1" successfully created
vagrant@debian1:~$ sudo lvcreate -L 500M -n v_gp1 gp1
  Logical volume "v_gp1" created.
vagrant@debian1:~$ lsblk -f
NAME        FSTYPE LABEL UUID                                 FSAVAIL FSUSE% MOUNTPOINT
sda                                                                          
├─sda1      ext4         983742b1-65a8-49d1-a148-a3865ea09e24   16.1G     7% /
├─sda2                                                                       
└─sda5      swap         04559374-06db-46f1-aa31-e7a4e6ec3286                [SWAP]
sdb                                                                          
└─gp1-v_gp1               
```

### Crear el target y definir una LUN

> Crea un **target con una LUN** y conéctala a un cliente GNU/Linux. 

Necesitaremos el paquete `tgt`. Este paquete se conoce como Marco de Destino. Tiene como objetivo simplificar la creación y el mantenimiento de controladores de destino SCSI. 

```sh
sudo apt-get install tgt
```

Ahora definiremos la **LUN**. Para no entrar en detalles una LUN es una pequeña parte de un disco lógico que se asignará al servidor cliente para su utilización. Nuestro cliente lo reconocerá como un disco corriente aunque en realidad se trate de una infraestructura más compleja en la que el almacenamiento está compartido por red. (SAN por ejemplo).

Para ello editaremos el fichero de configuración `/etc/tgt/targets.conf` y indicamos el target con destino al volumen lógico que hemos definido anteriormente.

```sh
# Empty targets configuration file -- please see the package
# documentation directory for an example.
#
# You can drop individual config snippets into /etc/tgt/conf.d
include /etc/tgt/conf.d/*.conf

<target iqn.2021-04.iscsi:tgt1>
    backing-store /dev/gp1/v_gp1   
</target>

```

Reiniciamos el servicio tgt de esta forma 

```sh
sudo /etc/init.d/tgt reload
```

Verificamos que está disponible el LUN que acabamos de definir 

```sh
vagrant@debian1:~$ sudo tgtadm --mode target --op show
Target 1: iqn.2021-04.iscsi:tgt1
    System information:
        Driver: iscsi
        State: ready
    I_T nexus information:
    LUN information:
        LUN: 0
            Type: controller
            SCSI ID: IET     00010000
            SCSI SN: beaf10
            Size: 0 MB, Block size: 1
            Online: Yes
            Removable media: No
            Prevent removal: No
            Readonly: No
            SWP: No
            Thin-provisioning: No
            Backing store type: null
            Backing store path: None
            Backing store flags: 
        LUN: 1
            Type: disk
            SCSI ID: IET     00010001
            SCSI SN: beaf11
            Size: 524 MB, Block size: 512
            Online: Yes
            Removable media: No
            Prevent removal: No
            Readonly: No
            SWP: No
            Thin-provisioning: No
            Backing store type: rdwr
            Backing store path: /dev/gp1/v_gp1
            Backing store flags: 
    Account information:
    ACL information:
        ALL

```

Efectivamente tenemos la LUN definida y el servidor configurado para que los clientes puedan acceder al disco.

### Máquina 2: Iniciador Debian


Antes de continuar vamos a explicar brevemente que es un iniciador. 

El **iniciador ISCSI** es un software en este caso que, origina la comunicación entre el cliente y el sistema de almacenamiento ISCSI externo y permite el envío de datos entre ambos.

Necesitaremos instalar el paquete `open-iscsi`. Este software nos permite usar el target del servidor. 

```sh
sudo apt-get install open-iscsi
```

Editamos el fichero `/etc/iscsi/iscsid.conf` y le indicamos que busque los targets de forma automática de la siguiente forma.

```sh
#*****************
# Startup settings
#*****************

# To request that the iscsi initd scripts startup a session set to "automatic".
node.startup = automatic
#
# To manually startup the session set to "manual". The default is manual.
#node.startup = manual

```

Reiniciamos el servicio para efectuar los cambios

```sh
sudo systemctl restart open-iscsi
```

> Explica cómo escaneas desde el cliente buscando los targets disponibles y utiliza la unidad lógica proporcionada, formateándola si es necesario y montándola.

Ahora vamos a comprobar que al escanear encontramos el target indicando la ip del servidor.

```sh
vagrant@debian2:~$ sudo iscsiadm -m discovery -t st -p 10.0.4.3
10.0.4.3:3260,1 iqn.2021-04.iscsi:tgt1
```

#### Conectar al target 

Para conectarnos al target utilizaremos **iscsiadm** que es la herramienta que tiene el paquete open-iscsi para su administración. 

Le tendremos que pasar varios parámetros, entre ellos el modo, el nombre del target y el portal destino, en este caso la ip del servidor, siendo el puerto predeterminado el 3260.

```sh
sudo iscsiadm -m node -T iqn.2021-04.iscsi:tgt1 --portal "10.0.4.3" --login
```

Vemos que efectivamente se ha conectando con éxito.

```sh
vagrant@debian2:~$ sudo iscsiadm -m node -T iqn.2021-04.iscsi:tgt1 --portal "10.0.4.3" --login

Logging in to [iface: default, target: iqn.2021-04.iscsi:tgt1, portal: 10.0.4.3,3260] (multiple)
Login to [iface: default, target: iqn.2021-04.iscsi:tgt1, portal: 10.0.4.3,3260] successful.
```

Ahora si todo ha ido bien deberíamos de ver el nuevo disco en nuestro cliente 

```sh
vagrant@debian2:~$ lsblk -f
NAME   FSTYPE LABEL UUID                                 FSAVAIL FSUSE% MOUNTPOINT
sda                                                                     
├─sda1 ext4         983742b1-65a8-49d1-a148-a3865ea09e24   16.1G     7% /
├─sda2                                                                  
└─sda5 swap         04559374-06db-46f1-aa31-e7a4e6ec3286                [SWAP]
sdb                                                                     
```

### Formatear y montar el disco nuevo

Ahora ya podemos formatear y montar el disco para darle uso.

```sh
sudo fdisk /dev/sdb 
sudo mkfs.ext4 /dev/sdb1
sudo mkdir /home/vagrant/disco
sudo mount /dev/sdb1 /home/vagrant/disco
```

Vemos que se ha creado y montado correctamente

```sh
vagrant@debian2:~$ sudo mount /dev/sdb1 /home/vagrant/disco/
vagrant@debian2:~$ lsblk -f
NAME   FSTYPE LABEL UUID                                 FSAVAIL FSUSE% MOUNTPOINT
sda                                                                     
├─sda1 ext4         983742b1-65a8-49d1-a148-a3865ea09e24   16.1G     7% /
├─sda2                                                                  
└─sda5 swap         04559374-06db-46f1-aa31-e7a4e6ec3286                [SWAP]
sdb                                                                     
└─sdb1 ext4         a7bc3eab-12fa-41d5-9bb4-c9a1fc6eb753    444M     0% /home/vagrant/disco
```

### Montar el target automáticamente.

> Utiliza systemd mount para que el target se monte automáticamente al arrancar el cliente

Para ello vamos a crear una unidad de systemd tipo `.mount`. Esta se encargará de montar los volúmenes despues que se inicie el servicio de open-iscsi. 

Para hacer esto necesitaremos indicar en el fichero de extensión .mount el target que vamos a montar y dónde lo vamos a montar. 

Creamos el directorio donde lo vamos a montar

```sh
root@debian2:~# mkdir /iscsi
```

Creamos la unidad 

```sh
sudo nano /etc/systemd/system/iscsi-tgt1.mount
```

```sh
[Unit]
Description=Unidad de montaje para tgt1
After=open-iscsi.service

[Mount]
What=/dev/sdb1
Where=/iscsi/tgt1
Type=ext4
Options=defaults

[Install]
WantedBy=multi-user.target
```


Reiniciamos los servicios 

```sh
vagrant@debian2:~$ sudo systemctl daemon-reload
vagrant@debian2:~$ sudo systemctl enable iscsi-tgt1.mount
vagrant@debian2:~$ sudo systemctl start iscsi-tgt1.mount

```

Comprobamos que está habilitado 

```sh
vagrant@debian2:~$ sudo systemctl status iscsi-tgt1.mount
● iscsi-tgt1.mount - Unidad de montaje para tgt1
   Loaded: loaded (/etc/systemd/system/iscsi-tgt1.mount; enabled; vendor preset: enabled)
   Active: active (mounted) since Sat 2021-04-24 17:43:34 GMT; 1min 42s ago
    Where: /iscsi/tgt1
     What: /dev/sdb1
    Tasks: 0 (limit: 544)
   Memory: 112.0K
   CGroup: /system.slice/iscsi-tgt1.mount

Apr 24 17:43:34 debian2 systemd[1]: Mounting Unidad de montaje para tgt1...
Apr 24 17:43:34 debian2 systemd[1]: Mounted Unidad de montaje para tgt1.

```

Si reiniciamos la máquina cliente y todo ha ido bien debería de montarse automáticamente.

```sh
vagrant@debian2:~$ lsblk 
NAME   MAJ:MIN RM  SIZE RO TYPE MOUNTPOINT
sda      8:0    0 19.8G  0 disk 
├─sda1   8:1    0 18.8G  0 part /
├─sda2   8:2    0    1K  0 part 
└─sda5   8:5    0 1021M  0 part [SWAP]
sdb      8:16   0  500M  0 disk 
└─sdb1   8:17   0  499M  0 part /iscsi/tgt1
```

Comprobamos que es totalmente funcional 

```sh
vagrant@debian2:~$ cd /iscsi/tgt1/
vagrant@debian2:/iscsi/tgt1$ ls
hola.txt  lost+found
vagrant@debian2:/iscsi/tgt1$ 

```

### Target con 2 LUN. Cliente Windows CHAP.

> Crea un target con 2 LUN y autenticación por CHAP y conéctala a un cliente windows. Explica cómo se escanea la red en windows y cómo se utilizan las unidades nuevas (formateándolas con NTFS)

#### Máquina 1: Servidor Debian 

Creamos dos volúmenes lógicos de 200M cada uno.

```sh
vagrant@debian1:~$ sudo lvcreate -L 200M -n v1_gp1 gp1
  Logical volume "v1_gp1" created.
vagrant@debian1:~$ sudo lvcreate -L 200M -n v2_gp1 gp1
  Logical volume "v2_gp1" created.
vagrant@debian1:~$ lsblk -f
NAME         FSTYPE      LABEL UUID                                   FSAVAIL FSUSE% MOUNTPOINT
sda                                                                                  
├─sda1       ext4              983742b1-65a8-49d1-a148-a3865ea09e24     16.1G     7% /
├─sda2                                                                               
└─sda5       swap              04559374-06db-46f1-aa31-e7a4e6ec3286                  [SWAP]
sdb          LVM2_member       bc0nrL-OLGb-0Y2M-IC0g-zJiX-T5Mk-7UGptu                
├─gp1-v_gp1                                                                          
├─gp1-v1_gp1                                                                         
└─gp1-v2_gp1          
```


De igual forma que creamos el primer target, ahora vamos a crear otro pero definiremos dos **LUN**. Utilizaremos la autentificación **CHAP** , es decir le pondremos el usuario y la contraseña para que se pueda autentificar con el cliente windows.

```sh
## Crear el target

<target iqn.2021-04.iscsi:tgt2>
      backing-store /dev/gp1/v1_gp1
      backing-store /dev/gp1/v2_gp1
      initiator-address 10.0.4.5
      incominguser usuario contrasenia
</target>

```

Ahora reiniciamos el servicio y habilitamos el target con los dos lun, podemos ver que se han habilitado los nuevos lun con los discos indicados 

```sh
vagrant@debian1:~$ sudo /etc/init.d/tgt reload
[ ok ] Reloading tgt configuration (via systemctl): tgt.service.
vagrant@debian1:~$ sudo nano /etc/tgt/targets.conf 
vagrant@debian1:~$ sudo tgtadm --mode target --op show
Target 1: iqn.2021-04.iscsi:tgt1
    System information:
        Driver: iscsi
        State: ready
    I_T nexus information:
        I_T nexus: 1
            Initiator: iqn.1993-08.org.debian:01:59ae50965476 alias: debian2
            Connection: 0
                IP Address: 10.0.4.4
    LUN information:
        LUN: 0
            Type: controller
            SCSI ID: IET     00010000
            SCSI SN: beaf10
            Size: 0 MB, Block size: 1
            Online: Yes
            Removable media: No
            Prevent removal: No
            Readonly: No
            SWP: No
            Thin-provisioning: No
            Backing store type: null
            Backing store path: None
            Backing store flags: 
        LUN: 1
            Type: disk
            SCSI ID: IET     00010001
            SCSI SN: beaf11
            Size: 524 MB, Block size: 512
            Online: Yes
            Removable media: No
            Prevent removal: No
            Readonly: No
            SWP: No
            Thin-provisioning: No
            Backing store type: rdwr
            Backing store path: /dev/gp1/v_gp1
            Backing store flags: 
    Account information:
    ACL information:
        ALL
Target 2: iqn.2021-04.iscsi:tgt2
    System information:
        Driver: iscsi
        State: ready
    I_T nexus information:
    LUN information:
        LUN: 0
            Type: controller
            SCSI ID: IET     00020000
            SCSI SN: beaf20
            Size: 0 MB, Block size: 1
            Online: Yes
            Removable media: No
            Prevent removal: No
            Readonly: No
            SWP: No
            Thin-provisioning: No
            Backing store type: null
            Backing store path: None
            Backing store flags: 
        LUN: 1
            Type: disk
            SCSI ID: IET     00020001
            SCSI SN: beaf21
            Size: 210 MB, Block size: 512
            Online: Yes
            Removable media: No
            Prevent removal: No
            Readonly: No
            SWP: No
            Thin-provisioning: No
            Backing store type: rdwr
            Backing store path: /dev/gp1/v1_gp1
            Backing store flags: 
        LUN: 2ca
            Type: disk
            SCSI ID: IET     00020002
            SCSI SN: beaf22
            Size: 210 MB, Block size: 512
            Online: Yes
            Removable media: No
            Prevent removal: No
            Readonly: No
            SWP: No
            Thin-provisioning: No
            Backing store type: rdwr
            Backing store path: /dev/gp1/v2_gp1
            Backing store flags: 
    Account information:
        celia.celia
    ACL information:
        10.0.4.5
vagrant@debian1:~$ 

```

### Máquina 3: Cliente windows

En la máquina windows vamos a buscar 'iscsi initiator' 

![win1.png](/images/iscsi/win1.png)


Ahora vamos a la pestaña configuración y le cambiamos el nombre 

![win2.png](/images/iscsi/win2.png)

Vamos a la pestaña de Targets , refrescamos y debe de aparecer los targets en linea, elegimos en este caso el segundo que es el que tiene los dos LUN.

![win3.png](/images/iscsi/win3.png)

Antes de conectarnos con OK, vamos a Avanced y configuramos el usuario y la contraseña

![win4.png](/images/iscsi/win4.png)

Una vez configurado y aceptado vemos que se ha conectado correctamente.

![win5.png](/images/iscsi/win5.png)

Para formatear los discos vamos a la utilidad 'disk Management' y ya nos aparece que los dos discos estan para su uso

![win6.png](/images/iscsi/win6.png)

Los formateamos con NTFS

![win7.png](/images/iscsi/win7.png)

Una vez formateados podemos ver que están operativos para funcionar.

![win8.png](/images/iscsi/win8.png)

Podemos crear un directorio y fichero de prueba

![win9.png](/images/iscsi/win9.png)


Como hemos podido comprobar con esta imagen tenemos un servidor en el que tenemos un disco con tres particiones, una de ellas compartida en red con un cliente debian y las dos ultimas con un cliente windows a partir de targets y sus LUN bien definidas.

![final.png](/images/iscsi/final.png)


## Conclusión 

Esto puede ser realmente útil para un fácil acceso a tu almacenamiento desde la red estés en el sitio que estés si dispones de una VPN por ejemplo.