---
title: "Compilación de un kernel linux a medida"
date: 2021-03-18T20:07:29+01:00
draft: false
toc: false
images:
tags: ['kernel linux']
---
![kernel.jpg](/images/kernel/kernel.jpg)

## Conceptos previos

El **kernel linux** es el núcleo del **sistema operativo**. Es la parte software más importante del sistema. Su principal función es controlar el hardware del dispositivo o ordenador. Gestiona la memoria del sistema y los procesos, además controla las llamadas del sistema y permite la **conexión del software con el hardware** (entre ellos periféricos) para su uso. 

La mayor parte del kernel está compuesto por **controladores** o 'drivers' para poder adaptarse y ser compatible con cualquier dispositivo, aunque cabe destacar que mientras más controladores cargados tengamos el rendimiento irá bajando.

Normalmente el usuario de un equipo no suele interactuar con el kernel, pero en algunas distribuciones y con permisos de superusuario podemos gestionarlo, habilitar y deshabilitar módulos del mismo incluso **recompilarlo** si es necesario para situaciones muy puntuales o dispositivos que lo requieran.

Es importante tener el kernel actualizado en la versión estable para tener redundancia en cuanto a fallos de seguridad y otros errores. Normalmente podemos actualizarlo simplemente utilizando las actualizaciones de la propia distribución que estemos utlizando.

Al ser linux un **kérnel libre**, es posible descargar el **código fuente**, configurarlo y comprimirlo. Además, esta tarea a priori compleja, es más sencilla de lo que parece gracias a las **herramientas disponibles**.

En esta tarea vamos a tratar de compilar un kérnel completamente funcional que reconozca todo el hardware **básico** de nuestro equipo y que sea a la vez lo más pequeño posible, es decir que incluya un **vmlinuz** lo más pequeño posible y que incorpore sólo los módulos imprescindibles.

El hardware básico incluye como mínimo el teclado, la interfaz de red y la consola gráfica (texto).

______________________________________________________________________________________

## 1. Obtener el código fuente del kernel

¿Qué versión de kernel linux tengo?

Ejecutamos 'uname -r' para ver la versión que estamos utilizando

```sh
4.19.0-14-amd64
```

* Buscamos las **fuentes** en la paqueteria de Debian

```sh
apt search linux-source
```

Salida:

```sh
Ordenando... Hecho
Buscar en todo el texto... Hecho
linux-source/stable,stable,now 4.19+105+deb10u9 all [instalado]
  Linux kernel source (meta-package)

linux-source-4.19/stable,stable,now 4.19.171-2 all [instalado, automático]
  Linux kernel source for version 4.19 with Debian patches

```
* Segun la versión de kernel que tenemos instalado:

```sh
sudo apt policy linux-source
```
```sh
linux-source:
  Instalados: 4.19+105+deb10u9
  Candidato:  4.19+105+deb10u9
  Tabla de versión:
 *** 4.19+105+deb10u9 500
        500 http://deb.debian.org/debian buster/main amd64 Packages
        500 http://security.debian.org/debian-security buster/updates/main amd64 Packages
        100 /var/lib/dpkg/status

```

* Entonces descargamos las fuentes de la versión del kernel que nos pertenece. Además del paquete **build-essential** y **qtbase5-dev**, que son esenciales para su compilación.

```sh
sudo apt install linux-source=4.19+105+deb10u9 build-essential qtbase5-dev
```

## 2. Descomprimir las fuentes en un directorio 'seguro' como usuario.

Vamos a trabajar en un directorio de usuario para asegurarnos de no tocar partes importantes del sistema y podamos perder algún archivo necesario.

Crearemos un directorio de trabajo y descomprimimos el código fuente del kernel.

```sh
$ mkdir /home/celiagm/compilar
$ sudo mv /usr/src/linux-source-4.19.tar.xz /home/celiagm/compilar/
$ cd /home/celiagm/compilar/
$ tar -xf linux-source-4.19.tar.xz 
```

* Vemos el tamaño que ocupa el directorio

```sh
celiagm@debian:~/compilar$ du -hs linux-source-4.19
910M	linux-source-4.19

```
* Vemos el **contenido** de nuestras fuentes

```sh
celiagm@debian:~/compilar$ cd linux-source-4.19/
celiagm@debian:~/compilar/linux-source-4.19$ ls
arch   COPYING  Documentation  fs       ipc      kernel    MAINTAINERS  net      scripts   tools
block  CREDITS  drivers        include  Kbuild   lib       Makefile     README   security  usr
certs  crypto   firmware       init     Kconfig  LICENSES  mm           samples  sound     virt

```

