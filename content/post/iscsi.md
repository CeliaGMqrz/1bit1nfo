+++
author = "Celia García Márquez"
title = "ISCSI"
date = "2021-04-07"
description = "Configurar un servidor ISCSI"
tags = [
    "ISCSI", "almacenamiento",
]
thumbnail= "images/iscsi/iscsi.png"
+++

## Conceptos previos 

**¿Qué es ISCSI?**

Así a grandes rasgos se utiliza principalmente en redes de almacenamiento y proporciona acceso a dispositivos de bloque sobre TCP/IP. Es un protocolo a nivel de aplicación que como hemos dicho anteriormente permite el acceso a un dispositivo de almacenamiento de forma remota y segura.


```sh
# -*- mode: ruby -*-
# vi: set ft=ruby :


Vagrant.configure("2") do |config|
  disco = '.vagrant/midisco.vdi'
  config.vm.define :nodo1 do |nodo1|
    nodo1.vm.box = "debian/buster64"
    nodo1.vm.hostname = "nodo1"
    nodo1.vm.network :public_network, :bridge=>"wlp2s0"
    nodo1.vm.network :private_network, ip: "10.0.0.2"
    nodo1.vm.provider :virtualbox do |v|
      v.customize ["createhd", "--filename", disco, "--size", 1024]
      v.customize ["storageattach", :id, "--storagectl", "SATA Controller", "--port", 1, "--device", 0, "--type", "hdd", "--medium", disco]
    end
  end
  config.vm.define :nodo2 do |nodo2|
    nodo2.vm.box = "debian/buster64"
    nodo2.vm.hostname = "nodo2"
    nodo2.vm.network :private_network, ip: "10.0.0.3"
  end
end
```

## Tarea:
Configura un escenario con vagrant o similar que incluya varias máquinas que permita realizar la configuración de un servidor iSCSI y dos clientes (uno linux y otro windows). Explica de forma detallada en la tarea los pasos realizados.

Crea un target con una LUN y conéctala a un cliente GNU/Linux. Explica cómo escaneas desde el cliente buscando los targets disponibles y utiliza la unidad lógica proporcionada, formateándola si es necesario y montándola.
Utiliza systemd mount para que el target se monte automáticamente al arrancar el cliente
Crea un target con 2 LUN y autenticación por CHAP y conéctala a un cliente windows. Explica cómo se escanea la red en windows y cómo se utilizan las unidades nuevas (formateándolas con NTFS)