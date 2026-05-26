-- Indicador 3: Impacto de descuentos en ingresos por tienda
SELECT 
    t.nombre AS tienda,
    t.region,
    ROUND(SUM(dp.cantidad * dp.precio_unitario), 2) AS ingresos_brutos,
    ROUND(SUM(dp.cantidad * dp.precio_unitario * dp.descuento / 100), 2) AS monto_descuentos,
    ROUND(
        (SUM(dp.cantidad * dp.precio_unitario * dp.descuento / 100)
        / NULLIF(SUM(dp.cantidad * dp.precio_unitario), 0)) * 100
    , 2) AS porcentaje_descuento
FROM tienda t
JOIN pedido pe ON t.id_tienda = pe.id_tienda
JOIN detalle_pedido dp ON pe.id_pedido = dp.id_pedido
WHERE pe.estado IN ('completado', 'devuelto')
GROUP BY t.id_tienda, t.nombre, t.region
ORDER BY monto_descuentos DESC;
