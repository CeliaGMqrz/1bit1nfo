# Introducción a Kubernetes

* Instalación de minikube

```sh
curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube_latest_amd64.deb

sudo dpkg -i minikube_latest_amd64.deb

```

El proyecto kubernetes

Gestiona el despliegue de aplicaciones sobre contenedores, automatizando el despliegue, con énfasis en la escabilidad y controlando todo el ciclo de vida.

* Despliega aplicaciones rápidamente
* Escala aplicaciones al vuelo
* Integra cambios sin interrupciones
* Permite limitar los recursos a utilizar
* Es un proyecto centrado en la puesta en PRODUCCIÓN de contenedores y por tanto indicada su gestión para administradores de sistemas y personal de equipos de operaciones.
* Afecta a los desarrolladores, ya que las aplicaciones deben adaptarse para poder desplegarse en kubernetes.
* Puede desplegarse en nube
* Extensible: Módulos, plugins, adaptable
* Autoreparable
* 