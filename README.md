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
│   ├── indicador(1).sql           # Rentabilidad por Producto/Categoría por tienda y región
│   ├── indicador(2).sql           # Análisis comparativo Descuentos vs Devoluciones por tienda y región
│   ├── indicador(3).sql           # Margen de Ganancia por Tienda y Región
│   └── query_de_prueba.sql        # Query de prueba (obsoleta)
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

## Indicadores Financieros

El proyecto incluye 3 indicadores SQL para análisis financiero profundo del área 3 (Finanzas), cada uno segmentado por tienda y región:

### Indicador 1: Rentabilidad por Producto/Categoría
**Archivo:** `queries/indicador(1).sql`

Análisis de rentabilidad por producto y categoría ofrecidos en cada tienda por región.
- **Columnas:** tienda, ciudad, región, categoría, producto, márgenes unitarios y porcentuales, unidades vendidas, ingresos, costos, ganancia neta
- **Uso:** Identificar productos/categorías más rentables por ubicación
- **Segmentación:** Por tienda y región

### Indicador 2: Descuentos vs Devoluciones
**Archivo:** `queries/indicador(2).sql`

Análisis comparativo del impacto financiero entre descuentos promocionales y devoluciones/reembolsos.
- **Columnas:** tienda, ciudad, región, ingresos, montos de descuentos/reembolsos, porcentajes, pérdida total, factor principal
- **Uso:** Priorizar acciones de recuperación de margen (descuentos vs devoluciones)
- **Segmentación:** Por tienda y región

### Indicador 3: Margen de Ganancia por Tienda
**Archivo:** `queries/indicador(3).sql`

Comparativa de rentabilidad por tienda con análisis de margen bruto vs neto.
- **Columnas:** tienda, ciudad, región, total pedidos, unidades vendidas, ingresos, costos, márgenes bruto/neto y porcentuales, reembolsos
- **Uso:** Comparar desempeño de tiendas y evaluar impacto de devoluciones
- **Segmentación:** Por tienda y región

---

## Query de Prueba (Obsoleta)

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
