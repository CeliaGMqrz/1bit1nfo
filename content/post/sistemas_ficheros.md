+++
author = "Celia García Márquez"
title = "Sistemas de ficheros avanzados. Btrfs."
date = "2021-05-03"
description = "Sistemas de ficheros avanzados"
tags = [
    "Btrfs",
]
thumbnail= "images/btrfs/btrfs.png"
+++

## ZFS/Btrfs

Son sistemas de archivos de alto rendimiento.

En este post hablaremos sobre Btrfs, que es el que hemos elegido para la práctica.

**Btrfs** lo desarrolló Oracle Corporation para GNU/Linux. Surge con el objetivo de sustituir el sistema de archivos ZFS linux. Actualmente se considera estable. A diferencia del sistema original tiene una serie de caracteristicas que lo aventaja.

Se trata de un sistema completo de almacenamiento que no requiere otras herramientas pero podemos instalar *btrfs-progs* que es una herramienta adicional. Btrfs viene nativa en el kernel linux actualmente.

Btrfs tiene como caracteristicas similares a las de ZFS.

Caracteristicas avanzadas de ZFS:

* Consta de Copy on Write (CoW). Este sistema hace que al copiar un fichero, la copia no es más que una referencia o puntero del original(no cambian los rangos en los bloques a no ser que se modifique la copia).
* Permite la deduplicación.
* Cifrado propio.
* Permite la compresión. Almacena los ficheros comprimidos para optimizar el uso del espacio.
* Gestión de volúmenes. Permite gestionar volúmenes de forma independiente.
* Permite hacer snapshots de forma nativa.
* Tiene redundancia (RAID) sin necesidad de utilizar otro software como mdadm.


Como hemos dicho anteriormente, Btrfs prácticamente tiene las mismas caracteristicas excluyendo el *cifrado propio*.



## Entorno de trabajo: Escenario.

### Crea un escenario que incluya una máquina y varios discos asociados a ella.

Vamos a crear una mv en Vagrant con Virtualbox, que contendrá 5 discos y el SO será Debian Buster.

```sh
disk = './tmp/hdd21.vdi'
disk2 = './tmp/hdd22.vdi'
disk3 = './tmp/hdd23.vdi'
disk4 = './tmp/hdd24.vdi'
disk5 = './tmp/hdd25.vdi'

Vagrant.configure("2") do |config|
  config.vm.box = "debian/buster64"
  config.vm.hostname = "btrfs2"
  config.vm.provider "virtualbox" do |vb|
     vb.memory = "1024"
     vb.cpus = 1

     #Añadir discos
     if not File.exist?(disk)
       vb.customize ['createhd', '--filename', disk, '--size', 1 * 1024]
     end
     vb.customize ['storageattach', :id,  '--storagectl', 'SATA Controller', '--port', 1, '--device', 0, '--type', 'hdd', '--medium', disk]
     if not File.exist?(disk)
       vb.customize ['createhd', '--filename', disk2, '--size', 1 * 1024]
     end
     vb.customize ['storageattach', :id,  '--storagectl', 'SATA Controller', '--port', 2, '--device', 0, '--type', 'hdd', '--medium', disk2]
     if not File.exist?(disk)
       vb.customize ['createhd', '--filename', disk3, '--size', 1 * 1024]
     end
     vb.customize ['storageattach', :id,  '--storagectl', 'SATA Controller', '--port', 3, '--device', 0, '--type', 'hdd', '--medium', disk3]
     if not File.exist?(disk)
       vb.customize ['createhd', '--filename', disk4, '--size', 1 * 1024]
     end
     vb.customize ['storageattach', :id,  '--storagectl', 'SATA Controller', '--port', 4, '--device', 0, '--type', 'hdd', '--medium', disk4]
     if not File.exist?(disk)
       vb.customize ['createhd', '--filename', disk5, '--size', 1 * 1024]
     end
     vb.customize ['storageattach', :id,  '--storagectl', 'SATA Controller', '--port', 5, '--device', 0, '--type', 'hdd', '--medium', disk5]
  end
end

```

Una vez dentro de la mv vamos a ejecutar '*lsblk*' para ver que los discos están disponibles.

