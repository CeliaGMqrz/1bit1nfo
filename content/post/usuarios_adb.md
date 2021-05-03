1. (ORACLE, Postgres, MySQL) Crea un usuario llamado Becario y, sin usar los roles de ORACLE, dale los siguientes privilegios:

        ◦ Conectarse a la base de datos.
        ◦ Modificar el número de errores en la introducción de la contraseña de cualquier usuario.
        ◦ Modificar índices en cualquier esquema (este privilegio podrá pasarlo a quien quiera)
        ◦ Insertar filas en scott.emp (este privilegio podrá pasarlo a quien quiera)
        ◦ Crear objetos en cualquier tablespace.
        ◦ Gestión completa de usuarios, privilegios y roles.


## Oracle 

* Conectarse a la base de datos 

```sh
# Crear el usuario Becario 
Create user Becario identified by Becario;
# Conectarse a la base de datos
grant create session to Becario;
# Modificar el número de errores en la introducción de la contraseña de cualquier usuario.
grant create profile to Becario;
Create profile Limitepasswd LIMIT
FAILED_LOGIN_ATTEMPTS 5;
# Ahora le damos al usuario becarios la posibilidad de dar dicho perfil
grant alter user to Becario;
