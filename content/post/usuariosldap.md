+++
author = "Celia García Márquez"
title = "Usuarios, grupos y ACLs en LDAP"
date = "2021-05-18"
description = "Usuarios en LDAP"
tags = [
    "LDAP","usuarios",
]
thumbnail= "images/ldap/banner.png"
+++

### Crear usuarios 

> **Crea 10 usuarios con los nombres que prefieras en LDAP, esos usuarios deben ser objetos de los tipos posixAccount e inetOrgPerson. Estos usuarios tendrán un atributo userPassword.**

* El atributo **posixAccount** implica tener:
  * cn (Nombre completo del usuario)
  * uid (identificador único de nombre) > 1000
  * gidNumber (Identificador de grupo) > 1000

* El atributo **inetOrgPerson** es un atributo que no requiere adicionales.

* El atributo **userPassword** lo obtenemos con el siguiente comando, especificando la contraseña del usuario, en mi caso lo he ejecutado manualmente ya que no son muchos usuarios pero podríamos hacerlo con un script.

```sh
debian@freston:~$ sudo slappasswd -h {SSHA}
New password: 
Re-enter new password: 
{SSHA}IWO9oVgji7cI/p/0hz2q/yt/c9mZDWX8
```

Creamos el fichero `usuarios.ldif` con el siguiente contenido:

```shell

dn: uid=celia,ou=People,dc=freston,dc=celia,dc=gonzalonazareno,dc=org
objectClass: posixAccount
objectClass: inetOrgPerson
objectClass: top
cn: Celia Garcia
gidNumber: 2001
homeDirectory: /home/celia
loginShell: /bin/bash
sn: celia
uid: celia
uidNumber: 2001
userPassword: {SSHA}IWO9oVgji7cI/p/0hz2q/yt/c9mZDWX8

dn: uid=maria,ou=People,dc=freston,dc=celia,dc=gonzalonazareno,dc=org
objectClass: posixAccount
objectClass: inetOrgPerson
objectClass: top
cn: Maria Jesus
gidNumber: 2002
homeDirectory: /home/maria
loginShell: /bin/bash
sn: maria
uid: maria
uidNumber: 2002
userPassword: {SSHA}aL6P65hiTDxWxRD1++7e/baB+hi7DQon

dn: uid=mario,ou=People,dc=freston,dc=celia,dc=gonzalonazareno,dc=org
objectClass: posixAccount
objectClass: inetOrgPerson
objectClass: top
cn: Mario Garcia
gidNumber: 2003
homeDirectory: /home/mario
loginShell: /bin/bash
sn: mario
uid: mario
uidNumber: 2003
userPassword: {SSHA}crEyszzAYZ34MwDgShygZpbQ0ouXR03p

dn: uid=joni,ou=People,dc=freston,dc=celia,dc=gonzalonazareno,dc=org
objectClass: posixAccount
objectClass: inetOrgPerson
objectClass: top
cn: Jonathan Marquez
gidNumber: 2004
homeDirectory: /home/joni
loginShell: /bin/bash
sn: joni
uid: joni
uidNumber: 2004
userPassword: {SSHA}fIj8uX/5620PtKXj6txJWRE1sfwIC7sW

dn: uid=adrian,ou=People,dc=freston,dc=celia,dc=gonzalonazareno,dc=org
objectClass: posixAccount
objectClass: inetOrgPerson
objectClass: top
cn: Adrian Garcia
gidNumber: 2005
homeDirectory: /home/adrian
loginShell: /bin/bash
sn: adri
uid: adrian
uidNumber: 2005
userPassword: {SSHA}0zmtwpE0l/LPP66t86OlA4HZrXIShlVr

dn: uid=ana,ou=People,dc=freston,dc=celia,dc=gonzalonazareno,dc=org
objectClass: posixAccount
objectClass: inetOrgPerson
objectClass: top
cn: Ana Rodriguez
gidNumber: 2006
homeDirectory: /home/ana
loginShell: /bin/bash
sn: ana
uid: ana
uidNumber: 2006
userPassword: {SSHA}d1oN9Uk36cp5xJ53Dbe8hHQhl4504+xY

dn: uid=lorena,ou=People,dc=freston,dc=celia,dc=gonzalonazareno,dc=org
objectClass: posixAccount
objectClass: inetOrgPerson
objectClass: top
cn: Lorena Garcia
gidNumber: 2007
homeDirectory: /home/lorena
loginShell: /bin/bash
sn: lorena
uid: lorena
uidNumber: 2007
userPassword: {SSHA}+itrewH/UYWCVoQDnXcvcr2fT3IO55t2

dn: uid=sara,ou=People,dc=freston,dc=celia,dc=gonzalonazareno,dc=org
objectClass: posixAccount
objectClass: inetOrgPerson
objectClass: top
cn: Sara Gonzalez
gidNumber: 2008
homeDirectory: /home/sara
loginShell: /bin/bash
sn: sara
uid: sara
uidNumber: 2008
userPassword: {SSHA}Yapb6M5GYjhUpyNSKpdWAI0lDzzaJ+rP

dn: uid=rosario,ou=People,dc=freston,dc=celia,dc=gonzalonazareno,dc=org
objectClass: posixAccount
objectClass: inetOrgPerson
objectClass: top
cn: Rosario Jadilla
gidNumber: 2009
homeDirectory: /home/rosario
loginShell: /bin/bash
sn: rosario
uid: rosario
uidNumber: 2009
userPassword: {SSHA}fdbK+kMk5BjZUyyy4SAi9KNOrExHZxkS

dn: uid=antonio,ou=People,dc=freston,dc=celia,dc=gonzalonazareno,dc=org
objectClass: posixAccount
objectClass: inetOrgPerson
objectClass: top
cn: Antonio Lainez
gidNumber: 2010
homeDirectory: /home/antonio
loginShell: /bin/bash
sn: antonio
uid: antonio
uidNumber: 2010
userPassword: {SSHA}XxOFWtmpAfaCY0fxF6JKuhZ69cq5iRkS

```

