---
title: "Instalación y configuración básica de VMWare ESXi"
date: 2020-12-22T13:53:35+01:00
draft: false
toc: false
images:
tags: ['vmware']
---


## Descripción de la tarea:

Utiliza el servidor físico que se te haya asignado e instala la versión adecuada del sistema de virtualización VMWare ESXi (ten en cuenta que recibe diferentes denominaciones comerciales, pero nos referimos al sistema de virtualización de VMWare que proporciona virtualización de alto rendimiento mediante la técnica de la paravirtualización).

Realiza la configuración del servicio que permita su gestión remota desde un equipo cliente e instala en tu equipo la aplicación cliente que permita gestionar remotamente el hipervisor.

Instala una máquina virtual que tenga acceso a Internet. La corrección consistirá en comprobar el funcionamiento de dicha máquina virtual.



## Instalación de VMWare ESXi

Obtenemos la imagen de VMWare para nuestro servidor:

[descargar ISO VMWare ESXi](/images/vmware/https://www.dell.com/support/home/es-es/drivers/driversdetails?driverid=5yc4t)

Grabamos la ISO en un usb y lo introducimos en el servidor. 

Reinciamos y configuramos el servidor para que arranque por el usb, a continuación realizamos la instalación. Es una instalación bastante simple así que pasamos a la configuración. Lo único relevante aquí es tener en cuenta las credenciales que nos va a pedir para su administración.

Nota: Es importante tener activado en la BIOS la opción de Virtualización, sin este requisito no se podrá instalar y nos surgirá el siguiente error.

![requisito.jpeg](/images/vmware/requisito.jpeg)

Nos pedirá la confirmación para instalar sobre el disco

![confirm.jpeg](/images/vmware/confirm.jpeg)

Vemos que se ha instalado correctamente

![complete.jpg](/images/vmware/complete.jpg)


## Configuración de VMWare desde el Servidor

Para configurar MVWare nos pedirá las credenciales que facilitamos en la instalación

![credenciales.jpeg](/images/vmware/credenciales.jpeg)

Le indicaremos una dirección IP estática, la cual será 172.22.221.68, anteriormente tenia la 172.22.221.63. Le hemos añadido 5 más para que podamos conectarnos a la máquina.

![estatica.jpg](/images/vmware/estatica.jpg)

De forma que quedaría así

![estatica1.jpg](/images/vmware/estatica1.jpg)

Nos aseguramos que está habilitado el ssh

![ssh.jpg](/images/vmware/ssh.jpg)

Ahora reiniciamos el servidor, arrancando desde el disco duro donde se ha instalado el software y tendríamos lista la instalación para poder acceder remotamente desde nuestro equipo.

## Instalación del cliente vSphere Client en Windows10

Desde casa he accedido a través de la VPN. He instalado OpenVPN sobre Windows y he configurado el cliente para conectarme a la red del Centro.

Accedemos desde el navegador a la dirección del servidor configurada en VMWare, la cual es **172.22.221.68**. Nos aparece lo siguiente:

![vmw1.jpg](/images/vmware/vmw1.jpg)

Aquí nos aparece el enlace para descargar el cliente vSphere, lo descargamos y lo instalamos sobre nuestro sistema.

Cuando esté instalado lo abrimos, nos pedirá la ip del servidor y nuestras crenciales, cuando lo introducimos tendrá este aspecto.

![credenciales.png](/images/vmware/credenciales.png)

![vmw2.jpg](/images/vmware/vmw2.jpg)


## Crear máquina virtual en VMWare a través del Cliente

Seleccionamos nuestro servidor y creamos la una máquina virtual nueva.

![vmw5.jpg](/images/vmware/vmw5.jpg)

![vmw3.jpg](/images/vmware/vmw3.jpg)

Tenemos dos opciones de configuración, típica o avanzada, en la típica se configuran varios valores por defecto y en la avanada podemos indicar la ram que vamos a usar el número de cpu e hilos entre otras cosas. No es relevante qué vamos a elegir aquí para esta práctica.

![vmw4.jpg](/images/vmware/mvw4.jpg)

Nos pedirá el nombre que le vamos a poner a la máquina, en mi caso le he puesto xannan.

![vmw6.jpg](/images/vmware/vmw6.jpg)

Seleccionamos el almacenamiento

![vmw7.jpg](/images/vmware/vmw7.jpg)

Seleccionamos el sistema operativo que vamos a instalar en mi caso puse 'otro linux 64'

![vmw8.jpg](/images/vmware/vmw8.jpg)

Dejamos por defecto la interfaz de red 

![vmw9.jpg](/images/vmware/vmw9.jpg)

Dejamos por defecto los valores para crear el disco

![vmw10.jpg](/images/vmware/vmw10.jpg)

Nos hará un resumen de la máquina que va a crear y le damos a 'Finish' para finalizar.

Ya tendríamos la máquina virtual creada

![mv1.jpg](/images/vmware/mv1.jpg)

A continuación le vamos a insertar una iso que tenemos en el equipo local a través del cliente de esta forma. La máquina deberá de estar encendida en ese momento.

![isodisk.jpg](/images/vmware/isodisk.jpg)

Reiniciamos la máquina virtual para que arranque desde el cd con la iso e iniciará la instalación.

![instalacion1.jpg](/images/vmware/instalacion1.jpg)


Desafortunadamente la instalación no se lleva a cabo, se queda congelado y no podemos continuar. Posiblemente por un fallo relacionado con las redes suponiendo que estamos conectados a través de una VPN. 

Lo volvemos a intentar en el Centro, creamos una máquina virtual nueva con el mismo procedimiento y los mismos pasos efectuados y efectivamente desde allí podemos hacer la instalación, comprobamos que efectivamente la máquina tiene acceso a internet.

Parte de la instalación de debian y comprobación de red

[Ver Video 1](https://youtu.be/4riAUMLBVFc)

Comprobación de que la máquina está actualizada y con acceso a la red

[Ver Video 2](https://www.youtube.com/watch?v=uu71yR7GQLA)