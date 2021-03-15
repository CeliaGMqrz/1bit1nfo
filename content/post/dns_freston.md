---
title: "Configurar un DNS con bind9"
date: 2021-01-12T19:49:10+01:00
draft: false
toc: false
tags: ['dns','bind9']
---

### Objetivo:

Vamos  a instalar un servidor dns en freston que nos permita gestionar la resolución directa e inversa de nuestros nombres. Cada alumno va a poseer un servidor dns con autoridad sobre un subdominio de nuestro dominio principal **gonzalonazareno.org**, que se llamará **tu_nombre.gonzalonazareno.org**. A partir de este momento no será necesario la resolución estática en los servidores.

* Determina la regla DNAT en dulcinea para que podamos hacer consultas DNS desde el exterior

* Configura de forma adecuada todas las máquinas para que usen como servidor DNS a freston

* Indica al profesor el nombre de tu dominio para que pueda realizar la delegación en el servidor DNS principal papion-dns.

Comprueba que los servidores tienen configurados el nuevo nombre de dominio de forma adecuada después de volver a reiniciar el servidor (o tomar una nueva configuración DHCP). Para que el servidor tenga el FQDN debes tener configurado de forma correcta el parámetro domain y el parámetro search en el fichero /etc/resolv.conf, además debemos evitar que este fichero se sobreescriba con los datos que manda el servidor DHCP de OpenStack. Quizás sea buena idea mirar la configuración de cloud-init. Documenta la configuración que has tenido que modificar y muestra el contenido del fichero /etc/resolv.conf y la salida del comando hostname -f después de un reinicio.

### Instalación de bind9 y su configuración

* El servidor DNS se llama freston.celia.gonzalonazareno.org y va a ser el servidor con autoridad para la zona celia.gonzalonazareno.org.

* El servidor debe resolver el nombre de todas las máquinas.

* El servidor debe resolver los distintos servicios (virtualhosh, servidor de base de datos, servido ldap, ...).

* Debes determinar cómo vas a nombrar a dulcinea, para que seamos capaz de resolver la ip flotante y la ip fija. Para ello vamos a usar vistas en bind9.

* Debes considerar la posibilidad de hacer tres zonas de resolución inversa: para las redes 10.0.0.0/24, 10.0.1.0/24 y 10.0.2.0/24. (No vamos a crear la zona inversa para la red externa de ip flotantes). para resolver ip fijas y flotantes del cloud.
______________________________________________________________________________

## 1. Instalación del servicio bind9

* Primero vamos a instalar el servicio bind9 en Freston

```sh
sudo apt-get install bind9
```

## 2. Configuración de bind9

El servidor DNS se va a configurar en un principio de la siguiente manera:

* El servidor DNS se llama freston.celia.gonzalonazareno.org y va a ser el servidor con autoridad para la zona celia.gonzalonazareno.org.

Para ello vamos a editar el fichero **/etc/hosts** del servidor Freston

Actualmente lo tenemos así para que resuelva nombres de forma estática

```sh
127.0.1.1 freston.celia.gonzalonazareno.org freston
127.0.0.1 localhost
10.0.1.6 dulcinea.celia.gonzalonazareno.org dulcinea
10.0.1.11 sancho.celia.gonzalonazareno.org sancho
10.0.2.4 quijote.celia.gonzalonazareno.org quijote
```
Ahora vamos a dejar solo nuestro nombre ya que bind se encargará de la resolucion de nombres una vez esté configurado.

```sh
127.0.1.1 freston.celia.gonzalonazareno.org freston
127.0.0.1 localhost
```



* En el fichero de configuración **/etc/bind/named.conf** Comentamos la línea en la que están definidas las zonas por defecto, ya que vamos a definirlas nosotros.

### `/etc/bind/named.conf`

