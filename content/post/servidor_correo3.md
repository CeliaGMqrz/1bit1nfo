---
title: "Servidor de Correos. Postfix (III)."
date: 2021-01-25T17:15:21+01:00
draft: false
toc: false
images:
tags: ['servidor de correos','dovecot', 'IMAP']
---

## Gestión de correos desde un cliente

### Tarea 8: Configurar postfix con Maildir

**Descripción:**

Configura el buzón de los usuarios de tipo Maildir. Envía un correo a tu usuario y comprueba que el correo se ha guardado en el buzón **Maildir** del usuario del sistema correspondiente. Recuerda que ese tipo de buzón no se puede leer con la utilidad mail.

**Configuración:**

* Para hacer esta tarea vamos a indicar a postfix en su configuración dónde se van a guardar los nuevos correos.

```sh
nano /etc/postfix/main.cf
```
* Añadimos la siguiente línea

```sh
home_mailbox = Maildir/
```

* Reiniciamos el servicio

```sh
sudo systemctl restart postfix
```

* Ahora vamos a probar si se ha configurado correctamente para ello vamos a instalar el siguiente paquete

```sh
sudo apt-get install mailutils
```

* Una vez instalado vamos a enviar un correo desde la cuenta de debian, comprobaremos que utilizando mail ya no aparece si no que se almacena en el directorio Maildir

Enviamos un correo de prueba a debian

```sh
debian@kiara:~$ echo "prueba"| mail -s "email de prueba" debian
```
Comprobamos que con la utilidad mail ya no podemos visualizarlo.

```sh
debian@kiara:~$ mail
No mail for debian
debian@kiara:~$ mailq
Mail queue is empty
```

Comprobamos que el correo de prueba o los correos de prueba que hemos enviado se han incluido dentro del directorio /Maildir.

```sh
debian@kiara:~$ ls Maildir/
cur                  dovecot.list.index.log  dovecot-uidvalidity           subscriptions
dovecot.index.cache  dovecot.mailbox.log     dovecot-uidvalidity.601e9f0c  tmp
dovecot.index.log    dovecot-uidlist         new

debian@kiara:~$ ls Maildir/new/
1612893822.V801I61e44M2366.kiara  1612893826.V801I61e43M8243.kiara

debian@kiara:~$ cat Maildir/new/161289382
1612893822.V801I61e44M2366.kiara  1612893826.V801I61e43M8243.kiara

debian@kiara:~$ cat Maildir/new/1612893826.V801I61e43M8243.kiara
Return-Path: <debian@iesgn05.es>
X-Original-To: debian
Delivered-To: debian@iesgn05.es
Received: by kiara.iesgn05.es (Postfix, from userid 1000)
	id 0135161E45; Tue,  9 Feb 2021 18:03:46 +0000 (UTC)
To: debian@iesgn05.es
Subject: email de prueba
MIME-Version: 1.0
Content-Type: text/plain; charset="UTF-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20210209180346.0135161E45@kiara.iesgn05.es>
Date: Tue,  9 Feb 2021 18:03:46 +0000 (UTC)
From: Debian <debian@iesgn05.es>
```

Esto mismo lo podemos hacer con el usuario root y sería el mismo procedimiento.

### Tarea 9: Instalación de dovecot. Protocolo IMAP.

**Descripción:**
Instala configura dovecot para ofrecer el protocolo IMAP. Configura dovecot de manera adecuada para ofrecer autentificación y cifrado

#### 9.11. Conceptos:

* **Dovecot**: es un servidor de IMAP Y POP3 de código abierto para sistemas Linux. Puede trabajar con mbox y Maildir.

* **IMAP**: Es un protocolo de acceso a mensajes de Internet, que permite el acceso a mensajes almacenados en un servidor de internet. A través de IMAP se puede tener acceso al correo electrónico teniendo acceso a la red. Se ejecuta en los puertos 143 y 993 (SSL).

Es importante saber que utiliza la **sincronización** para garantizar que se guarde una copia de los mensajes en los diferentes directorios inicados en el servidor y así quedarán ordenados los correos.

* **Pop**: Protocolo de oficina de correo. También es usado para la obtencion de mensajes de correo electrónico almacenados en un servidor remoto. Ya no se utliza normalmente.