Después de haber decomprimido el código fuente de nuestro kernel, vamos a configurarlo, de forma que indicaremos sus características y los dispositivos de nuestro ordenador que va a soportar.

Vamos a usar la herramienta **make**, que nos va ayudar a compilar nuestro kernel, ya que permite ver los módulos del mismo y las dependencias que necesitamos para compilar.

* Para ver la **ayuda** de make ejecutamos el siguiente comando

```sh
make help
```

## 3. Copiar la configuración del kernel que tenemos actualmente

* Esta es la opción que nos muestra la ayuda

```sh
 oldconfig	  - Update current config utilising a provided .config as base
```

* Ahora copiamos el fichero de configuración que tenemos inicialmente en nuestro kernel a nuestro directorio

```sh 
sudo cp /boot/config-4.19.0-14-amd64 .config
```

Una vez tengamos ya el fichero de configuración vamos a ejecutar **make oldconfig**, que restaura la configuración que teníamos en el fichero que acabamos de copiar de nuestro kernel.

* Ejecutamos **make oldconfig**

```sh
make oldconfig
```

El kernel linux es **modular**, permite insertar o eliminar módulos para distintas funcionalidades. Los módulos no son más que fragmentos de código, abierto en este caso que podemos añadir o quitar del kernel.

Algunas funcionalidades que podemos añadir al kernel son: Registar las temperaturas de componentes de nuestro ordenador, usar los controladores privativos de nuestra tarjeta gráfica (etc)

Para saber el número de módulos que tenemos disponibles en el kernel ejecutamos el siguiente comando

```sh
ls -R /lib/modules/$(uname -r)
```

Si queremos ver una lista de los módulos que estamos usando podemos ejecutar `lsmod`. Que nos muestra el nombre del módulo, el tamaño que ocupa cargado en memoria y además si esta siendo usado por otro módulo.

En el directorio `/proc/modules` también podemos ver la misma información.

Por ejemplo, si queremos ver que módulo está usando mi tarjeta gráfica ejecutamos 

```sh
lspci -v
```

Salida:

```sh
...

01:00.0 VGA compatible controller: NVIDIA Corporation TU116M (rev a1) (prog-if 00 [VGA controller])
	Subsystem: Micro-Star International Co., Ltd. [MSI] TU116M
	Flags: fast devsel, IRQ 16
	Memory at a4000000 (32-bit, non-prefetchable) [size=16M]
	Memory at 90000000 (64-bit, prefetchable) [size=256M]
	Memory at a0000000 (64-bit, prefetchable) [size=32M]
	I/O ports at 5000 [size=128]
	Expansion ROM at a5000000 [disabled] [size=512K]
	Capabilities: <access denied>
	Kernel modules: nouveau

...

```
Comprobamos que actualmente está usando el 'nouveau' ya que no tenemos instalado los drivers de nuestra tarjeta gráfica NVIDIA.

* Miramos el número de elementos que se van a compilar como modulos y estaticamente.

Modulos:

```sh
grep "=m" .config|wc -l
```

Estatica:

```sh
grep "=y" .config|wc -l
```

```sh
celiagm@debian:~/compilar/linux-source-4.19$ grep "=m" .config|wc -l
3381
celiagm@debian:~/compilar/linux-source-4.19$ grep "=y" .config|wc -l
2016
```

Tenemos un total de 3381 módulos y 2016 estáticos.

## 4. Selección y reducción de elementos (loadmodconfig)

Ahora vamos a usar una herramienta muy útil que nos reducirá la cantidad de módulos y nos va a facilitar el trabajo, ya que deshabilitará módulos que considere innecesarios.

```sh
make localmodconfig
```
* Vemos que se ha reducido significativamente.

```sh
celiagm@debian:~/compilar/linux-source-4.19$ grep "=y" .config|wc -l
1469
celiagm@debian:~/compilar/linux-source-4.19$ grep "=m" .config|wc -l
217
```

## 5. Proceso de compilación

###  Primera compilación

* Nos aseguramos que tenemos estos paquetes instalados antes de proceder con la compilación:

```sh
sudo apt-get install libelf-dev libssl-dev pkg-config
```
* Procedemos a la compilación. Con la opción **-j** le pasamos como parámetro el número de núcleos que queremos que utilice nuestro pc. Dependiendo del número de núcleos que use tardaremos más o menos.

```sh
make -j 12 bindeb-pkg
```

Una vez terminada la compilación vamos a ver el peso del fichero deb.

* Comprobar el peso del fichero deb, en el directorio padre que es donde se han generado los ficheros deb

