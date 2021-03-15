---
title: "Servidor de Correos. Postfix (I)"
date: 2021-01-22T12:48:10+01:00
draft: false
toc: false
images:
tags: ['servidor correos','spf','mailx','postfix']
---

![postfix.png](/images/ovh_correo/postfix.png)

## 1. Objetivo. 

Instalación y configuración de un servidor de correos en una máquina de OVH, para el dominio **iesgn05**. El nombre del servidor de correo será **mail.iesgn05.es**.

Configurar un registro **SPF**, que es un mecanismo de autenticación que mediante un registro DNS de tipo TXT describe las direcciones IPs y nombres DNS autorizados a enviar correo @DOMINIO. 

Suponiendo que el servidor de correo se llama **mail.iesgn05.es**, crearemos un registro MX siendo este **mail.iesgn05.es**, de la siguiente forma en el panel de ovh.

![registromx.png](/images/ovh_correo/registromx1.png)

Además **mail** será un **CNAME** de kiara.iesgn05.es

![cname.png](/images/ovh_correo/cname.png)

## 2. Gestión de correos desde el servidor

### 2.1. Instalación del servidor de correos

Para instalar el servidor de correos vamos a descargar e instalar el paquete
**postfix**  y la utilidad **bsd-mailx**  para leer los correos.

```sh
sudo apt-get install postfix bsd-mailx
```

Cuando instalemos postfix, dejaremos la configuración por defecto por el momento, dejando la opción 'Internet Site', le indicaremos que el dominio de nuestro correo será **iesgn05.es**. Este dominio se puede configurar en el fichero **/etc/mailname**.

### 2.2. Enviar un correo de prueba desde el servidor de correos al exterior

**Tarea 1**: Documenta una prueba de funcionamiento, donde envíes desde tu servidor local al exterior. Muestra el log donde se vea el envío. Muestra el correo que has recibido. Muestra el registro SPF.

* Mandamos el correo de prueba:

```sh
debian@kiara:~$ mail cgarmai95@gmail.com
Subject: Prueba Postfix
Hola esto es una prueba para la tarea de postfix
Cc: 
You have mail in /var/mail/debian
```

* Comprobamos que nos llega el correo

![correo1.png](/images/ovh_correo/correo1.png)

*  Mostramos el log

```sh
debian@kiara:~$ sudo tail  /var/log/mail.log
Feb  2 12:49:27 kiara postfix/smtpd[1636]: connect from unknown[193.56.29.44]
Feb  2 12:49:27 kiara postfix/smtpd[1636]: disconnect from unknown[193.56.29.44] ehlo=1 auth=0/1 rset=1 quit=1 commands=3/4
Feb  2 12:52:47 kiara postfix/anvil[1638]: statistics: max connection rate 1/60s for (smtp:209.85.167.181) at Feb  2 12:48:57
Feb  2 12:52:47 kiara postfix/anvil[1638]: statistics: max connection count 1 for (smtp:209.85.167.181) at Feb  2 12:48:57
Feb  2 12:52:47 kiara postfix/anvil[1638]: statistics: max cache size 2 at Feb  2 12:49:27
Feb  2 12:57:45 kiara postfix/pickup[1551]: C4F0661F15: uid=1000 from=<debian>
Feb  2 12:57:45 kiara postfix/cleanup[1696]: C4F0661F15: message-id=<20210202125745.C4F0661F15@kiara.iesgn05.es>
Feb  2 12:57:45 kiara postfix/qmgr[1552]: C4F0661F15: from=<debian@iesgn05.es>, size=448, nrcpt=1 (queue active)
Feb  2 12:57:46 kiara postfix/smtp[1698]: C4F0661F15: to=<cgarmai95@gmail.com>, relay=gmail-smtp-in.l.google.com[64.233.167.27]:25, delay=0.81, delays=0.02/0.01/0.4/0.39, dsn=2.0.0, status=sent (250 2.0.0 OK  1612270666 y16si2203772wmi.219 - gsmtp)
Feb  2 12:57:46 kiara postfix/qmgr[1552]: C4F0661F15: removed

```

* Mostrar registro SPF

![spf1.png](/images/ovh_correo/spf1.png)

![spf2.png](/images/ovh_correo/spf2.png)

![spf3.png](/images/ovh_correo/spf3.png)

### 2.2. Enviar un correo de prueba del exterior al servidor de correos