```sh
vagrant@btrfs2:~$ lsblk
NAME   MAJ:MIN RM  SIZE RO TYPE MOUNTPOINT
sda      8:0    0 19.8G  0 disk
├─sda1   8:1    0 18.8G  0 part /
├─sda2   8:2    0    1K  0 part
└─sda5   8:5    0 1021M  0 part [SWAP]
sdb      8:16   0    1G  0 disk
sdc      8:32   0    1G  0 disk
sdd      8:48   0    1G  0 disk
sde      8:64   0    1G  0 disk
sdf      8:80   0    1G  0 disk

```

### Instala si es necesario el software de ZFS/Btrfs.

Instalamos el software necesario si no viene incluido de la siguiente forma.

```sh
sudo apt install btrfs-tools
```

### Gestiona los discos adicionales con ZFS/Btrfs.

En esta practica vamos a montar un Raid 5 con los tres primeros discos y dejaremos los dos últimos para sustituirlos en caso de fallo de alguno de ellos.

**¡!**

Todos los discos son de 1 GB pero podríamos tener discos de diferente tamaño para comprobar que al montar el RAID aprobecha todo el espacio posible y no pone un máximo o una quota como lo hace mdadm de la forma tradicional. En este caso como todos son de 1Gb no se verá esta característica, pero es importante mencionarla.

#### Formatear sdb a btrfs

Vamos a crear un sistema de ficheros btrfs sobre sdb

```sh
mkfs.btrfs /dev/sdb
```

```sh
root@btrfs2:/home/vagrant# mkfs.btrfs /dev/sdb
btrfs-progs v4.20.1
See http://btrfs.wiki.kernel.org for more information.

Label:              (null)
UUID:               0f50eb6d-5c33-4633-b2d7-a2dbcaac8d9b
Node size:          16384
Sector size:        4096
Filesystem size:    1.00GiB
Block group profiles:
  Data:             single            8.00MiB
  Metadata:         DUP              51.19MiB
  System:           DUP               8.00MiB
SSD detected:       no
Incompat features:  extref, skinny-metadata
Number of devices:  1
Devices:
   ID        SIZE  PATH
    1     1.00GiB  /dev/sdb

```

Comprobamos que se ha definido correctamente

```sh
root@btrfs2:/home/vagrant# lsblk -f
NAME   FSTYPE LABEL UUID                                 FSAVAIL FSUSE% MOUNTPOINT
sda
├─sda1 ext4         983742b1-65a8-49d1-a148-a3865ea09e24   16.1G     7% /
├─sda2
└─sda5 swap         04559374-06db-46f1-aa31-e7a4e6ec3286                [SWAP]
sdb    btrfs        0f50eb6d-5c33-4633-b2d7-a2dbcaac8d9b
sdc
sdd
sde
sdf
```
### Soporte en dos dispositivos (pool de almacenamiento)

Extenderemos el almacenamiento al disco sdc y comprobamos que funciona correctamente montandolo en un directorio.

```sh
root@btrfs2:/home/vagrant# sudo mkfs.btrfs -f /dev/sdb /dev/sdc
btrfs-progs v4.20.1
See http://btrfs.wiki.kernel.org for more information.

Label:              (null)
UUID:               86b2529f-b1a8-4937-8bbc-71666a87c24b
Node size:          16384
Sector size:        4096
Filesystem size:    2.00GiB
Block group profiles:
  Data:             RAID0           204.75MiB
  Metadata:         RAID1           102.38MiB
  System:           RAID1             8.00MiB
SSD detected:       no
Incompat features:  extref, skinny-metadata
Number of devices:  2
Devices:
   ID        SIZE  PATH
    1     1.00GiB  /dev/sdb
    2     1.00GiB  /dev/sdc

```

Vemos que se ha montado correctamente y que el UUID es el mismo. Lo interpreta como RAID0 /RAID1. Une los dos discos como si fueran uno.

```sh
root@btrfs2:/home/vagrant# mkdir /btrfs
root@btrfs2:/home/vagrant# mount /dev/sdb /btrfs/
root@btrfs2:/home/vagrant# lsblk -f
NAME   FSTYPE LABEL UUID                                 FSAVAIL FSUSE% MOUNTPOINT
sda
├─sda1 ext4         983742b1-65a8-49d1-a148-a3865ea09e24   16.1G     7% /
├─sda2
└─sda5 swap         04559374-06db-46f1-aa31-e7a4e6ec3286                [SWAP]
sdb    btrfs        86b2529f-b1a8-4937-8bbc-71666a87c24b    1.8G     1% /btrfs
sdc    btrfs        86b2529f-b1a8-4937-8bbc-71666a87c24b
sdd
sde
sdf
```

