-- Indicador 3: Margen de ganancias dentro de las tiendas, en diferentes regiones.

WITH ventas_por_tienda AS (
    SELECT
        p.id_tienda,
        COUNT(DISTINCT p.id_pedido) AS total_pedidos,
        SUM(dp.cantidad) AS unidades_vendidas,
        SUM(dp.cantidad * dp.precio_unitario * (1 - dp.descuento / 100)) AS ingresos_totales,
        SUM(dp.cantidad * pr.precio_costo) AS costos_totales
    FROM pedido p
    JOIN detalle_pedido dp ON p.id_pedido = dp.id_pedido
    JOIN producto pr ON dp.id_producto = pr.id_producto
    WHERE p.estado IN ('completado', 'devuelto')
    GROUP BY p.id_tienda
),
devoluciones_por_tienda AS (
    SELECT
        p.id_tienda,
        COALESCE(SUM(d.monto_reembolso), 0) AS reembolsos_devoluciones
    FROM pedido p
    LEFT JOIN devolucion d ON p.id_pedido = d.id_pedido
    WHERE p.estado IN ('completado', 'devuelto')
    GROUP BY p.id_tienda
)
SELECT
    t.nombre AS tienda,
    t.ciudad,
    t.region,
    v.total_pedidos,
    v.unidades_vendidas,
    ROUND(v.ingresos_totales, 2) AS ingresos_totales,
    ROUND(v.costos_totales, 2) AS costos_totales,
    ROUND(v.ingresos_totales - v.costos_totales, 2) AS margen_bruto,
    ROUND(((v.ingresos_totales - v.costos_totales) / NULLIF(v.ingresos_totales, 0)) * 100, 2) AS margen_porcentaje_bruto,
    ROUND(COALESCE(d.reembolsos_devoluciones, 0), 2) AS reembolsos_devoluciones,
    ROUND(v.ingresos_totales - v.costos_totales - COALESCE(d.reembolsos_devoluciones, 0), 2) AS margen_neto,
    ROUND(((v.ingresos_totales - v.costos_totales - COALESCE(d.reembolsos_devoluciones, 0)) / NULLIF(v.ingresos_totales, 0)) * 100, 2) AS margen_porcentaje_neto
FROM ventas_por_tienda v
JOIN tienda t ON v.id_tienda = t.id_tienda
LEFT JOIN devoluciones_por_tienda d ON v.id_tienda = d.id_tienda
ORDER BY t.region, t.nombre, margen_neto DESC, margen_porcentaje_neto DESC;
