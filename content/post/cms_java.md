---
title: "Despliegue CMS en Java"
date: 2021-03-07T21:11:44+01:00
draft: false
toc: false
images:
tags: ['java','guacamole']
---

En esta entrada vamos a tratar de desplegar una aplicación CMS escrito en Java. Para ello usaremos 'Guacamole'.

## Entorno de trabajo. Escenario.

* Vamos a usar una máquina virtual con Vagrant y Virtualbox.
* Sistema operativo: Debian Buster.
* Necesitaremos usuario con privilegios root y la paquetería actualizada.


Una vez tengamos el entorno de trabajo nos aseguraremos que tenemos el sistema actualizado. 

## Guacamole como concepto. Tomcat.

**Apache Guacamole** es una herramienta **libre** y Open-Source que nos permite conectarnos remotamente a un servidor mediante el navegador web **sin necesidad de usar un cliente**.

No es una aplicación web autónoma ya que precisa de más componentes y elementos. Se trata de una aplicación web simple y mínima. Un componente esencial que vamos a usar con ella es **Tomcat**.

**Tomcat** es una especie de contenedor de ServLets que nos permite ejecutar herramientas desarrolladas con Java Server Page (JSP).

## Descargar el paquete de Guacamole desde las fuentes

* Instalamos las dependencias 

```sh
sudo apt install build-essential libcairo2-dev libjpeg62-turbo-dev libpng-dev libtool-bin libossp-uuid-dev libvncserver-dev freerdp2-dev libssh2-1-dev libtelnet-dev libwebsockets-dev libpulse-dev libvorbis-dev libwebp-dev libssl-dev libpango1.0-dev libswscale-dev libavcodec-dev libavutil-dev libavformat-dev
``` 

* Descargamos la version estable de guacamole

```sh
wget http://mirror.cc.columbia.edu/pub/software/apache/guacamole/1.2.0/source/guacamole-server-1.2.0.tar.gz
```

* Extraemos el archivo, lo compilamos e instalamos

```sh
tar -xvf guacamole-server-1.2.0.tar.gz
cd guacamole-server-1.2.0
./configure --with-init-dir=/etc/init.d
make
make install
```

* Actualizamos la memoria caché

```sh
sudo ldconfig
```

* Ahora vamos a cargar systemd para que pueda encontrar el demonio proxy de guacamole, que es 'guacd'. Lo iniciamos y comprobamos su estado.

```sh
sudo systemctl daemon-reload
sudo systemctl start guacd
sudo systemctl enable guacd
systemctl status guacd
```
Comprobamos el estado del demonio 
```sh
root@debian-cms:/home/vagrant/guacamole/guacamole-server-1.2.0# systemctl status guacd
● guacd.service - LSB: Guacamole proxy daemon
   Loaded: loaded (/etc/init.d/guacd; generated)
   Active: active (running) since Sun 2021-03-07 20:37:03 GMT; 29s ago
     Docs: man:systemd-sysv-generator(8)
    Tasks: 1 (limit: 544)
   Memory: 10.6M
   CGroup: /system.slice/guacd.service
           └─10976 /usr/local/sbin/guacd -p /var/run/guacd.pid

Mar 07 20:37:03 debian-cms systemd[1]: Starting LSB: Guacamole proxy daemon...
Mar 07 20:37:03 debian-cms guacd[10974]: Guacamole proxy daemon (guacd) version 1.2.0 started
Mar 07 20:37:03 debian-cms guacd[10973]: Starting guacd: guacd[10974]: INFO:        Guacamole proxy daemo
Mar 07 20:37:03 debian-cms guacd[10973]: SUCCESS
Mar 07 20:37:03 debian-cms systemd[1]: Started LSB: Guacamole proxy daemon.
Mar 07 20:37:03 debian-cms guacd[10976]: Listening on host 127.0.0.1, port 4822

```
* Comprobamos que esta escuchando en el puerto indicado

```sh
root@debian-cms:/home/vagrant/guacamole/guacamole-server-1.2.0# sudo ss -lnpt | grep guacd
LISTEN    0         5                127.0.0.1:4822             0.0.0.0:*        users:(("guacd",pid=10976,fd=4))                 
```
## Instalar la aplicacion web Guacamole y tomcat.

Como hemos dicho anteriormente la aplicación web de Guacamole está escrita en Javak por ello necesitamos instalar **tomcat** (contenedor Java Servelt)

```sh
sudo apt install tomcat9 tomcat9-admin tomcat9-common tomcat9-user
```

Apache Tomcat escuchará en el puerto 8080 

```sh
sudo ss -lnpt | grep java
```

```sh
root@debian-cms:/home/vagrant/guacamole/guacamole-server-1.2.0# sudo ss -lnpt | grep java
LISTEN    0         100                      *:8080                   *:*        users:(("java",pid=12680,fd=37))       
```

* Ahora sí descargamos la aplicación web de guacamole

```sh
wget https://downloads.apache.org/guacamole/1.2.0/binary/guacamole-1.2.0.war

```
* Trasladamos la aplicación al directorio de tomcat para poder servirla

```sh
sudo mv guacamole-1.2.0.war /var/lib/tomcat9/webapps/guacamole.war
```

* Reinciamos los servicios

```sh
sudo systemctl restart tomcat9 guacd
```

Vamos a comprobar que desde el navegador ya tenemos disponible la aplicación con Tomcat. Si accedemos a la ip por el puerto 8080 

![guacamole1.png](/images/guacamole/guacamole1.png)


Ademas podemos ver que accediendo a la siguiente dirección:

