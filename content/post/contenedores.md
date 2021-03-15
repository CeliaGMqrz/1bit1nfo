---
title: "Introducción a Docker"
date: 2021-03-07T21:11:44+01:00
draft: false
toc: false
images:
tags: ['java','guacamole']
---

## Contenedores y aplicaciones

¿Qué son los contendores?

Son diferentes compartimentos en el que cada aplicación visualiza un sistema operativo virtualmente sin compartirlo con nadie. Aislamos cada aplicación en un compartimento. Instalaremos una aplicacion en cada contenedor. En cada contenedor podemos tener solo un proceso.

Con los contenedores podemos utilizar distintas versiones de software.

Es un mecanismo de virtualización ligera que permite al sistema operativo dar la sensación de aislamiento a cada proceso de forma que no compartimos recursos. No son maquinas virtuales ya que comparten el mismo kernel. 

Grupos de control de kernel linux- > limite de recursos.

Hasta ahora conocemos aplicaciones monolíticas que funcionan en un mismo nodo y comparten recursos. 
Aplicacion distribuida, un componente por nodo. 

## Introducción a Docker

El uso de los contenedores Docker es muy distinto a lo que hemos estado haciendo tradicionalmente en la instalacion de aplicaciones web por ejemplo y otros.

Docker significa 'estibador', 'el que mueve los contenedores en el puerto'. 

**Docker** fue una empresa que desarrolló este mecanismo. Cambia toda la forma del **despliegue de aplicaciones**. No compite con un sistema de virtualización. Gestiona **contenedores a un alto nivel**proporcionando todas las capas y funcionalidad adicional. Cambia la forma de distribuir la aplicación. Se crea el contenedor ya funcionando, **más rápido y eficaz**. La instalación y **gestión de los contenedores es muy simple**. El contenedor se ejecuta con un comando y se para cuando termina su función. Está **escrito en go** y es **software libre**.

**Docker engine**, es propiamente el software. En el que se distinguen tres capas: El **demonio** como tal de docker, que es el que se encarga de ejecutar el software, luego está **docker API** que es la capa de aplicacion y por último la capa **docker CLI** que es como el cliente por donde nosotros podemos acceder a la API y gestionar el software.

![capas.png](/images/docker/capas.png)


**Docker compose**: Se trata de un componente de docker que nos permite definir aplicaciones que corren en múltiples contenedores. Utiliza 'yml'. 