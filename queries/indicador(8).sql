-- Tab 2, Indicador 8: Rentabilidad por segmento de cliente
-- Compara ingresos, costos, margen bruto e ingreso por cliente
-- entre los segmentos VIP, regular y nuevo.

SELECT
    c.segmento,
    COUNT(DISTINCT c.id_cliente) AS clientes_activos,
    COUNT(DISTINCT pe.id_pedido) AS total_pedidos,
    ROUND(COUNT(DISTINCT pe.id_pedido)::numeric /
          NULLIF(COUNT(DISTINCT c.id_cliente), 0), 2) AS pedidos_por_cliente,
    ROUND(SUM(dp.cantidad * dp.precio_unitario * (1 - dp.descuento / 100)), 2) AS ingresos_totales,
    ROUND(SUM(dp.cantidad * pr.precio_costo), 2) AS costos_totales,
    ROUND(SUM(dp.cantidad * dp.precio_unitario * (1 - dp.descuento / 100)) -
          SUM(dp.cantidad * pr.precio_costo), 2) AS margen_bruto,
    ROUND(SUM(dp.cantidad * dp.precio_unitario * (1 - dp.descuento / 100)) /
          NULLIF(COUNT(DISTINCT c.id_cliente), 0), 2) AS ingreso_por_cliente,
    ROUND(((SUM(dp.cantidad * dp.precio_unitario * (1 - dp.descuento / 100)) -
            SUM(dp.cantidad * pr.precio_costo)) /
            NULLIF(SUM(dp.cantidad * dp.precio_unitario * (1 - dp.descuento / 100)), 0)) * 100, 2) AS margen_porcentaje
FROM cliente c
JOIN pedido pe ON c.id_cliente = pe.id_cliente
JOIN detalle_pedido dp ON pe.id_pedido = dp.id_pedido
JOIN producto pr ON dp.id_producto = pr.id_producto
WHERE pe.estado IN ('completado', 'devuelto')
GROUP BY c.segmento
ORDER BY margen_bruto DESC;
