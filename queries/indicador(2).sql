-- Indicador 2: Análisis comparativo entre descuentos y devoluciones por tienda y región

SELECT 
    t.nombre AS tienda,
    t.ciudad,
    t.region,
    ROUND(SUM(dp.cantidad * dp.precio_unitario), 2) AS ingresos_sin_descuento,
    ROUND(SUM(dp.cantidad * dp.precio_unitario * dp.descuento / 100), 2) AS monto_descuentos,
    ROUND((SUM(dp.cantidad * dp.precio_unitario * dp.descuento / 100) / 
           SUM(dp.cantidad * dp.precio_unitario)) * 100, 2) AS descuentos_porcentaje,
    COALESCE(ROUND(SUM(d.monto_reembolso), 2), 0) AS monto_reembolsos,
    ROUND((COALESCE(SUM(d.monto_reembolso), 2) / 
           SUM(dp.cantidad * dp.precio_unitario)) * 100, 2) AS reembolsos_porcentaje,
    COALESCE(ROUND(SUM(d.monto_reembolso), 2), 0) + 
    ROUND(SUM(dp.cantidad * dp.precio_unitario * dp.descuento / 100), 2) AS perdida_total,
    ROUND(((COALESCE(SUM(d.monto_reembolso), 2) + 
            SUM(dp.cantidad * dp.precio_unitario * dp.descuento / 100)) / 
            SUM(dp.cantidad * dp.precio_unitario)) * 100, 2) AS perdida_total_porcentaje,
    CASE 
        WHEN ROUND(SUM(dp.cantidad * dp.precio_unitario * dp.descuento / 100), 2) > 
             COALESCE(ROUND(SUM(d.monto_reembolso), 2), 0)
        THEN 'DESCUENTOS - Factor Principal'
        ELSE 'DEVOLUCIONES - Factor Principal'
    END AS factor_principal
FROM detalle_pedido dp
JOIN pedido p ON dp.id_pedido = p.id_pedido
JOIN tienda t ON p.id_tienda = t.id_tienda
LEFT JOIN devolucion d ON p.id_pedido = d.id_pedido
WHERE p.estado IN ('completado', 'devuelto')
GROUP BY t.id_tienda, t.nombre, t.ciudad, t.region
ORDER BY t.region, t.nombre, perdida_total DESC;