```sh
celiagm@debian:~/compilar$ du -hs linux-image-4.19.171_4.19.171-1_amd64.deb 
11M	linux-image-4.19.171_4.19.171-1_amd64.deb
```


* Una vez tenemos el fichero deb pasamos a instalar el 'nuevo' kernel

```sh
sudo dpkg -i linux-image-4.19.171_4.19.171-1_amd64.deb
```
* Iniciamos el sistema y en el grub de arranque lo seleccionamos, y podemos ver que funciona correctamente.

_______________________________________________

#### Comandos de utilidad

* Ver los kernel instalados

```sh
dpkg -l | grep linux-image
```

* Desinstalar el kernel que **no funciona** cuando sea necesario:

```sh
apt-get remove --purge linux-image-X.X.X-X
```

_______________________________________________


**Reducir elementos**

Con el siguiente comando se nos abre una ventana y podemos elegir los módulos o elementos que queremos quitar. Hay otras opciones desde la línea de comando en las que se nos despliega un menú pero sin entorno gráfico, pero en este caso lo haremos así.

```sh
make xconfig
```
Hay 3 estados:
[ ]- No se compilará, no formará parte de su núcleo.
[•]- Se compilará como un módulo.
[✓]. Se compilará en el núcleo y estará presente.


Antes de empezar a quitar módulos hay que tener en cuenta que el fichero .config se va modificando, entonces lo que haremos será una copia de seguidad del fichero en cada reducción por si quitamos un módulo que es esencial y no funciona nuestro kernel; Así poder volver a un punto anterior y volver a probar.

```sh
cp .config ../bakcupconfig1
```

#### 1º REDUCCIÓN

Módulos dehabilitados:
```sh
RF switch subsystem support (RFKILL): soporte para interruptor de tarjetas wifi y bluetooh
Bluetooth subsystem support (BT): Bluetooth
QoS and/or fair queueing (NET_SCHED): elegir paquetes retraso primero o en cola
Network packet filtering framework (Netfilter) (NETFILTER): filtrado de paquetes, cortafuegos
Multimedia support (MEDIA_SUPPORT): Soporte para multimedia
Sound card support (SOUND): Soporte para el sonido
Linux guest support (HYPERVISOR_GUEST): Soporte para maquinas virtuales
Macintosh device drivers (MACINTOSH_DRIVERS)
Macintosh device drivers (MACINTOSH_DRIVERS)
Hardware Monitoring support (HWMON): Monitoreo de hardware
Hardware crypto devices (CRYPTO_HW): Encriptación de hardware
Virtualization (VIRTUALIZATION)

```
Numero de elementos:
```sh
celiagm@debian:~/compilar/linux-source-4.19$ grep "=m" .config|wc -l
145
celiagm@debian:~/compilar/linux-source-4.19$ grep "=y" .config|wc -l
1319
```

Tamaño conseguido:
```sh
celiagm@debian:~/compilar$ du -hs linux-image-4.19.171_4.19.171-1_amd64.deb 
9,2M	linux-image-4.19.171_4.19.171-1_amd64.deb
```

#### 2º REDUCCIÓN

Módulos dehabilitados:
```sh
Network device Support -> Wireless LAN
Mouse interface (INPUT_MOUSEDEV)
DMA memory allocation support (ZONE_DMA)
Symmetric multi-processing support (SMP)
Memtest (MEMTEST)
Enable DMI scanning (DMI)
Platform support for Chrome hardware (CHROME_PLATFORMS)
IBM Calgary IOMMU support (CALGARY_IOMMU)
Enable support for 16-bit segments (X86_16BIT)
Allow for memory hot-add (MEMORY_HOTPLUG)
Track memory changes (MEM_SOFT_DIRTY)
Supervisor Mode Access Prevention (X86_SMAP)
The IPv6 protocol (IPV6)
Battery (ACPI_BATTERY)
AMD MCE features (X86_MCE_AMD)
IP: multicast routing (IP_MROUTE)
LED Support (NEW_LEDS)
Accessibility support (ACCESSIBILITY)
Virtualization drivers (VIRT_DRIVERS)
Staging drivers (STAGING)
Network File Systems (NETWORK_FILESYSTEMS)

```
Numero de elementos:
```sh
celiagm@debian:~/compilar/linux-source-4.19$ grep "=m" .config|wc -l
136
celiagm@debian:~/compilar/linux-source-4.19$ grep "=y" .config|wc -l
1181
```
Tamaño conseguido:
```sh
celiagm@debian:~/compilar$ du -hs linux-image-4.19.171_4.19.171-3_amd64.deb 
7,4M	linux-image-4.19.171_4.19.171-3_amd64.deb


```

