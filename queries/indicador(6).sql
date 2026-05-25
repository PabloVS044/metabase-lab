-- Indicador 6: Rentabilidad por proveedor

SELECT
    pv.nombre                                                                             AS proveedor,
    pv.pais,
    pv.calificacion,
    pv.tiempo_entrega_dias,
    COUNT(DISTINCT pr.id_producto)                                                        AS total_productos,
    COALESCE(SUM(dp.cantidad), 0)                                                         AS unidades_vendidas,
    ROUND(COALESCE(SUM(dp.cantidad * dp.precio_unitario * (1 - dp.descuento / 100)), 0), 2) AS ingresos_totales,
    ROUND(COALESCE(SUM(dp.cantidad * pr.precio_costo), 0), 2)                            AS costos_totales,
    ROUND(COALESCE(SUM(dp.cantidad * (dp.precio_unitario * (1 - dp.descuento / 100)
        - pr.precio_costo)), 0), 2)                                                      AS ganancia_neta,
    ROUND((COALESCE(SUM(dp.cantidad * dp.precio_unitario * (1 - dp.descuento / 100)), 0)
         - COALESCE(SUM(dp.cantidad * pr.precio_costo), 0))
         / NULLIF(SUM(dp.cantidad * dp.precio_unitario * (1 - dp.descuento / 100)), 0)
         * 100, 2)                                                                       AS margen_porcentaje
FROM proveedor pv
JOIN producto pr        ON pv.id_proveedor = pr.id_proveedor
LEFT JOIN detalle_pedido dp ON pr.id_producto = dp.id_producto
LEFT JOIN pedido p          ON dp.id_pedido  = p.id_pedido
                            AND p.estado IN ('completado', 'devuelto')
GROUP BY pv.id_proveedor, pv.nombre, pv.pais, pv.calificacion, pv.tiempo_entrega_dias
ORDER BY ganancia_neta DESC NULLS LAST;