> **Diferencias entre IMAP y POP**: La diferencia principal entre estos dos protocolos es que IMAP almacena los mensajes en el servidor de correo y sus copias en los directorios de forma ordenada mientras que POP3 los descarga y almacena de forma local sólo en la bandeja de entrada.

**Tipos de buzones**

Hasta ahora hemos utilizado el buzon **mbox** a través del protocolo POP3, pero ahora vamos a utlizar el buzón **Maildir**, en el que los mensajes se guardan en un directorio llamado Maildir, imprescindible para el protocolo que vamos a usar **IMAP**.

> La configuracion de **maildir** la hemos realizado en la tarea anterior.

#### 9.2. Instalación de dovecot

* Instalamos los paquetes pertintentes que vamos a usar para dovecot.

> No es necesario descargar *dovecot-pop3d* porque en esta práctica solo vamos a usar IMAP, pero puede ser interesante descargarlo para probar su funcionamiento.

```sh
sudo apt install dovecot-imapd dovecot-pop3d dovecot-core
```

#### 9.3. Cifrado

Ahora vamos a crear los certificados con LET'S ENCRYPT. Para que sean de confianza.
Los usaremos despues para configurar SSL.

##### Crear certificados con Let's Encrypt

* Instalamos cerbot

```sh
nano /etc/apt/sources.list
# Agregamos:
deb http://ftp.debian.org/debian buster-backports main
# Actualizamos:
apt-get update
# Instalamos:
apt install certbot -t buster-backports
```

* Es importante que paremos el servicio de apache o nginx si están en funcionamiento

```sh
debian@kiara:~$ sudo systemctl stop nginx
```

Ejecutamos el proceso para crear los certificados para mail.iesgn05.es

```sh
debian@kiara:~$ sudo certbot certonly --standalone -d mail.iesgn05.es
Saving debug log to /var/log/letsencrypt/letsencrypt.log
Plugins selected: Authenticator standalone, Installer None
Obtaining a new certificate
Performing the following challenges:
http-01 challenge for mail.iesgn05.es
Waiting for verification...
Cleaning up challenges

IMPORTANT NOTES:
 - Congratulations! Your certificate and chain have been saved at:
   /etc/letsencrypt/live/mail.iesgn05.es/fullchain.pem
   Your key file has been saved at:
   /etc/letsencrypt/live/mail.iesgn05.es/privkey.pem
   Your cert will expire on 2021-05-07. To obtain a new or tweaked
   version of this certificate in the future, simply run certbot
   again. To non-interactively renew *all* of your certificates, run
   "certbot renew"
 - If you like Certbot, please consider supporting our work by:

   Donating to ISRG / Let's Encrypt:   https://letsencrypt.org/donate
   Donating to EFF:                    https://eff.org/donate-le
```

#### 9.4. Configuración de postfix y dovecot

* Adoptaremos la siguiente configuración en postfix

`sudo nano /etc/postfix/main.cf`

```sh
# See /usr/share/postfix/main.cf.dist for a commented, more complete version
# Debian specific:  Specifying a file name will cause the first
# line of that file to be used as the name.  The Debian default
# is /etc/mailname.
#myorigin = /etc/mailname

smtpd_banner = $myhostname ESMTP $mail_name (Debian/GNU)
biff = no

# appending .domain is the MUA's job.
append_dot_mydomain = no

# Uncomment the next line to generate "delayed mail" warnings
#delay_warning_time = 4h

readme_directory = no

# See http://www.postfix.org/COMPATIBILITY_README.html -- default to 2 on
# fresh installs.
compatibility_level = 2

# TLS parameters
smtpd_tls_cert_file=/etc/ssl/certs/ssl-cert-snakeoil.pem
smtpd_tls_key_file=/etc/ssl/private/ssl-cert-snakeoil.key
smtpd_use_tls=yes
smtpd_tls_session_cache_database = btree:${data_directory}/smtpd_scache
smtp_tls_session_cache_database = btree:${data_directory}/smtp_scache

# See /usr/share/doc/postfix/TLS_README.gz in the postfix-doc package for
# information on enabling SSL in the smtp client.

smtpd_relay_restrictions = permit_mynetworks permit_sasl_authenticated defer_unauth_destination
myhostname = kiara.iesgn05.es
alias_maps = hash:/etc/aliases
alias_database = hash:/etc/aliases
myorigin = /etc/mailname
mydestination = $myhostname, iesgn05.es, kiara.iesgn05.es, localhost.iesgn05.es, localhost
relayhost =
mynetworks = 127.0.0.0/8 [::ffff:127.0.0.0]/104 [::1]/128
mailbox_size_limit = 0
recipient_delimiter = +
inet_interfaces = all
inet_protocols = all

# Con esta línea alojaremos los correos en /Maildir/
home_mailbox = Maildir/

# SMTP-Auth settings
# Esta es la configuración adoptada para dovecot
smtpd_sasl_type = dovecot
smtpd_sasl_path = private/auth
smtpd_sasl_auth_enable = yes
smtpd_sasl_security_options = noanonymous
smtpd_sasl_local_domain = $myhostname
smtpd_recipient_restrictions = permit_mynetworks,permit_auth_destination,permit_sasl_authenticated,reject
```

