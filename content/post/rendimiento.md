---
title: "Gestión de peticiones y rendimiento de servidores Web"
date: 2021-02-16T17:15:21+01:00
draft: false
toc: false
images:
tags: ['varnish','rendimiento', 'apache', 'nginx']
---

![vs.jpg](/images/rendimiento/vs.jpg)

Los servidores web pueden ser configurados para manejar peticiones de diferente forma. En esta entrada vamos a hablar de los **MPM** (Módulos de multiprocesamiento) que nos permiten configurar el servidor web para gestionar las peticiones que llegan al servidor.

Se pueden hacer distintas configuraciones en los servidores web para que sirvan páginas PHP y Pyhton. Comprobaremos el **rendimiento** de las mismas dependiendo de la configuración adoptada. Se mencionarán distintas aplicaciones para mejorar este rendimiento (aceleradores PHP, varnish ...)

## Módulos de multiprocesamiento (MPMs)

Los **MPMs**son formas de procesar las peticiones que un servidor web como por ejemplo, Apache, puede usar y normalmente suele elegirse la más ventajosa teniendo en cuenta el sistema operativo donde esté funcionando y dependiendo también de qué aplicaciones web vayan a ejecutarse.

Estos módulos son los que se encargan básicamente de las funciones internas del servidor, como puede ser procesar las peticiones HTTP, administrar procesos o hilos de Apache. 

Podemos tener varios módulos MPM instalados pero solamente uno cargado y funcionando.

**Multiprocesos de Apache**

* Multiproceso del tipo **Prefork** (mpm-prefork)

    * Apache inicia varios subprocesos y cada petición es atendida por uno de estos; Cuando termina con la petición podría atender a otro cliente o ser terminado (MaxRequestPerChild). 

    * Este tipo es el más estable ya que un error crítico solo afectaría a una petición. 

    * Requiere más recursos (RAM y CPU) para atender cierto número de peticiones simultáneas, respecto a otras configuraciones.

    * Favorece el uso de PHP.

    * Prefork es la configuración estándar para la mayoría de las instalaciones de apache.

* Multiproceso tipo **Worker** (mpm-worker)

    * Apache inicia varios subprocesos y estos mantienen varios hilos (threads) con los cuales procesan las peticiones. De forma que un subproceso puede atender varios clientes. (ThreadsPerChild).
    * El hecho de que un subproceso pueda manejar varias peticiones supone utilizar menos recursos.
    * Inconveniente: Módulos/extensiones son Thread-Safe.Un fallo crítico afecta a varias peticiones.Es decir, MPM Worker al usar threads sólo soporta módulos de Apache que sean thread-safe, por lo que el famoso mod_php no puede ser usado con Apache MPM Worker.
    * No se puede usar aceleradores PHP junto a Worker.
    * Es ideal para servir contenido estático.
    * Solo disponible en Apache2.x
    * No es compatible con mod_php, pero existe una alternativa que es php-fpm, que nos ofrece un mejor uso de recursos y mayor eficiencia, aunque la configuración es algo más compleja.
  
**¿Qué es mejor Prefork o Worker?**

Segun el punto de vista desde el rendimiento, Prefork está pensado más para servir contenido dinámico y Worker para contenido estático. 

El servidor con Worker puede manejar más peticiones que el Prefork y no consume tantos recursos. Prefork utiliza mucha más CPU. 

Dependiendo el tipo de contenido que vayamos a servir elegiría uno u otro.

* Multiproceso tipo **Event** (mpm-event)

    * Ya es estable
    * Es una mejora de MPM worker y soluciona el problema de optimización de Worker con la opciñon Keep Alive de Apache.
    * Está basado en MPM Worker y tiene las mismas ventajas e incovenientes y tampoco es compatible con mod_php.

* Multiprocesamiento tipo **ITK** (mpm-itk)
    * Es nuevo y experimental, muy parecido a Prefork, utiliza subprocesos y no hilos (threads).
    * Permite asignar a cada virtualhost servido un usuario del sistema, así en un servidor compartido que aloja varios sitios web, los usuarios no pueden interactuar con los archivos del resto.
  
**Factores a tener en cuenta para elegir MPM**

* Volumen de visitas y tráfico de nuestro servidor. Si el tráfico es elevado descartaríamos Prefork, aunque podríamos acompañarlo con un sistema de cache 'Varnish Cache' para aumentar el volumen de visitas soportadas.
* Servir contenido estático o dinámico: Como hemos dicho anteriormente si queremos servir contenido estático está claro que es mejor usar Worker o Event, si queremos servir contenido dinámico, tendriamos que tener en cuenta el consumo de recursos y optar por Prefork.
* Recursos del servidor.
* Necesidades específicas. Si queremos desplegar una aplicación que en concreto necesite un MPM pues no hay más que pensar.

## Gestión de peticiones

