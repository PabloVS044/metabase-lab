-- Tab 2, Indicador 10: Capital Inmovilizado en Inventario por Categoría
-- Muestra cuánto capital está retenido en el inventario actual de las tiendas,
-- calculando el valor de costo total y el margen de ganancia potencial.

SELECT 
    c.departamento,
    c.nombre AS categoria,
    SUM(i.stock_actual) AS unidades_en_stock,
    ROUND(SUM(i.stock_actual * pr.precio_costo), 2) AS capital_inmovilizado_costo,
    ROUND(SUM(i.stock_actual * pr.precio_venta), 2) AS valor_venta_potencial,
    ROUND(SUM(i.stock_actual * (pr.precio_venta - pr.precio_costo)), 2) AS margen_potencial,
    ROUND(
        (SUM(i.stock_actual * (pr.precio_venta - pr.precio_costo)) / 
        NULLIF(SUM(i.stock_actual * pr.precio_venta), 0)) * 100
    , 2) AS margen_potencial_porcentaje
FROM inventario i
JOIN producto pr ON i.id_producto = pr.id_producto
JOIN categoria c ON pr.id_categoria = c.id_categoria
GROUP BY c.departamento, c.nombre
ORDER BY capital_inmovilizado_costo DESC;