**Tarea 2**: Documenta una prueba de funcionamiento, donde envíes un correo desde el exterior (gmail, hotmail,…) a tu servidor local. Muestra el log donde se vea el envío. Muestra cómo has leído el correo. Muestra el registro MX de tu dominio.


* Enviamos el correo de prueba

![correo3.png](/images/ovh_correo/correo3.png)

* Mostramos el log del envio

```sh
MIME-Version: 1.0
Date: Tue, 2 Feb 2021 14:04:59 +0100
Message-ID: <CA+p9fxqyBkUsnr5Yt6Rn-SXZBbtxLCkgnfYPF7cLijtyuW6rfA@mail.gmail.com>
Subject: Prueba desde gmail a kiara
From: "Celia García Márquez" <cgarmai95@gmail.com>
To: Debian <debian@iesgn05.es>
Content-Type: multipart/alternative; boundary="0000000000002f3ef505ba5a1eb0"

--0000000000002f3ef505ba5a1eb0
Content-Type: text/plain; charset="UTF-8"
Content-Transfer-Encoding: quoted-printable

Hola que tal
--=20
*Atte. Celia Garc=C3=ADa M=C3=A1rquez*

--0000000000002f3ef505ba5a1eb0
Content-Type: text/html; charset="UTF-8"
Content-Transfer-Encoding: quoted-printable

<div dir=3D"ltr"><br clear=3D"all"><div>Hola que tal</div>-- <br><div dir=
=3D"ltr" class=3D"gmail_signature" data-smartmail=3D"gmail_signature"><div =
dir=3D"ltr"><i>Atte. Celia Garc=C3=ADa M=C3=A1rquez</i></div></div></div>

--0000000000002f3ef505ba5a1eb0--
```

* Comprobamos que nos ha llegado el correo, vemos el mendaje con la utilidad `mail`

```sh
Message 2:
From cgarmai95@gmail.com  Tue Feb  2 13:05:11 2021
X-Original-To: debian@iesgn05.es
DKIM-Signature: v=1; a=rsa-sha256; c=relaxed/relaxed;
        d=gmail.com; s=20161025;
        h=mime-version:from:date:message-id:subject:to;
        bh=maUT1zl1aFw8XLXYFAOZU0IOOc11ZQ/6jx4DBNw3yLE=;
        b=bW4Oc6T+/mxK0rs2yU1nsJOMnYFk9k6aZNbW0OYjbNhmojxgq/KRhilSDcXwd2uNuD
         XD5cgKurDhiEN/KBxAQ02HebFwBkpXXAqTHaKBq93tbVEVeiKwP23zmdIyC15F5d5DTZ
         e3Ldy0SgMb2MBVBZbCxBaRhEt29GhWZ3xy8iNQxDvmUgh5uuJWkSRvyhVj5LlxVrNojY
         mRbTeHrfiGDBis12GNcjBrMqFI3iT7iv9WWkZSb41V/UzcVsH7y+Eszw38R+2qIF32DK
         CCY846MJ7j1w2dGwXiGFKuU6sa9rm3KiQVFa4SHqkQyLYtPpHGzbdj3HS2/bCUnVYyhm
         g03A==
X-Google-DKIM-Signature: v=1; a=rsa-sha256; c=relaxed/relaxed;
        d=1e100.net; s=20161025;
        h=x-gm-message-state:mime-version:from:date:message-id:subject:to;
        bh=maUT1zl1aFw8XLXYFAOZU0IOOc11ZQ/6jx4DBNw3yLE=;
        b=ogIOae0bD2FjhHW9NPoLTLB/9rCSViFOYYqwPlzQyAlWnr6eR08nZw8GGYH4YlTa29
         HBLvcAspZ2V+yKp2lqgYFl3ss0InMVOeLKYYFsaNhDxgVNfTNs6woifu867g09UN68Lp
         gs0rCoKPIfBlrhlqSbGGOQtLH84SEuG1N+34e5K2JIidrwywJ6BcGP4oZ2DEl3kv0Ix1
         ExJN5ahfGJF2FQrxzMyYwE5Cc0cZ8KOHeGkN6dx92fAxFUZr4+0moADSOCc/81PWoIpP
         /6z8AxxhKdtGPM9u8fH3gdnb/86Q1Gr/lTZkLAM7errvBY6Zc9Ltsih2kqrDRAjyzaoi
         CCug==
X-Gm-Message-State: AOAM532/qsslGhRD+9WipCJyDD31ZwFieJqoUCOw/ubHeX28zBYqpVMy
        QU/VpMTn38JwS/iKo/mw8oQZhZjaGVJYwbGNrQ5A/UMNqi//dw==
X-Google-Smtp-Source: ABdhPJzX7CidzRiM76WU6nBIX72hHFyIQlQcSlWOmle/Bp7QIbR/J3P1bI1aFSHIV7GhKS6mi+SY+lWRrS9W0ahnXtk=
X-Received: by 2002:a05:6808:904:: with SMTP id w4mr2662510oih.160.1612271110121;
 Tue, 02 Feb 2021 05:05:10 -0800 (PST)
MIME-Version: 1.0
From: =?UTF-8?Q?Celia_Garc=C3=ADa_M=C3=A1rquez?= <cgarmai95@gmail.com>
Date: Tue, 2 Feb 2021 14:04:59 +0100
Subject: Prueba desde gmail a kiara
To: Debian <debian@iesgn05.es>
Content-Type: multipart/alternative; boundary="000000000000ccecca05ba5a1e91"

--000000000000ccecca05ba5a1e91
Content-Type: text/plain; charset="UTF-8"
Content-Transfer-Encoding: quoted-printable

Hola que tal
--=20
*Atte. Celia Garc=C3=ADa M=C3=A1rquez*

--000000000000ccecca05ba5a1e91
Content-Type: text/html; charset="UTF-8"
Content-Transfer-Encoding: quoted-printable

<div dir=3D"ltr"><br clear=3D"all"><div>Hola que tal</div>-- <br><div dir=
=3D"ltr" class=3D"gmail_signature" data-smartmail=3D"gmail_signature"><div =
dir=3D"ltr"><i>Atte. Celia Garc=C3=ADa M=C3=A1rquez</i></div></div></div>

--000000000000ccecca05ba5a1e91--
```

