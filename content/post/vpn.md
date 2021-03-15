---
title: "VPN con OpenVPN y certificados x509"
date: 2021-02-24T08:27:54+01:00
draft: false
toc: false
images:
tags: ['vpn']
---

## Conceptos

**¿Qué es una VPN?**

Se trata de una **Red privada virtual.** Es una tecnología de red de ordenadores que perminte una extensión segura de la red de área local sobre una red pública o no controlada como Internet. Permite que el ordenador en la red envíe y reciba datos sobre redes compartidas o públicas como si fuera una red privada.

El modelo de **VPN de acceso remoto** es el modelo más usado actualmente. Los usuarios se conectan con la empresa desde sitios remotos (oficinas, domicilios..), utilizando internet como vínculo de acceso. Se hace de forma segura ya que son autentificados y además el nivel de acceso es muy similar al que tendrían si estuviesen en la red local de la empresa.

## 1. VPN de Acceso Remoto con OpenVPN y Certificados x509.

![vpn.png](/images/vpn/vpn.png)

**Descripción de la tarea 1 en cuestión:**


Vamos a configurar una conexión **VPN** de acceso remoto entre dos equipos:

* Uno de los equipos (el que actuará como servidor), estará conectado a dos redes.
  
* Para la autenticación de los estremos se usarán obligatoriamente certificados digitales, que se generarán utilizando OpenSSL y se almacenarán en  el directorio /etc/openvpn, junto a los parámetros Diffie-Helman y el certificado de propia Autoridad de certificación.
  
* Se utilizarán direcciones de red 10.99.99.0/24 para las direcciones virtuales de la VPN. La dirección 10.99.99.1 se asignará al servidor VPN.
  
* Los ficheros de configuración del servidor y del cliente se crearán en el directorio /etc/openvpn de cada máquina, y se llamarán servidor.conf y cliente.conf respectivamente. La configuración establecida debe cumplir los siguientes aspectos:
  * El demonio openvpn se manejará con systemctl.
  * Se debe configurar para que la comunicación esté comprimida.
  * La asignación de direcciones IP será dinámica.
  * Existirá un fichero de log en el equipo.
  * Se mandarán a los clientes las rutas necesarias.

* Tras el establecimiento de la VPN, la máquina cliente debe ser capaz de acceder a una máquina que esté en la otra red a la que está conectado el servidor.
  
* Instala el complemento de VPN en networkmanager y configura el cliente de forma gráfica desde este complemento.


## 1.2. Crear el entorno de trabajo

En este caso vamos a usar una receta para ansible. 

Necesitaremos dos equipos, un sevidor y una máquina local. El servidor estará conectado a dos redes. Y otro equipo cliente que usaremos para acceder a la máquina LAN O local.

