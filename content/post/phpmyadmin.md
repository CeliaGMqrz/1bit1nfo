+++
author = "Celia García Márquez"
title = "Phpmyadmin para administrar MySQL"
date = "2021-03-24"
description = "MySQL: phpmyadmin, cliente remoto"
tags = [
    "mysql",
]
thumbnail= "images/mysql/banner.png"
+++

## Descripción

Instalación de una herramienta de administración web para MySQL y prueba desde un cliente remoto

## Requisitos previos

* Una máquina virtual con Debian Buster (paquetería actualizada). En mi caso usaré una máquina alzada con vagrant y virtualbox
* Un servidor MySQL instalado. Instalaremos MariaDB.
* Otra máquina virtual que actuará como cliente remoto con una red compartida con el servidor.

Hemos ejecutado los siguientes comandos para hacer todo lo mencionado
```sh
# Actualizamos la máquina
$ sudo apt update && apt upgrade
# Instalamos mariadb desde los repositorios de debian
$ sudo apt install mariadb-server
# Ejecutamos el script de seguridad de mariadb (opcional)
$ sudo mysql_secure_installation
```


## Creación de la base de datos y usuario de prueba

En este [post](https://1bit1nfo.netlify.app/post/mysql_clienteremoto/), está la creación de la base de datos, usuario, datos de prueba y además la conexión de un cliente remoto.

Una vez ya hemos comprobado que tenemos los requisitos mencionados en el post podemos continuar con lo siguiente.

## Herramienta de administración web. phpMyAdmin.

**phpMyAdmin** es una herramienta escrita en **php** con la intención de manejar la administración de **MySQL** a través un navegador web. Actualmente puede crear y eliminar bases de datos, modificar tablas, añadir registros, hacer consultas, administrar privilegios etc...

Para utilizar esta herramienta necesitaremos un servidor web, en nuestro caso será **apache2** y **soporte php**. 

Utilizaremos el mismo servidor en el que se aloja la base de datos para ofrecer también el servicio web. Aunque lo más parecido a la realidad es que en una máquina tengamos el servidor de base de datos y en otro el servidor web.

**Instalación del servidor web apache2 y soporte php**

```sh
sudo apt install apache2 php php-mysql php-zip php-bz2 php-mbstring php-gd libapache2-mod-php 
```
Comprobamos que el servicio está funcionando y que podemos acceder acceder al sitio web por defecto en este caso.

```powershell
vagrant@servermysql:~$ sudo systemctl status apache2
● apache2.service - The Apache HTTP Server
   Loaded: loaded (/lib/systemd/system/apache2.service; enabled; vendor preset: enabled)
   Active: active (running) since Tue 2021-03-23 09:07:56 GMT; 24s ago
     Docs: https://httpd.apache.org/docs/2.4/
 Main PID: 10008 (apache2)
    Tasks: 6 (limit: 544)
   Memory: 12.9M
   CGroup: /system.slice/apache2.service
           ├─10008 /usr/sbin/apache2 -k start
           ├─10012 /usr/sbin/apache2 -k start
           ├─10013 /usr/sbin/apache2 -k start
           ├─10014 /usr/sbin/apache2 -k start
           ├─10015 /usr/sbin/apache2 -k start
           └─10016 /usr/sbin/apache2 -k start

Mar 23 09:07:56 servermysql systemd[1]: Starting The Apache HTTP Server...
Mar 23 09:07:56 servermysql apachectl[10004]: AH00558: apache2: Could not reliably determine the server's
Mar 23 09:07:56 servermysql systemd[1]: Started The Apache HTTP Server.

```

![apache.png](/images/mysql/apache.png)

Ahora vamos a modificar el fichero de configuracion del virtualhost que viene por defecto. Podriamos crear un fichero de configuración nuevo y agregar la configuración en el mismo pero vamos a usar el que viene para facilitar la configuracion con phpMyAdmin. 


`sudo nano /etc/apache2/sites-available/000-default.conf`

Añadiremos la configuración necesaria así como los alias que necesita phpMyAdmin para que el sitio funcione.

```sh
<VirtualHost *:80>
        ServerAdmin webmaster@localhost
        DocumentRoot /var/www/html

        ErrorLog ${APACHE_LOG_DIR}/error.log
        CustomLog ${APACHE_LOG_DIR}/access.log combined

        Alias /phpmyadmin /usr/share/phpmyadmin

        <Directory /usr/share/phpmyadmin>
            Options SymLinksIfOwnerMatch
            DirectoryIndex index.php

            <IfModule mod_php5.c>
                <IfModule mod_mime.c>
                    AddType application/x-httpd-php .php
                </IfModule>
                <FilesMatch ".+\.php$">
                    SetHandler application/x-httpd-php
                </FilesMatch>

                php_value include_path .
                php_admin_value upload_tmp_dir /var/lib/phpmyadmin/tmp
                php_admin_value open_basedir /usr/share/phpmyadmin/:/etc/phpmyadmin/:/var/lib/phpmyadmin/:/usr/share/php/php-gettext/:/usr/share/php/php-php-gettext/:/usr/share/javascript/:/usr/share/php/tcpdf/:/usr/share/doc/phpmyadmin/:/usr/share/php/phpseclib/
                php_admin_value mbstring.func_overload 0
            </IfModule>
            <IfModule mod_php.c>
                <IfModule mod_mime.c>
                    AddType application/x-httpd-php .php
                </IfModule>
                <FilesMatch ".+\.php$">
                    SetHandler application/x-httpd-php
                </FilesMatch>

                php_value include_path .
                php_admin_value upload_tmp_dir /var/lib/phpmyadmin/tmp
                php_admin_value open_basedir /usr/share/phpmyadmin/:/etc/phpmyadmin/:/var/lib/phpmyadmin/:/usr/share/php/php-gettext/:/usr/share/php/php-php-gettext/:/usr/share/javascript/:/usr/share/php/tcpdf/:/usr/share/doc/phpmyadmin/:/usr/share/php/phpseclib/
                php_admin_value mbstring.func_overload 0
            </IfModule>
        </Directory>

        <Directory /usr/share/phpmyadmin/templates>
            Require all denied
        </Directory>
        <Directory /usr/share/phpmyadmin/libraries>
            Require all denied
        </Directory>
        <Directory /usr/share/phpmyadmin/setup/lib>
            Require all denied
        </Directory>
</VirtualHost>
```

### Instalación de phpmyadmin

Para instalar esta herramienta vamos a ir a su página oficial para encontrar el enlace a la versión mas actual y lo descargaremos en la máquina virtual y lo descomprimimos de la siguiente forma:

```sh
# Obtener el paquete
wget https://files.phpmyadmin.net/phpMyAdmin/5.1.0/phpMyAdmin-5.1.0-all-languages.tar.gz


# Lo descomprimimos y lo movemos al directorio /usr/share
sudo tar xzvf phpMyAdmin-5.1.0-all-languages.tar.gz
sudo mv  phpMyAdmin-5.1.0-all-languages /usr/share/
```

Le cambiamos el nombre al directorio para que sea mas legible

```sh
root@servermysql:/usr/share# mv phpMyAdmin-5.1.0-all-languages/ phpmyadmin
root@servermysql:/usr/share# cd phpmyadmin/

# Vemos el contenido del directorio
root@servermysql:/usr/share/phpmyadmin# ls -l
total 672
-rw-r--r--  1 root root     41 Feb 24 06:05 babel.config.json
-rw-r--r--  1 root root  41123 Feb 24 06:05 ChangeLog
-rw-r--r--  1 root root   4106 Feb 24 06:05 composer.json
-rw-r--r--  1 root root 201246 Feb 24 06:05 composer.lock
-rw-r--r--  1 root root   4474 Feb 24 06:05 config.sample.inc.php
-rw-r--r--  1 root root   2587 Feb 24 06:05 CONTRIBUTING.md
drwxr-xr-x  3 root root   4096 Feb 24 06:05 doc
drwxr-xr-x  2 root root   4096 Feb 24 06:05 examples
-rw-r--r--  1 root root  22486 Feb 24 06:05 favicon.ico
-rw-r--r--  1 root root    413 Feb 24 06:05 index.php
drwxr-xr-x  5 root root   4096 Feb 24 06:05 js
drwxr-xr-x  5 root root   4096 Feb 24 06:05 libraries
-rw-r--r--  1 root root  18092 Feb 24 06:05 LICENSE
drwxr-xr-x 45 root root   4096 Feb 24 06:05 locale
-rw-r--r--  1 root root   2285 Feb 24 06:05 package.json
-rw-r--r--  1 root root   1034 Feb 24 06:05 print.css
-rw-r--r--  1 root root   1520 Feb 24 06:05 README
-rw-r--r--  1 root root     29 Feb 24 06:05 RELEASE-DATE-5.1.0
-rw-r--r--  1 root root     26 Feb 24 06:05 robots.txt
drwxr-xr-x  3 root root   4096 Feb 24 06:05 setup
-rw-r--r--  1 root root   1354 Feb 24 06:05 show_config_errors.php
drwxr-xr-x  2 root root   4096 Feb 24 06:05 sql
drwxr-xr-x 25 root root   4096 Feb 24 06:05 templates
drwxr-xr-x  5 root root   4096 Feb 24 06:05 themes
-rw-r--r--  1 root root   1613 Feb 24 06:05 url.php
drwxr-xr-x 17 root root   4096 Feb 24 06:05 vendor
-rw-r--r--  1 root root 293093 Feb 24 06:05 yarn.lock

```

Una vez que hemos descomprimido vamos a crear un directorio para alojar los archivos **temporales** de phpmyadmin.

```sh
sudo mkdir -p /var/lib/phpmyadmin/tmp
```

Ahora vamos a darle **permisos** para que apache pueda utilizar los directorio 

```sh
sudo chown -R www-data:www-data /var/lib/phpmyadmin
sudo chown -R www-data:www-data /usr/share/phpmyadmin
```

Phpmyadmin tiene un **fichero de configuación** por defecto que vamos a copiar para usarlo y modificarlo.

```sh
cp config.sample.inc.php config.inc.php
```

Una vez copiado lo vamos a modificar de la siguiente forma

```sh
root@mysql:/usr/share/phpmyadmin# nano config.inc.php
```
Buscaremos la siguiente línea, en la que especificaremos una cadena de texto de 32 caracteres aleatorios que sirve para cifrar las cookies de la sesión. Esta cadena se puede generar a mano o usando cualquier paquete que haga esta función. 

```sh
$cfg['blowfish_secret'] = ''; /* YOU MUST FILL IN THIS FOR COOKIE AUTH! */
```
También buscaremos las siguientes líneas que sirven para habilitar la directiva en la que se da lugar a usar una base de datos de phpmyadmin a un usuario con una contraseña, la dejaremos por defecto, pero es recomendable usar una contraseña más segura.

```sh
$cfg['Servers'][$i]['controluser'] = 'pma';
$cfg['Servers'][$i]['controlpass'] = 'pmapass';
```

También activaremos todas las variables de la sección **Storage and tables**

```sh
$cfg['Servers'][$i]['pmadb'] = 'phpmyadmin';
$cfg['Servers'][$i]['bookmarktable'] = 'pma__bookmark';
$cfg['Servers'][$i]['relation'] = 'pma__relation';
$cfg['Servers'][$i]['table_info'] = 'pma__table_info';
$cfg['Servers'][$i]['table_coords'] = 'pma__table_coords';
$cfg['Servers'][$i]['pdf_pages'] = 'pma__pdf_pages';
$cfg['Servers'][$i]['column_info'] = 'pma__column_info';
$cfg['Servers'][$i]['history'] = 'pma__history';
$cfg['Servers'][$i]['table_uiprefs'] = 'pma__table_uiprefs';
$cfg['Servers'][$i]['tracking'] = 'pma__tracking';
$cfg['Servers'][$i]['userconfig'] = 'pma__userconfig';
$cfg['Servers'][$i]['recent'] = 'pma__recent';
$cfg['Servers'][$i]['favorite'] = 'pma__favorite';
$cfg['Servers'][$i]['users'] = 'pma__users';
$cfg['Servers'][$i]['usergroups'] = 'pma__usergroups';
$cfg['Servers'][$i]['navigationhiding'] = 'pma__navigationhiding';
$cfg['Servers'][$i]['savedsearches'] = 'pma__savedsearches';
$cfg['Servers'][$i]['central_columns'] = 'pma__central_columns';
$cfg['Servers'][$i]['designer_settings'] = 'pma__designer_settings';
$cfg['Servers'][$i]['export_templates'] = 'pma__export_templates';
```

Indicaremos el path de los archivos temporales 

```sh
$cfg['TempDir'] = '/var/lib/phpmyadmin/tmp';
```

Una vez modificado el fichero de configuración vamos a crear la base de datos para phpmyadmin, de modo que vamos al directorio 'sql' y ahí ejecutamos el siguiente comando para pasarle los datos a mysql 

```sh
root@servermysql:/usr/share/phpmyadmin/sql# mariadb < create_tables.sql 
```

Comprobamos que se ha creado la base de datos y las tablas correspondientes.


```sh
root@servermysql:/usr/share/phpmyadmin/sql# mysql -u root -p
Enter password: 
Welcome to the MariaDB monitor.  Commands end with ; or \g.
Your MariaDB connection id is 38
Server version: 10.3.27-MariaDB-0+deb10u1 Debian 10

Copyright (c) 2000, 2018, Oracle, MariaDB Corporation Ab and others.

Type 'help;' or '\h' for help. Type '\c' to clear the current input statement.

MariaDB [(none)]> show databases;
+--------------------+
| Database           |
+--------------------+
| academia           |
| information_schema |
| mysql              |
| performance_schema |
| phpmyadmin         |
+--------------------+
5 rows in set (0.001 sec)

MariaDB [(none)]> use phpmyadmin
Reading table information for completion of table and column names
You can turn off this feature to get a quicker startup with -A

Database changed
MariaDB [phpmyadmin]> show tables;
+------------------------+
| Tables_in_phpmyadmin   |
+------------------------+
| pma__bookmark          |
| pma__central_columns   |
| pma__column_info       |
| pma__designer_settings |
| pma__export_templates  |
| pma__favorite          |
| pma__history           |
| pma__navigationhiding  |
| pma__pdf_pages         |
| pma__recent            |
| pma__relation          |
| pma__savedsearches     |
| pma__table_coords      |
| pma__table_info        |
| pma__table_uiprefs     |
| pma__tracking          |
| pma__userconfig        |
| pma__usergroups        |
| pma__users             |
+------------------------+
19 rows in set (0.001 sec)

```

Ahora crearemos el usuario pma con la correspondiente contraseña, recuerda que puedes ponerle el nombre de usuario y contraseña que quieras pero lo hemos dejado por defecto ya que este es un escenario de prueba para el post.

```sh
MariaDB [phpmyadmin]> GRANT SELECT, INSERT, UPDATE, DELETE ON phpmyadmin.* TO 'pma'@'localhost' IDENTIFIED BY 'pmapass';
Query OK, 0 rows affected (0.075 sec)

MariaDB [phpmyadmin]> FLUSH PRIVILEGES;
Query OK, 0 rows affected (0.001 sec)

```

Por último vamos a reiniciar los servicios tanto mariadb como apache2 y comprobamos que están en correcto funcionamiento.

```sh
systemctl reload mariadb
systemctl reload apache2
systemctl status mariadb
systemctl status apache2
```

Ahora sí podemos comenzar con la configuración desde el navegador. Accedemos a la dirección de nuestro servidor con la url. 

Nota: Nos ha surgido un error:

Composer detected issues in your platform: Your Composer dependencies require the following PHP extensions to be installed: xml.

Simplemente no teníamos instalada la extensión xml para php, asi que la instalamos y reiniciamos el servicio.

```sh
apt install php-xml
systemctl restart apache2
``` 

Como podemos ver ya se puede ver en el navegador el formulario para introducir nuestras credenciales.

![credenciales.png](/images/mysql/credenciales.png)

Introducimos el usuario y la contraseña que anteriormente usamos para la base de datos de prueba 'academia' y entramos.


![captura1.png](/images/mysql/captura1.png)

Como podemos ver nos muestra todas las opciones que tenemos para gestionar nuestra base de datos, vamos a hacer click en nuestra base de datos 'academia' y veremos las tablas de la misma.


![captura2.png](/images/mysql/captura1.png)

Vamos a pinchar sobre una tabla en concreto y podremos ver los registros de la tabla.

![registrosninos.png](/images/mysql/registrosninos.png)

Desde esta herramienta podemos ver que podemos administrar la base de datos de forma gráfica ademas podemos hacer consultas de linea de comando en la pestaña de SQL.

![consulta.png](/images/mysql/consulta.png)


Fuentes:

https://chachocool.com/como-instalar-phpmyadmin-en-debian-10-buster/