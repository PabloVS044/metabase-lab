-- Indicador 1: rentabilidad de cada categoria y producto que ofrece cada tienda, por región

SELECT 
    t.nombre AS tienda,
    t.ciudad,
    t.region,
    c.nombre AS categoria,
    p.nombre AS producto,
    ROUND(p.precio_costo, 2) AS costo_unitario,
    ROUND(p.precio_venta, 2) AS precio_venta,
    ROUND(p.precio_venta - p.precio_costo, 2) AS margen_unitario,
    ROUND(((p.precio_venta - p.precio_costo) / p.precio_venta) * 100, 2) AS margen_porcentaje,
    COUNT(DISTINCT dp.id_pedido) AS cantidad_pedidos,
    SUM(dp.cantidad) AS unidades_vendidas,
    ROUND(SUM(dp.cantidad * dp.precio_unitario * (1 - dp.descuento / 100)), 2) AS ingresos_totales,
    ROUND(SUM(dp.cantidad * p.precio_costo), 2) AS costos_totales,
    ROUND(SUM(dp.cantidad * (dp.precio_unitario * (1 - dp.descuento / 100) - p.precio_costo)), 2) AS ganancia_neta
FROM producto p
INNER JOIN categoria c ON p.id_categoria = c.id_categoria
LEFT JOIN detalle_pedido dp ON p.id_producto = dp.id_producto
LEFT JOIN pedido pe ON dp.id_pedido = pe.id_pedido
LEFT JOIN tienda t ON pe.id_tienda = t.id_tienda
WHERE pe.estado IS NULL OR pe.estado IN ('completado', 'devuelto')
GROUP BY t.id_tienda, t.nombre, t.ciudad, t.region, p.id_producto, p.nombre, c.nombre, p.precio_costo, p.precio_venta
ORDER BY t.region, t.nombre, margen_porcentaje DESC, ingresos_totales DESC;
