---
title: "Compilar un programa en C con Makefile"
date: 2020-10-31T18:13:42+01:00
draft: false
toc: false
images:
tags: ['compilar','compilar c','c','lynx','compilar lynx']
---

# Compilación de un programa en C utilizando un Makefile

## Requisitos previos

* Suponemos que tenemos una máquina virtual con Debian Buster, en este caso voy a usar **Vagrant** con **qemu-kvm** para crearla. Necesitaremos tener instalado los paquetes necesarios (vagrant, qemu-kvm, virt-manager...). 

Usaremos el siguiente fichero Vagrantfile:

```sh
Vagrant.configure("2") do |config|
    config.vm.box = "debian/buster64"
    config.vm.hostname = "buster"
    config.vm.synced_folder ".", "/vagrant", disabled: true
    config.vm.provider :libvirt do |libvirt|
        libvirt.uri = 'qemu+unix:///system'
        libvirt.host = "debian"
        libvirt.cpus = 1
        libvirt.memory = 512
    end
end
```

* La máquina deberá estar actualizada y con los repositorios en orden

```sh
nano /etc/apt/souces.list
```

```sh
deb http://deb.debian.org/debian buster main
deb-src http://deb.debian.org/debian buster main

deb http://deb.debian.org/debian-security/ buster/updates main
deb-src http://deb.debian.org/debian-security/ buster/updates main

deb http://deb.debian.org/debian buster-updates main
deb-src http://deb.debian.org/debian buster-updates main

```
```sh
sudo apt update
sudo apt upgrade
```

* Ademas necesitaremos instalar algunos paquetes claves que nos pedirá al hacer la compilación e instalación de nuestro paquete. Uno de ellos lo vamos a descargar ya. Se trata de un paquete que contiene una lista informativa de los paquetes que se consideran esenciales para la creación de paquetes Debian, este es **build-essential**.

```sh
sudo apt-get install build-essential
```

## Programa escrito en C: Lynx

**Lynx** es un navegador web y cliente de gopher en modo texto. Este navegador es usado desde la linea de comandos, en terminales. Es muy útil para sistemas sin entorno gráfico y a la vez es fácil e intuitivo para su manejo.

Está escrito en C, y en las fuentes aparece un fichero Makefile para poder compilarlo.