Ya creado el fichero ejecutamos el siguiente comando para agregar todos los usuarios:

```sh
ldapadd -x -D 'cn=admin,dc=freston,dc=celia,dc=gonzalonazareno,dc=org' -W -f usuarios.ldif
```
Vemos como se añaden los usuarios:
```sh
debian@freston:~$ ldapadd -x -D 'cn=admin,dc=freston,dc=celia,dc=gonzalonazareno,dc=org' -W -f usuarios.ldif
Enter LDAP Password: 

adding new entry "uid=celia,ou=People,dc=freston,dc=celia,dc=gonzalonazareno,dc=org"

adding new entry "uid=maria,ou=People,dc=freston,dc=celia,dc=gonzalonazareno,dc=org"

adding new entry "uid=mario,ou=People,dc=freston,dc=celia,dc=gonzalonazareno,dc=org"

adding new entry "uid=joni,ou=People,dc=freston,dc=celia,dc=gonzalonazareno,dc=org"

adding new entry "uid=adrian,ou=People,dc=freston,dc=celia,dc=gonzalonazareno,dc=org"

adding new entry "uid=ana,ou=People,dc=freston,dc=celia,dc=gonzalonazareno,dc=org"

adding new entry "uid=lorena,ou=People,dc=freston,dc=celia,dc=gonzalonazareno,dc=org"

adding new entry "uid=sara,ou=People,dc=freston,dc=celia,dc=gonzalonazareno,dc=org"

adding new entry "uid=rosario,ou=People,dc=freston,dc=celia,dc=gonzalonazareno,dc=org"

adding new entry "uid=antonio,ou=People,dc=freston,dc=celia,dc=gonzalonazareno,dc=org"

```

### Crear grupos 

> **Crea 3 grupos en LDAP dentro de una unidad organizativa diferente que sean objetos del tipo groupOfNames. Estos grupos serán: comercial, almacen y admin**

Creamos otro fichero pero esta vez para los grupos 

```sh
dn: cn=comercial,ou=Group,dc=freston,dc=celia,dc=gonzalonazareno,dc=org
objectClass: top
objectClass: groupOfNames
cn: comercial
member:

dn: cn=almacen,ou=Group,dc=freston,dc=celia,dc=gonzalonazareno,dc=org
objectClass: top
objectClass: groupOfNames
cn: almacen
member:

dn: cn=admin,ou=Group,dc=freston,dc=celia,dc=gonzalonazareno,dc=org
objectClass: top
objectClass: groupOfNames
cn: admin
member:
```

