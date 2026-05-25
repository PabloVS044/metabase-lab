-- Indicador 5: Contribución de ingresos por segmento de cliente (VIP, regular, nuevo)

SELECT
    c.segmento,
    COUNT(DISTINCT c.id_cliente)                                                          AS total_clientes,
    COUNT(DISTINCT p.id_pedido)                                                           AS total_pedidos,
    ROUND(COUNT(DISTINCT p.id_pedido)::NUMERIC / COUNT(DISTINCT c.id_cliente), 2)        AS pedidos_por_cliente,
    ROUND(SUM(dp.cantidad * dp.precio_unitario * (1 - dp.descuento / 100)), 2)           AS ingresos_totales,
    ROUND(SUM(dp.cantidad * dp.precio_unitario * (1 - dp.descuento / 100))
         / NULLIF(COUNT(DISTINCT c.id_cliente), 0), 2)                                   AS ingreso_por_cliente,
    ROUND(SUM(dp.cantidad * dp.precio_unitario * (1 - dp.descuento / 100))
         / NULLIF(COUNT(DISTINCT p.id_pedido), 0), 2)                                    AS ticket_promedio,
    ROUND((SUM(dp.cantidad * dp.precio_unitario * (1 - dp.descuento / 100))
         / NULLIF(SUM(SUM(dp.cantidad * dp.precio_unitario * (1 - dp.descuento / 100)))
             OVER (), 0)) * 100, 2)                                                      AS porcentaje_ingresos
FROM cliente c
JOIN pedido p          ON c.id_cliente = p.id_cliente
JOIN detalle_pedido dp ON p.id_pedido  = dp.id_pedido
WHERE p.estado IN ('completado', 'devuelto')
GROUP BY c.segmento
ORDER BY ingresos_totales DESC;