```sh

// This is the primary configuration file for the BIND DNS server named.
//
// Please read /usr/share/doc/bind9/README.Debian.gz for information on the
// structure of BIND configuration files in Debian, *BEFORE* you customize
// this configuration file.
//
// If you are just adding zones, please do that in /etc/bind/named.conf.local

include "/etc/bind/named.conf.options";
include "/etc/bind/named.conf.local";
//include "/etc/bind/named.conf.default-zones";
```

* Ahora vamos a editar el fichero **/etc/bind/named.conf.options**

En este fichero se definen las opciones que le vamos a dar a nuestro servicio, de tal forma que permitiremos que las peticiones de todos los clientes puedan ser recursivas. Tambien permitiremos las consultas desde el exterior, la red interna, la red DMZ y la del DNS del centro. Además permitiremos guardar las consultas en caché para una obtención más rápida de las mismas.
### `/etc/bind/named.conf.options`
```sh
allow-recursion { any; };
allow-query { 10.0.1.0/24; 10.0.2.0/24; 192.168.202.2; 172.22.0.0/15; };
allow-query-cache { any; };
```

## 2.1.Configurar las vistas

Necesitaremos vistas. Las necesitamos para tener zonas diferenciadas según de donde venga la consulta. Para ello tenemos que editar el fichero **/etc/bind/named.conf.local**

### `/etc/bind/named.conf.local`
* Vista para la red interna:

```sh
view interna {
        match-clients {10.0.1.0/24;};
        allow-recursion { any; };

        zone "celia.gonzalonazareno.org"
        {
                type master;
                file "/var/cache/bind/db.int.celia.gonzalonazareno.org";
        };

        zone "1.0.10.in-addr.arpa"
        {
                type master;
                file "/var/cache/bind/db.1.0.10";
        };

        zone "2.0.10.in-addr.arpa"
        {
                type master;
                file "/var/cache/bind/db.2.0.10";
        };

        include "/etc/bind/zones.rfc1918";
        include "/etc/bind/named.conf.default-zones";
};
```

* Vista para la red externa

```sh
view externa {
        match-clients { 172.22.0.0/15; 192.168.202.2;};
        allow-recursion { any; };

        zone "celia.gonzalonazareno.org"
        {
                type master;
                file "/var/cache/bind/db.ext.celia.gonzalonazareno.org";
        };

        include "/etc/bind/zones.rfc1918";
        include "/etc/bind/named.conf.default-zones";
};
```

* Vista para la red DMZ

```sh
view dmz {
        match-clients {10.0.2.0/24;};
        allow-recursion { any; };

        zone "celia.gonzalonazareno.org"
        {
                type master;
                file "/var/cache/bind/db.dmz.celia.gonzalonazareno.org";
        };

        zone "1.0.10.in-addr.arpa"
        {
                type master;
                file "/var/cache/bind/db.1.0.10";
        };

        zone "2.0.10.in-addr.arpa"
        {
                type master;
                file "/var/cache/bind/db.2.0.10";
        };

        include "/etc/bind/zones.rfc1918";
        include "/etc/bind/named.conf.default-zones";
};
```

* Vamos a crear las zonas una vez tenemos listas las vistas, para ello copiamos el fichero 'vacio' y creamos los ficheros nuevos para cada zona.

## 2.2. Crear zonas


### **Zona para la red interna**

```sh
sudo cp /etc/bind/db.empty /var/cache/bind/db.int.celia.gonzalonazareno.org

```
Editamos el fichero de tal forma

```sh
sudo nano /var/cache/bind/db.int.celia.gonzalonazareno.org
```

### `/etc/bind/db.int.celia.gonzalonazareno.org `

```sh
; BIND reverse data file for empty rfc1918 zone
;
; DO NOT EDIT THIS FILE - it is used for multiple zones.
; Instead, copy it, edit named.conf, and use that copy.
;
$TTL    86400
@       IN      SOA     freston.celia.gonzalonazareno.org. root.localhost. (
                              1         ; Serial
                         604800         ; Refresh
                          86400         ; Retry
                        2419200         ; Expire
                          86400 )       ; Negative Cache TTL
;
@       IN      NS      freston.celia.gonzalonazareno.org.
$ORIGIN celia.gonzalonazareno.org.
freston  IN     A       10.0.1.2
dulcinea IN     A       10.0.1.6
sancho   IN     A       10.0.1.11
quijote  IN     A       10.0.2.4
www      IN     CNAME   quijote
bd       IN     CNAME   sancho
```

