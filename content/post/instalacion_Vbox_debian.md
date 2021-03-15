---
title: "Instalación de Virtualbox en Debian Buster"
date: 2020-10-15T15:50:23+02:00
draft: false
toc: false
images:
tags: [Virtualbox, debian10, instalar virtualbox]
---


### Instalar Virtualbox 6.0 en Debian Buster

![image](/images/vbox.jpg)

VirtualBox no viene en el repositorio predeterminado de Debian 10, por tanto lo instalaremos desde el repositorio oficial de Oracle.
Para ello vamos a agregar el repositorio en el fichero correspondiente:

```sh
$ sudo nano /etc/apt/sources.list
```
Añadimos el repositorio y guardamos el fichero.
```sh
deb https://download.virtualbox.org/virtualbox/debian buster contrib
```
Descargamos e importamos la clave pública de Oracle GPG en nuestro Debian 10.

```sh
$ wget -q https://www.virtualbox.org/download/oracle_vbox_2016.asc -O- | sudo apt-key add -
```
Actualizamos los paquetes
```sh
$ sudo apt update
```
Instalamos la versión que queramos de virtualbox
```sh
$ apt search virtualbox
$ sudo apt-get install virtualbox-6.0
```

