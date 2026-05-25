-- Indicador 3: Margen de ganancias dentro de las tiendas, en diferentes regiones. 

SELECT 
    t.nombre AS tienda,
    t.ciudad,
    t.region,
    COUNT(DISTINCT p.id_pedido) AS total_pedidos,
    SUM(dp.cantidad) AS unidades_vendidas,
    ROUND(SUM(dp.cantidad * dp.precio_unitario * (1 - dp.descuento / 100)), 2) AS ingresos_totales,
    ROUND(SUM(dp.cantidad * pr.precio_costo), 2) AS costos_totales,
    ROUND(SUM(dp.cantidad * dp.precio_unitario * (1 - dp.descuento / 100)) - 
          SUM(dp.cantidad * pr.precio_costo), 2) AS margen_bruto,
    ROUND(((SUM(dp.cantidad * dp.precio_unitario * (1 - dp.descuento / 100)) - 
            SUM(dp.cantidad * pr.precio_costo)) / 
            SUM(dp.cantidad * dp.precio_unitario * (1 - dp.descuento / 100))) * 100, 2) AS margen_porcentaje_bruto,
    COALESCE(ROUND(SUM(d.monto_reembolso), 2), 0) AS reembolsos_devoluciones,
    ROUND(SUM(dp.cantidad * dp.precio_unitario * (1 - dp.descuento / 100)) - 
          SUM(dp.cantidad * pr.precio_costo) - 
          COALESCE(SUM(d.monto_reembolso), 0), 2) AS margen_neto,
    ROUND(((SUM(dp.cantidad * dp.precio_unitario * (1 - dp.descuento / 100)) - 
            SUM(dp.cantidad * pr.precio_costo) - 
            COALESCE(SUM(d.monto_reembolso), 0)) / 
            SUM(dp.cantidad * dp.precio_unitario * (1 - dp.descuento / 100))) * 100, 2) AS margen_porcentaje_neto
FROM tienda t
JOIN pedido p ON t.id_tienda = p.id_tienda
JOIN detalle_pedido dp ON p.id_pedido = dp.id_pedido
JOIN producto pr ON dp.id_producto = pr.id_producto
LEFT JOIN devolucion d ON p.id_pedido = d.id_pedido
WHERE p.estado IN ('completado', 'devuelto')
GROUP BY t.id_tienda, t.nombre, t.ciudad, t.region
ORDER BY t.region, t.nombre, margen_neto DESC, margen_porcentaje_neto DESC;
