---
title: "Servidor Nginx"
date: 2020-11-11T17:51:13+01:00
draft: false
toc: false
images:
tags: ['nginx','virtualhosting','servidor nginx']
---


# Servidor Web Nginxx

![image.jpg](/images/nginx/image.jpg)


**NGINX** es un servidor web open source de alta performance que ofrece el contenido estático de un sitio web de forma rápida y fácil de configurar. Ofrece recursos de equilibrio de carga, proxy inverso y streaming, además de gestionar miles de conexiones simultáneas. El resultado de sus aportes es una mayor velocidad y escalabilidad.

Además de otras tareas, los servidores web son los encargados de la entrega de aplicaciones web, respondiendo a peticiones HTTPS realizadas por usuarios, normalmente desde un navegador web.

El funcionamiento base de Nginx es similar al de otros servidores web, en el que un usuario realiza una petición a través del navegador al servidor, y este le envía la información solicitada al navegador.

Lo que hace diferente a Nginx es su arquitectura a la hora de manejar procesos, ya que otros servidores web como Apache crean un hilo por cada solicitud.

-> [Más informacion](https://rockcontent.com/es/blog/nginx/)

## Instalación de Nginx

* Para instalar Nginx vamos a usar el repositorio de Debian, así que lo primero será actualizar la información de paquetes.

```sh
sudo su
apt update
apt upgrade
```

* Instalamos el paquete nginx

```sh
apt install nginx
```

* Modificar el html y visualizar el sitio

```sh
root@servidor-nginx:/var/www/html# nano index.html 
```

![pruebahtml.png](/images/nginx/pruebahtml.png)

[Tarea 2: Crear virtualhosting](https://github.com/CeliaGMqrz/servidor_Nginx/blob/main/t2_virtualhosting.md)

## Virtual Hosting

Tarea 2 (2 punto)(Obligatorio): Configura la resolución estática en los clientes y muestra el acceso a cada una de las páginas.

______________________________________________________________________________________

Queremos que nuestro servidor web ofrezca dos sitios web, teniendo en cuenta lo siguiente:

1. Cada sitio web tendrá nombres distintos.

2. Cada sitio web compartirán la misma dirección IP y el mismo puerto (80).

Los dos sitios web tendrán las siguientes características:

* El nombre de dominio del primero será **www.iesgn.org**, su directorio base será **/srv/www/iesgn** y contendrá una página llamada index.html, donde sólo se verá una bienvenida a la página del Instituto Gonzalo Nazareno.

* En el segundo sitio vamos a crear una página donde se pondrán noticias por parte de los departamento, el nombre de este sitio será **departamentos.iesgn.org**, y su directorio base será **/srv/www/departamentos**. En este sitio sólo tendremos una página inicial index.html, dando la bienvenida a la página de los departamentos del instituto.

______________________________________________________________________________________

## Crear los virtual hosting

Crear el virtualhosting **iesgn** y el de **departamentos**. Para ello copiamos el archivo *default* que se encuentra en el fichero */etc/nginx/sites-available* y le ponemos el nombre de cada virtualhost.

```sh
root@servidor-nginx:/etc/nginx/sites-available# cp default iesgn
root@servidor-nginx:/etc/nginx/sites-available# ls
default  iesgn
root@servidor-nginx:/etc/nginx/sites-available# cp default departamentos
root@servidor-nginx:/etc/nginx/sites-available# ls
default  departamentos	iesgn

```

Deberemos de modificar los ficheros de forma que, eliminamos el 'default_server' para que no haya conflictos con el fichero 'default' que viene por defecto. Cambiamos la ruta de directorios indicando /srv/www/directorio. Cambiamos el 'server_name' indicando el nombre con el que vamos a acceder a nuestro sitio web.

## **IESGN**

```sh
nano /etc/nginx/sites-available/iesgn 
```

```sh
# Default server configuration
#
server {
        listen 80;

        root /srv/www/iesgn;

        # Add index.php to the list if you are using PHP
        index index.html index.htm index.nginx-debian.html;

        server_name www.iesgn.org;

        location / {
                # First attempt to serve request as file, then
                # as directory, then fall back to displaying a 404.
                try_files $uri $uri/ =404;
        }

}

```

## **DEPARTAMENTOS**

```sh
nano /etc/nginx/sites-available/departamentos 
```

```sh
# Default server configuration

server {
        listen 80;

        root /srv/www/departamentos;

        # Add index.php to the list if you are using PHP
        index index.html index.htm index.nginx-debian.html;

        server_name departamentos.iesgn.org;

        location / {
                # First attempt to serve request as file, then
                # as directory, then fall back to displaying a 404.
                try_files $uri $uri/ =404;
        }

}

```

Creamos los enlaces simbólicos para la carpeta 'sites-enabled' y así activar nuestros virtualhosting, en apache utilizabamos una herramienta pero aquí hay que hacerlo manual.

```sh
ln -s /etc/nginx/sites-available/iesgn /etc/nginx/sites-enabled/iesgn
ln -s /etc/nginx/sites-available/departamentos /etc/nginx/sites-enabled/departamentos

```
Comprobamos que está bien configurado con **nginx -t**

```sh
root@servidor-nginx:/etc/nginx/sites-available# nginx -t
nginx: the configuration file /etc/nginx/nginx.conf syntax is ok
nginx: configuration file /etc/nginx/nginx.conf test is successful

```

Crear los **directorios** correspondientes, no es necesario dar permisos ya que con Nginx usa los permisos de superusuario 'root'. Hemos creado la siguiente estructura tal y como se pide en el ejercicio:

```sh
root@servidor-nginx:/srv# tree
.
└── www
    ├── departamentos
    │   └── index.html
    └── iesgn
        └── index.html

3 directories, 2 files


```

#### Configurar el cliente (máquina anfitriona)

Configuramos nuestro fichero /etc/hosts añadiendo estas líneas

```sh
172.22.200.152 www.iesgn.org
172.22.200.152 departamentos.iesgn.org

```

Reiniciamos el servicio

```sh
systemctl restart nginx
```

Comprobamos que podemos acceder a ellas

**www.iesgn.org**

![iesgn.png](/images/nginx/iesgn.png)

**departamentos.iesgn.org**

![departamentos.png](/images/nginx/departamentos.png)

# Mapeo de URL


Cambia la configuración del sitio web www.iesgn.org para que se comporte de la siguiente forma:

* **Tarea 3 (1 punto)(Obligatorio): Cuando se entre a la dirección www.iesgn.org se redireccionará automáticamente a www.iesgn.org/principal, donde se mostrará el mensaje de bienvenida. En el directorio principal no se permite ver la lista de los ficheros, no se permite que se siga los enlaces simbólicos y no se permite negociación de contenido. Muestra al profesor el funcionamiento.**

Para redireccionar *www.iesgn.org* a *www.iesgn.org/principal* necesitamos editar el fichero de configuracion de *iesgn*

```sh

# Default server configuration
#
server {
        listen 80;

        root /srv/www/iesgn;

        # Add index.php to the list if you are using PHP
        index index.html index.htm index.nginx-debian.html;

        server_name www.iesgn.org;

        location = / {
                return 301 $scheme://www.iesgn.org/principal;
                # First attempt to serve request as file, then
                # as directory, then fall back to displaying a 404.
                try_files $uri $uri/ =404;   
        }

        location /principal/ {
                # No se permite ver la lista de ficheros
                autoindex off;
                # No se permite el seguimiento de enlaces simbólicos
                disable_symlinks off;
                # No se permite la negociación de contenido
                try_files $uri $uri/ index.html;
        }

}

```
No nos olvidemos de crear el directorio *principal* y mover el *index.html* a su interior.

```sh
mkdir /srv/www/iesgn/principal
mv /srv/www/iesgn/index.html /srv/www/iesgn/principal/
```


______________________________________________________________________________________

* **Tarea 4 (1 punto)(Obligatorio): Si accedes a la página www.iesgn.org/principal/documentos se visualizarán los documentos que hay en /srv/doc. Por lo tanto se permitirá el listado de fichero y el seguimiento de enlaces simbólicos siempre que sean a ficheros o directorios cuyo dueño sea el usuario. Muestra al profesor el funcionamiento.**

Creamos los directorios */srv/doc* y */srv/www/iesgn/principal/documentos*

```sh
mkdir /srv/doc
mkdir /srv/www/iesgn/principal/documentos
```

Dentro de */srv/doc* creamos los ficheros de prueba y le ponemos los permisos y propietarios adecuados para cada uno, de forma que uno sea de **root** y el otro sea del usuario **debian**

```sh
root@servidor-nginx:/srv/doc# ls -l
total 8
-rw-r--r-- 1 root   root   32 Nov 10 13:04 ficheroderoot.txt
-rw-r--r-- 1 debian debian 38 Nov 10 13:07 ficherodeusuario.txt

```

Creamos el enlace simbólico del contendio que hay en doc hacia la carpeta documentos

```sh
root@servidor-nginx:~# ln -svf /srv/doc /srv/www/iesgn/principal/documentos
'/srv/www/iesgn/principal/documentos/doc' -> '/srv/doc'

```

**Fichero de configuración**

Usamos '*alias*' para poder mostrar los documentos de la ruta */srv/doc*, activamos el listado de ficheros, el seguimiento de enlaces simbólicos y le ponemos la opción *if_not_owner* para que deniegue el acceso a un archivo si no es el propietario

```sh
# Default server configuration
#
server {
        listen 80;

        root /srv/www/iesgn;

        # Add index.php to the list if you are using PHP
        index index.html index.htm index.nginx-debian.html;

        server_name www.iesgn.org;

        location = / {
                return 301 $scheme://www.iesgn.org/principal;
                # First attempt to serve request as file, then
                # as directory, then fall back to displaying a 404.
                try_files $uri $uri/ =404;
        }

        location /principal {
                # No se permite ver la lista de ficheros
                autoindex off;
                # No se permite el seguimiento de enlaces simbólicos
                disable_symlinks off;
                # No se permite la negociación de contenido
                try_files $uri $uri/ index.html;
        }

        location /principal/documentos {

                #alias
                alias /srv/doc;
                # Permitir listado de ficheros
                autoindex on;
                # Permitir el seguimiento de enlaces simbólicos solo al propietario
                disable_symlinks if_not_owner;
        }

}


```
______

![documentos.png](/images/nginx/documentos.png)
_________________
______________________________________________________________

* **Tarea 5 (1 punto): En todo el host virtual se debe redefinir los mensajes de error de objeto no encontrado y no permitido. Para el ello se crearan dos ficheros html dentro del directorio error. Entrega las modificaciones necesarias en la configuración y una comprobación del buen funcionamiento.**

Creamos los dos ficheros html dentro de un directorio *error* en nuestro virtualhosting. Y modificamos el fichero de nuestro virtualhosting

```sh
root@servidor-nginx:/etc/nginx# tree /srv/www/iesgn/error/
/srv/www/iesgn/error/
├── 403.html
└── 404.html
```

```sh
# Default server configuration
#
server {
        listen 80;

        #set $root_path /var/www/iesgn;
        #root $root_path;
        root /srv/www/iesgn;

        # Add index.php to the list if you are using PHP
        index index.html index.htm index.nginx-debian.html;

        server_name www.iesgn.org;
        error_page 404 = /error/404.html;
        error_page 403 = /error/403.html;
        location = / {
                return 301 $scheme://www.iesgn.org/principal;
                # First attempt to serve request as file, then
                # as directory, then fall back to displaying a 404.
                #try_files $uri $uri/ =404;

        }

        location /principal {
                # No se permite ver la lista de ficheros
                autoindex off;
                # No se permite el seguimiento de enlaces simbólicos
                disable_symlinks off;
                # No se permite la negociación de contenido
                try_files $uri $uri/ index.html;
        }

        location /principal/documentos {

                #alias
                alias /srv/doc;
                # Permitir listado de ficheros
                autoindex on;
                # Permitir el seguimiento de enlaces simbólicos solo al propietario
                disable_symlinks if_not_owner;

        }

}

```
Reiniciamos el servicio.

Provocamos un error en la url y vemos el **error 404**.

![404.png](/images/nginx/404.png)


Cambiamos el 'autoindex on' por '**autoindex off**' para denegar los permisos de visibilidad de ficheros y comprobamos que nos muestra la pagina de **error 403** que hemos creado.

![403.png](/images/nginx/403.png)

## Autentificación, Autorización y Control de Acceso

* **Tarea 6 (1 punto)(Obligatorio): Añade al escenario otra máquina conectada por una red interna al servidor. A la URL departamentos.iesgn.org/intranet sólo se debe tener acceso desde el cliente de la red local, y no se pueda acceder desde la anfitriona por la red pública. A la URL departamentos.iesgn.org/internet, sin embargo, sólo se debe tener acceso desde la anfitriona por la red pública, y no desde la red local.**

1. Creamos la máquina (cliente) , cuya ip flotante es: **172.22.200.148**

![instancias.png](/images/nginx/instancias.png)

3. Creamos los directorios internet e intranet con un index.html

```sh
mkdir /srv/www/departamentos/intranet
mkdir /srv/www/departamentos/internet
cp /srv/www/iesgn/principal/index.html /srv/www/departamentos/intranet/
cp /srv/www/iesgn/principal/index.html /srv/www/departamentos/internet/
nano /srv/www/departamentos/internet/index.html 
nano /srv/www/departamentos/intranet/index.html 
```

2. Configuramos el servidor en nuestro virtualhost departamentos y el */etc/hosts* en el cliente

En el **sevidor**:

```sh
nano /etc/nginx/sites-available/departamentos 
```

```sh
# Default server configuration

server {
        listen 80;

        root /srv/www/departamentos;

        # Add index.php to the list if you are using PHP
        index index.html index.htm index.nginx-debian.html;

        server_name departamentos.iesgn.org;

        location / {
                # First attempt to serve request as file, then
                # as directory, then fall back to displaying a 404.
                try_files $uri $uri/ =404;
        }

        location /intranet {
                allow 10.0.0.6/24;
                deny all;
        }
}

```

En el **cliente**:

```sh
nano /etc/hosts
```

```sh
# Your system has configured 'manage_etc_hosts' as True.
# As a result, if you wish for changes to this file to persist
# then you will need to either
# a.) make changes to the master file in /etc/cloud/templates/hosts.debian.tmpl
# b.) change or remove the value of 'manage_etc_hosts' in
#     /etc/cloud/cloud.cfg or cloud-config from user-data
#
127.0.1.1 cliente-nginx.novalocal cliente-nginx
127.0.0.1 localhost

10.0.0.5 departamentos.iesgn.org
# The following lines are desirable for IPv6 capable hosts
::1 ip6-localhost ip6-loopback
fe00::0 ip6-localnet
ff00::0 ip6-mcastprefix
ff02::1 ip6-allnodes
ff02::2 ip6-allrouters
ff02::3 ip6-allhosts

```


3. Comprobamos que no podemos acceder desde el exterior (con nuestra máquina física) a la **intranet**

![intranet_exterior.png](/images/nginx/intranet_exterior.png)


4. Comrprobamos que sí podemos acceder desde la red local (máquina cliente) a la **intranet**.

![intranet_interior.png](/images/nginx/intranet_interior.png)


5. Configuramos el servidor y el cliente para que desde la red local no se pueda acceder a **internet** pero sí desde el exterior.

Desde el **servidor**:

```sh
# Default server configuration

server {
        listen 80;

        root /srv/www/departamentos;

        # Add index.php to the list if you are using PHP
        index index.html index.htm index.nginx-debian.html;

        server_name departamentos.iesgn.org;

        location / {
                # First attempt to serve request as file, then
                # as directory, then fall back to displaying a 404.
                try_files $uri $uri/ =404;
        }

        location /intranet {
                allow 10.0.0.6/24;
                deny all;
        }

        location /internet {
                allow 172.23.0.0/16;
                deny all;
        }

}


```

Desde el **cliente**:

```sh
# Your system has configured 'manage_etc_hosts' as True.
# As a result, if you wish for changes to this file to persist
# then you will need to either
# a.) make changes to the master file in /etc/cloud/templates/hosts.debian.tmpl
# b.) change or remove the value of 'manage_etc_hosts' in
#     /etc/cloud/cloud.cfg or cloud-config from user-data
#
127.0.1.1 cliente-nginx.novalocal cliente-nginx
127.0.0.1 localhost

10.0.0.5 departamentos.iesgn.org
# The following lines are desirable for IPv6 capable hosts
::1 ip6-localhost ip6-loopback
fe00::0 ip6-localnet
ff00::0 ip6-mcastprefix
ff02::1 ip6-allnodes
ff02::2 ip6-allrouters
ff02::3 ip6-allhosts

```


6. Comprobamos que podemos acceder desde el exterior con la red pública a 'internet' pero no desde el interior por la red local.

* Red pública:

![internet_publica.png](/images/nginx/internet_publica.png)

* Red local: 

![internet_cliente.png](/images/nginx/internet_cliente.png)


* **Tarea 7 (1 punto): Autentificación básica. Limita el acceso a la URL departamentos.iesgn.org/secreto. Comprueba las cabeceras de los mensajes HTTP que se intercambian entre el servidor y el cliente.**

Creamos el direcotorio secreto en departamentos y le añadimos un index.html

```sh
root@servidor-nginx:/home/debian# mkdir /srv/www/departamentos/secreto
root@servidor-nginx:/home/debian# cd /srv/www/departamentos/
root@servidor-nginx:/srv/www/departamentos# ls
index.html  internet  intranet	secreto
root@servidor-nginx:/srv/www/departamentos# cp index.html secreto/
root@servidor-nginx:/srv/www/departamentos# cd secreto/
root@servidor-nginx:/srv/www/departamentos/secreto# ls
index.html
root@servidor-nginx:/srv/www/departamentos/secreto# nano index.html 

```
Creamos el fichero .htpasswd con el paquete **apache2-utils** en el directorio /srv

```sh
htpasswd -cb .htpasswd servidor servidor1
```

Configuramos nuestro fichero de configuracion de 'departamentos' y le añadimos la opción de autentificación básica. Apuntamos al fichero /srv/.htpasswd donde tenemos el usuario (servidor) y la contraseña (servidor1) que hemos configurado previamente.

```sh
# Default server configuration

server {
        listen 80;

        root /srv/www/departamentos;

        # Add index.php to the list if you are using PHP
        index index.html index.htm index.nginx-debian.html;

        server_name departamentos.iesgn.org;

        location / {
                # First attempt to serve request as file, then
                # as directory, then fall back to displaying a 404.
                try_files $uri $uri/ =404;
        }

        location /intranet {
                allow 10.0.0.6/24;
                deny all;
        }

        location /internet {
                allow 172.23.0.0/16;
                deny all;
        }

        location /secreto {
                auth_basic "Zona de control";
                auth_basic_user_file /srv/.htpasswd;
        }
}

```
Ahora comprobamos que desde nuestra máquina física nos pide usuario y contraseña


![secreto1.png](/images/nginx/secreto1.png)


![secreto2.png](/images/nginx/secreto2.png)


Vemos las cabeceras http con el comando **curl**

```sh
celiagm@debian:~/github/servidor_Nginx$ curl -I departamentos.iesgn.org/secreto
HTTP/1.1 401 Unauthorized
Server: nginx/1.14.2
Date: Wed, 11 Nov 2020 13:24:34 GMT
Content-Type: text/html
Content-Length: 195
Connection: keep-alive
WWW-Authenticate: Basic realm="Zona de control"

```
Vemos las cabeceras http con el comando **wget**

```sh
celiagm@debian:~/github/servidor_Nginx$ wget -S departamentos.iesgn.org/secreto
--2020-11-11 14:26:09--  http://departamentos.iesgn.org/secreto
Resolviendo departamentos.iesgn.org (departamentos.iesgn.org)... 172.22.200.152
Conectando con departamentos.iesgn.org (departamentos.iesgn.org)[172.22.200.152]:80... conectado.
Petición HTTP enviada, esperando respuesta... 
  HTTP/1.1 401 Unauthorized
  Server: nginx/1.14.2
  Date: Wed, 11 Nov 2020 13:26:09 GMT
  Content-Type: text/html
  Content-Length: 195
  Connection: keep-alive
  WWW-Authenticate: Basic realm="Zona de control"

La autentificación usuario/contraseña falló.

```

* **Tarea 8 (2 punto): Vamos a combinar el control de acceso (tarea 6) y la autentificación (tarea 7), y vamos a configurar el virtual host para que se comporte de la siguiente manera: el acceso a la URL departamentos.iesgn.org/secreto se hace forma directa desde la intranet, desde la red pública te pide la autentificación. Muestra el resultado al profesor.**

Para ello debemos modificar el fichero de configuración de departaentos en el servidor:

Añadimos estas dos líneas:

```sh

                satisfy any;
                allow 10.0.0.0/24;

```


De forma que con la directiva **safisfy any** se concede el acceso si un cliente cumple al menos una condición. Es decir se le permite el acceso al cliente y al resto de máquinas que estén conectadas a la red interna, pero se le pide autentificación al resto.

Quedaría tal que así:

```sh

# Default server configuration

server {
        listen 80;

        root /srv/www/departamentos;

        # Add index.php to the list if you are using PHP
        index index.html index.htm index.nginx-debian.html;

        server_name departamentos.iesgn.org;

        location / {
                # First attempt to serve request as file, then
                # as directory, then fall back to displaying a 404.
                try_files $uri $uri/ =404;
        }

        location /intranet {
                allow 10.0.0.6/24;
                deny all;
        }

        location /internet {
                allow 172.23.0.0/16;
                deny all;
        }

        location /secreto {
                satisfy any;
                allow 10.0.0.0/24;
                auth_basic "Zona de control";
                auth_basic_user_file /srv/.htpasswd;
        }
}

```





Vemos que que desde fuera nos pide autentificación. 

Para que se pueda probar la autentificacion el usuario es **servidor** y la contraseña es **servidor1**.


![secreto3.png](/images/nginx/secreto3.png)

![secreto4.png](/images/nginx/secreto4.png)


Aquí vemos que desde fuera nos pide la autentifición y desde la intranet nos deja entrar sin autentificación.

![secreto5.png](/images/nginx/secreto5.png)