http://192.168.100.183:8080/guacamole/#/

Comprobamos que la aplicación ya está para ser usada.

![guacamole2.png](/images/guacamole/guacamole2.png)

> He instalado también un entorno de escritorio ya que no tenia entorno para esta máquina. 

```sh
sudo apt update
sudo apt install xfce4 xfce4-goodies
```

Si entramos y tenemos instalado un entorno de escritorio en nuestra maquina podremos verlo a traves del navegador indicando nuestras credenciales 

![escritorio.png](/images/guacamole/escritorio.png)


Podemos ver la carpeta de nuestro usuario por ejemplo.

![vagrant.png](/images/guacamole/vagrant.png)

## Configuración de Guacamole

* Vamos a crear un directorio donde vamos a tener la configuración del mismo 

```sh
sudo mkdir /etc/guacamole
sudo nano /etc/guacamole/guacamole.properties
```

* Añadimos las siguientes lineas 

```sh
# Nombre de host y puerto del proxy guacamole
guacd-hostname: localhost
guacd-port:     4822
# Clase de proveedor de autenticación (autentica la combinación de usuario / contraseña, necesaria si se usa la pantalla de inicio de sesión proporcionada)
auth-provider: net.sourceforge.guacamole.net.basic.BasicFileAuthenticationProvider
basic-user-mapping: /etc/guacamole/user-mapping.xml

```

El módulo de autentificación por defecto lee las credenciales ubicadas en el fichero 'user-mapping.xml' por lo que vamos a generar un hash y la contraseña que queramos 

```sh
echo -n contrasenia | openssl md5
```


Ahora creamos el xml de asignación para usuarios

```sh
sudo nano /etc/guacamole/user-mapping.xml
```

En este fichero indicaremos el usuario que vayamos a poner, y el hash que nos generó con la contraseña que hemos creado previamente, más adelante crearemos la contraseña para VNC.

```sh
<user-mapping>

    <!-- Per-user authentication and config information -->
    <authorize
         username="vagrant"
         password="1060b7b46a3bd36b3a0d66e0127d051"
         encoding="md5">

       <connection name="default">
         <protocol>vnc</protocol>
         <param name="hostname">localhost</param>
         <param name="port">5901</param>
         <param name="password">vnc_password</param>
       </connection>
    </authorize>

</user-mapping>
```

Guardamos y reiniciamos los servicios 

```sh
sudo systemctl restart tomcat9 guacd
```

* Instalar un servidor VNC

```sh
sudo apt install tigervnc-standalone-server
```
* Iniciamos VNC y elegimos una contraseña

```sh
vncserver
```

```sh
vagrant@debian-cms:~/guacamole/guacamole-server-1.3.0$ vncserver

You will require a password to access your desktops.

Password:
Verify:
Would you like to enter a view-only password (y/n)? n
/usr/bin/xauth:  file /home/vagrant/.Xauthority does not exist

New 'debian-cms:2 (vagrant)' desktop at :2 on machine debian-cms

Starting applications specified in /etc/X11/Xvnc-session
Log file is /home/vagrant/.vnc/debian-cms:2.log

Use xtigervncviewer -SecurityTypes VncAuth -passwd /home/vagrant/.vnc/passwd :2 to connect to the VNC server.

```

Ahora editamos el fichero /etc/guacamole/user-mapping.xml y cambiamos la contraseña para VNC y reinciamos los servicios

```sh
sudo systemctl restart tomcat9 guacd
```

## Instalación de apache2 y configuración

* Instalamos apache2 

```sh
sudo apt install apache2
```

* Creamos una página web simple 

```sh
nano /etc/apache2/sites-available/000-default.conf
```

```sh
<VirtualHost *:80>
        ServerName www.misitio.org
        ServerAdmin webmaster@localhost
        DocumentRoot /var/www/html
        ErrorLog ${APACHE_LOG_DIR}/error.log
        CustomLog ${APACHE_LOG_DIR}/access.log combined
</VirtualHost>
```

* Comprobamos que funciona 

![guacamole3.png](/images/guacamole/guacamole3.png)


## Proxy inverso 

Instalamos los módulos necesarios para la conexión entre tomcat y apache2

```sh
sudo apt install libapache2-mod-jk
sudo a2enmod proxy proxy_http
```


* En el fichero de configuración del virtualhost añadimos las opciones de proxy 


```sh
<VirtualHost *:80>
        ServerName www.misitio.org
        ServerAdmin webmaster@localhost
        DocumentRoot /var/www/html
        ErrorLog ${APACHE_LOG_DIR}/error.log
        CustomLog ${APACHE_LOG_DIR}/access.log combined
</VirtualHost>

<Location /guacamole/>
    Order allow,deny
    Allow from all
    ProxyPass http://localhost:8080/guacamole/ flushpackets=on
    ProxyPassReverse http://localhost:8080/guacamole/
</Location>

```

Y en el html creamos un enlace para acceder a la aplicación

```sh
<h1>Hola! Enhorabuena tu sitio funciona!!!</h1>
<p>Guacamole-></p><a href=http://www.misitio.org/guacamole/#/> Enlace </a>
```

![enlace.png](/images/guacamole/enlace.png)

Si accedemos al sitio y accedemos al enlace que hemos dejado para ir a la aplicación vemos que funciona correctamente.

![funciona1.png](/images/guacamole/funciona1.png)

![funciona2.png](/images/guacamole/funciona2.png)

Fuentes:

https://www.linuxbabe.com/debian/apache-guacamole-remote-desktop-debian-10-buster

https://openbinary20.com/2018/03/24/apache-guacamole/