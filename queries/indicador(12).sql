-- Tab 2, Indicador 12: Rentabilidad y Margen Bruto por Proveedor
-- Evalúa el desempeño financiero de los productos según su proveedor,
-- mostrando ingresos, costos y el margen de ganancia real obtenido.

SELECT
    prov.nombre AS proveedor,
    prov.pais,
    prov.calificacion,
    SUM(dp.cantidad) AS unidades_vendidas,
    ROUND(SUM(dp.cantidad * pr.precio_costo), 2) AS costo_total,
    ROUND(SUM(dp.cantidad * dp.precio_unitario * (1 - dp.descuento / 100)), 2) AS ingresos_generados,
    ROUND(SUM(dp.cantidad * dp.precio_unitario * (1 - dp.descuento / 100)) - SUM(dp.cantidad * pr.precio_costo), 2) AS margen_bruto,
    ROUND(
        ((SUM(dp.cantidad * dp.precio_unitario * (1 - dp.descuento / 100)) - SUM(dp.cantidad * pr.precio_costo)) /
        NULLIF(SUM(dp.cantidad * dp.precio_unitario * (1 - dp.descuento / 100)), 0)) * 100
    , 2) AS margen_porcentaje
FROM proveedor prov
JOIN producto pr ON prov.id_proveedor = pr.id_proveedor
JOIN detalle_pedido dp ON pr.id_producto = dp.id_producto
JOIN pedido pe ON dp.id_pedido = pe.id_pedido
WHERE pe.estado IN ('completado', 'devuelto')
GROUP BY prov.id_proveedor, prov.nombre, prov.pais, prov.calificacion
ORDER BY margen_bruto DESC;
