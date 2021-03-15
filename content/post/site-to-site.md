---
title: "VPN con OpenVPN y certificados x509 (II)"
date: 2021-02-24T08:27:54+01:00
draft: false
toc: false
images:
tags: ['vpn']
---

Escenario:

Tenemos dos servidores, dos maquinas conectadas a las redes locales diferentes y un cliente. Los servidores están conectados a dos redes la exterior en común y una interna compartida con su respectivo cliente de forma que tenemos el siguiente direccionamiento:


* Servidor 1: vpn_server
  * Red común 172.22.201.64
  * Red 10.0.0.8
  * Red1 192.168.100.2
* Maquina de la red local 1: lan
  * Red1 192.168.100.10

* Servidor 2: vpn_server2
  * Red común 172.22.201.33
  * Red 10.0.0.13
  * Red2 192.168.200.8
* Maquina de la red local 1: lan2
  * Red2 192.168.200.4


Objetivo:

Tras el establecimiento de la VPN, una máquina de cada red detrás de cada servidor VPN debe ser capaz de acceder a una máquina del otro extremo.

Cabe decir que tenemos instalado en las 4 máquinas el paquete openvpn.

Configuración

Servidor 2 (rol de servidor)

`sudo nano /etc/openvpn/servidor.conf `

```sh
# Use a dynamic TUN device
dev tun
# Virtual ip
ifconfig 10.99.99.1 10.99.99.2
# Local subnet
route 192.168.100.0 255.255.255.0
# Enable TLS and assume server role
tls-server
# Diffie-Hellman
dh /etc/openvpn/keys/dh.pem
# Certificado de la CA
ca /etc/openvpn/keys/ca.crt
# Certificado local
cert /etc/openvpn/keys/servidor.crt
# Clave privada 
key /etc/openvpn/keys/servidor.key
# Use fast LZO compression
comp-lzo
# Ping remote every 10sg and restart after 60sg passed without sign of file from remote.
keepalive 10 60
# Set output verbosity to normal usage range
verb 3
log /var/log/office1.log

```

* Vemos que se ha creado el tunel

```sh
13: tun0: <POINTOPOINT,MULTICAST,NOARP,UP,LOWER_UP> mtu 1500 qdisc pfifo_fast state UNKNOWN group default qlen 100
    link/none 
    inet 10.99.99.1 peer 10.99.99.2/32 scope global tun0
       valid_lft forever preferred_lft forever
    inet6 fe80::e63:da50:7b73:26f6/64 scope link stable-privacy 
       valid_lft forever preferred_lft forever
```


* Ahora le pasamos los certificados y claves al cliente de sergio


Servidor 1 (rol de cliente)

```sh
#### Fichero de sit-to-site vpn ####
#Dispositivo de túnel
dev tun

#IP del servidor
remote 172.22.201.33

#Encaminamiento
ifconfig 10.99.99.2 10.99.99.1

# Subred remota
route 192.168.200.0 255.255.255.0

#Rol de cliente
tls-client

#Certificado de la CA
ca /etc/openvpn/ca_celia.crt

#Certificado cliente
cert /etc/openvpn/cliente_celia.crt

#Clave privada cliente
key /etc/openvpn/cliente_celia.key

#Activar la compresión LZO
comp-lzo

#Detectar caídas de la conexión
keepalive 10 60

#Nivel de la información
verb 3

log /var/log/vpn.log

```

Funcionamiento:

Podemos comprobar que tenemos comunicación de extremo a extremo. Del cliente 1 al cliente 2 y a ambos servidores estandos en redes locales distintas.

![vpn1.jpeg](/images/vpn/vpn1.jpeg)