Ahora vamos a desmontarlo y crearemos el raid 5 en los tres primeros discos.

### Configura los discos en RAID, haciendo pruebas de fallo de algún disco y sustitución, restauración del RAID. Comenta ventajas e inconvenientes respecto al uso de RAID software con mdadm.

Creamos raid5 con btrfs, le indicaremos que es un RAID5 de la siguiente forma.


```sh
root@btrfs2:/home/vagrant# mkfs.btrfs -d raid5 -m raid5 -f /dev/sdb /dev/sdc /dev/sdd
btrfs-progs v4.20.1
See http://btrfs.wiki.kernel.org for more information.

Label:              (null)
UUID:               76597d6f-6564-4468-9f6d-2d4f1de13a39
Node size:          16384
Sector size:        4096
Filesystem size:    3.00GiB
Block group profiles:
  Data:             RAID5           204.75MiB
  Metadata:         RAID5           204.75MiB
  System:           RAID5            16.00MiB
SSD detected:       no
Incompat features:  extref, raid56, skinny-metadata
Number of devices:  3
Devices:
   ID        SIZE  PATH
    1     1.00GiB  /dev/sdb
    2     1.00GiB  /dev/sdc
    3     1.00GiB  /dev/sdd

```

Vemos los dispositivos de bloques en el que el uuid es el mismo y pertenece a los tres discos.

```sh
root@btrfs2:/home/vagrant# btrfs filesystem show
Label: none  uuid: 76597d6f-6564-4468-9f6d-2d4f1de13a39
	Total devices 3 FS bytes used 128.00KiB
	devid    1 size 1.00GiB used 212.75MiB path /dev/sdb
	devid    2 size 1.00GiB used 212.75MiB path /dev/sdc
	devid    3 size 1.00GiB used 212.75MiB path /dev/sdd

```

Montamos uno de los discos del raid y comprobamos su capacidad.

```sh
root@btrfs2:/home/vagrant# mount /dev/sdb /btrfs/
root@btrfs2:/home/vagrant# df -h
Filesystem      Size  Used Avail Use% Mounted on
udev            480M     0  480M   0% /dev
tmpfs            99M  2.9M   96M   3% /run
/dev/sda1        19G  1.4G   17G   8% /
tmpfs           494M     0  494M   0% /dev/shm
tmpfs           5.0M     0  5.0M   0% /run/lock
tmpfs           494M     0  494M   0% /sys/fs/cgroup
tmpfs            99M     0   99M   0% /run/user/1000
/dev/sdb        3.0G   17M  2.6G   1% /btrfs

```

Como se puede apreciar tiene un total de 3GB , la suma de los tres discos.


Debemos saber que hay una utilidad, SCRUB de btrfs, que se utiliza pra limpiar el sistema de archivos btrfs. Lee los dispositivos de bloque y verifica las sumas de su comprobación, en otras palabras comprueba que no hay errores, y repara los bloques dañados si hay una copia correcta disponible.

De la siguiente forma comprobamos que todo está correcto.

```sh
root@btrfs2:/home/vagrant# btrfs scrub start /dev/sdb
scrub started on /dev/sdb, fsid 76597d6f-6564-4468-9f6d-2d4f1de13a39 (pid=5086)
root@btrfs2:/home/vagrant# btrfs scrub status /dev/sdb
scrub status for 76597d6f-6564-4468-9f6d-2d4f1de13a39
	scrub started at Sat May  1 18:21:39 2021 and finished after 00:00:00
	total bytes scrubbed: 0.00B with 0 errors

```

En este ejemplo no vamos a provocar un fallo como tal pero suponemos que uno de los discos está dañado, entonces procedemos a añadir uno de los discos adicionales para sustituirlo.

Comprobaremos que el tamaño a 4 gb ya que tenemos los 4 discos.

