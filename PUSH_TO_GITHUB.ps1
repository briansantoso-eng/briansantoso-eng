# Push FreightDW to GitHub (Updated README)
# Usage: .\PUSH_TO_GITHUB.ps1

Write-Host "🚀 Pushing FreightDW README to GitHub..." -ForegroundColor Green
Write-Host ""

# Navigate to portfolio directory
$PortfolioPath = "C:\Users\burai\OneDrive - WiseTech Global\Data Architect Portfolio"
Set-Location $PortfolioPath
Write-Host "✓ Location: $PortfolioPath" -ForegroundColor Green
Write-Host ""

# Stage README changes
Write-Host "✓ Staging README.md..." -ForegroundColor Green
git add README.md
Write-Host "✓ Staged!" -ForegroundColor Green
Write-Host ""

# Commit
Write-Host "✓ Committing changes..." -ForegroundColor Green
git commit -m "Refactor: Update README with professional positioning and architecture narrative"
Write-Host "✓ Committed!" -ForegroundColor Green
Write-Host ""

# Push to GitHub
Write-Host "✓ Pushing to GitHub..." -ForegroundColor Green
git push origin main
Write-Host "✓ Push successful!" -ForegroundColor Green
Write-Host ""

Write-Host "✅ SUCCESS! README updated on GitHub!" -ForegroundColor Green
Write-Host ""
Write-Host "📍 View it at:" -ForegroundColor Cyan
Write-Host "https://github.com/briansantoso-eng/FreightDW-DataArchitectPortfolio" -ForegroundColor Yellow
Write-Host ""
Write-Host "📋 Next steps (manual on GitHub web):" -ForegroundColor Yellow
Write-Host "1. Update profile bio: https://github.com/briansantoso-eng/settings/profile" -ForegroundColor Yellow
Write-Host "2. Pin FreightDW repo (click star icon)" -ForegroundColor Yellow
Write-Host "3. Delete non-essential repos (CloudDocs RAG, AI Model Governance, etc.)" -ForegroundColor Yellow
