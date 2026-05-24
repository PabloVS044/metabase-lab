-- ========================================================================
-- INDICADOR 1: INGRESOS TOTALES POR TIENDA Y CANAL
-- ========================================================================
-- Descripción: Muestra el total de ingresos (monto de pedidos) 
-- segmentado por tienda y canal de venta (tienda física vs online)
-- 
-- Negocio: KPI crítico para evaluar el desempeño de cada ubicación
-- física y comparar canales de venta
-- 
-- Importancia: Permite identificar qué tiendas generan más ingresos
-- y si el canal online crece vs tiendas físicas
-- 
-- Visualización: Tabla con subtotales o gráfico de barras agrupadas
-- ========================================================================

SELECT 
    t.nombre AS tienda,
    t.ciudad AS ciudad,
    t.region AS region,
    p.canal AS canal_venta,
    COUNT(DISTINCT p.id_pedido) AS cantidad_pedidos,
    SUM(dp.cantidad) AS unidades_vendidas,
    SUM(dp.cantidad * dp.precio_unitario * (1 - dp.descuento / 100)) AS ingreso_total,
    ROUND(
        SUM(dp.cantidad * dp.precio_unitario * (1 - dp.descuento / 100)) / 
        COUNT(DISTINCT p.id_pedido), 2
    ) AS ingreso_promedio_pedido
FROM tienda t
JOIN pedido p ON t.id_tienda = p.id_tienda
JOIN detalle_pedido dp ON p.id_pedido = dp.id_pedido
WHERE p.estado IN ('completado', 'devuelto')
GROUP BY t.id_tienda, t.nombre, t.ciudad, t.region, p.canal
ORDER BY t.region, t.nombre, p.canal;