```sh
root@btrfs2:/home/vagrant# btrfs device add /dev/sde /btrfs
root@btrfs2:/home/vagrant# lsblk -f
NAME   FSTYPE LABEL UUID                                 FSAVAIL FSUSE% MOUNTPOINT
sda
├─sda1 ext4         983742b1-65a8-49d1-a148-a3865ea09e24   16.1G     7% /
├─sda2
└─sda5 swap         04559374-06db-46f1-aa31-e7a4e6ec3286                [SWAP]
sdb    btrfs        76597d6f-6564-4468-9f6d-2d4f1de13a39    3.1G     0% /btrfs
sdc    btrfs        76597d6f-6564-4468-9f6d-2d4f1de13a39
sdd    btrfs        76597d6f-6564-4468-9f6d-2d4f1de13a39
sde    btrfs        76597d6f-6564-4468-9f6d-2d4f1de13a39
sdf
root@btrfs2:/home/vagrant# df -h
Filesystem      Size  Used Avail Use% Mounted on
udev            480M     0  480M   0% /dev
tmpfs            99M  2.9M   96M   3% /run
/dev/sda1        19G  1.4G   17G   8% /
tmpfs           494M     0  494M   0% /dev/shm
tmpfs           5.0M     0  5.0M   0% /run/lock
tmpfs           494M     0  494M   0% /sys/fs/cgroup
tmpfs            99M     0   99M   0% /run/user/1000
/dev/sdb        4.0G   17M  3.2G   1% /btrfs

```

Vemos los discos actuales.

```sh
root@btrfs2:/home/vagrant# btrfs filesystem show
Label: none  uuid: 76597d6f-6564-4468-9f6d-2d4f1de13a39
	Total devices 4 FS bytes used 256.00KiB
	devid    1 size 1.00GiB used 364.75MiB path /dev/sdb
	devid    2 size 1.00GiB used 364.75MiB path /dev/sdc
	devid    3 size 1.00GiB used 364.75MiB path /dev/sdd
	devid    4 size 1.00GiB used 0.00B path /dev/sde

```

Eliminamos el disco que tiene el fallo por ejemplo el **sdc** y comprobamos  que usa el nuevo disco **sde**

```sh
root@btrfs2:/home/vagrant# btrfs device delete /dev/sdc /btrfs/
root@btrfs2:/home/vagrant# btrfs filesystem show
Label: none  uuid: 76597d6f-6564-4468-9f6d-2d4f1de13a39
	Total devices 3 FS bytes used 320.00KiB
	devid    1 size 1.00GiB used 320.00MiB path /dev/sdb
	devid    3 size 1.00GiB used 320.00MiB path /dev/sdd
	devid    4 size 1.00GiB used 320.00MiB path /dev/sde
```

Vemos que actualmente tenemos ocupados (sdb, sdd, sde)

```sh
vagrant@btrfs2:~$ lsblk -f
NAME FSTYPE LABEL UUID                                 FSAVAIL FSUSE% MOUNTPOINT
sda
├─sda1
│    ext4         983742b1-65a8-49d1-a148-a3865ea09e24   16.1G     7% /
├─sda2
│
└─sda5
     swap         04559374-06db-46f1-aa31-e7a4e6ec3286                [SWAP]
sdb  btrfs        76597d6f-6564-4468-9f6d-2d4f1de13a39
sdc
sdd  btrfs        76597d6f-6564-4468-9f6d-2d4f1de13a39
sde  btrfs        76597d6f-6564-4468-9f6d-2d4f1de13a39
sdf
```

____________________________

### Realiza ejercicios con pruebas de funcionamiento de las principales funcionalidades: compresión, cow, deduplicación, cifrado, etc.

## Compresion al vuelo

![compres.png](/images/btrfs/compes.png)

Se trata de almacenar la información comprimida, de foma que hacer la lectura el sistema es capaz de descomprimirla en ese mismo momento. La compresión se realiza archivo por archivo. Hay tres algoritmos disponibles ZLIB, LZO y ZSTD. El método predeterminado utliza el algoritmo ZLIB.

Para ello vamos a utilzar el disco sdf, le damos formato y lo montamos en un directorio aparte.

```sh
sudo mkfs.btrfs /dev/sdf

```

```sh
vagrant@btrfs2:~$ mkdir compresion
```

Ahora relizamos la compresión al vuelo

