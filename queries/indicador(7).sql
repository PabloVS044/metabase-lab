-- Tab 2, Indicador 7: Distribución de ingresos por método de pago
-- Muestra cuánto dinero entra por cada canal de pago (efectivo, tarjeta, transferencia),
-- su participación porcentual y el ticket promedio por transacción.

SELECT
    pa.metodo AS metodo_pago,
    COUNT(DISTINCT pa.id_pago) AS cantidad_transacciones,
    ROUND(SUM(pa.monto), 2) AS monto_total,
    ROUND(
        SUM(pa.monto) / SUM(SUM(pa.monto)) OVER () * 100
    , 2) AS porcentaje_del_total,
    ROUND(AVG(pa.monto), 2) AS ticket_promedio
FROM pago pa
JOIN pedido pe ON pa.id_pedido = pe.id_pedido
WHERE pe.estado IN ('completado', 'devuelto')
GROUP BY pa.metodo
ORDER BY monto_total DESC;