Los añadimos:

```sh
ldapadd -x -D cn=admin,dc=freston,dc=celia,dc=gonzalonazareno,dc=org -W -f grupos1.ldif
```

Vemos como se añaden:

```sh
debian@freston:~$ ldapadd -x -D cn=admin,dc=freston,dc=celia,dc=gonzalonazareno,dc=org -W -f grupos1.ldif
Enter LDAP Password: 
adding new entry "cn=comercial,ou=Group,dc=freston,dc=celia,dc=gonzalonazareno,dc=org"

adding new entry "cn=almacen,ou=Group,dc=freston,dc=celia,dc=gonzalonazareno,dc=org"

adding new entry "cn=admin,ou=Group,dc=freston,dc=celia,dc=gonzalonazareno,dc=org"

```

### Añadir usuarios

> **Añade usuarios que pertenezcan a:** 

> * **Solo al grupo comercial**

> * **Solo al grupo almacen**

> * **Al grupo comercial y almacen**

> * **Al grupo admin y comercial**

> * **Solo al grupo admin**

Creamos el fichero nuevo para mover los usuario a los grupos indicados.

**`modificargrupos.ldif`**

```sh
# Solo al grupo comercial
dn: cn=comercial,ou=Group,dc=freston,dc=celia,dc=gonzalonazareno,dc=org
changetype:modify
add: member
member: uid=joni,ou=People,dc=freston,dc=celia,dc=gonzalonazareno,dc=org

dn: cn=comercial,ou=Group,dc=freston,dc=celia,dc=gonzalonazareno,dc=org
changetype:modify
add: member
member: uid=sara,ou=People,dc=freston,dc=celia,dc=gonzalonazareno,dc=org

# Solo al grupo almacen 
dn: cn=almacen,ou=Group,dc=freston,dc=celia,dc=gonzalonazareno,dc=org
changetype:modify
add: member
member: uid=maria,ou=People,dc=freston,dc=celia,dc=gonzalonazareno,dc=org

dn: cn=almacen,ou=Group,dc=freston,dc=celia,dc=gonzalonazareno,dc=org
changetype:modify
add: member
member: uid=ana,ou=People,dc=freston,dc=celia,dc=gonzalonazareno,dc=org

# Al grupo comercial y almacen
dn: cn=comercial,ou=Group,dc=freston,dc=celia,dc=gonzalonazareno,dc=org
changetype:modify
add: member
member: uid=mario,ou=People,dc=freston,dc=celia,dc=gonzalonazareno,dc=org

dn: cn=almacen,ou=Group,dc=freston,dc=celia,dc=gonzalonazareno,dc=org
changetype:modify
add: member
member: uid=mario,ou=People,dc=freston,dc=celia,dc=gonzalonazareno,dc=org

dn: cn=comercial,ou=Group,dc=freston,dc=celia,dc=gonzalonazareno,dc=org
changetype:modify
add: member
member: uid=rosario,ou=People,dc=freston,dc=celia,dc=gonzalonazareno,dc=org

dn: cn=almacen,ou=Group,dc=freston,dc=celia,dc=gonzalonazareno,dc=org
changetype:modify
add: member
member: uid=rosario,ou=People,dc=freston,dc=celia,dc=gonzalonazareno,dc=org

# Al grupo admin y al comercial

dn: cn=admin,ou=Group,dc=freston,dc=celia,dc=gonzalonazareno,dc=org
changetype:modify
add: member
member: uid=celia,ou=People,dc=freston,dc=celia,dc=gonzalonazareno,dc=org

dn: cn=admin,ou=Group,dc=freston,dc=celia,dc=gonzalonazareno,dc=org
changetype:modify
add: member
member: uid=lorena,ou=People,dc=freston,dc=celia,dc=gonzalonazareno,dc=org

dn: cn=comercial,ou=Group,dc=freston,dc=celia,dc=gonzalonazareno,dc=org
changetype:modify
add: member
member: uid=celia,ou=People,dc=freston,dc=celia,dc=gonzalonazareno,dc=org
 
dn: cn=comercial,ou=Group,dc=freston,dc=celia,dc=gonzalonazareno,dc=org
changetype:modify
add: member
member: uid=lorena,ou=People,dc=freston,dc=celia,dc=gonzalonazareno,dc=org

# Solo al grupo admin 

dn: cn=admin,ou=Group,dc=freston,dc=celia,dc=gonzalonazareno,dc=org
changetype:modify
add: member
member: uid=antonio,ou=People,dc=freston,dc=celia,dc=gonzalonazareno,dc=org

dn: cn=admin,ou=Group,dc=freston,dc=celia,dc=gonzalonazareno,dc=org
changetype:modify
add: member
member: uid=adrian,ou=People,dc=freston,dc=celia,dc=gonzalonazareno,dc=org
```

