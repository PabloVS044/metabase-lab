-- Tab 2, Indicador 11: Impacto Financiero de Devoluciones por Motivo
-- Analiza el costo que asume la empresa en reembolsos por devoluciones, 
-- agrupado por el motivo de la devolución.

SELECT
    dev.motivo,
    COUNT(dev.id_devolucion) AS cantidad_devoluciones,
    ROUND(SUM(dev.monto_reembolso), 2) AS total_reembolsado,
    ROUND(AVG(dev.monto_reembolso), 2) AS reembolso_promedio,
    ROUND(
        SUM(dev.monto_reembolso) / SUM(SUM(dev.monto_reembolso)) OVER () * 100
    , 2) AS porcentaje_del_total_perdido
FROM devolucion dev
JOIN pedido pe ON dev.id_pedido = pe.id_pedido
GROUP BY dev.motivo
ORDER BY total_reembolsado DESC;
