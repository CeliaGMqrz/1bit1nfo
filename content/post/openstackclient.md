---
title: "Instalar Openstackclient y deshabilitar la seguridad de puertos"
date: 2020-11-19T19:31:53+01:00
draft: false
toc: false
images:
tags: ['openstackclient']
---

Necesitamos instalar *Openstackclient*, para ello lo vamos hacer desde un entorno virtual para no comprometer la paquetería de nuestro sistema, ya que no es necesario para nuestro sistema actualmente.

_____________________________________________________________________
Recordamos como creamos un **entorno virtual** con *venv*

-  Instalamos el paquete necesario para instalar módulos:

```sh
apt-get install python3-venv
```

- Desde el usuario sin privilegios podemos crear un entorno virtual con python3:

```sh
python3 -m venv entorno
```

- Activar y desactivar el entorno

```sh
source entorno/bin/activate
(entorno)$ deactivate
```

_______________________________________________________________________

Usando el entorno virtual creado previamente, vamos a instalar el paquete Openstackclient (*necesitaremos la libreria de python3*). 

```sh
sudo apt install python3-dev
pip install python-openstackclient
```

Nos vamos al '*Acceso y Seguridad*' del cloud y descargamos el fichero con las variables de entorno de nuestro proyecto. Este fichero tiene una extensión sh. Este script se ejecuta desde nuestro entorno virtual en el directorio del mismo. Pero antes deberemos de editar el fichero proporcionando la ruta del certificado del IES, añadiendo las siguiente línea (la ruta puede variar dependiendo de donde tengamos el certificado).

```powershell
export OS_CACERT=/usr/local/share/ca-certificates/gonzalonazareno.crt
```

A tener en cuenta:

* Deberemos de tener en nuestro fichero /etc/hosts bien configurada la ip con el nombre del cloud, siendo este:

```powershell
(entorno) celiagm@debian:~/venv/entorno$ sudo nano /etc/hosts
```

```powershell
172.22.222.1    jupiter.gonzalonazareno.org
```
* Como hemos dicho anteriormente el script debe estar ubicado dentro de nuestro entorno virtual. Lo ejecutamos con **source** y le pasamos la contraseña

```powershell

(entorno) celiagm@debian:~/venv/entorno$ source Proyecto\ de\ celia.garcia-openrc.sh
Please enter your OpenStack Password for project Proyecto de celia.garcia as user celia.garcia: 
```

* Ahora listamos los servidores que tenemos en nuestro proyecto

```powershell
$ openstack server list

``` 
```powershell

(entorno) celiagm@debian:~/venv/entorno$ openstack server list
+--------------------------------------+----------------+--------+---------------------------------------------------------------------+--------------------------------+---------+
| ID                                   | Name           | Status | Networks                                                            | Image                          | Flavor  |
+--------------------------------------+----------------+--------+---------------------------------------------------------------------+--------------------------------+---------+
| c39a7cc7-f485-4617-a62f-acdd39a19682 | Dulcinea       | ACTIVE | celia.garcia=10.0.1.6; red de celia.garcia=10.0.0.3, 172.22.200.222 | Debian Buster 10.6             | m1.mini |
| e23fc109-de1b-4bdf-8b88-cf7b2721350c | Quijote        | ACTIVE | celia.garcia=10.0.1.13                                              | CentOS 7                       | m1.mini |
| 26e2f672-2408-40d8-bcec-752059db35fa | Sancho         | ACTIVE | celia.garcia=10.0.1.11                                              | Ubuntu 20.04 LTS (focal fossa) | m1.mini |
| a460fd00-f4d7-4999-bc05-a42f54e3dd56 | cliente_nginx  | ACTIVE | red de celia.garcia=10.0.0.6, 172.22.200.148                        | Debian Buster 10.6             | m1.mini |
| d88962ae-4617-4fe3-be33-c1bbfe686c69 | servidor_nginx | ACTIVE | red de celia.garcia=10.0.0.5, 172.22.200.152                        | Debian Buster 10.6             | m1.mini |
+--------------------------------------+----------------+--------+---------------------------------------------------------------------+--------------------------------+---------+

```

