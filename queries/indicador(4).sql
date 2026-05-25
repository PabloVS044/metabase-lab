-- Indicador 4: Tendencia mensual de ingresos y margen por región

SELECT
    t.region,
    DATE_TRUNC('month', p.fecha)                    AS fecha_mes,
    TO_CHAR(DATE_TRUNC('month', p.fecha), 'YYYY-MM') AS mes,
    COUNT(DISTINCT p.id_pedido)                     AS total_pedidos,
    SUM(dp.cantidad)                                AS unidades_vendidas,
    ROUND(SUM(dp.cantidad * dp.precio_unitario * (1 - dp.descuento / 100)), 2)           AS ingresos_totales,
    ROUND(SUM(dp.cantidad * pr.precio_costo), 2)                                          AS costos_totales,
    ROUND(SUM(dp.cantidad * dp.precio_unitario * (1 - dp.descuento / 100))
        - SUM(dp.cantidad * pr.precio_costo), 2)                                          AS margen_bruto,
    ROUND(((SUM(dp.cantidad * dp.precio_unitario * (1 - dp.descuento / 100))
          - SUM(dp.cantidad * pr.precio_costo))
         / NULLIF(SUM(dp.cantidad * dp.precio_unitario * (1 - dp.descuento / 100)), 0)
         ) * 100, 2)                                AS margen_porcentaje
FROM tienda t
JOIN pedido p       ON t.id_tienda    = p.id_tienda
JOIN detalle_pedido dp ON p.id_pedido = dp.id_pedido
JOIN producto pr    ON dp.id_producto = pr.id_producto
WHERE p.estado IN ('completado', 'devuelto')
GROUP BY t.region, DATE_TRUNC('month', p.fecha)
ORDER BY fecha_mes, t.region;
