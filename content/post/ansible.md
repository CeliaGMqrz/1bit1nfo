---
title: "Introducción a Ansible"
date: 2021-01-20T17:15:21+01:00
draft: false
toc: false
images:
tags: ['ansible']
---

## Conceptos

**Ansible** es un software que automatiza el aprovisionamiento de software, la gestión de configuraciones y el depliegue de aplicaciones. Está categorizado como una **herramienta de orquestación**. Es muy útil para administradores de sistemas y DevOps

Ansible permite **gestionar los servidores**, configuraciones y aplicaciones de forma sencilla.

Utiliza **ssh** para conectarse a los nodos y únicamente requiere **python** en el servidor remoto que se vaya a ejecutar para poder utilizarlo. 

Usa un fichero **YAML** para definir las configuraciones y las acciones que se van a desarrollar en los servidores.

## Entorno virtual

Necesitamos crear un entorno virtual para tener python al alcance.

* Crear un entorno virtual, lo vamos a llamar 'ansible'

```sh
apt-get install python3-venv
python3 -m venv ansible
source ansible/bin/activate
```

* Instalamos Ansible en nuestro entorno

```sh
pip install ansible
```

Vamos a clonar el siguiente repositorio para hacer la prueba de uso

* Clonar el repositorio:  https://github.com/josedom24/automatizacion_iaw 

```sh
git clone https://github.com/josedom24/automatizacion_iaw.git
```

* Comprobamos la versión de Ansible

```sh
(ansible) celiagm@debian:~/venv/ansible/automatizacion_iaw$ ansible --version
ansible 2.10.5
  config file = /home/celiagm/venv/ansible/automatizacion_iaw/ansible.cfg
  configured module search path = ['/home/celiagm/.ansible/plugins/modules', '/usr/share/ansible/plugins/modules']
  ansible python module location = /home/celiagm/venv/ansible/lib/python3.7/site-packages/ansible
  executable location = /home/celiagm/venv/ansible/bin/ansible
  python version = 3.7.3 (default, Jul 25 2020, 13:03:44) [GCC 8.3.0]
```

* Nos aseguramos de nuestra configuración, en la que en la parte de hosts tenemos la ip de el servidor remoto al que nos vamos a conectar y donde vamos a instalar los servicios.

`hosts`

```sh
[servidores_web]
nodo1 ansible_ssh_host=172.22.200.150 ansible_python_interpreter=/usr/bin/python3
```


* En site.yaml vamos a tener la configuración para indicar los servicios que vamos a instalar a través de unos roles.

`site.yaml`

```sh
- hosts: all
  become: true
  roles:
   - role: commons

- hosts: servidores_web
  become: true
  roles:
   - role: apache2

- hosts: servidores_web
  become: true
  roles:
   - role: mariadb

- hosts: servidores_web
  become: true
  roles:
   - role: wordpress

```

* Ejecutamos ansible-playbook con el fichero de configuración, de esta forma se van a ir instalando los servicios en el servidor remoto.

```sh
ansible-playbook site.yaml 
```

Salida:

```sh
(ansible) celiagm@debian:~/venv/ansible/automatizacion_iaw$ ansible-playbook site.yaml 

PLAY [all] **********************************************************************************************

TASK [Gathering Facts] **********************************************************************************
ok: [nodo1]

TASK [commons : Ensure system is updated] ***************************************************************
[WARNING]: Updating cache and auto-installing missing dependency: python3-apt
changed: [nodo1]

PLAY [servidores_web] ***********************************************************************************

TASK [Gathering Facts] **********************************************************************************
ok: [nodo1]

TASK [apache2 : install apache2+php] ********************************************************************
ok: [nodo1]

TASK [apache2 : Copy index.html] ************************************************************************
changed: [nodo1]

TASK [apache2 : Copy info.php] **************************************************************************
changed: [nodo1]

RUNNING HANDLER [apache2 : restart apache2] *************************************************************
changed: [nodo1]

PLAY [servidores_web] ***********************************************************************************

TASK [Gathering Facts] **********************************************************************************
ok: [nodo1]

TASK [mariadb : ensure mariadb is installed] ************************************************************
ok: [nodo1]

TASK [mariadb : ensure mariadb binds to internal interface] *********************************************
changed: [nodo1]

RUNNING HANDLER [mariadb : restart mariadb] *************************************************************
changed: [nodo1]

PLAY [servidores_web] ***********************************************************************************

TASK [Gathering Facts] **********************************************************************************
ok: [nodo1]

TASK [wordpress : install unzip] ************************************************************************
changed: [nodo1]

TASK [wordpress : download wordpress] *******************************************************************
changed: [nodo1]

TASK [wordpress : unzip wordpress] **********************************************************************
changed: [nodo1]

TASK [wordpress : create database wordpress] ************************************************************
changed: [nodo1]

TASK [wordpress : create user mysql wordpress] **********************************************************
changed: [nodo1] => (item=localhost)

TASK [wordpress : copy wp-config.php] *******************************************************************
changed: [nodo1]

RUNNING HANDLER [wordpress : restart apache2] ***********************************************************
changed: [nodo1]

PLAY RECAP **********************************************************************************************
nodo1                      : ok=19   changed=13   unreachable=0    failed=0    skipped=0    rescued=0    ignored=0   

```