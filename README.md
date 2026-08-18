# Brian Santoso

**Data Solutions Architect** | SQL Architecture & Trade Compliance | Sydney

---

## About Me

Advanced SQL engineer with deep trade compliance & customs domain expertise. Hands-on problem-solver. Detail-oriented. Prefer direct solutions over standard workflows.

---

## Professional Work

### **[Schematic Claude Skills](https://github.com/briansantoso-eng/schematic-claude-skills)**

A suite of Claude Code skills that turns a large, inheritance-driven reference database into plain-English lookups — and generates the Excel change requests a governance process actually accepts.

**Skills Suite:**
- **Criteria Library** — live lookups across product hierarchies, areas, modules and valid configurations
- **Registry Change Designer** — parses a change request, resolves inheritance, generates a before/after Excel comparison
- **Release Group Routing** — routing lookups, plus impact analysis before a code is retired

**What it solves:** Documents registry changes against live current state | Parses natural-language change requests | Refuses to generate a sheet when a code collides or a row needs a human decision | Surfaces the inheritance cases that quietly cost 4× the expected effort

**Technical highlights:** Parameterised T-SQL | XML hierarchy parsing | Single-source-of-truth reference doc, no hard-coded domain values | Generated Excel deliverables

*Public write-up of the architecture and design decisions; the implementation is internal.*

---

## Personal Projects

### **[Data Architect Portfolio](https://github.com/briansantoso-eng/FreightDW-Portfolio)**

**FreightDW: Enterprise Data Warehouse**

Star schema dimensional model with production-grade patterns:
- SCD Type 1/2 slowly changing dimensions
- Multi-layer ETL (staging → conformed → analytics)
- 100% data quality validation
- Strategic indexing for enterprise queries
- 18 analytics KPIs

**Skills:** Advanced SQL | Data modeling | ETL/SCD | Query optimization | Database architecture | Data quality frameworks

### **[Automated Visa Form Routing System](https://github.com/briansantoso-eng/visa-form-automation)**

**Event-driven email automation with conditional routing**

Zero-code workflow that classifies inbound inquiries and auto-replies with the correct application form:
- Branch routing on subject line via parallel Paths, not sequential filters
- Dynamic recipient mapping — replies to any sender, no allowlist to maintain
- Unmatched subjects halt cleanly; concurrent senders run in full isolation
- Diagnosed a silent routing bug where a failed Filter halted the whole run instead of skipping a branch

**Skills:** Workflow automation | Event-driven design | Conditional routing | Gmail integration | Systematic debugging

---

## Tech Stack

**Database:** SQL Server (T-SQL) | **Query Patterns:** Advanced optimization, subqueries, window functions | **Tools:** SSMS, Python, Excel, Git | **Domain:** CargoWise, customs & trade compliance

---

**Email:** brian.santosoeng@gmail.com | **Sydney, Australia**