Ejecutamos el siguiente comando para **añadirlos**:

```sh
ldapmodify -x -D cn=admin,dc=freston,dc=celia,dc=gonzalonazareno,dc=org -W -f modificargrupos.ldif
```

**Comprobamos** que se han modificado:

```sh
debian@freston:~$ ldapsearch -x -h freston -b ou=Group,dc=freston,dc=celia,dc=gonzalonazareno,dc=org
# extended LDIF
#
# LDAPv3
# base <ou=Group,dc=freston,dc=celia,dc=gonzalonazareno,dc=org> with scope subtree
# filter: (objectclass=*)
# requesting: ALL
#

# Group, freston.celia.gonzalonazareno.org
dn: ou=Group,dc=freston,dc=celia,dc=gonzalonazareno,dc=org
objectClass: top
objectClass: organizationalUnit
ou: Group

# admin, Group, freston.celia.gonzalonazareno.org
dn: cn=admin,ou=Group,dc=freston,dc=celia,dc=gonzalonazareno,dc=org
objectClass: top
objectClass: groupOfNames
cn: admin
member:
member: uid=celia,ou=People,dc=freston,dc=celia,dc=gonzalonazareno,dc=org
member: uid=lorena,ou=People,dc=freston,dc=celia,dc=gonzalonazareno,dc=org
member: uid=antonio,ou=People,dc=freston,dc=celia,dc=gonzalonazareno,dc=org
member: uid=adrian,ou=People,dc=freston,dc=celia,dc=gonzalonazareno,dc=org

# almacen, Group, freston.celia.gonzalonazareno.org
dn: cn=almacen,ou=Group,dc=freston,dc=celia,dc=gonzalonazareno,dc=org
objectClass: top
objectClass: groupOfNames
cn: almacen
member:
member: uid=maria,ou=People,dc=freston,dc=celia,dc=gonzalonazareno,dc=org
member: uid=ana,ou=People,dc=freston,dc=celia,dc=gonzalonazareno,dc=org
member: uid=mario,ou=People,dc=freston,dc=celia,dc=gonzalonazareno,dc=org
member: uid=rosario,ou=People,dc=freston,dc=celia,dc=gonzalonazareno,dc=org

# comercial, Group, freston.celia.gonzalonazareno.org
dn: cn=comercial,ou=Group,dc=freston,dc=celia,dc=gonzalonazareno,dc=org
objectClass: top
objectClass: groupOfNames
cn: comercial
member:
member: uid=joni,ou=People,dc=freston,dc=celia,dc=gonzalonazareno,dc=org
member: uid=sara,ou=People,dc=freston,dc=celia,dc=gonzalonazareno,dc=org
member: uid=mario,ou=People,dc=freston,dc=celia,dc=gonzalonazareno,dc=org
member: uid=rosario,ou=People,dc=freston,dc=celia,dc=gonzalonazareno,dc=org
member: uid=celia,ou=People,dc=freston,dc=celia,dc=gonzalonazareno,dc=org
member: uid=lorena,ou=People,dc=freston,dc=celia,dc=gonzalonazareno,dc=org

# search result
search: 2
result: 0 Success

# numResponses: 5
# numEntries: 4

```


### Atributo 'memberOf'

Es un atributo que se refiere al 'ser miembro y pertenencia' de un grupo.

