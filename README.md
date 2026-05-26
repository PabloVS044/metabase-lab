# RetailMax - Dashboard de Finanzas en Metabase

Proyecto de visualizacion de datos para RetailMax usando PostgreSQL + Metabase sobre Docker Compose. El repositorio deja preconfigurado el usuario de calificacion y automatiza la creacion del dashboard del area de Finanzas con 2 tabs y 12 indicadores SQL.

## Levantar el ambiente

```bash
docker compose up --build
```

Servicios incluidos:

- PostgreSQL 16 con carga automatica de `data/DDL (1).sql` y `data/DATA (1).sql`
- Metabase en `http://localhost:3000`
- Bootstrap `retailmax_metabase_init` que configura usuario, conexion a PostgreSQL, tarjetas y dashboard

## Credenciales de calificacion

- Correo: `calificar@uvg.edu.gt`
- Contrasena: `secret123+`

## Dashboard esperado

- Nombre: `RetailMax - Finanzas`
- Tab 1: `Rentabilidad Comercial`
- Tab 2: `Control Financiero`
- Total minimo: 12 indicadores, todos construidos con Native Query / SQL

Los indicadores se cargan desde `queries/indicador(1).sql` hasta `queries/indicador(12).sql`. El bootstrap ignora `queries/query_de_prueba.sql`.

## Estructura

```text
metabase-lab/
├── docker-compose.yml
├── data/
├── metabase-data/
├── metabase-init/
├── queries/
├── docs/
└── README.md
```

## Variables opcionales

Si necesitas sobreescribir valores, puedes copiar `.env.example` a `.env` y ajustar:

- `POSTGRES_DB`
- `POSTGRES_USER`
- `POSTGRES_PASSWORD`
- `POSTGRES_PORT`
- `METABASE_PORT`

El usuario de calificacion y los nombres del dashboard/tabs quedaron fijos en `docker-compose.yml` para cumplir la rubrica exactamente.

## Reinicio limpio

Si ya existe un volumen de Metabase con una configuracion anterior y quieres regenerar todo:

```bash
docker compose down -v
docker compose up --build
```

## Estado actual

- Compose real versionado en `docker-compose.yml`
- Usuario de calificacion configurado por defecto
- Dashboard armado automaticamente desde SQL nativo
- Queries 2, 3 y 6 corregidas para evitar agregaciones inconsistentes

## Pendiente fuera de este README

- `informe.pdf` con documentacion completa de los 12 indicadores
- enlace al video de presentacion en el repositorio