* Editamos el fichero de configuración de los permisos de acceso para postfix

`nano /etc/dovecot/conf.d/10-auth.conf`

```sh
# Disable LOGIN command and all other plaintext authentications unless
# SSL/TLS is used (LOGINDISABLED capability). Note that if the remote IP
# matches the local IP (ie. you're connecting from the same computer), the
# connection is considered secure and plaintext authentication is allowed.
# See also ssl=required setting.
disable_plaintext_auth = no

. . .

# En este fichero nos aseguramos que se encuentra esta configuracion
auth_mechanisms = plain
```

**¡¡ATENCIÓN!!**

En la primera linea si la descomentamos e indicamos un 'no' , tenemos que ser conscientes de que la seguridad de nuestro servidor está en juego. Se recomienda dejarlo en 'yes' para que los usuarios se autentifiquen sólo a través de conexiones seguras con SSL/TLS. **Utilizar IMAP sin SSL/TLS se considera imprudente.**
En este caso le indicaremos que no, ya que, tendremos la configuracion tipo SSL como 'yes'.


* Cambiamos la configuracion del siguiente fichero de la siguiente manera, estamos modificando la ruta de donde se guardan los correos al directorio personal en la raiz donde se encuentra Maildir.

`sudo nano /etc/dovecot/conf.d/10-mail.conf`

```sh
#mail_location = mbox:~/mail:INBOX=/var/mail/%u
mail_location = maildir:~/Maildir

. . .

# Group to enable temporarily for privileged operations. Currently this is
# used only with INBOX when either its initial creation or dotlocking fails.
# Typically this is set to "mail" to give access to /var/mail.
mail_privileged_group = mail
mail_access_groups = mail

```

* Tendremos que crear también un CNAME en la zona dns que apunte a imap, y asegurarnos que el puerto 143 y el 993 estén abiertos.


* Miramos si los puertos están abiertos

```sh
debian@kiara:~$ sudo netstat -putona | grep '143'
tcp        0      0 0.0.0.0:143             0.0.0.0:*               LISTEN      313/dovecot          off (0.00/0/0)
tcp6       0      0 :::143                  :::*                    LISTEN      313/dovecot          off (0.00/0/0)


debian@kiara:~$ sudo netstat -putona | grep '993'
tcp        0      0 0.0.0.0:993             0.0.0.0:*               LISTEN      1096/dovecot         off (0.00/0/0)
tcp6       0      0 :::993                  :::*                    LISTEN      1096/dovecot         off (0.00/0/0)

```

* Creamos el CNAME en la zona DNS

![imap.png](/images/ovh_correo/imap.png)


* Habilitamos la opción 'protocols' estableciendo como valor imap

`sudo nano /etc/dovecot/dovecot.conf`

```sh
# Añadir la siguiente linea
protocols = imap
# Buscar y descomentar la siguiete línea
listen = *, ::
```

* Comprobamos que está habilitada la configuación para ssl, pero en este caso hemos reemplazado los antiguos certificados por los que hemos creado con **letsencrypt**. Estos certificados los hemos copiado al directorio **/ect/dovecot/private**

`sudo nano /etc/dovecot/conf.d/10-ssl.conf`