> **Modifica OpenLDAP apropiadamente para que se pueda obtener los grupos a los que pertenece cada usuario a través del atributo "memberOf".**

Lo primero que tenemos que hacer es crear una serie de ficheros .ldif para esta configuración. 

#### Ficheros de configuración ldap: memberOf
Estos ficheros cargan el atributo memberOf.

Creamos los ficheros con el siguiente **contenido**:


`memberof_config.ldif`
```sh
dn: cn=module,cn=config
cn: module
objectClass: olcModuleList
objectclass: top
olcModuleLoad: memberof.la
olcModulePath: /usr/lib/ldap
```

`memberof_config2.ldif`
```sh
dn: olcOverlay={0}memberof,olcDatabase={1}mdb,cn=config
objectClass: olcConfig
objectClass: olcMemberOf
objectClass: olcOverlayConfig
objectClass: top
olcOverlay: memberof
olcMemberOfDangling: ignore
olcMemberOfRefInt: TRUE
olcMemberOfGroupOC: groupOfNames
olcMemberOfMemberAD: member
olcMemberOfMemberOfAD: memberOf
```

`memberof_config3.ldif`

```sh
dn: cn=module,cn=config
cn: module
objectclass: olcModuleList
objectclass: top
olcmoduleload: refint.la
olcmodulepath: /usr/lib/ldap

dn: olcOverlay={1}refint,olcDatabase={1}mdb,cn=config
objectClass: olcConfig
objectClass: olcOverlayConfig
objectClass: olcRefintConfig
objectClass: top
olcOverlay: {1}refint
olcRefintAttribute: memberof member manager owner
```

Cargamos la **configuración** de la siguiente manera:

```sh
debian@freston:~$ sudo ldapadd -Y EXTERNAL -H ldapi:/// -f memberof_config.ldif 
SASL/EXTERNAL authentication started
SASL username: gidNumber=0+uidNumber=0,cn=peercred,cn=external,cn=auth
SASL SSF: 0
adding new entry "cn=module,cn=config"

debian@freston:~$ sudo ldapadd -Y EXTERNAL -H ldapi:/// -f memberof_config2.ldif 
SASL/EXTERNAL authentication started
SASL username: gidNumber=0+uidNumber=0,cn=peercred,cn=external,cn=auth
SASL SSF: 0
adding new entry "olcOverlay={0}memberof,olcDatabase={1}mdb,cn=config"

debian@freston:~$ sudo ldapadd -Y EXTERNAL -H ldapi:/// -f memberof_config3.ldif 
SASL/EXTERNAL authentication started
SASL username: gidNumber=0+uidNumber=0,cn=peercred,cn=external,cn=auth
SASL SSF: 0
adding new entry "cn=module,cn=config"

adding new entry "olcOverlay={1}refint,olcDatabase={1}mdb,cn=config"

```

#### Actualizar grupos y usuarios para memberOf
Para comprobar que funciona esto, necesitamos eliminar todos los grupos que hemos creado anteriormente, y después volver a crearlos para que se cargue adecuadamente el atributo.


```sh
# Borrar los grupos
ldapdelete -x -D "cn=admin,dc=freston,dc=celia,dc=gonzalonazareno,dc=org" 'cn=nombredelgrupo,ou=Group,dc=freston,dc=celia,dc=gonzalonazareno,dc=org' -W
```

```sh
debian@freston:~$ ldapdelete -x -D "cn=admin,dc=freston,dc=celia,dc=gonzalonazareno,dc=org" 'cn=comercial,ou=Group,dc=freston,dc=celia,dc=gonzalonazareno,dc=org' -W
Enter LDAP Password: 
debian@freston:~$ ldapdelete -x -D "cn=admin,dc=freston,dc=celia,dc=gonzalonazareno,dc=org" 'cn=almacen,ou=Group,dc=freston,dc=celia,dc=gonzalonazareno,dc=org' -W
Enter LDAP Password: 
debian@freston:~$ ldapdelete -x -D "cn=admin,dc=freston,dc=celia,dc=gonzalonazareno,dc=org" 'cn=admin,ou=Group,dc=freston,dc=celia,dc=gonzalonazareno,dc=org' -W
Enter LDAP Password: 

```

