---
title: "Instalación: aplicación web CMS Wagtail con Python"
date: 2021-01-21T13:04:33+01:00
draft: false
toc: false
images:
tags: ['cms','python','djando','wagtail']
---

![wagtail.png](/images/escenario/django/wagtail.png)

## Objetivo:

Instalar un CMS en un entorno virtual y personalizar el sitio web con Wagtail

## 1. Instalación de wagtail.


### Entorno de desarrollo: Creación del entorno virtual.

* Primero tendremos que crear un [entorno virtual](https://github.com/CeliaGMqrz/trabajando_python3_venv) en nuestra máquina anfitriona.


### Instalación y configuracion de wagtail

* Dentro del entorno virtual instalaremos el cms wagtail

```sh
pip install wagtail
```

* Creamos el sitio. En su interior podemos ver que se han creado varios ficheros, entre ellos está el fichero 'requirements.txt' que es el que vamos a usar para instalar los paquetes necesarios

```sh
wagtail start mysite
cd mysite
pip install -r requirements.txt
```

* Ahora vamos a mirar la app, crear el usuario administrador y probar su funcionamiento

```sh
python manage.py migrate
```

```sh
(wagtail) celiagm@debian:~/venv/wagtail/mysite$ python manage.py createsuperuser
Username (leave blank to use 'celiagm'): celiagm
Email address: cgarmai95@gmail.com
Password: 
Password (again): 
The password is too similar to the email address.
Bypass password validation and create user anyway? [y/N]: y
Superuser created successfully.
```

```sh
(wagtail) celiagm@debian:~/venv/wagtail/mysite$ python manage.py runserver
Watching for file changes with StatReloader
Performing system checks...

System check identified no issues (0 silenced).
January 21, 2021 - 13:25:24
Django version 3.1.5, using settings 'mysite.settings.dev'
Starting development server at http://127.0.0.1:8000/
Quit the server with CONTROL-C.

```

![wag1.png](/images/escenario/django/wag1.png)

* Nos vamos a **http://127.0.0.1:8000/admin/** en el navegador y metemos las credenciales que hemos configurado anteriormente y nos saldrá la pagina para administrar el sitio web.

![wag2.png](/images/escenario/django/wag2.png)


## 2. Personalización del Sitio Web


He seguido un poco la [documentación de Wagtail](https://docs.wagtail.io/en/stable/getting_started/tutorial.html), para personalizar el sitio web y ahora tiene el siguiente aspecto.

![inicio.png](/images/escenario/django/inicio.png)


Se le ha añadido varios apartados entre ellos un blog, al que se puede acceder añadiendo /blog a la url.

![admin.png](/images/escenario/django/admin.png)

![blog.png](/images/escenario/django/blog.png)