```sh
## SSL settings

# SSL/TLS support: yes, no, required. <doc/wiki/SSL.txt>
ssl = yes

# PEM encoded X.509 SSL/TLS certificate and private key. They're opened before
# dropping root privileges, so keep the key file unreadable by anyone but
# root. Included doc/mkcert.sh can be used to easily generate self-signed
# certificate, just make sure to update the domains in dovecot-openssl.cnf

#ssl_cert = </etc/dovecot/private/dovecot.pem
#ssl_key = </etc/dovecot/private/dovecot.key

ssl_cert = </etc/dovecot/private/fullchain.pem
ssl_key = </etc/dovecot/private/privkey.pem

```

* Comprobamos nuestra configuracion de **postfix**

```sh
debian@kiara:~$ sudo postconf -n
alias_database = hash:/etc/aliases
alias_maps = hash:/etc/aliases
append_dot_mydomain = no
biff = no
compatibility_level = 2
home_mailbox = Maildir/
inet_interfaces = all
inet_protocols = all
mailbox_size_limit = 0
mydestination = $myhostname, iesgn05.es, kiara.iesgn05.es, localhost.iesgn05.es, localhost
myhostname = kiara.iesgn05.es
mynetworks = 127.0.0.0/8 [::ffff:127.0.0.0]/104 [::1]/128
myorigin = /etc/mailname
readme_directory = no
recipient_delimiter = +
relayhost =
smtp_tls_session_cache_database = btree:${data_directory}/smtp_scache
smtpd_banner = $myhostname ESMTP $mail_name (Debian/GNU)
smtpd_recipient_restrictions = permit_mynetworks,permit_auth_destination,permit_sasl_authenticated,reject
smtpd_relay_restrictions = permit_mynetworks permit_sasl_authenticated defer_unauth_destination
smtpd_sasl_auth_enable = yes
smtpd_sasl_local_domain = $myhostname
smtpd_sasl_path = private/auth
smtpd_sasl_security_options = noanonymous
smtpd_sasl_type = dovecot
smtpd_tls_cert_file = /etc/ssl/certs/ssl-cert-snakeoil.pem
smtpd_tls_key_file = /etc/ssl/private/ssl-cert-snakeoil.key
smtpd_tls_session_cache_database = btree:${data_directory}/smtpd_scache
```


* Reiniciamos los servicios

```sh
sudo systemctl restart postfix
sudo systemctl restart dovecot
```

* Comprobamos los puertos

```sh
debian@kiara:~$ sudo netstat -tlpn
Active Internet connections (only servers)
Proto Recv-Q Send-Q Local Address           Foreign Address         State       PID/Program name
tcp        0      0 0.0.0.0:993             0.0.0.0:*               LISTEN      20901/dovecot
tcp        0      0 0.0.0.0:3306            0.0.0.0:*               LISTEN      658/mysqld
tcp        0      0 0.0.0.0:143             0.0.0.0:*               LISTEN      20901/dovecot
tcp        0      0 0.0.0.0:22              0.0.0.0:*               LISTEN      568/sshd
tcp        0      0 0.0.0.0:25              0.0.0.0:*               LISTEN      20572/master
tcp6       0      0 :::993                  :::*                    LISTEN      20901/dovecot
tcp6       0      0 :::143                  :::*                    LISTEN      20901/dovecot
tcp6       0      0 :::22                   :::*                    LISTEN      568/sshd
tcp6       0      0 :::25                   :::*                    LISTEN      20572/master
```

#### 9.5. Cuenta de correo en Evolution

* Ahora vamos a ir a Evolution desde nuestra máquina anfitriona. Y seguiremos los siguientes pasos:

> Archivo > Nuevo > Cuenta de correo

Indicamos la dirección de correo que en este caso es **debian@iesgn05.es** y el nombre que le vayamos a poner a la cuenta para identificarla.

![f1.png](/images/ovh_correo/f1.png)

Una vez verificada la direccion del servidor nos mostrará el protocolo que ofrece, en este caso solo estamos ofreciendo IMAP por lo que se nos pondrá por defecto.

Añadiremos el servidor donde ofrecemos imap, en este caso es **imap.iesgn05.es** que es el CNAME que agregamos previamente a nuestro DNS. Indicaremos el puerto 993 ya que, es el puerto seguro por donde va cifrada la conexión, con el método de cifrado TLS como habiamos configurado en los ficheros anteriormente.

La autentificación será por contraseña, en este caso es la contraseña de nuestro usuario debian.

![f2.png](/images/ovh_correo/f2.png)

