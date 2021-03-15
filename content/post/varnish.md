---
title: "Aumento del rendimiento de Nginx con Varnish"
date: 2021-02-16T17:15:21+01:00
draft: false
toc: false
images:
tags: ['varnish','rendimiento', 'apache', 'nginx']
---

> Para ver la introducción a este tema puedes entrar en este post:

[Gestión de peticiones y rendimiento de servidores Web](https://unbitdeinformacioncadadia.netlify.app/posts/2021/02/gesti%C3%B3n-de-peticiones-y-rendimiento-de-servidores-web/)


![varnish.png](/images/rendimiento/varnish.png)

## 1. Concepto: Varnish

Varnish es un acelerador de HTTP que funciona como **proxy inverso**. Se sitúa delante del servidor web, cacheando la respuesta del servidor web en memoria. De forma que cuando un cliente demanda la url por segunda vez, Varnish le da la respuesta ahorrando recursos en el backend y permitiendo más conexiones simultáneas. También se puede usar como **balanceador de carga**.

Características:

* Es estable y muy rápido
* Dispone de un lenguaje propio de configuración llamado VCL
* Escrito en C
* Ofrece soporte para GZIP y ESI


## 2. Aumento de rendimiento en la ejecución de scripts PHP

### 2.1. Configurar una máquina con Nginx + fpm_php. Ansible.

Vamos a configurar una máquina con Nginx y el módulo de fpm_php. Para que sea más rápido vamos a usar un repositorio preparado con una receta para Ansible. 

Previamente tenemos que haber configurado el [entorno virtual para Ansible](https://unbitdeinformacioncadadia.netlify.app/posts/2021/01/introducci%C3%B3n-a-ansible/).

* Desde el entorno virtual vamos a clonar el siguiente [repositorio](https://github.com/josedom24/ansible_nginx_fpm_php)

```sh
(ansible) celiagm@debian:~/venv/ansible$ git clone https://github.com/josedom24/ansible_nginx_fpm_php.git

```
* Comprobamos la configuración. Cambiaremos la ip por la nuestra, en este caso una máquina del cloud.

`hosts`
```sh
[servidores_web]
nodo1 ansible_ssh_host=172.22.200.152 ansible_python_interpreter=/usr/bin/python3
```

`site.yaml`

```sh

#- hosts: all
#  become: true
#  roles:
#   - role: commons

- hosts: servidores_web
  become: true
  roles:
   - role: nginx

- hosts: servidores_web
  become: true
  roles:
   - role: mariadb

- hosts: servidores_web
  become: true
  roles:
   - role: wordpress

```

* Ejecutamos la receta

```sh
ansible-playbook site.yaml 
```

* Vemos el recap

```sh
PLAY RECAP ***********************************************************************************************************************
nodo1                      : ok=17   changed=14   unreachable=0    failed=0    skipped=0    rescued=0    ignored=0
```

* Nos dirigimos a la url correspondiente y configuramos wordpress

![wordpress.png](/images/rendimiento/wordpress.png)


* Terminamos de configurar wordpress

![misitio.png](/images/rendimiento/misitio.png)


## 2.3. Pruebas de rendimiento 

Vamos a ejecutar pruebas de rendimiento con la utilidad ab desde la misma máquina. En este caso vamos a usar la máquina anfitriona.

Realizaremos las pruebas con distintos niveles de concurrencia (50, 100, 250, 500), reiniciaremos el servicio de nginx y fpm-php justo antes de hacer cada prueba.


```sh
# Nivel de concurrencia = 50
ab -t 10 -c 50 -k http://172.22.200.152/wordpress/index.php
# Respuestas por segundo 
Requests per second:    28.08 [#/sec] (mean)

# Nivel de concurrencia = 100
ab -t 10 -c 100 -k http://172.22.200.152/wordpress/index.php
# Respuestas por segundo 
Requests per second:    28.30 [#/sec] (mean)

# Nivel de concurrencia = 250
ab -t 10 -c 250 -k http://172.22.200.152/wordpress/index.php
# Respuestas por segundo 
Requests per second:    1279.42 [#/sec] (mean)

# Nivel de concurrencia = 500
ab -t 10 -c 500 -k http://172.22.200.152/wordpress/index.php
# Respuestas por segundo 
Requests per second:    2848.06 [#/sec] (mean)

```

## 2.4. Proxy inverso - Caché Varnish

Vamos a configurar un proxy inverso con Varnish, escuchando en el puerto 80, por lo que tnedremos que configurar nginx para que escuche por el puerto 8080.

* Configuramos nginx para que utilize el puerto 8080, editando el fichero de configuración default ubicado en sites-available.

```sh
        listen 8080 default_server;
        listen [::]:8080 default_server;
```
* Reiniciamos el servicio de nginx y comprobamos que está escuchando el puerto 8080

```sh
sudo systemctl restart nginx
```
```sh
sudo netstat putan

. . . 
tcp        0      0 0.0.0.0:8080            0.0.0.0:*               LISTEN      21218/nginx: master 
. . . 

```
* Instalamos Varnish

```sh
sudo apt-get install varnish
```

* Configuramos Varnish para que escuche en el puerto 80

```sh
sudo nano /etc/default/varnish
```

Configuracion:

```sh
. . . 
DAEMON_OPTS="-a :80 \
             -T localhost:6082 \
             -f /etc/varnish/default.vcl \
             -S /etc/varnish/secret \
             -s malloc,256m"
. . .
```

* Cambiamos la unidad de systemd para que varnish arranque desde el puerto 80

```sh
sudo nano /lib/systemd/system/varnish.service
```

```sh
ExecStart=/usr/sbin/varnishd -j unix,user=vcache -F -a :80 -T localhost:6082 -f /etc/varnish/default.vcl -S /etc/varnish/secret -s malloc,256m

```

* Reiniciamos la unidad de systemd y reiniciamos el servicio

```sh
sudo systemctl daemon-reload
sudo systemctl restart varnish
```

**Lenguaje de configuración VLC**

Varnish utiliza un lenguaje de configuración llamado VCL (Varnish Configuration Language). Su sintaxis recuerda un poco a C o Perl, ejecutará directivas de caché según estén definidas en un archivo de Varnish.

* Editamos el fichero de configuracion de varnish, suponiendo que tenemos ya configurado nginx para que escuche por el puerto 8080 tendrá el siguiente aspecto.

```sh
sudo nano /etc/varnish/default.vcl
```

```sh
backend default {
    .host = "127.0.0.1";
    .port = "8080";
}
```

* Con el siguiente comando podemos ver la estadística de uso de varnish

```sh
varnishstat
```

![varnishstat.png](/images/rendimiento/varnishstat.png)


### 2.5.Comprobación de la configuracion de Varnish y Nginx

Como podemos ver tenemos a varnish escuchando en el puerto 80 y a nginx en el puerto 8080

```sh
debian@ansible:~$ sudo netstat -putan
Active Internet connections (servers and established)
Proto Recv-Q Send-Q Local Address           Foreign Address         State       PID/Program name    
tcp        0      0 0.0.0.0:80              0.0.0.0:*               LISTEN      23552/varnishd      
tcp        0      0 0.0.0.0:8080            0.0.0.0:*               LISTEN      21218/nginx: master 
tcp        0      0 0.0.0.0:22              0.0.0.0:*               LISTEN      560/sshd            
tcp        0      0 127.0.0.1:6082          0.0.0.0:*               LISTEN      23552/varnishd      
tcp        0      0 0.0.0.0:3306            0.0.0.0:*               LISTEN      20409/mysqld        
tcp        0    524 10.0.0.8:22             172.23.0.82:49430       ESTABLISHED 22493/sshd: debian  
tcp6       0      0 :::80                   :::*                    LISTEN      23552/varnishd      
tcp6       0      0 :::8080                 :::*                    LISTEN      21218/nginx: master 
tcp6       0      0 :::22                   :::*                    LISTEN      560/sshd            
udp        0      0 10.0.0.8:123            0.0.0.0:*                           532/ntpd            
udp        0      0 127.0.0.1:123           0.0.0.0:*                           532/ntpd            
udp        0      0 0.0.0.0:123             0.0.0.0:*                           532/ntpd            
udp        0      0 0.0.0.0:68              0.0.0.0:*                           403/dhclient        
udp        0      0 0.0.0.0:68              0.0.0.0:*                           318/dhclient        
udp6       0      0 fe80::f816:3eff:fe5:123 :::*                                532/ntpd            
udp6       0      0 ::1:123                 :::*                                532/ntpd            
udp6       0      0 :::123                  :::*                                532/ntpd    
```

## 3. Pruebas de rendimiento con Varnish ya configurado

Como podemos ver responde más peticiones por segundo con varnish ya configurado.

```sh
# Nivel de concurrencia = 50
ab -t 10 -c 50 -k http://172.22.200.152/wordpress/index.php
# Respuestas por segundo 
Requests per second:    425.86 [#/sec] (mean)

# Nivel de concurrencia = 100
ab -t 10 -c 100 -k http://172.22.200.152/wordpress/index.php
# Respuestas por segundo 
Requests per second:    928.78 [#/sec] (mean)

# Nivel de concurrencia = 250
ab -t 10 -c 250 -k http://172.22.200.152/wordpress/index.php
# Respuestas por segundo 
Requests per second:    2212.44 [#/sec] (mean)

# Nivel de concurrencia = 500
ab -t 10 -c 500 -k http://172.22.200.152/wordpress/index.php
# Respuestas por segundo 
Requests per second:    3167.86 [#/sec] (mean)
```

* Si hacemos varias peticiones a la misma url podemos ver cuantas peticiones llegan al servidor web. Con un wc y filtrando con grep podríamos contar cuantas peticiones se han hecho a la url en concreto.

```sh
172.23.0.82 - - [17/Feb/2021:09:15:43 +0000] "GET http://172.22.200.152/wordpress/index.php HTTP/1.0" 301 0 "-" "ApacheBench/2.3"
172.23.0.82 - - [17/Feb/2021:09:15:43 +0000] "GET http://172.22.200.152/wordpress/index.php HTTP/1.0" 301 0 "-" "ApacheBench/2.3"
172.23.0.82 - - [17/Feb/2021:09:15:43 +0000] "GET http://172.22.200.152/wordpress/index.php HTTP/1.0" 301 0 "-" "ApacheBench/2.3"
172.23.0.82 - - [17/Feb/2021:09:15:44 +0000] "GET http://172.22.200.152/wordpress/index.php HTTP/1.0" 301 0 "-" "ApacheBench/2.3"
172.23.0.82 - - [17/Feb/2021:09:15:44 +0000] "GET http://172.22.200.152/wordpress/index.php HTTP/1.0" 301 0 "-" "ApacheBench/2.3"
172.23.0.82 - - [17/Feb/2021:09:15:44 +0000] "GET http://172.22.200.152/wordpress/index.php HTTP/1.0" 301 0 "-" "ApacheBench/2.3"
172.23.0.82 - - [17/Feb/2021:09:15:44 +0000] "GET http://172.22.200.152/wordpress/index.php HTTP/1.0" 301 0 "-" "ApacheBench/2.3"
172.23.0.82 - - [17/Feb/2021:09:15:44 +0000] "GET http://172.22.200.152/wordpress/index.php HTTP/1.0" 301 0 "-" "ApacheBench/2.3"
172.23.0.82 - - [17/Feb/2021:09:15:44 +0000] "GET http://172.22.200.152/wordpress/index.php HTTP/1.0" 301 0 "-" "ApacheBench/2.3"
172.23.0.82 - - [17/Feb/2021:09:15:44 +0000] "GET http://172.22.200.152/wordpress/index.php HTTP/1.0" 301 0 "-" "ApacheBench/2.3"
172.23.0.82 - - [17/Feb/2021:09:15:44 +0000] "GET http://172.22.200.152/wordpress/index.php HTTP/1.0" 301 0 "-" "ApacheBench/2.3"
172.23.0.82 - - [17/Feb/2021:09:15:44 +0000] "GET http://172.22.200.152/wordpress/index.php HTTP/1.0" 301 0 "-" "ApacheBench/2.3"

```