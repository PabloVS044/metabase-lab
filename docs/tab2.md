# Tab 2 — Indicadores Financieros (7–12)

---

## Indicador 7: Distribución de ingresos por método de pago

**Qué representa:** El total recaudado, participación porcentual y ticket promedio por cada método de pago (efectivo, tarjeta, transferencia).

**Importancia:** Permite identificar qué canales de pago mueven más dinero y cuál tiene mayor valor por transacción, información útil para decisiones de comisiones, promociones o eliminación de métodos poco usados.

**Visualización:** Gráfica de pastel para la participación porcentual; tabla complementaria con monto total y ticket promedio. El pastel comunica de forma inmediata qué método domina.

**SQL:**
```sql
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
```

---

## Indicador 8: Rentabilidad por segmento de cliente

**Qué representa:** Comparación de ingresos totales vs margen bruto por segmento de cliente (VIP, regular y nuevo).

**Importancia:** Evidencia qué segmento genera más dinero y cuánto queda realmente después de costos, lo que orienta dónde enfocar esfuerzos de fidelización o adquisición.

**Visualización:** Gráfica de barras agrupadas por segmento, con ingresos y margen bruto lado a lado. Facilita ver la brecha entre lo que entra y lo que queda por segmento.

**SQL:**
```sql
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
```

---

## Indicador 9: Evolución mensual de ingresos, costos y margen bruto

**Qué representa:** La tendencia financiera mes a mes: ingresos, costos y margen bruto con su porcentaje, durante todo el período de datos.

**Importancia:** Detecta estacionalidad, meses de bajo rendimiento y si el margen se está comprimiendo con el tiempo, lo que permite anticipar problemas financieros antes de que escalen.

**Visualización:** Gráfica de líneas con el tiempo en el eje X. Es la visualización estándar para series temporales porque muestra claramente tendencias y fluctuaciones.

**SQL:**
```sql
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
```

---

## Indicador 10: Capital inmovilizado en inventario por categoría

**Qué representa:** Cuánto capital está retenido en el stock actual por categoría, con el valor de costo, valor de venta potencial y margen potencial si se vendiera todo.

**Importancia:** Identifica categorías con exceso de inventario que inmovilizan capital sin generar ingresos, ayudando a priorizar liquidación o reducción de compras futuras.

**Visualización:** Gráfica de barras horizontales ordenadas por capital inmovilizado. Permite comparar fácilmente el peso de cada categoría y destacar las más críticas.

**SQL:**
```sql
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
```

---

## Indicador 11: Impacto financiero de devoluciones por motivo

**Qué representa:** El total reembolsado, cantidad de devoluciones y reembolso promedio agrupados por motivo de devolución, con la participación de cada motivo en la pérdida total.

**Importancia:** Identifica qué motivos generan más pérdidas para priorizarlos en planes de mejora operativa o de producto, ya sea calidad, entrega u otros.

**Visualización:** Gráfica de barras ordenadas por total reembolsado. Hace evidente cuál motivo representa el mayor costo sin necesidad de analizar números en detalle.

**SQL:**
```sql
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
```

---

## Indicador 12: Rentabilidad y margen bruto por proveedor

**Qué representa:** Ingresos generados, costos, margen bruto y porcentaje de margen por proveedor, incluyendo país y calificación del proveedor.

**Importancia:** Permite evaluar qué proveedores son más rentables en la práctica y si su calificación se correlaciona con mejores márgenes, lo que apoya decisiones de negociación o cambio de proveedor.

**Visualización:** Tabla ordenada por margen bruto, complementada con una barra de margen porcentual. La tabla es adecuada porque hay múltiples métricas por proveedor que se necesitan ver en conjunto.

**SQL:**
```sql
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
```
