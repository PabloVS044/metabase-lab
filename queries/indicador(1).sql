-- Indicador 1: Ingresos y Rendimiento por región 
SELECT 
    t.region,
    COUNT(DISTINCT pe.id_pedido) AS total_pedidos,
    ROUND(SUM(dp.cantidad * dp.precio_unitario * (1 - dp.descuento / 100)), 2) AS ingresos_netos,
    ROUND(SUM(dp.cantidad * (dp.precio_unitario * (1 - dp.descuento / 100) - p.precio_costo)), 2) AS ganancia_neta,
    ROUND(SUM(dp.cantidad * (dp.precio_unitario * (1 - dp.descuento / 100) - p.precio_costo)) / NULLIF(SUM(dp.cantidad * dp.precio_unitario * (1 - dp.descuento / 100)), 0) * 100, 2) AS margen_porcentaje
FROM tienda t
JOIN pedido pe ON t.id_tienda = pe.id_tienda
JOIN detalle_pedido dp ON pe.id_pedido = dp.id_pedido
JOIN producto p ON dp.id_producto = p.id_producto
WHERE pe.estado IN ('completado', 'devuelto')
GROUP BY t.region
ORDER BY ganancia_neta DESC;