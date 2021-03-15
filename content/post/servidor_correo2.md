---
title: "Servidor de Correos. Postfix (II). Alias y Redirecciones."
date: 2021-01-22T12:48:10+01:00
draft: false
toc: false
images:
tags: ['servidor correos','alias','redirecciones','postfix']
---

### 1. Uso de cron para notificar a root de una tarea

Vamos a comprobar como los procesos del servidor pueden mandar correos para informar sobre su estado. Por ejemplo cada vez que se ejecuta una tarea cron podemos enviar un correo informando del resultado. Normalmente estos correos se mandan al usuario root del servidor, para ello:

Vamos a crear un script sencillo que muestre las 10 últimas líneas de log de postfix:

```sh
# Creamos el script
nano /root/mostrar_log_mail.sh

#Con el siguiente contenido

#!/bin/sh

tail -n10 /var/log/mail.log

#Le damos los permisos oportunos y lo ejecutamos para ver que funciona

chmod 744 mostrar_log_mail.sh
bash mostrar_log_mail.sh

```

* Ahora ejecutamos el crontab -e, para inicializar la tarea y le indicamos a quien va ir dirigido el correo, en este caso a ROOT. 

`crontab -e`

```sh
debian@kiara:~$ crontab -e
no crontab for debian - using an empty one

Select an editor.  To change later, run 'select-editor'.
  1. /usr/bin/joe
  2. /usr/bin/jstar
  3. /usr/bin/jpico
  4. /usr/bin/jmacs
  5. /bin/nano        <---- easiest
  6. /usr/bin/vim.basic
  7. /usr/bin/rjoe
  8. /usr/bin/vim.tiny

Choose 1-8 [5]:  
crontab: installing new crontab
```

* Indicamos donde se va a enviar el correo cada vez que ejecute

```sh
MAILTO= root
```
* Ejecutamos **mail** con el usuario root y comprobamos que tenemos un correo mostrando el log

```sh
root@kiara:~# mail
Mail version 8.1.2 01/15/2001.  Type ? for help.
"/var/mail/root": 2 messages 2 new
>N  1 root@kiara.iesgn0  Mon Jan 25 10:39   22/783   Cron <debian@kiara> /root/mostrar_log_mail.sh
 N  2 root@kiara.iesgn0  Mon Jan 25 10:39   31/1832  Cron <root@kiara> /root/mostrar_log_mail.sh
& w
No file specified.
& 2
Message 2:
From root@kiara.iesgn05.es  Mon Jan 25 10:39:01 2021
X-Original-To: root
From: root@kiara.iesgn05.es (Cron Daemon)
To: root@kiara.iesgn05.es
Subject: Cron <root@kiara> /root/mostrar_log_mail.sh
MIME-Version: 1.0
Content-Type: text/plain; charset=UTF-8
Content-Transfer-Encoding: 8bit
X-Cron-Env: <MAILTO=root>
X-Cron-Env: <SHELL=/bin/sh>
X-Cron-Env: <HOME=/root>
X-Cron-Env: <PATH=/usr/bin:/bin>
X-Cron-Env: <LOGNAME=root>
Date: Mon, 25 Jan 2021 10:39:01 +0000 (UTC)

Jan 25 10:38:01 kiara postfix/pickup[29459]: 1610A4231B: uid=1000 from=<debian>
Jan 25 10:38:01 kiara postfix/cleanup[29250]: 1610A4231B: message-id=<20210125103801.1610A4231B@kiara.iesgn05.es>
Jan 25 10:38:01 kiara postfix/qmgr[27861]: 1610A4231B: from=<debian@kiara.iesgn05.es>, size=649, nrcpt=1 (queue active)
Jan 25 10:38:01 kiara postfix/local[29253]: 1610A4231B: to=<root@kiara.iesgn05.es>, orig_to=<root>, relay=local, delay=0.01, delays=0.01/0/0/0, dsn=2.0.0, status=sent (delivered to mailbox)
Jan 25 10:38:01 kiara postfix/qmgr[27861]: 1610A4231B: removed
Jan 25 10:38:01 kiara postfix/pickup[29459]: 18E484231B: uid=0 from=<root>
Jan 25 10:38:01 kiara postfix/cleanup[29250]: 18E484231B: message-id=<20210125103801.18E484231B@kiara.iesgn05.es>
Jan 25 10:38:01 kiara postfix/qmgr[27861]: 18E484231B: from=<root@kiara.iesgn05.es>, size=784, nrcpt=1 (queue active)
Jan 25 10:38:01 kiara postfix/local[29253]: 18E484231B: to=<root@kiara.iesgn05.es>, orig_to=<root>, relay=local, delay=0.01, delays=0/0/0/0, dsn=2.0.0, status=sent (delivered to mailbox)
Jan 25 10:38:01 kiara postfix/qmgr[27861]: 18E484231B: removed

& quit
Saved 1 message in /root/mbox
Held 1 message in /var/mail/root
You have mail in /var/mail/root
root@kiara:~# nano mostrar_log_mail.sh 
You have new mail in /var/mail/root

```

### 2. Alias y redirecciones para que nos llegue a un correo personal

Si queremos redireccionar los correos al usuario debian solo tenemos que indicarlo en el siguiente fichero

`/etc/aliases`

```sh
root: debian
```
Ejecutar

```sh
newaliases
```

Si abrimos el buzón de mail de **debian** veremos como se nos redirecciona 

```sh
root@kiara:~# mail
Mail version 8.1.2 01/15/2001.  Type ? for help.
"/var/mail/root": 2 messages 2 new
>N  1 root@kiara.iesgn0  Mon Jan 25 10:39   22/783   Cron <debian@kiara> /root/mostrar_log_mail.sh
```

Si además queremos que se redirecciona al exterior a **nuestro correo electrónico**, tenemos que crear el siguiente fichero

`nano /home/debian/.forward`

```sh
cgarmai95@gmail.com
```

Ejecutamos el script y comprobamos que se ha enviado un correo notificando su ejecución.

![redir_gmail.png](/images/ovh_correo/redir_gmail.png)

> Si queremos listar o eliminar las tareas de cron 

```sh
crontab -l
crontab -r
```