* Listamos las redes que tenemos


```powershell
$ openstack network list
```
```powershell
+--------------------------------------+---------------------+----------------------------------------------------------------------------+
| ID                                   | Name                | Subnets                                                                    |
+--------------------------------------+---------------------+----------------------------------------------------------------------------+
| 21124241-dddf-4c06-b646-eb15ed5cd84a | celia.garcia        | 46e30aa0-10de-4883-a8c7-707b5a884eec                                       |
| 49812d85-8e7a-4c31-baa2-d427692f6568 | ext-net             | 158bbe3e-3c98-485e-8042-ba6402111ea6, 6218710b-aa05-46f7-b198-7639efe3da95 |
| 90c37b05-bd26-49a3-b797-c6038b49a169 | red de celia.garcia | 029d2907-1315-41f3-af12-c1285ceb43d2                                       |

```

* Listar los puertos

```powershell
$ openstack port list
```

```powershell
(entorno) celiagm@debian:~/venv/entorno$ openstack port list
+--------------------------------------+------+-------------------+--------------------------------------------------------------------------+--------+
| ID                                   | Name | MAC Address       | Fixed IP Addresses                                                       | Status |
+--------------------------------------+------+-------------------+--------------------------------------------------------------------------+--------+
| 73876736-71bc-4bfc-b240-e2bb0f1ca505 |      | fa:16:3e:f7:be:35 | ip_address='10.0.1.13', subnet_id='46e30aa0-10de-4883-a8c7-707b5a884eec' | ACTIVE |
| 85b0d349-4240-4ea5-b277-fbd2bef00928 |      | fa:16:3e:77:40:7a | ip_address='10.0.0.3', subnet_id='029d2907-1315-41f3-af12-c1285ceb43d2'  | ACTIVE |
| a9bdd25d-cd44-44e1-96f3-fb5228872245 |      | fa:16:3e:04:0d:c4 | ip_address='10.0.0.1', subnet_id='029d2907-1315-41f3-af12-c1285ceb43d2'  | ACTIVE |
| b20a13b0-107c-44e1-91ad-b05c4c4ab6fb |      | fa:16:3e:eb:33:51 | ip_address='10.0.0.2', subnet_id='029d2907-1315-41f3-af12-c1285ceb43d2'  | ACTIVE |
| d6d4a998-73e9-4bc0-9ad1-57b481c146c5 |      | fa:16:3e:08:7a:18 | ip_address='10.0.0.6', subnet_id='029d2907-1315-41f3-af12-c1285ceb43d2'  | ACTIVE |
| d87620fe-c4e4-47e1-9381-ee47211795e3 |      | fa:16:3e:e8:a3:f7 | ip_address='10.0.1.2', subnet_id='46e30aa0-10de-4883-a8c7-707b5a884eec'  | ACTIVE |
| dac3549b-9fb3-488d-b399-ed7ee94ea724 |      | fa:16:3e:9a:c0:6a | ip_address='10.0.0.5', subnet_id='029d2907-1315-41f3-af12-c1285ceb43d2'  | ACTIVE |
| e99aaf3f-c607-4d1d-9e05-fec50b132296 |      | fa:16:3e:f2:65:68 | ip_address='10.0.1.11', subnet_id='46e30aa0-10de-4883-a8c7-707b5a884eec' | ACTIVE |
| fa58e181-e88f-4453-8f20-c4bd7d190179 |      | fa:16:3e:e0:bc:db | ip_address='10.0.1.6', subnet_id='46e30aa0-10de-4883-a8c7-707b5a884eec'  | ACTIVE |
+--------------------------------------+------+-------------------+--------------------------------------------------------------------------+--------+


```
______________________________________________________________________

### Deshabilitar seguridad de un puerto

* Vemos las caracteristicas de Dulcinea