Dejaremos por defecto las opciones de recepción

![f3.png](/images/ovh_correo/f3.png)

En este apartado veremos que se usará SMTP para la conexión al servidor. Indicaremos  en este caso es **smtp.iesgn05.es** y el puerto 465. (Esto aún no funcionará porque no hemos habilitado el SMPTPS)

![SMTP.png](/images/ovh_correo/SMTP.png)

Aquí nos mostrará un resumen de nuestra configuración

![ev5.png](/images/ovh_correo/ev5.png)

Si previamente en la configuración no hemos cambiado los certificados nos pasará lo siguiente:
______________________________
Le daremos a Siguiente y nos preguntará por el certificado que hemos proporcionado, como no esta firmado por una autoridad certificadora conocida nos preguntará si queremos aceptarla. En este caso como sabemos que es nuestra le damos a Aceptar permanentemente.

![confianza.png](/images/ovh_correo/confianza.png)
___________________

Pero en este caso no nos lo ha preguntado porque confía en nuestro certificado expedido por Let's Encrypt.

Ahora podemos comprobar que se ha sincronizado por el protocolo IMAP nuestra cuenta de correo en Evolution, en la siguiente imagen podemos ver todos los correos de prueba que hemos recibido y se encuentran en la bandeja de entrada:

![finalconcertificado.png](/images/ovh_correo/finalconcertificado.png)


### Prueba de funcionamiento


Vamos a enviar un correo desde Gmail a debian@iesgn05.es y comprobamos que llega a la bandeja de entrada:


![prueba1.png](/images/ovh_correo/prueba1.png)


![prueba2.png](/images/ovh_correo/prueba2.png)


Podemos ver el log de la prueba que hemos realizado

```sh
debian@kiara:~$ sudo tail -f  /var/log/mail.log
Feb  9 20:10:34 kiara dovecot: imap-login: Login: user=<debian>, method=PLAIN, rip=46.234.128.74, lip=146.59.196.84, mpid=22103, TLS, session=<ieAV4ey6Phgu6oBK>
Feb  9 20:10:36 kiara postfix/smtpd[22106]: warning: database /etc/aliases.db is older than source file /etc/aliases
Feb  9 20:10:36 kiara postfix/smtpd[22106]: connect from mail-oo1-f41.google.com[209.85.161.41]
Feb  9 20:10:36 kiara postfix/smtpd[22106]: DFE3E620CB: client=mail-oo1-f41.google.com[209.85.161.41]
Feb  9 20:10:36 kiara postfix/cleanup[22115]: DFE3E620CB: message-id=<CA+p9fxpwk2ggF9rrYUC77m6Dm1cViAuqz7vz5+W8hAAV==KQWw@mail.gmail.com>
Feb  9 20:10:36 kiara postfix/qmgr[20575]: DFE3E620CB: from=<cgarmai95@gmail.com>, size=2927, nrcpt=1 (queue active)
Feb  9 20:10:36 kiara postfix/local[22116]: warning: database /etc/aliases.db is older than source file /etc/aliases
Feb  9 20:10:36 kiara postfix/local[22116]: DFE3E620CB: to=<debian@iesgn05.es>, relay=local, delay=0.02, delays=0.01/0.01/0/0, dsn=2.0.0, status=sent (delivered to maildir)
Feb  9 20:10:36 kiara postfix/qmgr[20575]: DFE3E620CB: removed
Feb  9 20:10:37 kiara postfix/smtpd[22106]: disconnect from mail-oo1-f41.google.com[209.85.161.41] ehlo=2 starttls=1 mail=1 rcpt=1 bdat=1 quit=1 commands=7


```
### Tarea 11: Mandar correos desde un cliente remoto.

**Descripción:**

Configura de manera adecuada postfix para que podamos mandar un correo desde un cliente remoto. La conexión entre cliente y servidor debe estar autentificada con SASL usando dovecor y además debe estar cifrada. Para cifrar esta comunicación puedes usar dos opciones:

* ESMTP + STARTTLS: Usando el puerto 567/tcp enviamos de forma segura el correo al servidor.
* SMTPS: Utiliza un puerto no estándar (465) para SMTPS (Simple Mail Transfer Protocol Secure). No es una extensión de smtp. Es muy parecido a HTTPS.