```sh
sudo mount -o compress=zlib /dev/sdf compresion/
```

Vemos que se ha montado correctamente

```sh
vagrant@btrfs2:~$ lsblk -f
NAME   FSTYPE LABEL UUID                                 FSAVAIL FSUSE% MOUNTPOINT
sda
├─sda1 ext4         983742b1-65a8-49d1-a148-a3865ea09e24   16.1G     7% /
├─sda2
└─sda5 swap         04559374-06db-46f1-aa31-e7a4e6ec3286                [SWAP]
sdb    btrfs        76597d6f-6564-4468-9f6d-2d4f1de13a39
sdc
sdd    btrfs        76597d6f-6564-4468-9f6d-2d4f1de13a39
sde    btrfs        76597d6f-6564-4468-9f6d-2d4f1de13a39
sdf    btrfs        feef8097-1952-4633-ac08-04dd1eeee2f6  904.6M     2% /home/vagrant/compresion

```

Ahora vamos a introducir algunos ficheros para ver que puede almacenar más información ya que la comprime. Esto se demora unos minutos ya que está introduciendo datos hasta que se quede sin espacio.

El disco es de 1G por lo que introduciremos información con la utlidad dd.

```sh
vagrant@btrfs2:~$ sudo dd if=/dev/zero of=compresion/info
dd: writing to 'compresion/info': No space left on device
44332355+0 records in
44332354+0 records out
22698165248 bytes (23 GB, 21 GiB) copied, 152.189 s, 149 MB/s

```

Comprobamos el tamaño de la información comprimida que ocupa en este caso 22G

```sh
vagrant@btrfs2:~/compresion$ ls -la
total 22166200
drwxr-xr-x 1 root    root              8 May  3 15:11 .
drwxr-xr-x 4 vagrant vagrant        4096 May  3 15:04 ..
-rw-r--r-- 1 root    root    22698165248 May  3 15:14 info
vagrant@btrfs2:~/compresion$ du -hs
22G	.
vagrant@btrfs2:~/compresion$ du
22166196	.
vagrant@btrfs2:~/compresion$ du -hs info
22G	info

```

Comprobamos que el disco sigue siendo de 1G

```sh
vagrant@btrfs2:~/compresion$ sudo btrfs filesystem show /home/vagrant/compresion
Label: none  uuid: feef8097-1952-4633-ac08-04dd1eeee2f6
	Total devices 1 FS bytes used 709.50MiB
	devid    1 size 1.00GiB used 1023.00MiB path /dev/sdf

```

Como conclusión podemos entender que el espacio está mejor aprovechado ya que la compresion la realiza al momento de introducir la información.


## Cow


![cow.png](/images/btrfs/cow.png)


Btrfs utiliza Copy on Write. Esta técnica permite hacer copias a los ficheros pero de forma distinta. Consiste en tener los archivos aparentemente copiados pero estos son simplemente punteros hacia el original, no es un enlace tampoco, ya que al modificar una copia se crean dispositivos de bloques nuevos a partir de los ya creados. Pero los primeros dispositivos de bloques del fichero al hacer la 'copia' son los mismos en cada fichero copiado al original.

Con todo esto quiero decir que al hacer la copia del fichero si no se modifica la copia, el espacio consumido no aumenta al copiar sino al modificar el fichero copiado. Lo comprobamos de la siguiente forma.

Usaremos el disco sdf, que hemos utlizado antes pero antes hemos borrado la información del ejercicio anterior.


Creamos el fichero de prueba

```sh
vagrant@btrfs2:~/compresion$ sudo nano prueba.txt
vagrant@btrfs2:~/compresion$ ls -l
total 4
-rw-r--r-- 1 root root 14 May  3 15:43 prueba.txt

```

Vemos el espacio ocupado en el disco

```sh
vagrant@btrfs2:~/compresion$ df -h | grep 'sdf'
/dev/sdf        1.0G   17M  681M   3% /home/vagrant/compresion
```
Hacemos la copia con el parámetro --reflink
```sh
vagrant@btrfs2:~/compresion$ sudo cp --reflink=always prueba.txt copia.txt

vagrant@btrfs2:~/compresion$ df -h | grep 'sdf'
/dev/sdf        1.0G   17M  681M   3% /home/vagrant/compresion

```
Comprobamos que no ha ocupado más espacio.


