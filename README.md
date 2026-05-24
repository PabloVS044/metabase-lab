# RetailMax — Dashboard Analytics con Metabase

**Universidad del Valle de Guatemala | CC3088 - Bases de Datos 1 | Ciclo 1, 2026**

Dashboard analítico empresarial para RetailMax, una cadena de tiendas de productos de consumo. Implementación de Metabase sobre Docker con PostgreSQL, incluyendo indicadores SQL y usuario de calificación preconfigurado.

---

## Requisitos

- **Docker Desktop** instalado y ejecutándose
- Git (para control de versiones)
- Acceso a terminal (PowerShell, Bash, o similar)

---

## Instalación Rápida

### 1. Clonar el repositorio y navegar

```bash
git clone <repo-url>
cd metabase-lab
```

### 2. Levantar el ambiente

```bash
docker compose up -d
```

Esto iniciará:
- **PostgreSQL 16** en puerto `5432` con base de datos `retailmax_db`
- **Metabase** en puerto `3000`

**Tiempo de inicialización:** 30-60 segundos (Metabase realiza migración inicial)

### 3. Acceder a Metabase

**URL:** [http://localhost:3000](http://localhost:3000)

**Credenciales de Calificación:**
- Email: `calificar@uvg.edu.gt`
- Contraseña: `secret123+`

---

## Estructura del Proyecto

```
metabase-lab/
├── docker-compose.yml              # Configuración de servicios Docker
├── .env                            # Variables de entorno
├── data/
│   ├── DDL (1).sql                # DDL: Estructura de RetailMax
│   └── DATA (1).sql               # DML: Carga de datos de prueba
├── postgres-init/                  # Carpeta vacía (Docker ejecuta SQL de data/)
├── queries/
│   └── query_de_prueba.sql        # Query de prueba para validar datos
├── metabase-data/                 # Volumen persistente (generado automáticamente)
└── README.md                       # Este archivo
```

---

## Configuración de Metabase

### Usuario Administrativo (Preconfigurado)

El usuario `calificar@uvg.edu.gt` se configura automáticamente con acceso administrativo y contraseña `secret123+`.

### Conexión a PostgreSQL

La conexión a la base de datos RetailMax se configura automáticamente:

| Parámetro | Valor |
|-----------|-------|
| **Host** | `retailmax_postgres` |
| **Puerto** | `5432` |
| **Base de datos** | `retailmax_db` |
| **Usuario** | `retailmax` |
| **Contraseña** | `retailmax123` |

---

## Query de Prueba

**Archivo:** `queries/query_de_prueba.sql`

Query de validación para verificar que los datos se han cargado correctamente en la base de datos RetailMax.

---

## Solución de Problemas

### Metabase no responde

```bash
# Verificar estado de contenedores
docker compose ps

# Ver logs de Metabase
docker compose logs retailmax_metabase

# Reiniciar servicios
docker compose restart
```

### PostgreSQL no carga datos

```bash
# Verificar logs de PostgreSQL
docker compose logs retailmax_postgres

# Reiniciar y reconstruir volumen
docker compose down
docker volume rm metabase-lab_postgres_data
docker compose up -d
```

### Limpiar todo y comenzar de nuevo

```bash
docker compose down -v
docker compose up -d
```

---

## Variables de Entorno (.env)

| Variable | Valor Actual |
|----------|-------------|
| `POSTGRES_DB` | `retailmax_db` |
| `POSTGRES_USER` | `retailmax` |
| `POSTGRES_PASSWORD` | `retailmax123` |
| `POSTGRES_PORT` | `5432` |
| `METABASE_PORT` | `3000` |
| `JAVA_TIMEZONE` | `America/Guatemala` |

Para cambiar, edita `.env` y reinicia: `docker compose up -d`

---

## Persistencia

- **PostgreSQL:** Datos persistidos en volumen `postgres_data`
- **Metabase:** Dashboard y configuración persistidos en volumen `metabase_data`

Los volúmenes se mantienen incluso si bajas los contenedores. Para eliminarlos completamente:

```bash
docker compose down -v
```

---

## Contacto y Soporte

Para reportar problemas o preguntas sobre la configuración:
1. Verifica los logs: `docker compose logs -f`
2. Asegúrate de que Docker Desktop esté ejecutándose
3. Confirma que los puertos 5432 y 3000 no estén en uso por otros servicios

---

**Última actualización:** Mayo 2026