### **Zona inversa para la red interna**

Podemos usar como plantilla /etc/bind/db.127

```sh
sudo nano /etc/bind/db.1.0.10
```
### `/etc/bind/db.1.0.10 `
```sh
;
; BIND reverse data file for local loopback interface
;
$TTL    604800
@       IN      SOA     freston.celia.gonzalonazareno.org. root.localhost. (
                              1         ; Serial
                         604800         ; Refresh
                          86400         ; Retry
                        2419200         ; Expire
                         604800 )       ; Negative Cache TTL
;
@       IN      NS      freston.celia.gonzalonazareno.org.
$ORIGIN 1.0.10.in-addr.arpa.
2   IN      PTR     freston.celia.gonzalonazareno.org.
6   IN      PTR     dulcinea.celia.gonzalonazareno.org.
11  IN      PTR     sancho.celia.gonzalonazareno.org.

```
### **Zona para la red DMZ**

```sh
sudo cp db.int.celia.gonzalonazareno.org db.dmz.celia.gonzalonazareno.org
sudo nano db.dmz.celia.gonzalonazareno.org
```

### `/etc/bind/db.dmz.celia.gonzalonazareno.org `
```sh
; BIND reverse data file for empty rfc1918 zone
;
; DO NOT EDIT THIS FILE - it is used for multiple zones.
; Instead, copy it, edit named.conf, and use that copy.
;
$TTL    86400
@       IN      SOA     freston.celia.gonzalonazareno.org. root.localhost. (
                              1         ; Serial
                         604800         ; Refresh
                          86400         ; Retry
                        2419200         ; Expire
                          86400 )       ; Negative Cache TTL
;
@       IN      NS      freston.celia.gonzalonazareno.org.
$ORIGIN celia.gonzalonazareno.org.
freston  IN     A       10.0.1.2
dulcinea IN     A       10.0.1.6
sancho   IN     A       10.0.1.11
quijote  IN     A       10.0.2.4
www      IN     CNAME   quijote
bd       IN     CNAME   sancho
```
### **Zona inversa para la red DMZ**

### `/etc/bind/db.2.0.10  `
```sh
;
; BIND reverse data file for local loopback interface
;
$TTL    604800
@       IN      SOA     freston.celia.gonzalonazareno.org. root.localhost. (
                              1         ; Serial
                         604800         ; Refresh
                          86400         ; Retry
                        2419200         ; Expire
                         604800 )       ; Negative Cache TTL
;
@       IN      NS      freston.celia.gonzalonazareno.org.
$ORIGIN 2.0.10.in-addr.arpa.
4   IN      PTR     quijote.celia.gonzalonazareno.org.
```

### **Zona externa**

### `/etc/bind/db.ext.celia.gonzalonazareno.org`

```sh
; BIND reverse data file for empty rfc1918 zone
;
; DO NOT EDIT THIS FILE - it is used for multiple zones.
; Instead, copy it, edit named.conf, and use that copy.
;
$TTL    86400
@       IN      SOA     dulcinea.celia.gonzalonazareno.org. root.localhost. (
                              1         ; Serial
                         604800         ; Refresh
                          86400         ; Retry
                        2419200         ; Expire
                          86400 )       ; Negative Cache TTL
;
@       IN      NS      dulcinea.celia.gonzalonazareno.org.
$ORIGIN celia.gonzalonazareno.org.
dulcinea IN     A       172.22.200.222
www      IN     CNAME   dulcinea

```

> No necesitamos zona inversa para la red externa.

**IMPORTANTE!!**

Editar el fichero **/etc/hosts** de cada máquina e indicar el servidor de dns