Una vez visto los tipos de MPM que puede usar Apache, vamos a ir a una máquina virtual donde tenemos alojado un servidor web Apache. Por defecto Apache se configura con el módulo MPM Event, lo vemos de la siguiente forma

```sh
apachectl -V | egrep 'MPM'
```

Como podemos comprobar nos muestra que estamos usando el MPM de tipo event. 

```sh
root@servidor:/home/vagrant# apachectl -V | egrep 'MPM'
Server MPM:     event
```

Si quisieramos cambiarlo tendríamos que desactivar el actual y activar el nuevo que vayamos a usar 

```sh
a2dismod mpm_event
a2enmod mpm_prefork
service apache2 restart

apachectl -V | egrep 'MPM

# Salida:

Server MPM:     prefork

```

## El comando ab

La utilidad ab (Apache Benchmark) sirve para hacer pruebas de carga a un servidor apache, viene con el paquete apache2-utils.

Por ejemplo vamos a hacer peticiones al servidor web que tenemos en la maquina virtual

```sh
ab -t 10 -c 20 -k http://192.168.100.128/index.html
```
-t (Segundos que dure la prueba)
-c (Nivel de concurrencia: peticiones.)
-k (Conexión persistente: No hace conexion tcp/ip en cada petición)

```sh
celiagm@debian:~/Documentos/asir2/vagrant/virtualhosting$ ab -t 10 -c 20 -k http://192.168.100.128/index.html
This is ApacheBench, Version 2.3 <$Revision: 1843412 $>
Copyright 1996 Adam Twiss, Zeus Technology Ltd, http://www.zeustech.net/
Licensed to The Apache Software Foundation, http://www.apache.org/

Benchmarking 192.168.100.128 (be patient)
Completed 5000 requests
Completed 10000 requests
Completed 15000 requests
Completed 20000 requests
Completed 25000 requests
Completed 30000 requests
Completed 35000 requests
Completed 40000 requests
Completed 45000 requests
Completed 50000 requests
Finished 50000 requests


Server Software:        Apache/2.4.38
Server Hostname:        192.168.100.128
Server Port:            80

Document Path:          /index.html
Document Length:        10701 bytes

Concurrency Level:      20
Time taken for tests:   3.707 seconds
Complete requests:      50000
Failed requests:        0
Keep-Alive requests:    49515
Total transferred:      550528672 bytes
HTML transferred:       535050000 bytes
Requests per second:    13486.90 [#/sec] (mean)
Time per request:       1.483 [ms] (mean)
Time per request:       0.074 [ms] (mean, across all concurrent requests)
Transfer rate:          145018.04 [Kbytes/sec] received

Connection Times (ms)
              min  mean[+/-sd] median   max
Connect:        0    0   0.0      0       1
Processing:     0    1   1.7      1      35
Waiting:        0    1   1.6      1      35
Total:          0    1   1.7      1      35

Percentage of the requests served within a certain time (ms)
  50%      1
  66%      1
  75%      2
  80%      2
  90%      3
  95%      4
  98%      7
  99%      9
 100%     35 (longest request)

```

Comprobamos que las peticiones por segundo que ha analizado son:

```sh
. . .
Requests per second:    13486.90 [#/sec] (mean)
. . . 
```

## Pruebas de rendimiento

Si hicieramos distintas pruebas a día de hoy, tanto con **apache2** como con **nginx** llegamos a la conclusión que nginx obtiene mejores resultados usando php-fpm

![php1.png](/images/rendimiento/php1.png)


Si instalamos apache2 con el módulo de PHP se desactiva MPM event y se activa el prefork y el rendimiento es más lento.

Para solucionar este problema de rendimiento vamos a desactivar el módulo prefork y activar el mpm-event.

```sh
a2dismod mpm_prefork
a2enmod mpm_event
systemctl restart apache2
```

## Aumento del rendimiento en servidores web

Hemos visto que Nginx con php-fpm tiene mejores resultados, aun así podemos mejorar el rendimiento de este. Podemos usar los siguientes servicios:

* Memcached: Este servicio guarda en memoria contenido en la caché u objetos en memoria RAM a través de un plugin utilizando un puerto.

* Varnish: Es un acelerador de HTTP que funciona como **proxy inverso**. Se situa delante del servidor web, cacheando la respuesta del servidor web en memoria. De forma que cuando un cliente demanda la url por segunda vez, Varnish le da la respuesta ahorrando recursos en el backend y permitiendo más conexiones simultáneas.

Para ver el aumento de rendimiento con Varnish accede a este [post](https://unbitdeinformacioncadadia.netlify.app/posts/2021/02/aumento-del-rendimiento-de-nginx-con-varnish/)

Fuentes:

https://fp.josedomingo.org/serviciosgs/u05/

https://blog.ichasco.com/nginx-mejorar-el-rendimiento-con-la-cache/