#### 3º REDUCCIÓN

Módulos dehabilitados:

```sh
[General Setup]
Support initial ramdisk/ramfs compressed using bzip2 (RD_BZIP2)
Support initial ramdisk/ramfs compressed using LZMA (RD_LZMA)
Support initial ramdisk/ramfs compressed using XZ (RD_XZ)
Support initial ramdisk/ramfs compressed using LZO (RD_LZO)
Support initial ramdisk/ramfs compressed using LZ4 (RD_LZ4)

[Procesor Type and Features]
Intel Low Power Subsystem Support (X86_INTEL_LPSS)
AMD ACPI2Platform devices support (X86_AMD_PLATFORM_DEVICE)
Old AMD GART IOMMU support (GART_IOMMU)
```

Número de elementos:

```sh
celiagm@debian:~/compilar/linux-source-4.19$ grep "=m" .config|wc -l
134
celiagm@debian:~/compilar/linux-source-4.19$ grep "=y" .config|wc -l
1163
```
Tamaño conseguido:
```sh
celiagm@debian:~/compilar$ du -hs linux-image-4.19.171_4.19.171-9_amd64.deb 
7,4M	linux-image-4.19.171_4.19.171-9_amd64.deb

```

#### 4º REDUCCIÓN

Módulos dehabilitados:

```sh
Amateur Radio support (HAMRADIO)
Sony MemoryStick card support (MEMSTICK)
X86 Platform Specific Device Drivers (X86_PLATFORM_DEVICES)
Fibre Channel driver support (NET_FC)
Quota support (QUOTA)
```
Número de elementos:
```sh
celiagm@debian:~/compilar/linux-source-4.19$ grep "=y" .config|wc -l
1155
celiagm@debian:~/compilar/linux-source-4.19$ grep "=m" .config|wc -l
128
```
Tamaño conseguido:
```sh
celiagm@debian:~/compilar$ du -hs linux-image-4.19.171_4.19.171-10_amd64.deb 
7,3M	linux-image-4.19.171_4.19.171-10_amd64.deb
```

#### 5º REDUCCIÓN

Módulos dehabilitados:
```sh
IA32 Emulation (IA32_EMULATION)
Configure standard kernel features (expert users) (EXPERT)

Collect scheduler debugging info (SCHED_DEBUG)
Collect scheduler statistics (SCHEDSTATS)
Detect stack corruption on calls to schedule()
Trigger a BUG when data corruption is detected (BUG_ON_DATA_CORRUPTION)
Warn on W+X mappings at boot (DEBUG_WX
```
Número de elementos:
```sh
celiagm@debian:~/compilar/linux-source-4.19$ grep "=y" .config|wc -l
1154
celiagm@debian:~/compilar/linux-source-4.19$ grep "=m" .config|wc -l
129
```
Tamaño conseguido:
```sh
celiagm@debian:~/compilar$ du -hs linux-image-4.19.171_4.19.171-12_amd64.deb 
7,3M	linux-image-4.19.171_4.19.171-12_amd64.deb
```

#### 6º REDUCCIÓN

Estos elementos no se pueden quitar :

```sh
Intel 8xx/9xx/G3x/G4x/HD Graphics (DRM_I915)
Direct Rendering Manager (XFree86 4.1.0 and higher DRI support) (DRM)
```
Motivo: Tenemos la gráfica integrada.

Estos sí:

```sh
/dev/agpgart (AGP Support) (AGP)
GHASH digest algorithm (CLMUL-NI accelerated)
Trace gpio events (TRACING_EVENTS_GPIO)
Kernel Function Graph Tracer (FUNCTION_GRAPH_TRACER)
Restrict unprivileged use of performance events (SECURITY_PERF_EVENTS_RESTRICT)
NSA SELinux Support (SECURITY_SELINUX)
```
Número de elementos:
```sh

celiagm@debian:~/compilar/linux-source-4.19$ grep "=y" .config|wc -l
1142
celiagm@debian:~/compilar/linux-source-4.19$ grep "=m" .config|wc -l
129

```
Tamaño conseguido:

```sh
celiagm@debian:~/compilar$ du -hs linux-image-4.19.171_4.19.171-20_amd64.deb 
7,2M	linux-image-4.19.171_4.19.171-20_amd64.deb

```

#### 7º REDUCCIÓN

Llegados a este punto vamos a ver si podemos quitar o están ya deshabilitados los siguientes módulos que no creemos que sean necesarios:

```sh
usb 2.0 -> Driver=rtsx_usb
Realtek USB card reader (MISC_RTSX_USB)

Audio -> snd_hda_intel
HD Audio PCI (SND_HDA_INTEL)

wifi -> iwlwifi
Intel Wireless WiFi Next Gen AGN - Wireless-N/Advanced-N/Ultimate-N (iwlwifi) (IWLWIFI)

mouse -> usbhid
xHCI HCD (USB 3.0) support (USB_XHCI_HCD)

webcam -> uvcvideo
USB Webcam Gadget (USB_G_WEBCAM)
```

```sh
celiagm@debian:~/compilar/linux-source-4.19$ grep "=y" .config|wc -l
1142
celiagm@debian:~/compilar/linux-source-4.19$ grep "=m" .config|wc -l
124

```
Tamaño conseguido:

```sh
celiagm@debian:~/compilar$ du -hs linux-image-4.19.171_4.19.171-21_amd64.deb 
7,1M	linux-image-4.19.171_4.19.171-21_amd64.deb

```

Anotaciones:

Cuando iniciamos el sistema con este kernel ya no disponemos de los elementos mencionados anteriormente, ni la web cam, ni los puertos usb externos como el ratón, ni la tarjeta wifi. Además tampoco tenemos el sonido.


#### 8º REDUCCIÓN

Wireless (WIRELESS)

```sh
celiagm@debian:~/compilar/linux-source-4.19$ grep "=m" .config|wc -l
122
celiagm@debian:~/compilar/linux-source-4.19$ grep "=y" .config|wc -l
1128

```
Tamaño conseguido

```sh
celiagm@debian:~/compilar$ du -hs linux-image-4.19.171_4.19.171-22_amd64.deb 
6,6M	linux-image-4.19.171_4.19.171-22_amd64.deb

```

#### 9º REDUCCIÓN

ISDN support (ISDN)
Touchscreens (INPUT_TOUCHSCREEN)
Joysticks/Gamepads (INPUT_JOYSTICK)
Tablets (INPUT_TABLET)

```sh
celiagm@debian:~/compilar/linux-source-4.19$ grep "=y" .config|wc -l
1123
celiagm@debian:~/compilar/linux-source-4.19$ grep "=m" .config|wc -l
122

```

```sh
celiagm@debian:~/compilar$ du -hs linux-image-4.19.171_4.19.171-23_amd64.deb 
6,6M	linux-image-4.19.171_4.19.171-23_amd64.deb

```

#### 10º REDUCCIÓN

Módulos deshabilitados:

```sh
Mice (INPUT_MOUSE)
Miscellaneous devices (INPUT_MISC)
DRM DP AUX Interface (DRM_DP_AUX_CHARDEV)

Virtio drivers (VIRTIO_MENU)
Mailbox Hardware Support (MAILBOX)
Watchdog Timer Support (WATCHDOG)
MMC/SD/SDIO card support (MMC)
SPI support


```
Número de elementos:
```sh
celiagm@debian:~/compilar/linux-source-4.19$ grep "=y" .config|wc -l
1107
celiagm@debian:~/compilar/linux-source-4.19$ grep "=m" .config|wc -l
119
```

Tamaño conseguido:
```sh
celiagm@debian:~/compilar/debs$ du -hs linux-image-4.19.171_4.19.171-25_amd64.deb 
6,6M	linux-image-4.19.171_4.19.171-25_amd64.deb

```

```sh
celiagm@debian:~/compilar/linux-source-4.19$ grep "=m" .config|wc -l
117
celiagm@debian:~/compilar/linux-source-4.19$ grep "=y" .config|wc -l
1089

```
Anotaciones:

* Hemos conseguido quitar el touchpad.
* Tenemos conexión a internet, teclado y podemos acceder a la consola. 
* No hemos podido eliminar el entorno gráfico, (tarjeta integrada.)


# Conclusión

Como podemos ver:

Vmlinuz
```sh
celiagm@debian:~/compilar/linux-source-4.19$ ls -lh /boot/ | egrep 'vmlinuz'
-rw-r--r-- 1 root root 4,1M mar 20 20:20 vmlinuz-4.19.171
```

Fichero deb
```sh
celiagm@debian:~/compilar$ du -hs linux-image-4.19.171_4.19.171-26_amd64.deb 
6,5M	linux-image-4.19.171_4.19.171-26_amd64.deb
```

Hemos pasado de 5,1 M de peso en Vmlinuz a 4,1M y de 11M a 6,5M en el fichero deb.

Hemos reducido considerablemente el kernel considerando un uso básico del sistema con lo más esencial.