```sh
nameserver 10.0.1.2
search celia.gonzalonazareno.org
```

## 3. Regla DNAT en Dulcinea

Una regla DNAT cambia la dirección destino de un paquete. Funciona comom el Port de Forwarding.

Le vamos a decir que añada una regla dnat, indicando que el tráfico que venga por el puerto 53 y la interfaz eth0 lo redirija a la interfaz de freston (10.0.1.2) al puerto 53, cambiado la dirección destino de ese tráfico para que se puedan realizar las consultas desde fuera al dns que tenemos en el interior.

```sh
sudo iptables -t nat -A PREROUTING -p udp --dport 53 -i eth0 -j DNAT --to 10.0.1.2:53
```

Comprobamos que la regla se ha añadido correctamente

```sh
debian@dulcinea:~$ sudo iptables -t nat -L -nv
Chain PREROUTING (policy ACCEPT 0 packets, 0 bytes)
 pkts bytes target     prot opt in     out     source               destination
   21  2122 DNAT       udp  --  eth0   *       0.0.0.0/0            0.0.0.0/0            udp dpt:53 to:10.0.1.2:53

Chain INPUT (policy ACCEPT 0 packets, 0 bytes)
 pkts bytes target     prot opt in     out     source               destination

Chain POSTROUTING (policy ACCEPT 0 packets, 0 bytes)
 pkts bytes target     prot opt in     out     source               destination
 1466  112K MASQUERADE  all  --  *      eth0    10.0.1.0/24          0.0.0.0/0
  428 30576 MASQUERADE  all  --  *      eth0    10.0.2.0/24          0.0.0.0/0

Chain OUTPUT (policy ACCEPT 0 packets, 0 bytes)
 pkts bytes target     prot opt in     out     source               destination
```

## 4. CONSULTAS

Entrega el resultado de las siguientes consultas desde un cliente interno a nuestra red y otro externo:

* El servidor DNS con autoridad sobre la zona del dominio tu_nombre.gonzalonazareno.org

#### Cliente interno:

```sh
debian@dulcinea:~$ dig ns celia.gonzalonazareno.org

; <<>> DiG 9.11.5-P4-5.1+deb10u2-Debian <<>> ns celia.gonzalonazareno.org
;; global options: +cmd
;; Got answer:
;; ->>HEADER<<- opcode: QUERY, status: NOERROR, id: 64888
;; flags: qr aa rd ra; QUERY: 1, ANSWER: 1, AUTHORITY: 0, ADDITIONAL: 2

;; OPT PSEUDOSECTION:
; EDNS: version: 0, flags:; udp: 4096
; COOKIE: 8559e5d7dd18224732b6c17b5ffb621ecaa6ca73d21b38c5 (good)
;; QUESTION SECTION:
;celia.gonzalonazareno.org.	IN	NS

;; ANSWER SECTION:
celia.gonzalonazareno.org. 86400 IN	NS	freston.celia.gonzalonazareno.org.

;; ADDITIONAL SECTION:
freston.celia.gonzalonazareno.org. 86400 IN A	10.0.1.2

;; Query time: 1 msec
;; SERVER: 10.0.1.2#53(10.0.1.2)
;; WHEN: Sun Jan 10 21:22:54 CET 2021
;; MSG SIZE  rcvd: 120

```

#### Cliente externo:

```sh
celiagm@debian:~$ dig @172.22.200.222 ns celia.gonzalonazareno.org

; <<>> DiG 9.11.5-P4-5.1+deb10u2-Debian <<>> @172.22.200.222 ns celia.gonzalonazareno.org
; (1 server found)
;; global options: +cmd
;; Got answer:
;; ->>HEADER<<- opcode: QUERY, status: NOERROR, id: 62993
;; flags: qr aa rd ra; QUERY: 1, ANSWER: 1, AUTHORITY: 0, ADDITIONAL: 2

;; OPT PSEUDOSECTION:
; EDNS: version: 0, flags:; udp: 4096
; COOKIE: 6826810ba15b1058052ad0ad5ffdbe8b28a1029fabee5c20 (good)
;; QUESTION SECTION:
;celia.gonzalonazareno.org.	IN	NS

;; ANSWER SECTION:
celia.gonzalonazareno.org. 86400 IN	NS	dulcinea.celia.gonzalonazareno.org.

;; ADDITIONAL SECTION:
dulcinea.celia.gonzalonazareno.org. 86400 IN A	172.22.200.222

;; Query time: 88 msec
;; SERVER: 172.22.200.222#53(172.22.200.222)
;; WHEN: mar ene 12 16:21:47 CET 2021
;; MSG SIZE  rcvd: 121

```
* La dirección IP de dulcinea.

#### Cliente interno:

Desde el cliente interno obtenemos la dirección ip de dulcinea correspondiente a la red desde la que preguntamos internamente.

```sh
root@sancho:/home/ubuntu# dig dulcinea.celia.gonzalonazareno.org

; <<>> DiG 9.16.1-Ubuntu <<>> dulcinea.celia.gonzalonazareno.org
;; global options: +cmd
;; Got answer:
;; ->>HEADER<<- opcode: QUERY, status: NOERROR, id: 29638
;; flags: qr aa rd ra; QUERY: 1, ANSWER: 1, AUTHORITY: 1, ADDITIONAL: 2

;; OPT PSEUDOSECTION:
; EDNS: version: 0, flags:; udp: 4096
; COOKIE: 65c55cf8c6f45eea90576a2b5ffcae73f7cb8e54aa7baac7 (good)
;; QUESTION SECTION:
;dulcinea.celia.gonzalonazareno.org. IN	A

;; ANSWER SECTION:
dulcinea.celia.gonzalonazareno.org. 86400 IN A	10.0.1.6

;; AUTHORITY SECTION:
celia.gonzalonazareno.org. 86400 IN	NS	freston.celia.gonzalonazareno.org.

;; ADDITIONAL SECTION:
freston.celia.gonzalonazareno.org. 86400 IN A	10.0.1.2

;; Query time: 0 msec
;; SERVER: 10.0.1.2#53(10.0.1.2)
;; WHEN: Mon Jan 11 21:00:51 CET 2021
;; MSG SIZE  rcvd: 145

```

#### Cliente externo:

Como podemos comprobar nos da la ip flotante de dulcinea ya que estamos preguntando desde un cliente externo.

```sh
celiagm@debian:~$ dig @172.22.200.222 dulcinea.celia.gonzalonazareno.org

; <<>> DiG 9.11.5-P4-5.1+deb10u2-Debian <<>> @172.22.200.222 dulcinea.celia.gonzalonazareno.org
; (1 server found)
;; global options: +cmd
;; Got answer:
;; ->>HEADER<<- opcode: QUERY, status: NOERROR, id: 63671
;; flags: qr aa rd ra; QUERY: 1, ANSWER: 1, AUTHORITY: 1, ADDITIONAL: 1

;; OPT PSEUDOSECTION:
; EDNS: version: 0, flags:; udp: 4096
; COOKIE: 92d96ff1c492f1fef7751e095ffdbf629b7f9f966a88d817 (good)
;; QUESTION SECTION:
;dulcinea.celia.gonzalonazareno.org. IN	A

;; ANSWER SECTION:
dulcinea.celia.gonzalonazareno.org. 86400 IN A	172.22.200.222

;; AUTHORITY SECTION:
celia.gonzalonazareno.org. 86400 IN	NS	dulcinea.celia.gonzalonazareno.org.

;; Query time: 85 msec
;; SERVER: 172.22.200.222#53(172.22.200.222)
;; WHEN: mar ene 12 16:25:22 CET 2021
;; MSG SIZE  rcvd: 121

```


* Una resolución de www.

#### Cliente interno:

```sh
debian@dulcinea:~$ dig www.celia.gonzalonazareno.org

; <<>> DiG 9.11.5-P4-5.1+deb10u2-Debian <<>> www.celia.gonzalonazareno.org
;; global options: +cmd
;; Got answer:
;; ->>HEADER<<- opcode: QUERY, status: NOERROR, id: 37621
;; flags: qr aa rd ra; QUERY: 1, ANSWER: 2, AUTHORITY: 1, ADDITIONAL: 2

;; OPT PSEUDOSECTION:
; EDNS: version: 0, flags:; udp: 4096
; COOKIE: aca3b042c7b7a507cb9e72615ffb628e2669239b2b833cb7 (good)
;; QUESTION SECTION:
;www.celia.gonzalonazareno.org.	IN	A

;; ANSWER SECTION:
www.celia.gonzalonazareno.org. 86400 IN	CNAME	quijote.celia.gonzalonazareno.org.
quijote.celia.gonzalonazareno.org. 86400 IN A	10.0.2.4

;; AUTHORITY SECTION:
celia.gonzalonazareno.org. 86400 IN	NS	freston.celia.gonzalonazareno.org.

;; ADDITIONAL SECTION:
freston.celia.gonzalonazareno.org. 86400 IN A	10.0.1.2

;; Query time: 1 msec
;; SERVER: 10.0.1.2#53(10.0.1.2)
;; WHEN: Sun Jan 10 21:24:46 CET 2021
;; MSG SIZE  rcvd: 162

```

#### Cliente externo:

Igualmente desde el cliente externo la respuesta es dulcinea con su ip flotante.

```sh
celiagm@debian:~$ dig @172.22.200.222 www.celia.gonzalonazareno.org

; <<>> DiG 9.11.5-P4-5.1+deb10u2-Debian <<>> @172.22.200.222 www.celia.gonzalonazareno.org
; (1 server found)
;; global options: +cmd
;; Got answer:
;; ->>HEADER<<- opcode: QUERY, status: NOERROR, id: 40115
;; flags: qr aa rd ra; QUERY: 1, ANSWER: 2, AUTHORITY: 1, ADDITIONAL: 1

;; OPT PSEUDOSECTION:
; EDNS: version: 0, flags:; udp: 4096
; COOKIE: 7039cbb23f22926f7f93def35ffdbedc6e6ccff4f6b729a5 (good)
;; QUESTION SECTION:
;www.celia.gonzalonazareno.org.	IN	A

;; ANSWER SECTION:
www.celia.gonzalonazareno.org. 86400 IN	CNAME	dulcinea.celia.gonzalonazareno.org.
dulcinea.celia.gonzalonazareno.org. 86400 IN A	172.22.200.222

;; AUTHORITY SECTION:
celia.gonzalonazareno.org. 86400 IN	NS	dulcinea.celia.gonzalonazareno.org.

;; Query time: 87 msec
;; SERVER: 172.22.200.222#53(172.22.200.222)
;; WHEN: mar ene 12 16:23:08 CET 2021
;; MSG SIZE  rcvd: 139

```

* Un resolución inversa de IP fija en cada una de las redes. (Esta consulta sólo funcionará desde una máquina interna).

#### Red interna: 10.0.1.0:

```sh
ubuntu@sancho:~$ dig -x 10.0.1.6

; <<>> DiG 9.16.1-Ubuntu <<>> -x 10.0.1.6
;; global options: +cmd
;; Got answer:
;; ->>HEADER<<- opcode: QUERY, status: NOERROR, id: 53123
;; flags: qr aa rd ra; QUERY: 1, ANSWER: 1, AUTHORITY: 1, ADDITIONAL: 2

;; OPT PSEUDOSECTION:
; EDNS: version: 0, flags:; udp: 4096
; COOKIE: c2a1b13108b08d9c4de459eb5ffdc107294d3d1779e913a7 (good)
;; QUESTION SECTION:
;6.1.0.10.in-addr.arpa.		IN	PTR

;; ANSWER SECTION:
6.1.0.10.in-addr.arpa.	604800	IN	PTR	dulcinea.celia.gonzalonazareno.org.

;; AUTHORITY SECTION:
1.0.10.in-addr.arpa.	604800	IN	NS	freston.celia.gonzalonazareno.org.

;; ADDITIONAL SECTION:
freston.celia.gonzalonazareno.org. 86400 IN A	10.0.1.2

;; Query time: 0 msec
;; SERVER: 10.0.1.2#53(10.0.1.2)
;; WHEN: Tue Jan 12 16:32:23 CET 2021
;; MSG SIZE  rcvd: 164

```