Los agregamos de nuevo:

```sh
ldapadd -x -D cn=admin,dc=freston,dc=celia,dc=gonzalonazareno,dc=org -W -f grupos1.ldif
```

Comprobamos que se han agregado:

```sh
debian@freston:~$ ldapadd -x -D cn=admin,dc=freston,dc=celia,dc=gonzalonazareno,dc=org -W -f grupos1.ldif
Enter LDAP Password: 
adding new entry "cn=comercial,ou=Group,dc=freston,dc=celia,dc=gonzalonazareno,dc=org"

adding new entry "cn=almacen,ou=Group,dc=freston,dc=celia,dc=gonzalonazareno,dc=org"

adding new entry "cn=admin,ou=Group,dc=freston,dc=celia,dc=gonzalonazareno,dc=org"

```

Modificamos los usuarios a los grupos de nuevo:

```sh
ldapmodify -x -D cn=admin,dc=freston,dc=celia,dc=gonzalonazareno,dc=org -W -f modificargrupos.ldif
```

Y ahora hacemos una consulta externa , indicando el nombre identificador para ver si realmente se ha habilitado el atributo memberOf .

```sh
ldapsearch -LL -Y EXTERNAL -H ldapi:/// "(uid=lorena)" -b dc=freston,dc=celia,dc=gonzalonazareno,dc=org memberOf
```

#### Comprobación memberOf
Como podemos comprobar efectivamente aparece de qué grupo es cada usuario.

```sh
debian@freston:~$ ldapsearch -LL -Y EXTERNAL -H ldapi:/// "(uid=lorena)" -b dc=freston,dc=celia,dc=gonzalonazareno,dc=org memberOf
SASL/EXTERNAL authentication started
SASL username: gidNumber=1000+uidNumber=1000,cn=peercred,cn=external,cn=auth
SASL SSF: 0
version: 1

dn: uid=lorena,ou=People,dc=freston,dc=celia,dc=gonzalonazareno,dc=org
memberOf: cn=admin,ou=Group,dc=freston,dc=celia,dc=gonzalonazareno,dc=org
memberOf: cn=comercial,ou=Group,dc=freston,dc=celia,dc=gonzalonazareno,dc=org

debian@freston:~$ ldapsearch -LL -Y EXTERNAL -H ldapi:/// "(uid=celia)" -b dc=freston,dc=celia,dc=gonzalonazareno,dc=org memberOf
SASL/EXTERNAL authentication started
SASL username: gidNumber=1000+uidNumber=1000,cn=peercred,cn=external,cn=auth
SASL SSF: 0
version: 1

dn: uid=celia,ou=People,dc=freston,dc=celia,dc=gonzalonazareno,dc=org
memberOf: cn=admin,ou=Group,dc=freston,dc=celia,dc=gonzalonazareno,dc=org
memberOf: cn=comercial,ou=Group,dc=freston,dc=celia,dc=gonzalonazareno,dc=org

debian@freston:~$ ldapsearch -LL -Y EXTERNAL -H ldapi:/// "(uid=joni)" -b dc=freston,dc=celia,dc=gonzalonazareno,dc=org memberOf
SASL/EXTERNAL authentication started
SASL username: gidNumber=1000+uidNumber=1000,cn=peercred,cn=external,cn=auth
SASL SSF: 0
version: 1

dn: uid=joni,ou=People,dc=freston,dc=celia,dc=gonzalonazareno,dc=org
memberOf: cn=comercial,ou=Group,dc=freston,dc=celia,dc=gonzalonazareno,dc=org

```

### ACLs

Para crear y actualizar ACL podemos usar la herramienta **ldapmodify**. Esta herramienta permite la creación, modificación y eliminación de cualquier conjunto de atributos asociados con una entrada en el directorio activo. Así pudiendo administrar y controlar el acceso a la información.

Las **ACL** actuales las podemos ver de la siguiente manera:

```sh
debian@freston:~$ sudo ldapsearch -LLLQ -Y EXTERNAL -H ldapi:/// -b cn=config -s one olcAccess
dn: cn=module{0},cn=config

dn: cn=module{1},cn=config

dn: cn=module{2},cn=config

dn: cn=schema,cn=config

dn: olcBackend={0}mdb,cn=config

dn: olcDatabase={-1}frontend,cn=config
olcAccess: {0}to * by dn.exact=gidNumber=0+uidNumber=0,cn=peercred,cn=external
 ,cn=auth manage by * break
olcAccess: {1}to dn.exact="" by * read
olcAccess: {2}to dn.base="cn=Subschema" by * read

dn: olcDatabase={0}config,cn=config
olcAccess: {0}to * by dn.exact=gidNumber=0+uidNumber=0,cn=peercred,cn=external
 ,cn=auth manage by * break

dn: olcDatabase={1}mdb,cn=config
olcAccess: {0}to attrs=userPassword by self write by anonymous auth by * none
olcAccess: {1}to attrs=shadowLastChange by self write by * read
olcAccess: {2}to * by * read

```

> **Crea las ACLs necesarias para que los usuarios del grupo almacen puedan ver todos los atributos de todos los usuarios pero solo puedan modificar las suyas.**


Agregar a un grupo a la información de control de acceso 

Creamos el fichero .ldif, podemos darle los permisos de dos formas:

* Contenido del fichero .ldif

```sh
dn: olcDatabase={1}mdb,cn=config
changetype: modify
add: olcAccess
olcAccess: to dn.base="" by group="cn=almacen,ou=Groups,dc=freston,dc=celia,dc=gonzalonazareno,dc=org" by self write
olcAccess: to dn.base="" by group="cn=almacen,ou=Groups,dc=freston,dc=celia,dc=gonzalonazareno,dc=org" read
olcAccess: to dn.base="" by group="cn=almacen,ou=Groups,dc=freston,dc=celia,dc=gonzalonazareno,dc=org" search
```

* Contenido del fichero 2 

```sh
dn: olcDatabase={1}mdb,cn=config
changetype: modify
add: olcAccess
olcAccess: to dn.subtree="ou=Group,dc=freston,dc=celia,dc=gonzalonazareno,dc=org" 
  by group.exact="cn=almacen,ou=Group,ou=freston,dc=celia,dc=gonzalonazareno,dc=org" read
  by self write
  by * search
```

* Así agregamos la ACL 

```sh
debian@freston:~$ sudo ldapmodify -Y EXTERNAL -H ldapi:/// -f acl1.ldif 
SASL/EXTERNAL authentication started
SASL username: gidNumber=0+uidNumber=0,cn=peercred,cn=external,cn=auth
SASL SSF: 0
modifying entry "olcDatabase={1}mdb,cn=config"
```
* Comprobamos que se han añadido las ACL correctamente.

```sh
debian@freston:~$ sudo ldapsearch -LLLQ -Y EXTERNAL -H ldapi:/// -b cn=config -s one olcAccess
dn: cn=module{0},cn=config

dn: cn=module{1},cn=config

dn: cn=module{2},cn=config

dn: cn=schema,cn=config

dn: olcBackend={0}mdb,cn=config

dn: olcDatabase={-1}frontend,cn=config
olcAccess: {0}to * by dn.exact=gidNumber=0+uidNumber=0,cn=peercred,cn=external
 ,cn=auth manage by * break
olcAccess: {1}to dn.exact="" by * read
olcAccess: {2}to dn.base="cn=Subschema" by * read

dn: olcDatabase={0}config,cn=config
olcAccess: {0}to * by dn.exact=gidNumber=0+uidNumber=0,cn=peercred,cn=external
 ,cn=auth manage by * break

dn: olcDatabase={1}mdb,cn=config
olcAccess: {0}to attrs=userPassword by self write by anonymous auth by * none
olcAccess: {1}to attrs=shadowLastChange by self write by * read
olcAccess: {2}to * by * read
olcAccess: {3}to dn.base="" by group="cn=almacen,ou=Groups,dc=freston,dc=celia
 ,dc=gonzalonazareno,dc=org" read
olcAccess: {4}to dn.base="" by group="cn=almacen,ou=Groups,dc=freston,dc=celia
 ,dc=gonzalonazareno,dc=org" search
olcAccess: {5}to dn.base="" by group="cn=almacen,ou=Groups,dc=freston,dc=celia
 ,dc=gonzalonazareno,dc=org" by self write
olcAccess: {6}to dn.subtree="ou=Group,dc=freston,dc=celia,dc=gonzalonazareno,d
 c=org"  by group.exact="cn=almacen,ou=Group,ou=freston,dc=celia,dc=gonzalonaz
 areno,dc=org" read by self write by * search

```


