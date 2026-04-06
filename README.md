# 📊 Supplier Performance Dashboard

> SQL-powered supplier scorecard with Excel dashboard — OTIF, lead time, quality, spend, and risk flags

[![Python](https://img.shields.io/badge/Python-3.8+-3572A5?style=flat-square&logo=python&logoColor=white)](https://python.org)
[![SQL](https://img.shields.io/badge/SQL-SQLite-e38c00?style=flat-square&logo=sqlite&logoColor=white)](https://sqlite.org)
[![Excel](https://img.shields.io/badge/Excel-Dashboard-217346?style=flat-square&logo=microsoft-excel&logoColor=white)](https://microsoft.com/excel)
[![License](https://img.shields.io/badge/License-MIT-green?style=flat-square)](LICENSE)

---

## 📌 Overview

End-to-end supplier performance system — SQL queries against a structured database, Python pipeline, and a **fully formatted Excel dashboard** with 6 sheets. Tracks OTIF, lead time variance, quality pass rate, spend concentration, and escalation risk across 40+ supplier interactions.

Built from managing supplier performance at **Daimler Trucks India** across 40+ vendors, driving **12% improvement in on-time delivery** and **~20% reduction in line-down incidents**.

---

## 🗄️ Architecture

```
supplier_data.db (SQLite)
├── suppliers          — vendor master (name, category, country, AVL status)
├── purchase_orders    — PO data (cost, qty, dates, escalation flags)
├── deliveries         — actual vs committed delivery dates, OTIF flags
└── quality_records    — inspection results, defect qty, defect type

supplier_performance.sql   — 7 analytical SQL queries
build_dashboard.py         — seeds DB, runs queries, builds Excel
supplier_performance_dashboard.xlsx  — output: 6-sheet dashboard
```

---

## 📊 Dashboard Sheets

| Sheet | Contents |
|---|---|
| 📊 **Summary Dashboard** | KPI cards (OTIF, Quality, Spend, Escalations) + master scorecard |
| 📈 **OTIF Trend** | Monthly OTIF % per supplier over 12 months + line chart |
| 🔍 **Quality Report** | Inspection pass rate, defect qty, conditional formatting |
| 💰 **Spend Analysis** | Spend by supplier, % of total, bar chart |
| 🚨 **Risk Flags** | Escalation count + OTIF-based risk scoring (🔴🟡🟢) |
| 📋 **Raw Data** | Full SQL output for further analysis |

---

## 🔍 SQL Queries (`supplier_performance.sql`)

| Query | Purpose |
|---|---|
| `1. Supplier Scorecard` | Master KPIs — OTIF, lead time, quality, spend per supplier |
| `2. OTIF Trend` | Monthly OTIF for sparklines and trend analysis |
| `3. Lead Time Analysis` | Avg vs committed lead time, variance per category |
| `4. Quality & Defect Report` | Inspection pass rate, defect PPM |
| `5. Spend Analysis` | Spend concentration, cumulative % (Pareto) |
| `6. Escalation & Risk Flags` | Risk scoring with single-source flag |
| `7. Business Review Prep` | Last 90 days — ready for QBR with suppliers |

---

## 🗂️ Project Structure

```
supplier-performance-dashboard/
│
├── supplier_performance.sql              # 7 SQL queries — run independently
├── build_dashboard.py                    # Pipeline: seed DB → run SQL → export Excel
│
├── supplier_data.db                      # Generated: SQLite database
├── supplier_performance_dashboard.xlsx   # Generated: 6-sheet Excel dashboard
│
└── README.md
```

---

## 🚀 Quick Start

### 1. Clone
```bash
git clone https://github.com/nisargamurthy1/supplier-performance-dashboard.git
cd supplier-performance-dashboard
```

### 2. Install
```bash
pip install pandas openpyxl
```

### 3. Run
```bash
python build_dashboard.py
```

### 4. Open the dashboard
Open `supplier_performance_dashboard.xlsx` in Excel or Google Sheets.

### 5. Run SQL queries independently
```bash
sqlite3 supplier_data.db < supplier_performance.sql
```
Or open `supplier_data.db` in [DB Browser for SQLite](https://sqlitebrowser.org/) and run individual queries from `supplier_performance.sql`.

---

## 📊 Sample KPIs (from seeded data)

| KPI | Value |
|---|---|
| Avg OTIF | 83.7% |
| Avg Quality Pass Rate | 91.7% |
| Total Spend | $1.7M |
| Total Escalations | 26 |
| Suppliers Tracked | 8 |

---

## 🔧 Customize

**Add your own supplier data** — replace the `seed_database()` function in `build_dashboard.py` with a load from your own CSV:
```python
df = pd.read_csv("your_suppliers.csv")
df.to_sql("suppliers", conn, if_exists="replace", index=False)
```

**Adjust risk thresholds** in `build_dashboard.py`:
```python
risk["risk_flag"] = risk.apply(lambda r:
    "🔴 HIGH RISK" if r["escalations"] >= 3 or r["otif_pct"] < 75 else ...
```

**Run individual SQL queries** by copying from `supplier_performance.sql` into your ERP's reporting tool (SAP, NetSuite, etc.) — queries are written in standard SQL.

---

## 📈 Real-World Results

Replicates supplier management work at **Daimler Trucks India**:

- 📊 Tracked **40+ suppliers** across mechanical, electrical, and electronics categories
- 🚛 Drove **12% improvement in on-time delivery** through scorecard-driven reviews
- 📈 Elevated **CTB status by 8.2%** via cross-functional supplier alignment
- 🏭 Reduced **line-down risk incidents by ~20%** through early escalation detection
- 📋 Maintained **COA/SDS compliance** tracking for all approved vendors

---

## 👩‍💻 Author

**Nisarga Narasimhamurthy**  
Supply Chain & Procurement Professional | San Jose, CA  
[LinkedIn](https://linkedin.com/in/nisarga-narasimhamurthy) · [Email](mailto:nnarasimhamu@umass.edu)
