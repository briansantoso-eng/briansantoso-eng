# Brian Santoso

**AI Automation Specialist & Consultant** | Sydney

---

## About Me

Design workflows for logistics at scale. Hands-on problem-solver. Detail-oriented. Prefer direct solutions over standard workflows.

---

## Professional Work

### **[Schematic Claude Skills](https://github.com/briansantoso-eng/schematic-claude-skills)**

A suite of **Claude Code agent skills** that turns a large, inheritance-driven reference database into plain-English lookups — and generates the Excel change requests a governance process actually accepts. The hard part was less the SQL than scoping what the agent is allowed to decide on its own.

**Skills Suite:**
- **Criteria Library** — live lookups across product hierarchies, areas, modules and valid configurations
- **Registry Change Designer** — parses a change request, resolves inheritance, generates a before/after Excel comparison
- **Release Group Routing** — routing lookups, plus impact analysis before a code is retired

**What it solves:** Documents registry changes against live current state | Parses natural-language change requests | Refuses to generate a sheet when a code collides or a row needs a human decision | Surfaces the inheritance cases that quietly cost 4× the expected effort

**Technical highlights:** Parameterised T-SQL | XML hierarchy parsing | Single-source-of-truth reference doc, no hard-coded domain values | Generated Excel deliverables

*Public write-up of the architecture and design decisions; the implementation is internal.*

---

## Personal Projects

### **[POS Reconciliation & Receipt Automation — Claude API](https://github.com/briansantoso-eng/receipt-expense-automation)**

**Receipts arrive by email. A bookkeeping spreadsheet comes back. Nobody types anything.**

A client forwards photos of their receipts. Once a week it reads them, checks them, and emails me a summary with the spreadsheet attached:
- **Claude reads the picture; Python checks the sums.** The model never does arithmetic, so if it misreads a total the code catches it before it reaches a spreadsheet
- **Only problems reach a human.** Clean receipts go straight through — anything doubtful is flagged with the reason why, so I only look at the ones that need me
- **It won't run for a client who hasn't paid.** Their receipts are saved but never read, so they cost nothing
- **Nothing goes to a client automatically.** I get the draft, I check it, I send it
- **Tested on real receipts** — crumpled, photographed sideways, one food-stained, one with no GST — all six correct on every total, tax and date
- **Tried making it 40% cheaper by shrinking the photos.** It started reading dates wrong while the totals stayed right, so I measured it properly and undid it

A second pipeline in the same repo handles the POS side: a client emails a sales export and their bank deposit figure, and it explains any gap in plain English.

How each decision was reached, including the two ideas I measured and threw away, is in [DECISIONS.md](https://github.com/briansantoso-eng/receipt-expense-automation/blob/main/DECISIONS.md).

**Skills:** Claude API (structured outputs, vision, batched requests) | Schema design as prompt engineering | Deterministic validation of model output | Exception routing | IMAP/SMTP | Scheduled unattended execution

### **[Automated Visa Form Routing System](https://github.com/briansantoso-eng/visa-form-automation)**

**Event-driven email automation with conditional routing**

Zero-code workflow that classifies inbound inquiries and auto-replies with the correct application form:
- Branch routing on subject line via parallel Paths, not sequential filters
- Dynamic recipient mapping — replies to any sender, no allowlist to maintain
- Unmatched subjects halt cleanly; concurrent senders run in full isolation
- Diagnosed a silent routing bug where a failed Filter halted the whole run instead of skipping a branch

**Skills:** Workflow automation | Event-driven design | Conditional routing | Gmail integration | Systematic debugging

### **[Data Architect Portfolio](https://github.com/briansantoso-eng/FreightDW-Portfolio)**

**FreightDW: Enterprise Data Warehouse**

Star schema dimensional model with production-grade patterns:
- SCD Type 1/2 slowly changing dimensions
- Multi-layer ETL (staging → conformed → analytics)
- 100% data quality validation
- Strategic indexing for enterprise queries
- 18 analytics KPIs

**Skills:** Advanced SQL | Data modeling | ETL/SCD | Query optimization | Database architecture | Data quality frameworks

---

## Tech Stack

**Automation & AI** — Claude Code skill development · Zapier (Paths, Filters, multi-step orchestration) · Gmail API · Event-driven workflow design · Conditional branch routing · Natural-language request parsing

**Data & SQL** — SQL Server (T-SQL) · Dimensional modelling (star schema, SCD Type 1/2) · Multi-layer ETL · Query optimisation (window functions, indexing) · XML hierarchy parsing · Data quality validation

**Tools** — Python · SSMS · Excel (generated deliverables) · Git

**Domain** — Logistics & freight forwarding · Customs & trade compliance · CargoWise

---

**Email:** brian.santosoeng@gmail.com | **Sydney, Australia**
