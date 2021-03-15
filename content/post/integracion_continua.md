---
title: "Introducción a la integración continua y despliegue continuo"
date: 2021-03-08T12:53:56+01:00
draft: false
toc: false
images:
tags:
  - untagged
---


## Conceptos previos.

La **integración contínua** es un método por el cuál se hacen integraciones automáticas de un proyecto habitualmente en un periodo de tiempo muy corto para detectar los fallos cuanto antes. 

La integración es la compilación y ejecución de pruebas de un proyecto, como por ejemplo una página web estática que se despliega.

Se lleva un control de versiones, pruebas e informes. 

El **despliegue contínuo** es una técnica más avanzada que la integración continua, ya que no hay intervención humana posible, si no que la automatización es completa.

Para llevar acabo estas tareas podemos usar herramientas como: Jenkins, Travis, Gitlab, Github actions, CircleCi ... entre otras.

![despliegue.png](/images/icdc/despliegue.png)

## Despliegue de una página web estática (build, deploy)

En esta práctica vamos a generar una página web con **Hugo** y desplegarlo en **Netlify**.

No voy a detenerme en cómo crear la pagina estática con hugo, pero se puede ver en [este repositorio](https://github.com/CeliaGMqrz/gen_pagina_estatica_hugo).

Crearemos un nuevo proyecto con hugo y lo subiremos a un repositorio de github (sólo los ficheros markdown), añadimos un .gitignore para la carpeta public y la carpeta themes.

Repositorio -> [Celia's Home](https://github.com/CeliaGMqrz/celiashome)



