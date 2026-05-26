-- Indicador 2: Análisis comparativo entre descuentos y devoluciones por tienda y región

WITH ventas_por_tienda AS (
    SELECT
        p.id_tienda,
        SUM(dp.cantidad * dp.precio_unitario) AS ingresos_sin_descuento,
        SUM(dp.cantidad * dp.precio_unitario * dp.descuento / 100) AS monto_descuentos
    FROM pedido p
    JOIN detalle_pedido dp ON p.id_pedido = dp.id_pedido
    WHERE p.estado IN ('completado', 'devuelto')
    GROUP BY p.id_tienda
),
devoluciones_por_tienda AS (
    SELECT
        p.id_tienda,
        COALESCE(SUM(d.monto_reembolso), 0) AS monto_reembolsos
    FROM pedido p
    LEFT JOIN devolucion d ON p.id_pedido = d.id_pedido
    WHERE p.estado IN ('completado', 'devuelto')
    GROUP BY p.id_tienda
)
SELECT
    t.nombre AS tienda,
    t.ciudad,
    t.region,
    ROUND(v.ingresos_sin_descuento, 2) AS ingresos_sin_descuento,
    ROUND(v.monto_descuentos, 2) AS monto_descuentos,
    ROUND((v.monto_descuentos / NULLIF(v.ingresos_sin_descuento, 0)) * 100, 2) AS descuentos_porcentaje,
    ROUND(COALESCE(d.monto_reembolsos, 0), 2) AS monto_reembolsos,
    ROUND((COALESCE(d.monto_reembolsos, 0) / NULLIF(v.ingresos_sin_descuento, 0)) * 100, 2) AS reembolsos_porcentaje,
    ROUND(v.monto_descuentos + COALESCE(d.monto_reembolsos, 0), 2) AS perdida_total,
    ROUND(((v.monto_descuentos + COALESCE(d.monto_reembolsos, 0)) / NULLIF(v.ingresos_sin_descuento, 0)) * 100, 2) AS perdida_total_porcentaje,
    CASE
        WHEN v.monto_descuentos > COALESCE(d.monto_reembolsos, 0)
        THEN 'DESCUENTOS - Factor Principal'
        ELSE 'DEVOLUCIONES - Factor Principal'
    END AS factor_principal
FROM ventas_por_tienda v
JOIN tienda t ON v.id_tienda = t.id_tienda
LEFT JOIN devoluciones_por_tienda d ON v.id_tienda = d.id_tienda
ORDER BY t.region, t.nombre, perdida_total DESC;
