## creando el archivo .env
1. Crear un archivo .env en la raiz de la carpeta con los siguientes datos

```
DB_USER=user
DB_PASSWORD=password
```

2. Abrir Git Bash o PowerShell dentro del proyecto
3. Ejecutar el siguiente comando:

```shell
docker-compose --env-file .env up -d
```
