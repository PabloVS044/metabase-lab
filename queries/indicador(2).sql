--Indicador 2: Margen de ganancia por categoría
SELECT 
    c.nombre AS categoria,
    ROUND(SUM(dp.cantidad * dp.precio_unitario * (1 - dp.descuento / 100)), 2) AS ingresos,
    ROUND(SUM(dp.cantidad * pr.precio_costo), 2) AS costos,
    ROUND(SUM(dp.cantidad * dp.precio_unitario * (1 - dp.descuento / 100))
          - SUM(dp.cantidad * pr.precio_costo), 2) AS ganancia_neta,
    ROUND(
        ((SUM(dp.cantidad * dp.precio_unitario * (1 - dp.descuento / 100))
          - SUM(dp.cantidad * pr.precio_costo))
        / NULLIF(SUM(dp.cantidad * dp.precio_unitario * (1 - dp.descuento / 100)), 0)) * 100
    , 2) AS margen_porcentaje
FROM categoria c
JOIN producto pr ON c.id_categoria = pr.id_categoria
JOIN detalle_pedido dp ON pr.id_producto = dp.id_producto
JOIN pedido pe ON dp.id_pedido = pe.id_pedido
WHERE pe.estado IN ('completado', 'devuelto')
GROUP BY c.nombre
ORDER BY ganancia_neta DESC;
