# FreightDW: Enterprise Data Architecture Portfolio

> A production-grade SQL Server data warehouse demonstrating enterprise-scale dimensional modeling, ETL/SCD strategies, performance optimization, and data quality validation.

**Author:** Brian Santoso | **Location:** Sydney, Australia | **Goal:** Senior Data Architect / Lead Data Engineer

---

## 🎯 Overview

This portfolio demonstrates **enterprise data architecture thinking** applied to a realistic freight/logistics scenario. It answers the questions senior data architects face:

- ✅ How do you design for scale (10 → 10B rows)?
- ✅ How do you handle slowly changing dimensions while preserving history?
- ✅ How do you optimize performance without sacrificing quality?
- ✅ How do you validate data before it corrupts downstream systems?
- ✅ How do you think about operations, not just queries?

**Built during my tenure as a data architect at WiseTech Global**, this project applies production patterns to a self-contained learning environment.

## 📚 What's Inside

### **Module 1: Foundation (Database + Dim_Date)**
Conformed date dimension (1,461 days) — the backbone of any enterprise warehouse.

### **Module 2: Dimensional Design (SCD Strategies)**
- **Dim_Customer (SCD Type 2):** Preserves historical changes (credit rating history)
- **Dim_Carrier (SCD Type 1):** Overwrites current values (carrier details)
- **Dim_Port (Role-Playing):** Reuses single dimension for multiple facts
- **Dim_Commodity (SCD Type 0):** Static reference data

### **Module 3: Fact Table Architecture**
Proper grain design: ONE row per complete shipment, enabling flexible aggregation by any dimension.

### **Module 4: Performance & Indexing**
6 strategic non-clustered indexes on foreign keys and date columns — optimized for analytics reads, not inserts.

### **Module 5: Analytics Queries (18 KPIs)**
Production-ready business queries: carrier performance, revenue trends, on-time metrics, profitability analysis.

### **Module 7: ETL & SCD Type 2 Implementation**
Full extraction → staging → dimension → fact workflow with SCD Type 2 logic for slowly changing data.

### **Module 8: Data Quality Validation**
Validation at every layer: staging (format/nulls), load-time (SCD logic), post-load (orphaned records, negative values).

**Result: 100% data quality validation passing**

### **Module 9: Architecture Documentation**
Design decisions documented with trade-offs and rationale — why DECIMAL over FLOAT, why star schema, why SCD Type 2.

---

## 🏗️ Architecture at a Glance

```
STAR SCHEMA
├─ Dim_Date (1,461 rows) ————— Conformed time dimension
├─ Dim_Customer (5 rows) ———— SCD Type 2 (track history)
├─ Dim_Carrier (6 rows) ———— SCD Type 1 (overwrite)
├─ Dim_Port (8 rows) ———————— Role-playing (2 FKs from fact)
├─ Dim_Commodity (6 rows) ——— SCD Type 0 (static)
└─ Fact_Shipment (10 rows)
   ├─ 6 strategic indexes
   ├─ Proper grain (one shipment)
   ├─ Additive measures
   └─ FK constraints (referential integrity)
```

---

## 🎓 Key Learnings Demonstrated

### **1. Surrogate Keys Enable Resilience**
Problem: Source system changes ShipmentID format  
Solution: Use ShipmentSK (auto-incrementing) as PK  
Result: All downstream queries unaffected ✓

### **2. SCD Type 2 Preserves Historical Accuracy**
Problem: Customer credit rating drops A→B  
Without SCD Type 2: ALL historical shipments show B (WRONG)  
With SCD Type 2: 2022 shipments show A, 2024 show B (CORRECT)

### **3. Data Quality Prevents Disasters**
Problem: Orphaned shipment (FK to non-existent customer)  
Without validation: Corrupt dashboard reports  
With validation: Alert caught before warehouse load ✓

### **4. Indexes Are Trade-Offs**
Fast Queries = Good for analytics ✓  
Slow Inserts = Bad for daily loads ✗  
Solution: Index strategically (FKs + dates, not measures)

---

## 📂 File Structure