* [Información oficial del paquete](https://packages.debian.org/buster/lynx)

* [Contenido del paquete](https://sources.debian.org/src/lynx/2.8.9rel.1-3/)



### Descargar las fuentes

* Primero vamos a ubicarnos en un sitio adecuado para descargar las fuentes. En este caso vamos a /usr/local para no interferir con otros archivos del sistema y creamos una carpeta llamada lynx.

```sh
cd /usr/local
mkdir lynx
```

* Vamos a descargarnos el código fuente:

```sh
$ sudo apt source lynx
```

* Vemos el contenido:

```sh
root@buster:/usr/local/lynx# ls
lynx-2.8.9rel.1			 lynx_2.8.9rel.1-3.dsc	       lynx_2.8.9rel.1.orig.tar.bz2.asc
lynx_2.8.9rel.1-3.debian.tar.xz  lynx_2.8.9rel.1.orig.tar.bz2


```

* Descomprimimos 

```sh
$ sudo tar -xjvf lynx_2.8.9rel.1.orig.tar.bz2 

```

* Vemos el contenido de nuestra carpeta descomprimida

```sh
vagrant@buster:/usr/local/lynx/lynx2.8.9rel.1$ ls
ABOUT-NLS       COPYING.asc      VMSPrint.com  config.guess  fixed512.com  make-msc.bat  samples
AUTHORS         INSTALLATION     WWW           config.hin    install-sh    makefile.bcb  scripts
BUILD           LYHelp.hin       aclocal.m4    config.sub    lib           makefile.in   src
CHANGES         LYMessages_en.h  bcblibs.bat   configure     lynx.cfg      makefile.msc  test
COPYHEADER      PACKAGE          build.bat     configure.in  lynx.hlp      makelynx.bat  userdefs.h
COPYHEADER.asc  PROBLEMS         build.com     descrip.mms   lynx.man      makew32.bat
COPYING         README           clean.com     docs          lynx_help     po

```

Como podemos comprobar hay un fichero llamado *INSTALLATION*, que nos va a indicar como tenemos que compilar e instalar lynx.


### Autoconfigurar. Debemos utilizar ./configure

```sh
root@buster:/usr/local/lynx/lynx2.8.9rel.1# ./configure
```

* Nos encontramos con el siguiente error:

```sh
configure: WARNING: pkg-config is not installed

```
Nos está diciendo que necesitamos un paquete esencial para la compilación, lo instalamos:

```sh
sudo apt-get install pkg-config
```
* Volvemos a ejecutar **./configure** y encontramos otro error:

```sh
configure: error: No curses header-files found
```
Buscando este error por internet, he encontrado que se debe a que necesita una biblioteca que permite escribir interfaces basadas en texto llamada Ncurses. En concreto nos hace falta una librería que es la siguiente:

```sh
apt-get install libncurses5-dev
```

* Volvemos a ejecutar configure y vemos que ahora se ejecuta perfectamente.

```sh
./configure
```

Haz click aquí para ver la salida ->> [salida](https://github.com/CeliaGMqrz/utilidades/blob/main/salida.md)

### COMPILAR. MAKEFILE

* Según la guía de *INSTALLATION* ahora tenemos que ejecutar **make** para crear los objetos y archivos necesarios.

```sh
make
```

* Estas son las últimas líneas que nos han salido:

```sh
Copying Lynx executable into top-level directory
rm -f ../lynx
cp lynx ../
Welcome to Lynx!
make[1]: Leaving directory '/usr/local/lynx/lynx2.8.9rel.1/src'

```

* Vamos al directorio que nos ha creado y vemos donde están todos los ficheros objetos:

```sh
cd lynx/lynx2.8.9rel.1/src/

```
![objetos.png](/images/objetos.png)

* Ahora deberemos de hacer un *make install* en el directorio adecuado:

```sh
root@buster:/usr/local/lynx/lynx2.8.9rel.1# make install
/bin/sh -c "P=`echo lynx|sed 's,x,x,'`; \
if test -f /usr/local/bin/$P ; then \
      mv -f /usr/local/bin/$P /usr/local/bin/$P.old; fi"
/usr/bin/install -c lynx /usr/local/bin/`echo lynx|sed 's,x,x,'`
mkdir -p /usr/local/share/man/man1
/usr/bin/install -c -m 644 ./lynx.man /usr/local/share/man/man1/`echo lynx|sed 's,x,x,'`.1
** installing ./lynx.cfg as /usr/local/etc/lynx.cfg
** installing ./samples/lynx.lss as /usr/local/etc/lynx.lss

Use make install-help to install the help-files
Use make install-doc to install extra documentation files

```
Después de todo esto ya tendriamos instalado **lynx**, nos muestra cómo podemos instalar la ayuda y la documentación extra.

* Ahora ejecutamos **lynx** y vemos que funciona perfectamente.

```sh
lynx www.google.es
```

![googlelynx.png](/images/googlelynx.png)


## Instalar la ayuda

```sh
root@buster:/usr/local/lynx/lynx2.8.9rel.1# make install-help
mkdir -p /usr/local/share/lynx_help
/bin/sh -c 'if cd "/usr/local/share/lynx_help" ; then \
	WD=`pwd` ; \
	TAIL=`basename "/usr/local/share/lynx_help"` ; \
	HEAD=`echo "$WD"|sed -e "s,/${TAIL}$,,"` ; \
	test "x$WD" != "x$HEAD" && rm -fr * ; \
	fi'
test -d /usr/local/share/lynx_help/keystrokes || mkdir /usr/local/share/lynx_help/keystrokes
Translating/copying html files
/bin/sh -c 'sed_prog=`pwd`/help_files.sed && \
	cd ./lynx_help && \
	dirs=keystrokes && \
	files="*.html */*.html" && \
	for f in $files ; do \
		sed -f $sed_prog $f > /usr/local/share/lynx_help/$f ; \
	done && \
	if test "" != "" ; then \
		(cd /usr/local/share/lynx_help &&  $files ) \
	fi'
Updating /usr/local/etc/lynx.cfg
/bin/sh -c \
'if test -f /usr/local/etc/lynx.cfg ; then \
	mv /usr/local/etc/lynx.cfg /usr/local/etc/lynx.tmp ; \
else \
	cp ./lynx.cfg /usr/local/etc/lynx.tmp ; \
fi'
Updating /usr/local/etc/lynx.cfg to point to installed help-files
sed	-e '/^HELPFILE:http/s!^!#!' \
	-e '/^#HELPFILE:file/s!#!!' \
	/usr/local/etc/lynx.tmp | \
/bin/sh ./scripts/cfg_path.sh lynx_help /usr/local/share/lynx_help | \
/bin/sh ./scripts/cfg_path.sh lynx_doc  /usr/local/share/lynx_help | \
sed	-e '/^HELPFILE:file/s!$!!' \
	-e '/^HELPFILE:file/s!$!!' \
	>/usr/local/etc/lynx.cfg
chmod 644 /usr/local/etc/lynx.cfg
rm -f /usr/local/etc/lynx.tmp

```

* Comprobamos que tenemos la ayuda instalada

```sh
root@buster:/usr/local/lynx/lynx2.8.9rel.1# lynx --help
USAGE: lynx [options] [file]
Options are:
  -                 receive options and arguments from stdin
  -accept_all_cookies 
                    accept cookies without prompting if Set-Cookie handling
                    is on (off)
  -anonymous        apply restrictions for anonymous account,
                    see also -restrictions
  -assume_charset=MIMEname
                    charset for documents that don't specify it
  -assume_local_charset=MIMEname
                    charset assumed for local files
  -assume_unrec_charset=MIMEname
                    use this instead of unrecognized charsets
  -auth=id:pw       authentication information for protected documents
  -base             prepend a request URL comment and BASE tag to text/html
                    outputs for -source dumps
  -bibhost=URL      local bibp server (default http://bibhost/)
  -book             use the bookmark page as the startfile (off)
  -buried_news      toggles scanning of news articles for buried references (on)
  -cache=NUMBER     NUMBER of documents cached in memory

```

* También podemos instalar la documentación 

```sh
root@buster:/usr/local/lynx/lynx2.8.9rel.1# make install-doc
mkdir -p /usr/local/share/lynx_doc
Copying sample files
/bin/sh -c '\
	( umask 022; \
	  cd . && \
	  /usr/bin/tar -cf - C[HO]* PROBLEMS README docs samples test ) | \
	( umask 022; \
	  cd /usr/local/share/lynx_doc && \
	  chmod -R u+w . && /usr/bin/tar -xf - )'
/bin/sh -c 'if test "" != "" ; then \
	(cd /usr/local/share/lynx_doc &&  -f docs/CHANGES*.[0-9] docs/*.announce ) \
fi'
/bin/sh -c 'for name in COPYING COPYHEADER; do \
	cd /usr/local/share/lynx_help && rm -f $name ;\
	r= ;\
	test "ln -s" = "ln -s" || r=`echo /usr/local/share/lynx_help|sed -e "s%[^/]\+%..%g" -e "s%^.%%"`; \
	cd /usr/local/share/lynx_help && ( ln -s $r/usr/local/share/lynx_doc/$name . || cp /usr/local/share/lynx_doc/$name . );\
	done'
/bin/sh -c 'case `id|sed -e "s/(.*//"` in uid=0) chown -R root /usr/local/share/lynx_doc;; esac'

```

* Miramos donde está instalado el paquete

```sh
root@buster:/home/vagrant# whereis lynx
lynx: /usr/local/bin/lynx /usr/local/etc/lynx.lss /usr/local/etc/lynx.cfg /usr/local/lynx

root@buster:/home/vagrant# which lynx
/usr/local/bin/lynx
```