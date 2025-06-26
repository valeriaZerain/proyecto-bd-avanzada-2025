# 📦 Backups

Esta carpeta contiene los respaldos automáticos generados diariamente para las bases de datos **PostgreSQL** y **MySQL**.

## 📁 Formato de nombres

Cada archivo de respaldo se nombra con el siguiente formato:

- `pg_backup_YYYY-MM-DD.dump`: Respaldo en formato comprimido personalizado (`.dump`) de la base de datos **PostgreSQL**.
- `mysql_backup_YYYY-MM-DD.sql`: Respaldo en formato SQL plano de la base de datos **MySQL**.

## ⚙️ Ejecución de backups

La creación de backups se realiza de dos formas:

1. **Automática:** Se ejecuta diariamente a las 3:00 AM. Además, esta ejecución automática inicia al momento de iniciar el servidor.
2. **Manual:** Puede iniciarse en cualquier momento mediante un endpoint específico, permitiendo realizar respaldos bajo demanda.

---

> [!IMPORTANT]  
> Los archivos se sobrescriben si ya existe un respaldo con la misma fecha. Asegúrate de moverlos o renombrarlos si necesitas conservar versiones anteriores.
