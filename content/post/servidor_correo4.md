---
title: "Servidor de Correos. Postfix (IV). Webmail Roundcube."
date: 2021-01-25T17:15:21+01:00
draft: false
toc: false
images:
tags: ['servidor de correos','roundcube', 'webmail', 'nginx', 'mariadb']
---

## Descripción

(Tarea 10 y 12)

Vamos a instalar un webmail (Roundcube), sobre Debian Buster alojado en una máquina de OVH, para gestionar el correo del equipo mediante una interfaz web. Recibo y envío de correos.

*RoundCube* es un cliente de correo electrónico IMAP, de código abierto y escrito en PHP. Para instalar este webmail deberemos de tener en funcionamiento un servidor de correos.

## 1. Requisitos:

* Tener en funcionamiento un servidor de web, en este caso usaremos [Nginx](https://github.com/CeliaGMqrz/servidor_Nginx)

* Un gestor de base de datos, usaremos *MariaDB*.

* Servidor de correos, en este caso usaremos [Postfix](https://unbitdeinformacioncadadia.netlify.app/posts/2021/01/servidor-de-correos.-postfix-i/)

* Un servidor DNS, en este caso OVH se encarga de ello pero podemos configurarlo con [Bind9](https://unbitdeinformacioncadadia.netlify.app/posts/2021/01/configurar-un-dns-con-bind9/), de forma que se cree un subdominio o dominio que se usará para roundcube, en este caso el subdominio será mail.iesgn05.es. que es un CNAME de nuestra máquina kiara.iesgn05.es.

## 2. Instalación de extensiones PHP 

*  Intalamos las extensiones que nos harán falta para roundcube

```sh 
sudo apt-get install php php-cli php-gd php-intl php-fpm php-curl php-imagick php-mysql php-zip php-xml php-mbstring php-bcmath -y
```


* Establecer zona horaria en php.ini, según la nuestra evidentemente.

```sh 
sudo sed -i 's/;date.timezone =/date.timezone = Europe\/Madrid/g' /etc/php/7.3/fpm/php.ini
```

* Reiniciar php-fpm

```sh 
sudo systemctl restart php7.3-fpm
```

## 2. Configuración MariaDB. Crear usuario y base de datos para roundcube


* Entramos a MySQL como superusuario

```sh 
sudo mysql -u root -p
```

* Creamos la base de datos para roundcube

```sh 
CREATE DATABASE roundcube DEFAULT CHARACTER SET utf8 COLLATE utf8_general_ci;
```

* Creamos el usuario para la base de datos

```sh 
CREATE USER 'roundcube'@'localhost' IDENTIFIED BY 'roundcube';
```

* Le otorgamos los permisos necesarios para la nueva base de datos

```sh 
GRANT ALL PRIVILEGES ON roundcube.* TO 'roundcube'@'localhost';
```

* Actualizamos los permisos

```sh 
flush privileges;
```

* Salimos del MySQL

```sh 
quit
```

## 3. Crear certificado para usar https con Letsencrypt

* Si no tenemos instalado LetsEncrypt lo instalamos

```sh 
nano /etc/apt/sources.list
# Agregamos:
deb http://ftp.debian.org/debian buster-backports main
# Actualizamos:
apt-get update
# Instalamos:
apt install certbot -t buster-backports
# Una vez instlado comentamos la línea de backports de nuevo y volvemos a hacer un apt update, porque ya no nos hará falta.
```

* Paramos nuestro servidor web nginx

```sh 
sudo systemctl stop nginx
```

* Creamos los certificados para correo.iesgn05.es

```sh 
sudo certbot -d mail.iesgn05.es --agree-tos -m debian@iesgn05.es
```

## 4. Configuración de NGINX

Una vez instalado y configurado Nginx con un sitio web inicial y comprobado que el sitio web funciona vamos a configurar el virtualhost que va servir nuestro webmail.

* Crearemos un fichero de configuración nuevo

```sh 
sudo nano /etc/nginx/sites-available/mail.iesgn05.es
```

* Le añadimos el siguiente contenido, como podemos ver hemos añadido la configuración pertinente para usar https y que sea un sitio de confianza. Tambien podemos ver que hemos añadido los parámetros pertinentes para que php funcione.

```sh 
server {
    listen 80;
    server_name mail.iesgn05.es;
    return 301 https://$host$request_uri;
}
 
server {
    listen 443 ssl http2;
    server_name mail.iesgn05.es;
    root /var/www/roundcubemail;
    index index.php index.htm index.html;
 
    ssl_certificate /etc/letsencrypt/live/mail.iesgn05.es/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/mail.iesgn05.es/privkey.pem;
 
    location / {
        try_files $uri $uri/ /index.php?$args;
    }
 
    location ~ \.php(?:$|/) {
        try_files $uri =404;
        fastcgi_split_path_info ^(.+\.php)(/.+)$;
        include fastcgi_params;
        fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
        fastcgi_param PATH_INFO $fastcgi_path_info;
        fastcgi_param HTTPS on;
        fastcgi_param modHeadersAvailable true;
        fastcgi_pass unix:/run/php/php7.3-fpm.sock;
        fastcgi_intercept_errors on;
        fastcgi_buffers 4 256k;
        fastcgi_busy_buffers_size 256k;
    }
}
```
* Creamos el enlace

```sh 
sudo ln -s /etc/nginx/sites-available/mail.iesgn05.es /etc/nginx/sites-enabled/
```

* Comprobamos la sintaxis

```sh 
sudo nginx -t
```

## 5. Instalación de Roundcube

* Obtenemos el paquete

```sh 
sudo wget https://github.com/roundcube/roundcubemail/releases/download/1.4.8/roundcubemail-1.4.8-complete.tar.gz -P /var/www/
```
* Lo descomprimimos en el documenroot

```sh 
sudo tar zxvf /var/www/roundcubemail-1.4.8-complete.tar.gz -C /var/www/
```

* Renombramos el directorio

```sh 
sudo mv /var/www/roundcubemail-1.4.8 /var/www/roundcubemail
```

* Le damos los permisos necesarios para nginx

```sh 
sudo chown www-data:www-data -R /var/www/roundcubemail
```

* Comprobamos que la sintaxis de nginx es correcta, reinciamos el servicio y comprobamos que está en funcionamiento. 

```sh 
sudo nginx -t
sudo systemctl restart nginx
sudo systemctl status nginx
```

* Nos dirigmos al navegador e introducimos la url: mail.iesgn05.es/installer

Nos saldrá el entorno de instalación de roundcube.

![r1.png](/images/ovh_correo/r1.png)

Le damos a NEXT y continuamos con la instalación.

Ahora vamos a crear la configuración:

* General configuration: Lo dejaremos por defecto.

![r2.png](/images/ovh_correo/r2.png)

* Logging & Debugging: Se trata de los ficheros de log, los dejaremos por defecto.

![r3.png](/images/ovh_correo/r3.png)

* Database setup: Aqui elegiremos la base de datos, El nombre de la base de datos, el usuario y la contraseña

![r4.png](/images/ovh_correo/r4.png)

* Aquí se hará la configuración de IMAP, la dejaremos por defecto que coja el puerto 143.

* Aquí se indicará la configuracion de SMTP

![r6.png](/images/ovh_correo/r6.png)

* Lo demás lo dejamos por defecto todo y le damos a 'Create config' y después a CONTINUE.

Ahora Vamos a comprobar la configuración, Inicializamos la base de datos para que se copien las tablas, en 'Initialize database'

![r7.png](/images/ovh_correo/r7.png)

Ahora hacemos el test para el envío por SMTP

![r8.png](/images/ovh_correo/r8.png)

Comprobamos que lo recibimos

![mensaje.png](/images/ovh_correo/mensaje.png)

Por último comprobamos el IMAP

![r10.png](/images/ovh_correo/r10.png)

Una vez comprobado todo vamos a eliminar el instalador

```sh 
sudo rm -fr /var/www/roundcubemail/installer/
```

Una vez eliminado vamos a abrir un navegador e indicar la url mail.iesgn05.es, nos pedirá el nombre de usuario y la contraseña para imap y se nos abrirá nuestro correo.

![webmailyes.png](/images/ovh_correo/webmailyes.png)

Probamos enviar y recibir correos desde Webmail y funciona correctamente

![wm1.png](/images/ovh_correo/wm1.png)

![wm2.png](/images/ovh_correo/wm2.png)

![wm3.png](/images/ovh_correo/wm3.png)

![wm4.png](/images/ovh_correo/wm4.png)

Fuentes:

- https://atetux.com/how-to-install-roundcube-webmail-1-4-on-debian-10