> **Crea las ACLs necesarias para que los usuarios del grupo admin puedan ver y modificar cualquier atributo de cualquier objeto.**

* Le damos el permiso al grupo admin a modificar cualquier atributo.

```sh
dn: olcDatabase={1}mdb,cn=config
changetype: modify
add: olcAccess
olcAccess: {1}to * by dn="cn=admin,dc=freston,dc=celia,dc=gonzalonazareno,dc=org" write by group.exact="cn=admin,ou=Group,dc=freston,dc=celia,dc=gonzalonazareno,dc=org" write
```
* Lo aplicamos 

```sh
debian@freston:~$ sudo ldapmodify -Y EXTERNAL -H ldapi:/// -f acl3.ldif 
SASL/EXTERNAL authentication started
SASL username: gidNumber=0+uidNumber=0,cn=peercred,cn=external,cn=auth
SASL SSF: 0
modifying entry "olcDatabase={1}mdb,cn=config"
```
* Comprobamos que se ha añadido 

```sh
debian@freston:~$ sudo ldapsearch -LLLQ -Y EXTERNAL -H ldapi:/// -b cn=config -s one olcAccess
dn: cn=module{0},cn=config

dn: cn=module{1},cn=config

dn: cn=module{2},cn=config

dn: cn=schema,cn=config

dn: olcBackend={0}mdb,cn=config

dn: olcDatabase={-1}frontend,cn=config
olcAccess: {0}to * by dn.exact=gidNumber=0+uidNumber=0,cn=peercred,cn=external
 ,cn=auth manage by * break
olcAccess: {1}to dn.exact="" by * read
olcAccess: {2}to dn.base="cn=Subschema" by * read

dn: olcDatabase={0}config,cn=config
olcAccess: {0}to * by dn.exact=gidNumber=0+uidNumber=0,cn=peercred,cn=external
 ,cn=auth manage by * break

dn: olcDatabase={1}mdb,cn=config
olcAccess: {0}to attrs=userPassword by self write by anonymous auth by * none
olcAccess: {1}to * by dn="cn=admin,dc=freston,dc=celia,dc=gonzalonazareno,dc=o
 rg" write by group.exact="cn=admin,ou=Group,dc=freston,dc=celia,dc=gonzalonaz
 areno,dc=org" write
olcAccess: {2}to attrs=shadowLastChange by self write by * read
olcAccess: {3}to * by * read
olcAccess: {4}to dn.base="" by group="cn=almacen,ou=Groups,dc=freston,dc=celia
 ,dc=gonzalonazareno,dc=org" read
olcAccess: {5}to dn.base="" by group="cn=almacen,ou=Groups,dc=freston,dc=celia
 ,dc=gonzalonazareno,dc=org" search
olcAccess: {6}to dn.base="" by group="cn=almacen,ou=Groups,dc=freston,dc=celia
 ,dc=gonzalonazareno,dc=org" by self write
olcAccess: {7}to dn.subtree="ou=Group,dc=freston,dc=celia,dc=gonzalonazareno,d
 c=org"  by group.exact="cn=almacen,ou=Group,ou=freston,dc=celia,dc=gonzalonaz
 areno,dc=org" read by self write by * search

```

```
Fuentes:

https://syspass-doc.readthedocs.io/en/3.1/configuration/ldap.html

https://www.openldap.org/lists/openldap-technical/201511/msg00154.html

https://wiki.debian.org/LDAP/OpenLDAPSetup#Access_Control_Lists

https://tldp.org/HOWTO/LDAP-HOWTO/accesscontrol.html

https://www.openldap.org/doc/admin24/access-control.html

http://www.zytrax.com/books/ldap/ch6/slapd-config.html#use-security

https://tldp.org/HOWTO/LDAP-HOWTO/accesscontrol.html
