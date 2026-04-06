-- ============================================================
-- supplier_performance.sql
-- Supplier Performance Dashboard — SQL Analysis Queries
-- Author: Nisarga Narasimhamurthy
-- ============================================================
-- Run against: supplier_data.db (SQLite)
-- Tables: suppliers, purchase_orders, deliveries, quality_records
-- ============================================================


-- ── 1. SUPPLIER SCORECARD ─────────────────────────────────────────────────
-- Master scorecard: OTIF, quality, lead time, spend per supplier

SELECT
    s.supplier_id,
    s.supplier_name,
    s.category,
    s.country,
    COUNT(po.po_number)                                          AS total_pos,
    ROUND(SUM(po.total_value), 2)                               AS total_spend,
    ROUND(AVG(po.unit_cost), 2)                                 AS avg_unit_cost,

    -- OTIF: delivered on time and in full
    ROUND(
        100.0 * SUM(CASE WHEN d.on_time = 1 AND d.in_full = 1 THEN 1 ELSE 0 END)
        / NULLIF(COUNT(d.delivery_id), 0), 1
    )                                                           AS otif_pct,

    -- On-time delivery rate
    ROUND(
        100.0 * SUM(CASE WHEN d.on_time = 1 THEN 1 ELSE 0 END)
        / NULLIF(COUNT(d.delivery_id), 0), 1
    )                                                           AS on_time_pct,

    -- Average lead time (days from PO to GR)
    ROUND(AVG(
        JULIANDAY(d.actual_delivery_date) - JULIANDAY(po.po_date)
    ), 1)                                                       AS avg_lead_time_days,

    -- Lead time variance vs committed
    ROUND(AVG(
        JULIANDAY(d.actual_delivery_date) - JULIANDAY(d.committed_delivery_date)
    ), 1)                                                       AS avg_lead_time_variance_days,

    -- Quality: acceptance rate
    ROUND(
        100.0 * SUM(CASE WHEN q.inspection_result = 'PASS' THEN 1 ELSE 0 END)
        / NULLIF(COUNT(q.inspection_id), 0), 1
    )                                                           AS quality_pass_pct,

    -- Total defects
    SUM(COALESCE(q.defect_qty, 0))                             AS total_defects,

    -- Escalations
    SUM(COALESCE(po.escalation_flag, 0))                        AS total_escalations

FROM suppliers s
LEFT JOIN purchase_orders po  ON s.supplier_id = po.supplier_id
LEFT JOIN deliveries d        ON po.po_number   = d.po_number
LEFT JOIN quality_records q   ON d.delivery_id  = q.delivery_id

GROUP BY s.supplier_id, s.supplier_name, s.category, s.country
ORDER BY otif_pct DESC;


-- ── 2. OTIF TREND BY MONTH ────────────────────────────────────────────────
-- Monthly OTIF trend per supplier — for sparkline charts in dashboard

SELECT
    s.supplier_name,
    STRFTIME('%Y-%m', d.actual_delivery_date)                   AS month,
    COUNT(d.delivery_id)                                        AS deliveries,
    ROUND(
        100.0 * SUM(CASE WHEN d.on_time = 1 AND d.in_full = 1 THEN 1 ELSE 0 END)
        / NULLIF(COUNT(d.delivery_id), 0), 1
    )                                                           AS otif_pct
FROM suppliers s
JOIN purchase_orders po ON s.supplier_id = po.supplier_id
JOIN deliveries d        ON po.po_number  = d.po_number
WHERE d.actual_delivery_date >= DATE('now', '-12 months')
GROUP BY s.supplier_name, month
ORDER BY s.supplier_name, month;


-- ── 3. LEAD TIME ANALYSIS ─────────────────────────────────────────────────
-- Avg vs committed lead time, and variance per supplier per part category

SELECT
    s.supplier_name,
    po.part_category,
    COUNT(po.po_number)                                         AS po_count,
    ROUND(AVG(po.committed_lead_time_days), 1)                 AS avg_committed_days,
    ROUND(AVG(
        JULIANDAY(d.actual_delivery_date) - JULIANDAY(po.po_date)
    ), 1)                                                       AS avg_actual_days,
    ROUND(AVG(
        JULIANDAY(d.actual_delivery_date) - JULIANDAY(d.committed_delivery_date)
    ), 1)                                                       AS avg_variance_days,
    MAX(JULIANDAY(d.actual_delivery_date) - JULIANDAY(d.committed_delivery_date))
                                                                AS max_slip_days
FROM suppliers s
JOIN purchase_orders po ON s.supplier_id = po.supplier_id
JOIN deliveries d        ON po.po_number  = d.po_number
GROUP BY s.supplier_name, po.part_category
ORDER BY avg_variance_days DESC;


-- ── 4. QUALITY & DEFECT REPORT ────────────────────────────────────────────
-- Inspection pass rate and defect qty by supplier

