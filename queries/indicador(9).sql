-- Tab 2, Indicador 9: Evolución mensual de ingresos, costos y margen bruto
-- Muestra la tendencia financiera mes a mes durante todo el período de datos.

SELECT
    TO_CHAR(pe.fecha, 'YYYY-MM') AS mes,
    ROUND(SUM(dp.cantidad * dp.precio_unitario * (1 - dp.descuento / 100)), 2) AS ingresos,
    ROUND(SUM(dp.cantidad * pr.precio_costo), 2) AS costos,
    ROUND(SUM(dp.cantidad * dp.precio_unitario * (1 - dp.descuento / 100)) -
          SUM(dp.cantidad * pr.precio_costo), 2) AS margen_bruto,
    ROUND(((SUM(dp.cantidad * dp.precio_unitario * (1 - dp.descuento / 100)) -
            SUM(dp.cantidad * pr.precio_costo)) /
            NULLIF(SUM(dp.cantidad * dp.precio_unitario * (1 - dp.descuento / 100)), 0)) * 100, 2) AS margen_porcentaje
FROM pedido pe
JOIN detalle_pedido dp ON pe.id_pedido = dp.id_pedido
JOIN producto pr ON dp.id_producto = pr.id_producto
WHERE pe.estado IN ('completado', 'devuelto')
GROUP BY TO_CHAR(pe.fecha, 'YYYY-MM')
ORDER BY mes;