Utilizaremos la siguiente [receta heat](https://fp.josedomingo.org/seguridadgs/u04/escenario_vpn.yaml) que cargaremos en openstack. Por lo que las ips variarán.


> En openstack cargamos la receta de forma que vamos a 'Orchestration' > Stacks > Launch Stack > Cargamos la url y lo lanzamos.


* **Servidor** tiene las direcciones:

  * **10.0.0.15/24**
  * **192.168.100.2/24**

* **LAN** tiene la direccion **192.168.100.10/24** 


* También usaremos otra máquina en este caso mi maquina 'ansible' para usarla de **cliente**, la cual tiene la direccion **10.0.0.8/24**


* Se utilizarán direcciones de red **10.99.99.0/24** para las direcciones virtuales de la VPN. La dirección **10.99.99.1** se asignará al servidor VPN.

Objetivo:

Desde el cliente vpn (maquina ansible) vamos a crear una conexion vpn al servidor y de esa forma podremos acceder a la máquina LAN.


## 1.3. Instalar OpenVPN en las máquinas cliente y servidor.

```sh
sudo apt-get install openvpn
```

## 1.4. Generación de claves y certificados con EasyRSA.

Podríamos montar una entidad certificadora y crear nuestros certificados autofirmados pero en este caso vamos a usar una herramienta muy útil y eficaz para ello. 

Se trata de Easy RSA. Automatiza la creación de certificados digitale y claves RSA. También nos permite generar módulos Diffie-Hellman, necesarios para ejecutar un Servidor OpenVPN.

Esta herramienta viene ya incluida cuando descargamos openvpn.

Vamos a crear:

* Una clave privada y un certificado x509 para la autoridad certificante que firma (CA)
* Una clave privada y un certificado x509 firmado para el servidor.
* Una clave privada y un certificado x509 firmado para cada cliente.
* Un grupo Diffie-Hellman para el servidor.

> La generación de los certificados requiere que especifiquemos información de propiedad (ORG, CN, País, provincia, email, etc). Una forma de establecer esta información y evitar que nos la pida con cada certificado creado, es copiar el archivo vars.example como vars, y luego editar algunas líneas:


```sh
root@vpn-server:/usr/share/easy-rsa# cp vars.example vars
root@vpn-server:/usr/share/easy-rsa# nano vars
```

```sh
set_var EASYRSA_REQ_COUNTRY     "ES"
set_var EASYRSA_REQ_PROVINCE    "Sevilla"
set_var EASYRSA_REQ_CITY        "Los Palacios"
set_var EASYRSA_REQ_ORG "iesgn"
set_var EASYRSA_REQ_EMAIL       "cgarmai95@gmail.com"
set_var EASYRSA_REQ_OU          "iesgn"

```

### Iniciando el entorno EasyRSA PKI

Iniciaremos el entorno de PKI (Public key infraestructure) de EasyRSA. Es necesario cargarlo en memoria para trabajar.

```sh
root@vpn-server:/usr/share/easy-rsa# ./easyrsa init-pki

Note: using Easy-RSA configuration from: ./vars

init-pki complete; you may now create a CA or requests.
Your newly created PKI dir is: /usr/share/easy-rsa/pki

```
Se ha creado el subdirectorio pki, donde después iremos creando las claves y certificados pertinentes.

## Generación de los parámetros Diffie-Hellman

**Se trata de un protocolo de establecimiento de claves entre partes que no han tenido contacto previo utilizando un canal inseguro y de manera anónima. Se emplea generalmente como medio para acordar claves simétricas que serán empleadas para el cifrado de una sesión.**


Para crearlo ejecutamos el siguiente comando

```sh
root@vpn-server:/usr/share/easy-rsa# ./easyrsa gen-dh

Note: using Easy-RSA configuration from: ./vars

Using SSL: openssl OpenSSL 1.1.1d  10 Sep 2019
Generating DH parameters, 2048 bit long safe prime, generator 2
This is going to take a long time
....
..........................................................................................................................................+...........................................................................................................+...................................................................+............................................................................++*++*++*++*

....

DH parameters of size 2048 created at /usr/share/easy-rsa/pki/dh.pem

```

Nos dice que ha creado la clave dh.pem en el directorio pki.

### Generar clave RSA y Certificado de la CA

En el mismo directorio vamos a generar la clave rsa y el certificado de la CA.

```sh
./easyrsa build-ca nopass
```

```sh
root@vpn-server:/usr/share/easy-rsa# ./easyrsa build-ca nopass

Note: using Easy-RSA configuration from: ./vars

Using SSL: openssl OpenSSL 1.1.1d  10 Sep 2019
Generating RSA private key, 2048 bit long modulus (2 primes)
............+++++
...........+++++
e is 65537 (0x010001)
Can't load /usr/share/easy-rsa/pki/.rnd into RNG
140063001072768:error:2406F079:random number generator:RAND_load_file:Cannot open file:../crypto/rand/randfile.c:98:Filename=/usr/share/easy-rsa/pki/.rnd
You are about to be asked to enter information that will be incorporated
into your certificate request.
What you are about to enter is what is called a Distinguished Name or a DN.
There are quite a few fields but you can leave some blank
For some fields there will be a default value,
If you enter '.', the field will be left blank.
-----
Common Name (eg: your user, host, or server name) [Easy-RSA CA]:celia

CA creation complete and you may now import and sign cert requests.
Your new CA certificate file for publishing is at:
/usr/share/easy-rsa/pki/ca.crt

```

### Crear la clave RSA y el certificado del servidor

```sh
root@vpn-server:/usr/share/easy-rsa# ./easyrsa gen-req servidor nopass

Note: using Easy-RSA configuration from: ./vars

Using SSL: openssl OpenSSL 1.1.1d  10 Sep 2019
Generating a RSA private key
................+++++
...................................................+++++
writing new private key to '/usr/share/easy-rsa/pki/private/servidor.key.e5ZxePwSG3'
-----
You are about to be asked to enter information that will be incorporated
into your certificate request.
What you are about to enter is what is called a Distinguished Name or a DN.
There are quite a few fields but you can leave some blank
For some fields there will be a default value,
If you enter '.', the field will be left blank.
-----
Common Name (eg: your user, host, or server name) [servidor]:

Keypair and certificate request completed. Your files are:
req: /usr/share/easy-rsa/pki/reqs/servidor.req
key: /usr/share/easy-rsa/pki/private/servidor.key

```

Se han generado dos ficheros el 'servidor.req' y el 'servidor.key'. La key es la clave privada del servidor y el req es la petición de firma.

Ahora vamos a firmar digitalmente el certificado del servidor por la CA

```sh
root@vpn-server:/usr/share/easy-rsa# ./easyrsa sign-req server servidor

Note: using Easy-RSA configuration from: ./vars

Using SSL: openssl OpenSSL 1.1.1d  10 Sep 2019


You are about to sign the following certificate.
Please check over the details shown below for accuracy. Note that this request
has not been cryptographically verified. Please be sure it came from a trusted
source or that you have verified the request checksum with the sender.

Request subject, to be signed as a server certificate for 1080 days:

subject=
    commonName                = servidor


Type the word 'yes' to continue, or any other input to abort.
  Confirm request details: yes
Using configuration from /usr/share/easy-rsa/pki/safessl-easyrsa.cnf
Check that the request matches the signature
Signature ok
The Subject's Distinguished Name is as follows
commonName            :ASN.1 12:'servidor'
Certificate is to be certified until Feb  9 08:56:17 2024 GMT (1080 days)

Write out database with 1 new entries
Data Base Updated

Certificate created at: /usr/share/easy-rsa/pki/issued/servidor.crt

```

Como podemos ver se ha creado el certificado del servidor firmado por la CA. 


## Crear la clave RSA y el certificado del cliente.

Se generará la lcave RSA y el certificado digital x509 desde la misma máquina.

```sh
root@vpn-server:/usr/share/easy-rsa# ./easyrsa gen-req cliente nopass

Note: using Easy-RSA configuration from: ./vars

Using SSL: openssl OpenSSL 1.1.1d  10 Sep 2019
Generating a RSA private key
..................................................................................................+++++
.........+++++
writing new private key to '/usr/share/easy-rsa/pki/private/cliente.key.NyQ0SCChVN'
-----
You are about to be asked to enter information that will be incorporated
into your certificate request.
What you are about to enter is what is called a Distinguished Name or a DN.
There are quite a few fields but you can leave some blank
For some fields there will be a default value,
If you enter '.', the field will be left blank.
-----
Common Name (eg: your user, host, or server name) [cliente]:

Keypair and certificate request completed. Your files are:
req: /usr/share/easy-rsa/pki/reqs/cliente.req
key: /usr/share/easy-rsa/pki/private/cliente.key

```

Firmamos el certificado del cliente con la CA 

```sh
root@vpn-server:/usr/share/easy-rsa# ./easyrsa sign-req client cliente

Note: using Easy-RSA configuration from: ./vars

Using SSL: openssl OpenSSL 1.1.1d  10 Sep 2019


You are about to sign the following certificate.
Please check over the details shown below for accuracy. Note that this request
has not been cryptographically verified. Please be sure it came from a trusted
source or that you have verified the request checksum with the sender.

Request subject, to be signed as a client certificate for 1080 days:

subject=
    commonName                = cliente


Type the word 'yes' to continue, or any other input to abort.
  Confirm request details: yes
Using configuration from /usr/share/easy-rsa/pki/safessl-easyrsa.cnf
Check that the request matches the signature
Signature ok
The Subject's Distinguished Name is as follows
commonName            :ASN.1 12:'cliente'
Certificate is to be certified until Feb  9 09:00:04 2024 GMT (1080 days)

Write out database with 1 new entries
Data Base Updated

Certificate created at: /usr/share/easy-rsa/pki/issued/cliente.crt

```

Ya esta generado el certificado firmado para el cliente.

### Generar la clave TLS.


Esto es opcional pero recomendable para que la conexíon sea más segura y estemos protegidos ante un ataque.

```sh
openvpn --genkey --secret ta.key
```

Ahora podemos pasar todos los ficheros necesarios que hemos creado desde el servidor al cliente.

Teniendo en cuenta esto:

* pki/dh.pem (para el servidor)
* pki/ca.crt (para el servidor y clientes)
* pki/private/ca.key (para firmar en la CA machine)
* pki/private/servidor.key (para el servidor)
* pki/issued/servidor.crt (para el servidor)
* pki/private/cliente.key (para el cliente)
* pki/issued/cliente.crt (para el cliente)
* ta.key (para el servidor y clientes)

### 1.5. Servidor openVPN. Claves necesarias

El servidor de OpenVPN necesita el certificado de la CA, certificado y clave del servidor, y el archivo de Diffie-Hellman:

```sh
sudo mkdir /etc/openvpn/keys
sudo cp /usr/share/easy-rsa/pki/dh.pem /etc/openvpn/keys
sudo cp /usr/share/easy-rsa/pki/ca.crt /etc/openvpn/keys
sudo cp /usr/share/easy-rsa/pki/private/servidor.key /etc/openvpn/keys
sudo cp /usr/share/easy-rsa/pki/issued/servidor.crt /etc/openvpn/keys
sudo cp /usr/share/easy-rsa/ta.key /etc/openvpn/keys
```

* Movemos los ficheros pasados previamente con scp a nuestro cliente, al dirtorio nuevo.

```sh
debian@ansible:~$ ls
ca.crt  cliente.crt  cliente.key  ta.key
debian@ansible:~$ sudo mkdir /etc/openvpn/keys
debian@ansible:~$ sudo mv cliente.key /etc/openvpn/keys/
debian@ansible:~$ sudo mv cliente.crt /etc/openvpn/keys/
debian@ansible:~$ sudo mv ca.crt /etc/openvpn/keys/
debian@ansible:~$ sudo mv ta.key /etc/openvpn/keys/
```

## 2. Configuración del servidor openvpn

Previamente hemos activado el bit de forwarding

`nano /etc/sysctl.conf`
```sh
net.ipv4.ip_forward=1
```

Tambien hemos descomentado la siguiente linea del fichero:

`sudo nano /etc/default/openvpn `
```sh
AUTOSTART="all"
```
Para configurar el servidor , creamos un archivo de configuración dentro del directorio openvpn

```sh
sudo nano /etc/openvpn/servidor.conf
```
```sh
# Use a dynamic TUN device
dev tun
# Use tcp for communicatting with client
proto tcp
# Virtual ip
server 10.99.99.0 255.255.255.0
# Local subnets
push "route 192.168.100.0 255.255.255.0"
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

```
* Reiniciamos el servicio con la nueva configuración
  
```sh
root@vpn-server:/etc/openvpn/keys# /etc/init.d/openvpn restart
[ ok ] Restarting openvpn (via systemctl): openvpn.service.

root@vpn-server:/etc/openvpn/keys# systemctl status openvpn
● openvpn.service - OpenVPN service
   Loaded: loaded (/lib/systemd/system/openvpn.service; enabled; vendor preset: enabled)
   Active: active (exited) since Thu 2021-02-25 10:34:54 UTC; 13s ago
  Process: 2715 ExecStart=/bin/true (code=exited, status=0/SUCCESS)
 Main PID: 2715 (code=exited, status=0/SUCCESS)

Feb 25 10:34:54 vpn-server systemd[1]: Starting OpenVPN service...
Feb 25 10:34:54 vpn-server systemd[1]: Started OpenVPN service.
```

* Comprobamos que se ha levantado la nueva interfaz virtual 'tun0'

```sh
debian@vpn-server:~$ ip a show 'tun0'
4: tun0: <POINTOPOINT,MULTICAST,NOARP,UP,LOWER_UP> mtu 1500 qdisc pfifo_fast state UNKNOWN group default qlen 100
    link/none 
    inet 10.99.99.1 peer 10.99.99.2/32 scope global tun0
       valid_lft forever preferred_lft forever
    inet6 fe80::1fb1:bb63:f185:5d3d/64 scope link stable-privacy 
       valid_lft forever preferred_lft forever
```

## 3.Configuración del cliente

`nano  /etc/openvpn/cliente.conf `

```sh
# Use a dynamic TUN device
dev tun

# Connect to server
remote 10.0.0.15

# Set virtual point-to-point IP addresses
ifconfig 10.99.99.0 255.255.255.0
pull

# Use TCP for communicating with server
proto tcp-client

# Enable TLS and assume client role during TLS handshake
tls-client

# Certificado de la CA
ca /etc/openvpn/keys/ca.crt

# Certificado del cliente
cert /etc/openvpn/keys/cliente.crt

# Clave privada del cliente
key /etc/openvpn/keys/cliente.key

# Use fast LZO compression
comp-lzo

# Ping remote every 10sg and restart after 60sg passed without sign of life from remote
keepalive 10 60

# Set output verbosity to normal usage range 
verb 3

# Output logging messages to openvpn.log file
log /var/log/openvpn.log

```
* Reiniciamos el servicio

```sh
debian@ansible:~$ sudo /etc/init.d/openvpn restart
[ ok ] Restarting openvpn (via systemctl): openvpn.service.
```

En mi caso he tenido que reiniciar el sistema

* Vemos el tun0


```sh
debian@ansible:~$ ip a show tun0
298: tun0: <POINTOPOINT,MULTICAST,NOARP,UP,LOWER_UP> mtu 1500 qdisc pfifo_fast state UNKNOWN group default qlen 100
    link/none 
    inet 10.99.99.6 peer 10.99.99.5/32 scope global tun0
       valid_lft forever preferred_lft forever
    inet6 fe80::b15:c77b:ed11:e4ed/64 scope link stable-privacy 
       valid_lft forever preferred_lft forever

debian@ansible:~$ ip r
default via 10.0.0.1 dev eth0 
10.0.0.0/24 dev eth0 proto kernel scope link src 10.0.0.8 
10.99.99.1 via 10.99.99.5 dev tun0 
10.99.99.5 dev tun0 proto kernel scope link src 10.99.99.6 
169.254.169.254 via 10.0.0.1 dev eth0 
192.168.100.0/24 via 10.99.99.5 dev tun0 

```

## Funcionamiento. Acceso desde el cliente a la LAN.

Direccionamiento del cliente:

![captura2.png](/images/vpn/captura2.png)

Funcionamiento
![captura1.png](/images/vpn/captura1.png)

* Comprobamos que podemos acceder al servidor y la red local lan.

```sh
debian@ansible:~$ ping 192.168.100.2
PING 192.168.100.2 (192.168.100.2) 56(84) bytes of data.
64 bytes from 192.168.100.2: icmp_seq=1 ttl=64 time=1.11 ms
64 bytes from 192.168.100.2: icmp_seq=2 ttl=64 time=1.08 ms
64 bytes from 192.168.100.2: icmp_seq=3 ttl=64 time=0.880 ms
64 bytes from 192.168.100.2: icmp_seq=4 ttl=64 time=1.27 ms
^C
--- 192.168.100.2 ping statistics ---
4 packets transmitted, 4 received, 0% packet loss, time 22ms
rtt min/avg/max/mdev = 0.880/1.083/1.269/0.142 ms

debian@ansible:~$ ping 192.168.100.10
PING 192.168.100.10 (192.168.100.10) 56(84) bytes of data.
64 bytes from 192.168.100.10: icmp_seq=1 ttl=63 time=2.91 ms
64 bytes from 192.168.100.10: icmp_seq=2 ttl=63 time=2.16 ms
64 bytes from 192.168.100.10: icmp_seq=3 ttl=63 time=1.71 ms
^C
--- 192.168.100.10 ping statistics ---
3 packets transmitted, 3 received, 0% packet loss, time 5ms
rtt min/avg/max/mdev = 1.710/2.259/2.905/0.495 ms

```