¿COMO VER LOS BLOQUES OCUPADOS?

Vemos que los dispositivos de bloques son los mismos

```sh
vagrant@btrfs2:~/compresion$ sudo btrfs filesystem df /home/vagrant/compresion 
Data, single: total=224.00MiB, used=128.00KiB
System, DUP: total=8.00MiB, used=16.00KiB
Metadata, DUP: total=163.19MiB, used=112.00KiB
GlobalReserve, single: total=16.00MiB, used=0.00B
vagrant@btrfs2:~/compresion$ sudo btrfs filesystem du /home/vagrant/compresion 
     Total   Exclusive  Set shared  Filename
     0.00B       0.00B           -  /home/vagrant/compresion/prueba.txt
     0.00B       0.00B           -  /home/vagrant/compresion/copia.txt
     0.00B       0.00B           -  /home/vagrant/compresion/copia2.txt
     0.00B       0.00B       0.00B  /home/vagrant/compresion
vagrant@btrfs2:~/compresion$ sudo btrfs filesystem usage /home/vagrant/compresion 
Overall:
    Device size:		   1.00GiB
    Device allocated:		 566.38MiB
    Device unallocated:		 457.62MiB
    Device missing:		     0.00B
    Used:			 384.00KiB
    Free (estimated):		 681.50MiB	(min: 452.69MiB)
    Data ratio:			      1.00
    Metadata ratio:		      2.00
    Global reserve:		  16.00MiB	(used: 0.00B)

Data,single: Size:224.00MiB, Used:128.00KiB
   /dev/sdf	 224.00MiB

Metadata,DUP: Size:163.19MiB, Used:112.00KiB
   /dev/sdf	 326.38MiB

System,DUP: Size:8.00MiB, Used:16.00KiB
   /dev/sdf	  16.00MiB

Unallocated:

```

## Redimension de discos 

Podemos aumentar o disminuir el tamaño del disco en caliente.

Lo podemos hacer con el disco sdf 

```sh
vagrant@btrfs2:~$ sudo btrfs filesystem show /home/vagrant/compresion/
Label: none  uuid: feef8097-1952-4633-ac08-04dd1eeee2f6
	Total devices 1 FS bytes used 68.54MiB
	devid    1 size 1.00GiB used 566.38MiB path /dev/sdf

```

Reducción:

```sh
vagrant@btrfs2:~$ sudo btrfs filesystem resize -400m /home/vagrant/compresion/
Resize '/home/vagrant/compresion/' of '-400m'
vagrant@btrfs2:~$ sudo btrfs filesystem show /home/vagrant/compresion/
Label: none  uuid: feef8097-1952-4633-ac08-04dd1eeee2f6
	Total devices 1 FS bytes used 68.54MiB
	devid    1 size 624.00MiB used 342.38MiB path /dev/sdf


```

Aumento:

```sh
vagrant@btrfs2:~$ sudo btrfs filesystem resize +300m /home/vagrant/compresion/
Resize '/home/vagrant/compresion/' of '+300m'
vagrant@btrfs2:~$ sudo btrfs filesystem show /home/vagrant/compresion/
Label: none  uuid: feef8097-1952-4633-ac08-04dd1eeee2f6
	Total devices 1 FS bytes used 68.47MiB
	devid    1 size 924.00MiB used 342.38MiB path /dev/sdf

```

## Fragmentación 

![defrag.png](/images/btrfs/defrag.png)

Para hacer una Fragmentación ejecutamos lo siguiente 

```sh
vagrant@btrfs2:~$ sudo btrfs filesystem defragment -r  /home/vagrant/compresion/
vagrant@btrfs2:~$ sudo btrfs filesystem show /home/vagrant/compresion/
Label: none  uuid: feef8097-1952-4633-ac08-04dd1eeee2f6
	Total devices 1 FS bytes used 68.47MiB
	devid    1 size 924.00MiB used 342.38MiB path /dev/sdf

```

> El cifrado no lo soporta btrfs

Fuentes 

https://www.oracle.com/technical-resources/articles/it-infrastructure/admin-advanced-btrfs.html
https://wiki.archlinux.org/title/btrfs#Copy-on-Write_(CoW)