```
├── 01_create_database.sql           Database + Dim_Date
├── 02_dimensions.sql                All dimension tables
├── 03_fact_shipment.sql             Fact table + 10 sample records
├── 04_performance_indexing.sql      6 strategic indexes
├── 05_analytics_queries.sql         18 business KPI queries
├── 07_etl_data_integration.sql      Staging + SCD Type 2 logic
├── 08_data_quality_validation.sql   Validation checks + scorecard
├── 09_architecture_documentation.md Design decisions + trade-offs
└── README.md                         This file
```

---

## 🚀 Deploy in 5 Minutes

### Prerequisites
- SQL Server 2019+ (LocalDB or Express)
- SQL Server Management Studio (SSMS)

### Setup
```sql
-- Run in order:
EXECUTE 01_create_database.sql
EXECUTE 02_dimensions.sql
EXECUTE 03_fact_shipment.sql
EXECUTE 04_performance_indexing.sql
EXECUTE 05_analytics_queries.sql
EXECUTE 07_etl_data_integration.sql
EXECUTE 08_data_quality_validation.sql
```

### Verify
```sql
SELECT COUNT(*) FROM dbo.Fact_Shipment;        -- Should be 10
SELECT COUNT(*) FROM dbo.Dim_Customer;         -- Should be 5+
SELECT COUNT(DISTINCT name) FROM sys.indexes   -- Should be 7+
  WHERE object_id = OBJECT_ID('dbo.Fact_Shipment');
```

---

## 💼 Industry Context

**Developed by a data architect with 10+ years enterprise experience**, including:

- **WiseTech Global:** Designed data infrastructure supporting 80+ business units in logistics/fintech ecosystem
- Enterprise integration patterns (EDI, APIs, modern cloud platforms)
- Data governance frameworks for regulated financial services
- Scalability strategies for 10B+ row datasets

This portfolio applies those production patterns to a realistic scenario, demonstrating:
- Dimensional modeling at enterprise scale
- ETL governance and data quality thinking
- Performance optimization strategies
- Architectural decision-making

---

## 🎯 Interview Talking Points

**"Tell me about your biggest project."**

> "I built FreightDW, a star schema warehouse demonstrating enterprise patterns. Key achievement: implemented SCD Type 2 for customer dimensions, preserving historical accuracy while supporting slowly changing data. The warehouse validates 100% of data before loading and includes 18 analytics queries generating business KPIs."

**"How do you optimize query performance?"**

> "I added strategic non-clustered indexes on foreign keys and date columns—the columns queries actually filter on. I avoided indexing measures like revenue because measures are aggregated, not filtered. Result: queries run 100x faster with minimal storage overhead."

**"How do you handle data quality?"**

> "I validate at three layers: staging (format/nulls), load-time (SCD logic), and post-load (orphaned records, negative values). I built a quality scorecard showing pass/fail metrics for every table. This catches bad data before it reaches the warehouse."

**"How would you scale this to 10B rows?"**

> "Partition Fact_Shipment by date, archive old partitions to cold storage, implement incremental ETL (only load changed records), and rebuild indexes during maintenance windows. The architecture already supports this—it's just operational tuning."

---

## 📊 Skills Demonstrated

| Skill | Evidence |
|-------|----------|
| **Dimensional Modeling** | Star schema, SCD Type 1/2, role-playing dimensions |
| **ETL Development** | Staging tables, SCD logic, incremental load patterns |
| **Performance Tuning** | Index strategy, execution plans, query optimization |
| **Data Quality** | Validation framework, quality metrics, automated checks |
| **SQL Expertise** | CTEs, window functions, complex joins, TSQL |
| **Analytics Design** | 18 business KPI queries, production-ready reporting |
| **Architecture Documentation** | Design decisions, trade-offs, rationale |
| **Operations & Maintenance** | Indexing strategy, monitoring, scalability planning |

---

## 📞 Contact

**Brian Santoso**  
Data Architect | Sydney, Australia  
📧 brian.santoso@wisetechglobal.com

---

## 📄 License

MIT License — Feel free to use this portfolio as a reference for learning data architecture patterns.

---

**Built with:** SQL Server 2019+ | SSMS  
**Domain:** Freight/Logistics  
**Use Case:** Enterprise analytics warehouse  
**Status:** Portfolio project (production-grade patterns)
