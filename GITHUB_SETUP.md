# How to Push FreightDW Portfolio to GitHub

## Step 1: Create GitHub Repository

1. Go to https://github.com/new
2. **Repository name:** `FreightDW-DataArchitectPortfolio`
3. **Description:** "Production-grade SQL Server data warehouse demonstrating enterprise dimensional modeling, ETL/SCD strategies, and data quality validation for Sydney data architect roles."
4. **Public** (so interviewers can see it)
5. **Initialize with:** Nothing (leave empty)
6. Click **Create Repository**

---

## Step 2: Copy Repository URL

After creating, GitHub shows:
```
https://github.com/briansantoso-eng/FreightDW-DataArchitectPortfolio.git
```

Copy this URL.

---

## Step 3: Open PowerShell in Your Portfolio Directory

```powershell
# Navigate to your portfolio folder
cd "C:\Users\burai\OneDrive - WiseTech Global\Data Architect Portfolio"
```

---

## Step 4: Initialize Git Repository

```powershell
# Initialize git in this folder
git init

# Add all files
git add .

# Create initial commit
git commit -m "Initial commit: FreightDW portfolio - Modules 1-9 complete

- Module 1: Database + Dim_Date (1,461 days)
- Module 2: Dimensions with SCD Type 1 & 2
- Module 3: Fact_Shipment star schema
- Module 4: Performance & Indexing (6 strategic indexes)
- Module 5: 18 Analytics KPI queries
- Module 7: ETL + SCD Type 2 logic
- Module 8: Data Quality validation (100% passing)
- Module 9: Architecture documentation
- Plus comprehensive README and portfolio narrative"
```

---

## Step 5: Add GitHub as Remote

```powershell
# Replace URL with your actual GitHub URL
git remote add origin https://github.com/briansantoso-eng/FreightDW-DataArchitectPortfolio.git

# Verify it worked
git remote -v
```

---

## Step 6: Push to GitHub

```powershell
# Set default branch to main
git branch -M main

# Push to GitHub
git push -u origin main
```

(First time, it will ask for your GitHub credentials. Use your GitHub username and a Personal Access Token instead of password)

---

## Step 7: Verify on GitHub

Go to https://github.com/briansantoso-eng/FreightDW-DataArchitectPortfolio

You should see all your files!

---

## Optional: Add to LinkedIn/Resume

**LinkedIn Profile URL:**
```
https://github.com/briansantoso-eng/FreightDW-DataArchitectPortfolio
```

**Resume bullet:**
```
• Built FreightDW: Production-grade SQL Server data warehouse (9 modules)
  demonstrating star schema, SCD Type 2 ETL, performance optimization, and
  data quality validation. 100% validation passing, 18 analytics KPIs.
  github.com/briansantoso-eng/FreightDW-DataArchitectPortfolio
```

---

## Troubleshooting

### "fatal: not a git repository"
```powershell
# You're in the wrong directory. Navigate to the portfolio folder first:
cd "C:\Users\burai\OneDrive - WiseTech Global\Data Architect Portfolio"
```

### "Permission denied (publickey)"
```powershell
# GitHub requires a Personal Access Token, not password
# Go to: https://github.com/settings/tokens
# Generate new token with "repo" scope
# Use token instead of password
```

### "Everything up-to-date"
```powershell
# You've already pushed. To add new changes:
git add .
git commit -m "Update: Added new feature"
git push
```

---

## Interview Talking Point

**Interviewer:** "Tell me about your data architecture experience."

**You:** "I built FreightDW, a production-grade data warehouse portfolio that demonstrates enterprise patterns. You can see the complete implementation on GitHub — it includes star schema design, SCD Type 2 ETL logic, performance optimization with strategic indexing, and comprehensive data quality validation. The whole project is documented with architecture decisions and trade-offs. Feel free to review it."

*They will be impressed. Most candidates can't build something this complete.*

---

Run these commands in PowerShell and your portfolio will be live on GitHub! 🚀
