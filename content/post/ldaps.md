---
title: "Configurar LDAPs en Debian. OpenLDAP. (Freston)"
date: 2021-01-25T09:27:32+01:00
draft: false
toc: false
images:
tags: ['ldaps']
---

![ldaps.png](/images/escenario/ldaps.png)

**¡!** Este post está relacionado con un entrono de trabajo con openstack incluido en otras entradas de mi blog.

### 1. Introducción

#### LDAP. Protocolo Ligero de Acceso a Directorio.

**¿Qué es LDAP?**

Es un **protocolo** muy utilizado por empresas que apuestan por el **software libre** al utilizar distribuciones de **Linux** para construir un **directorio activo **en el que se gestionan las credenciales de los trabajadores, los permisos y estaciones de trabajo.

Funciona como un **directorio remoto** en el que un conjunto de objetos están organizados de **forma jerárquica**. 

Tenemos que saber que **LDAP** está basado en el protocolo [X.500](https://es.wikipedia.org/wiki/X.500) para compartir directorios.

El uso básico del directorio activo es almacenar información virtual de usuarios y compartirlo entre ellos con una serie de permisos y restricciones.

> Esto es sólo una breve introducción de LDAP. Para más información puedes entrar en este [post](https://unbitdeinformacioncadadia.netlify.app/posts/2020/12/instalaci%C3%B3n-y-configuraci%C3%B3n-inicial-de-openldap/)

### 2. Objetivo:

Configura el servidor LDAP de frestón para que utilice el protocolo ldaps:// a la vez que el ldap:// utilizando el certificado x509 de la práctica de https o solicitando el correspondiente a través de gestiona. Realiza las modificaciones adecuadas en el cliente ldap de frestón para que todas las consultas se realicen por defecto utilizando ldaps://

### 3. Creación de un certificado SSL Wilcard

#### 3.1. Concepto: ¿Qué es un certificado SSL Wilcard?

Es un certificado que protege la dirección URL de un sitio web, así como también sus subdominios.

#### 3.2. Crear clave privada y certificado

El **certificado** principalmente se va a generar en Freston, nuestra máquina donde tenemos configurado el DNS de nuestro escenario.

* Generar la **clave privada**:

```sh
openssl genrsa 4069 > /etc/ssl/private/wc_private.key
```

* Generar el **certificado**:

```sh
root@freston:/home/debian# openssl req -new -key /etc/ssl/private/wc_private.key -out /home/debian/wc_celia.csr
You are about to be asked to enter information that will be incorporated
into your certificate request.
What you are about to enter is what is called a Distinguished Name or a DN.
There are quite a few fields but you can leave some blank
For some fields there will be a default value,
If you enter '.', the field will be left blank.
-----
Country Name (2 letter code) [AU]:ES
State or Province Name (full name) [Some-State]:Sevilla
Locality Name (eg, city) []:Dos Hermanas
Organization Name (eg, company) [Internet Widgits Pty Ltd]:IES Gonzalo Nazareno
Organizational Unit Name (eg, section) []:Informatica
Common Name (e.g. server FQDN or YOUR name) []:*.celia.gonzalonazareno.org
Email Address []:

Please enter the following 'extra' attributes
to be sent with your certificate request
A challenge password []:
An optional company name []:
```

#### 3.3. Enviar el certificado a la autoridad certificadora

* Enviar dicho certificado a la **autoridad certificadora** y esperar a que lo firmen. Debamos obtener un fichero.crt firmado y el de la autoridad certificadora, que en este caso es: **gonzalonazareno.crt**, que nos hemos bajado de gestiona.

* Los certificados deben estar  alojados en **/etc/ssl/certs**, y la clave privada en **/etc/ssl/private**.

### 4. Crear las ACLs. Access Control Lists.

Con las ACLs podemos configurar "quién tiene acceso a qué". Básicamente es una forma de determinar los **permisos** de acceso apropiados a un determinado objeto.

#### 4.1. Instalación del paquete acl

Necesitaremos instalar el paquete acl para Debian 10(Freston), donde tenemos nuestro directorio activo ya instalado. 

```sh
sudo apt-get install acl
```

#### 4.2. Crear ACLs

Creamos las ACLs para que el usuario debian tenga los permisos necesarios para trabajar con los certificados.

```sh
sudo setfacl -m u:openldap:r-x /etc/ssl/certs
sudo setfacl -m u:openldap:r-x /etc/ssl/certs/gonzalonazareno.crt 
sudo setfacl -m u:openldap:r-x /etc/ssl/certs/wc_celia_sign.crt 
sudo setfacl -m u:openldap:r-x /etc/ssl/private/
sudo setfacl -m u:openldap:r-x /etc/ssl/private/wc_private.key
```

### 5. Fichero de configuración .ldif 

En el nuevo fichero .ldif vamos a indicar los certificados pertintentes y la clave privada de la siguiente manera:

```sh
dn: cn=config
changetype: modify
add: olcTLSCACertificateFile
olcTLSCACertificateFile: /etc/ssl/certs/gonzalonazareno.crt
-
replace: olcTLSCertificateFile
olcTLSCertificateFile: /etc/ssl/certs/wc_celia_sign.crt
-
replace: olcTLSCertificateKeyFile
olcTLSCertificateKeyFile: /etc/ssl/private/wc_private.key
```

Añadimos el nuevo fichero a la configuración 

```sh
sudo ldapmodify -Y EXTERNAL -H ldapi:/// -f ldaps.ldif

#Salida:

olcTLSCACertificateFile: /etc/ssl/certs/gonzalonazareno.crt
olcTLSCertificateFile: /etc/ssl/certs/wc_celia_sign.crt
olcTLSCertificateKeyFile: /etc/ssl/private/wc_private.key
```

Nos aseguramos que no hay errores al añadirlo

```sh
sudo slapcat -b "cn=config" | grep -E "olcTLS" 

# Salida:
olcTLSCACertificateFile: /etc/ssl/certs/gonzalonazareno.crt
olcTLSCertificateFile: /etc/ssl/certs/wc_celia_sign.crt
olcTLSCertificateKeyFile: /etc/ssl/private/wc_private.key

sudo slaptest -u

# Salida:
config file testing succeeded

```

### 6. Configuración 

`/etc/ldap/ldap.conf`

Añadimos el certificado de la autoridad certificadora

```sh
TLS_CACERT      /etc/ssl/certs/gonzalonazareno.crt
```

`/etc/default/slapd`

Activamos la opción de ldaps de la siguiente forma

```sh
SLAPD_SERVICES="ldap:/// ldapi:/// ldaps:///"
```

### 7. Funcionamiento

Debemos reiniciar el servicio de ldaps y comprobar que esta funcionando

```sh
debian@freston:~$ sudo /etc/init.d/slapd restart
[ ok ] Restarting slapd (via systemctl): slapd.service.

debian@freston:~$ sudo /etc/init.d/slapd status
● slapd.service - LSB: OpenLDAP standalone server (Lightweight Directory Access Protocol)
   Loaded: loaded (/etc/init.d/slapd; generated)
   Active: active (running) since Mon 2021-01-25 09:09:29 CET; 4s ago
     Docs: man:systemd-sysv-generator(8)
  Process: 1134 ExecStart=/etc/init.d/slapd start (code=exited, status=0/SUCCESS)
    Tasks: 3 (limit: 562)
   Memory: 3.3M
   CGroup: /system.slice/slapd.service
           └─1143 /usr/sbin/slapd -h ldap:/// ldapi:/// ldaps:/// -g openldap -u openldap -F /etc/ldap/s…

Jan 25 09:09:29 freston systemd[1]: Starting LSB: OpenLDAP standalone server (Lightweight Directo…col)...
Jan 25 09:09:29 freston slapd[1139]: @(#) $OpenLDAP: slapd  (Nov 17 2020 01:23:45) $
                                             Debian OpenLDAP Maintainers <pkg-openldap-devel@list…an.org>
Jan 25 09:09:29 freston slapd[1143]: slapd starting
Jan 25 09:09:29 freston slapd[1134]: Starting OpenLDAP: slapd.
Jan 25 09:09:29 freston systemd[1]: Started LSB: OpenLDAP standalone server (Lightweight Director…tocol).
Hint: Some lines were ellipsized, use -l to show in full.
```

**Consulta**

```sh
debian@freston:~$ ldapsearch -x -H ldaps://freston.celia.gonzalonazareno.org:636 -b "cn=admin,dc=freston,dc=celia,dc=gonzalonazareno,dc=org"
# extended LDIF
#
# LDAPv3
# base <cn=admin,dc=freston,dc=celia,dc=gonzalonazareno,dc=org> with scope subtree
# filter: (objectclass=*)
# requesting: ALL
#

# admin, freston.celia.gonzalonazareno.org
dn: cn=admin,dc=freston,dc=celia,dc=gonzalonazareno,dc=org
objectClass: simpleSecurityObject
objectClass: organizationalRole
cn: admin
description: LDAP administrator

# search result
search: 2
result: 0 Success

# numResponses: 2
# numEntries: 1

```