-- Indicador 6: Rentabilidad por proveedor

WITH ventas_validas AS (
    SELECT
        pr.id_proveedor,
        pr.id_producto,
        dp.cantidad,
        dp.precio_unitario,
        dp.descuento,
        pr.precio_costo
    FROM pedido p
    JOIN detalle_pedido dp ON p.id_pedido = dp.id_pedido
    JOIN producto pr ON dp.id_producto = pr.id_producto
    WHERE p.estado IN ('completado', 'devuelto')
)
SELECT
    pv.nombre AS proveedor,
    pv.pais,
    pv.calificacion,
    pv.tiempo_entrega_dias,
    COUNT(DISTINCT pr.id_producto) AS total_productos,
    COALESCE(SUM(vv.cantidad), 0) AS unidades_vendidas,
    ROUND(COALESCE(SUM(vv.cantidad * vv.precio_unitario * (1 - vv.descuento / 100)), 0), 2) AS ingresos_totales,
    ROUND(COALESCE(SUM(vv.cantidad * vv.precio_costo), 0), 2) AS costos_totales,
    ROUND(COALESCE(SUM(vv.cantidad * (vv.precio_unitario * (1 - vv.descuento / 100) - vv.precio_costo)), 0), 2) AS ganancia_neta,
    ROUND(
        (
            COALESCE(SUM(vv.cantidad * vv.precio_unitario * (1 - vv.descuento / 100)), 0) -
            COALESCE(SUM(vv.cantidad * vv.precio_costo), 0)
        ) / NULLIF(COALESCE(SUM(vv.cantidad * vv.precio_unitario * (1 - vv.descuento / 100)), 0), 0) * 100,
        2
    ) AS margen_porcentaje
FROM proveedor pv
JOIN producto pr ON pv.id_proveedor = pr.id_proveedor
LEFT JOIN ventas_validas vv ON pr.id_producto = vv.id_producto
GROUP BY pv.id_proveedor, pv.nombre, pv.pais, pv.calificacion, pv.tiempo_entrega_dias
ORDER BY ganancia_neta DESC NULLS LAST;