* Registro MX de mi dominio

![correo4.png](/images/ovh_correo/correo4.png)

```sh
celiagm@debian:~$ dig mx gmail.com

; <<>> DiG 9.11.5-P4-5.1+deb10u2-Debian <<>> mx gmail.com
;; global options: +cmd
;; Got answer:
;; ->>HEADER<<- opcode: QUERY, status: NOERROR, id: 7515
;; flags: qr rd ra; QUERY: 1, ANSWER: 5, AUTHORITY: 4, ADDITIONAL: 9

;; OPT PSEUDOSECTION:
; EDNS: version: 0, flags:; udp: 4096
; COOKIE: 0f190ff7eb9f031ae3a4a3c160194ecd3909e7e1206a7f73 (good)
;; QUESTION SECTION:
;gmail.com.			IN	MX

;; ANSWER SECTION:
gmail.com.		1928	IN	MX	40 alt4.gmail-smtp-in.l.google.com.
gmail.com.		1928	IN	MX	30 alt3.gmail-smtp-in.l.google.com.
gmail.com.		1928	IN	MX	20 alt2.gmail-smtp-in.l.google.com.
gmail.com.		1928	IN	MX	5 gmail-smtp-in.l.google.com.
gmail.com.		1928	IN	MX	10 alt1.gmail-smtp-in.l.google.com.

;; AUTHORITY SECTION:
gmail.com.		15078	IN	NS	ns1.google.com.
gmail.com.		15078	IN	NS	ns3.google.com.
gmail.com.		15078	IN	NS	ns2.google.com.
gmail.com.		15078	IN	NS	ns4.google.com.

;; ADDITIONAL SECTION:
ns1.google.com.		971	IN	A	216.239.32.10
ns2.google.com.		971	IN	A	216.239.34.10
ns3.google.com.		971	IN	A	216.239.36.10
ns4.google.com.		971	IN	A	216.239.38.10
ns1.google.com.		971	IN	AAAA	2001:4860:4802:32::a
ns2.google.com.		971	IN	AAAA	2001:4860:4802:34::a
ns3.google.com.		971	IN	AAAA	2001:4860:4802:36::a
ns4.google.com.		971	IN	AAAA	2001:4860:4802:38::a

;; Query time: 1 msec
;; SERVER: 192.168.202.2#53(192.168.202.2)
;; WHEN: mar feb 02 14:08:29 CET 2021
;; MSG SIZE  rcvd: 437

```