```powershell
$ openstack server show Dulcinea
```

```powershell
(entorno) celiagm@debian:~/venv/entorno$ openstack server show Dulcinea
+-----------------------------+---------------------------------------------------------------------+
| Field                       | Value                                                               |
+-----------------------------+---------------------------------------------------------------------+
| OS-DCF:diskConfig           | AUTO                                                                |
| OS-EXT-AZ:availability_zone | nova                                                                |
| OS-EXT-STS:power_state      | Running                                                             |
| OS-EXT-STS:task_state       | None                                                                |
| OS-EXT-STS:vm_state         | active                                                              |
| OS-SRV-USG:launched_at      | 2020-11-19T20:28:18.000000                                          |
| OS-SRV-USG:terminated_at    | None                                                                |
| accessIPv4                  |                                                                     |
| accessIPv6                  |                                                                     |
| addresses                   | celia.garcia=10.0.1.6; red de celia.garcia=10.0.0.3, 172.22.200.222 |
| config_drive                |                                                                     |
| created                     | 2020-11-19T20:27:57Z                                                |
| flavor                      | m1.mini (12)                                                        |
| hostId                      | 829ef6cbc520f728c22007cd80702af381d72417f6ce13fbdcbf53e5            |
| id                          | c39a7cc7-f485-4617-a62f-acdd39a19682                                |
| image                       | Debian Buster 10.6 (51b38ecf-99e1-46a3-a497-9e1cc9c3c2d4)           |
| key_name                    | msi                                                                 |
| name                        | Dulcinea                                                            |
| progress                    | 0                                                                   |
| project_id                  | bf33696e5463476b95e310dd1e17f5f3                                    |
| properties                  |                                                                     |
| status                      | ACTIVE                                                              |
| updated                     | 2020-11-23T12:04:44Z                                                |
| user_id                     | bdfca7c57468ff40b7445535735bf867c444239818b740f4f59474b105c27dec    |
| volumes_attached            |                                                                     |
+-----------------------------+---------------------------------------------------------------------+

```

* Le quitamos el grupo de seguridad

```powershell
openstack server remove security group Dulcinea default
```
* Miramos la ip fija que tiene , en este caso es la 10.0.0.11

* Listamos los puertos y obtenemos el identificador de la máquina según la ip 

* Le quitamos la seguridad de puertos tanto de la red interna como de la red externa.

```powershell
openstack port set --disable-port-security fa58e181-e88f-4453-8f20-c4bd7d190179
openstack port set --disable-port-security 85b0d349-4240-4ea5-b277-fbd2bef00928
```

* Ahora comprobamos la conexión y vemos que es correcta:

```powershell
(entorno) celiagm@debian:~/venv/entorno$ ping 172.22.200.222
PING 172.22.200.222 (172.22.200.222) 56(84) bytes of data.
64 bytes from 172.22.200.222: icmp_seq=1 ttl=61 time=71.1 ms
64 bytes from 172.22.200.222: icmp_seq=2 ttl=61 time=70.1 ms
64 bytes from 172.22.200.222: icmp_seq=3 ttl=61 time=95.5 ms
^C
--- 172.22.200.222 ping statistics ---
3 packets transmitted, 3 received, 0% packet loss, time 4ms
rtt min/avg/max/mdev = 70.115/78.910/95.549/11.771 ms
```

```powershell
(entorno) celiagm@debian:~/venv/entorno$ ssh debian@172.22.200.222
Linux dulcinea 4.19.0-12-cloud-amd64 #1 SMP Debian 4.19.152-1 (2020-10-18) x86_64

The programs included with the Debian GNU/Linux system are free software;
the exact distribution terms for each program are described in the
individual files in /usr/share/doc/*/copyright.

Debian GNU/Linux comes with ABSOLUTELY NO WARRANTY, to the extent
permitted by applicable law.
Last login: Mon Nov 23 15:59:42 2020 from 172.23.0.70
debian@dulcinea:~$ 

```