Elige una de las opciones anterior para realizar el cifrado. Y muestra la configuración de un cliente de correo (evolution, thunderbird, …) y muestra como puedes enviar los correos.

#### 11.1. SMTPS. Configuración

Previamente hemos agregado un CNAME indicando smtp.iesgn05.es para kiara.iesgn05.es en la zona DNS.

Ahora vamos a intentar mandar un correo desde el servidor a gmail. 

Creamos el certificado con LetsEncrypt para smtp, previamente hemos creado un CNAME con SMTP para kiara.iesgn05.es

```sh
sudo certbot certonly --standalone -d smtp.iesgn05.es
```

* Para usar SMTPS hay que descomentar las siguientes lineas

`sudo nano /etc/postfix/master.cf`

```sh
smtp      inet  n       -       y       -       -       smtpd
smtps     inet  n       -       y       -       -       smtpd
  -o syslog_name=postfix/smtps
  -o smtpd_tls_wrappermode=yes
  -o smtpd_sasl_auth_enable=yes
  -o smtpd_client_restrictions=$mua_client_restrictions
  -o milter_macro_daemon_name=ORIGINATING
```


* Editamos el fichero de configuracion de postfix, cambiamos la configuracion indicando los nuevos certificados. Añadiremos la siguiente configuración de forma que activamos TLS para que nuestros correos sean seguros y reconozcan los certificados.

```sh
debian@kiara:~$ sudo nano /etc/postfix/main.cf
```

```sh
...
# TLS parameters

smtpd_use_tls=yes
smtpd_tls_key_file = /etc/letsencrypt/live/smtp.iesgn05.es/privkey.pem
smtpd_tls_cert_file = /etc/letsencrypt/live/smtp.iesgn05.es/fullchain.pem
smtpd_tls_session_cache_database = btree:${data_directory}/smtpd_scache
smtp_tls_session_cache_database = btree:${data_directory}/smtp_scache

smtp_tls_security_level = may
smtpd_tls_security_level = may
smtp_tls_note_starttls_offer = yes
smtpd_tls_loglevel = 1
smtpd_tls_received_header = yes
...
```

* Reiniciamos los servicios
```sh
debian@kiara:~$ sudo systemctl restart postfix
debian@kiara:~$ sudo systemctl restart dovecot
```

* Comprobamos los puertos. Vemos que se ha abierto el puerto 465 de SMTPS

```sh
debian@kiara:~/Maildir/new$ sudo netstat -tlnp
Active Internet connections (only servers)
Proto Recv-Q Send-Q Local Address           Foreign Address         State       PID/Program name    
tcp        0      0 0.0.0.0:993             0.0.0.0:*               LISTEN      32704/dovecot       
tcp        0      0 0.0.0.0:3306            0.0.0.0:*               LISTEN      658/mysqld          
tcp        0      0 0.0.0.0:143             0.0.0.0:*               LISTEN      32704/dovecot       
tcp        0      0 0.0.0.0:465             0.0.0.0:*               LISTEN      1157/master         
tcp        0      0 0.0.0.0:22              0.0.0.0:*               LISTEN      568/sshd            
tcp        0      0 0.0.0.0:25              0.0.0.0:*               LISTEN      1157/master         
tcp6       0      0 :::993                  :::*                    LISTEN      32704/dovecot       
tcp6       0      0 :::143                  :::*                    LISTEN      32704/dovecot       
tcp6       0      0 :::465                  :::*                    LISTEN      1157/master         
tcp6       0      0 :::22                   :::*                    LISTEN      568/sshd            
tcp6       0      0 :::25                   :::*                    LISTEN      1157/master      
```

#### Funcionamiento

* En Evolution cambiamos la configuracion de smtp de la siguiente forma

![SMTP.png](/images/ovh_correo/SMTP.png)


* Probamos enviar algun correo al nuestro personal

![pruebae.png](/images/ovh_correo/pruebae.png)


* Vemos que lo hemos recibido en gmail correctamente y conoce el certificado ya que está expedido por la autoridad de LetsEncrypt

![recibido.png](/images/ovh_correo/recibido.png)

![recibido2.jpeg](/images/ovh_correo/recibido2.jpeg)

* Lo contestamos y comprobamos que recibe y envía correctamente correos

![recibidook.png](/images/ovh_correo/recibidook.png)