SELECT
    s.supplier_name,
    s.category,
    COUNT(q.inspection_id)                                      AS total_inspections,
    SUM(CASE WHEN q.inspection_result = 'PASS' THEN 1 ELSE 0 END) AS passed,
    SUM(CASE WHEN q.inspection_result = 'FAIL' THEN 1 ELSE 0 END) AS failed,
    ROUND(
        100.0 * SUM(CASE WHEN q.inspection_result = 'PASS' THEN 1 ELSE 0 END)
        / NULLIF(COUNT(q.inspection_id), 0), 1
    )                                                           AS pass_rate_pct,
    SUM(COALESCE(q.defect_qty, 0))                             AS total_defect_qty,
    SUM(COALESCE(q.defect_qty, 0)) * 1.0
        / NULLIF(SUM(d.received_qty), 0) * 1000000             AS defect_ppm
FROM suppliers s
JOIN purchase_orders po  ON s.supplier_id = po.supplier_id
JOIN deliveries d        ON po.po_number   = d.po_number
JOIN quality_records q   ON d.delivery_id  = q.delivery_id
GROUP BY s.supplier_name, s.category
ORDER BY pass_rate_pct ASC;


-- ── 5. SPEND ANALYSIS ─────────────────────────────────────────────────────
-- Spend concentration — top suppliers by value, % of total spend

WITH total AS (
    SELECT SUM(total_value) AS grand_total FROM purchase_orders
)
SELECT
    s.supplier_name,
    s.category,
    COUNT(po.po_number)                                         AS po_count,
    ROUND(SUM(po.total_value), 2)                               AS total_spend,
    ROUND(100.0 * SUM(po.total_value) / total.grand_total, 1)  AS spend_pct,
    ROUND(SUM(SUM(po.total_value)) OVER (
        ORDER BY SUM(po.total_value) DESC
    ) / total.grand_total * 100, 1)                             AS cumulative_spend_pct
FROM suppliers s
JOIN purchase_orders po ON s.supplier_id = po.supplier_id
CROSS JOIN total
GROUP BY s.supplier_name, s.category, total.grand_total
ORDER BY total_spend DESC;


-- ── 6. ESCALATION & RISK FLAGS ────────────────────────────────────────────
-- Suppliers with escalations, single-source risk, and low OTIF

SELECT
    s.supplier_name,
    s.category,
    COUNT(DISTINCT po.part_number)                              AS parts_supplied,
    SUM(COALESCE(po.escalation_flag, 0))                        AS escalations,
    ROUND(
        100.0 * SUM(CASE WHEN d.on_time = 1 AND d.in_full = 1 THEN 1 ELSE 0 END)
        / NULLIF(COUNT(d.delivery_id), 0), 1
    )                                                           AS otif_pct,
    CASE
        WHEN SUM(COALESCE(po.escalation_flag, 0)) >= 3          THEN '🔴 HIGH RISK'
        WHEN SUM(COALESCE(po.escalation_flag, 0)) >= 1          THEN '🟡 MONITOR'
        ELSE                                                         '🟢 OK'
    END                                                         AS risk_flag,
    CASE
        WHEN COUNT(DISTINCT po.part_number) = 1                 THEN '⚠️ Single Source'
        ELSE                                                         'Multi Source'
    END                                                         AS source_risk
FROM suppliers s
JOIN purchase_orders po ON s.supplier_id = po.supplier_id
JOIN deliveries d        ON po.po_number  = d.po_number
GROUP BY s.supplier_name, s.category
ORDER BY escalations DESC, otif_pct ASC;


-- ── 7. SUPPLIER BUSINESS REVIEW PREP ─────────────────────────────────────
-- Last 90 days performance — used for QBR / supplier business reviews

SELECT
    s.supplier_name,
    s.contact_name,
    s.contact_email,
    COUNT(po.po_number)                                         AS pos_last_90d,
    ROUND(SUM(po.total_value), 2)                               AS spend_last_90d,
    ROUND(
        100.0 * SUM(CASE WHEN d.on_time = 1 AND d.in_full = 1 THEN 1 ELSE 0 END)
        / NULLIF(COUNT(d.delivery_id), 0), 1
    )                                                           AS otif_pct,
    ROUND(AVG(
        JULIANDAY(d.actual_delivery_date) - JULIANDAY(d.committed_delivery_date)
    ), 1)                                                       AS avg_lead_time_variance,
    SUM(COALESCE(q.defect_qty, 0))                             AS defects,
    SUM(COALESCE(po.escalation_flag, 0))                        AS escalations
FROM suppliers s
JOIN purchase_orders po  ON s.supplier_id = po.supplier_id
JOIN deliveries d        ON po.po_number   = d.po_number
LEFT JOIN quality_records q ON d.delivery_id = q.delivery_id
WHERE po.po_date >= DATE('now', '-90 days')
GROUP BY s.supplier_name, s.contact_name, s.contact_email
ORDER BY otif_pct ASC;