```sh
debian@dulcinea:~$ dig -x 10.0.1.11

; <<>> DiG 9.11.5-P4-5.1+deb10u2-Debian <<>> -x 10.0.1.11
;; global options: +cmd
;; Got answer:
;; ->>HEADER<<- opcode: QUERY, status: NOERROR, id: 48242
;; flags: qr aa rd ra; QUERY: 1, ANSWER: 1, AUTHORITY: 1, ADDITIONAL: 2

;; OPT PSEUDOSECTION:
; EDNS: version: 0, flags:; udp: 4096
; COOKIE: f2ecd80d6d26eb4e9d7615ed5ffdc3a9dc29eb38e4fdad3d (good)
;; QUESTION SECTION:
;11.1.0.10.in-addr.arpa.		IN	PTR

;; ANSWER SECTION:
11.1.0.10.in-addr.arpa.	604800	IN	PTR	sancho.celia.gonzalonazareno.org.

;; AUTHORITY SECTION:
1.0.10.in-addr.arpa.	604800	IN	NS	freston.celia.gonzalonazareno.org.

;; ADDITIONAL SECTION:
freston.celia.gonzalonazareno.org. 86400 IN A	10.0.1.2

;; Query time: 1 msec
;; SERVER: 10.0.1.2#53(10.0.1.2)
;; WHEN: Tue Jan 12 16:43:37 CET 2021
;; MSG SIZE  rcvd: 163

```

#### Red DMZ: 10.0.2.0:

```sh
debian@dulcinea:~$ dig -x 10.0.2.4

; <<>> DiG 9.11.5-P4-5.1+deb10u2-Debian <<>> -x 10.0.2.4
;; global options: +cmd
;; Got answer:
;; ->>HEADER<<- opcode: QUERY, status: NOERROR, id: 1318
;; flags: qr aa rd ra; QUERY: 1, ANSWER: 1, AUTHORITY: 1, ADDITIONAL: 2

;; OPT PSEUDOSECTION:
; EDNS: version: 0, flags:; udp: 4096
; COOKIE: 80dec2a22e8cbb7a8a45db0f5ffdc352c0f141f3086c692f (good)
;; QUESTION SECTION:
;4.2.0.10.in-addr.arpa.		IN	PTR

;; ANSWER SECTION:
4.2.0.10.in-addr.arpa.	604800	IN	PTR	quijote.celia.gonzalonazareno.org.

;; AUTHORITY SECTION:
2.0.10.in-addr.arpa.	604800	IN	NS	freston.celia.gonzalonazareno.org.

;; ADDITIONAL SECTION:
freston.celia.gonzalonazareno.org. 86400 IN A	10.0.1.2

;; Query time: 1 msec
;; SERVER: 10.0.1.2#53(10.0.1.2)
;; WHEN: Tue Jan 12 16:42:10 CET 2021
;; MSG SIZE  rcvd: 163

```

_______________________________________________________________________________


## Servidor Web

[Configurar un servidor web Apache2 en Centos8](https://unbitdeinformacioncadadia.netlify.app/posts/2021/01/servidor-web-apache2-httpd-en-centos8/)



## Servidor de base de datos

[Configurar Mariadb en Ubuntu](https://unbitdeinformacioncadadia.netlify.app/posts/2021/01/servidor-de-base-de-datos.-mariadb-en-ubuntu/)