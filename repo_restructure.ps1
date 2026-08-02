# repo_restructure.ps1 — PHASE 2: Restructure repo (ASCII-safe, no Unicode)
# Run from: E:\РАБОТА ДОМА\WEB\N8N BEGET\FOREIGN\DEEPSEEK\GIT
# Command: powershell -ExecutionPolicy Bypass -File repo_restructure.ps1

$ErrorActionPreference = "Stop"
$root = Get-Location
Write-Host "Root: $root"

# ============================================================
# STEP 1: Create directory structure
# ============================================================
Write-Host "`n[1/8] Creating directory structure..."

$dirs = @(
    "docs\templates",
    "docs\raw\error_history_sources",
    "docs\raw\decision_sources",
    "docs\standards",
    "workflows",
    "config",
    "tasks\active",
    "tasks\archive",
    "escalations\open",
    "escalations\resolved",
    "archive\workflows",
    "archive\documentation"
)

foreach ($dir in $dirs) {
    $path = Join-Path $root $dir
    if (-not (Test-Path $path)) {
        New-Item -ItemType Directory -Path $path -Force | Out-Null
        Write-Host "  CREATED: $dir"
    } else {
        Write-Host "  EXISTS:  $dir"
    }
}

# ============================================================
# STEP 2: Move core documentation -> docs/
# ============================================================
Write-Host "`n[2/8] Moving core docs -> docs/..."

$docsToMove = @(
    "ARCHITECTURE.md",
    "ENVIRONMENT.md",
    "SERVER_STRUCTURE.md",
    "WORKFLOW_MAP.md"
)

foreach ($file in $docsToMove) {
    $src = Join-Path $root $file
    $dst = Join-Path $root "docs\$file"
    if (Test-Path $src) {
        Move-Item -Path $src -Destination $dst -Force
        Write-Host "  MOVED: $file -> docs\$file"
    } else {
        Write-Host "  MISSING: $file (skipped)"
    }
}

# ============================================================
# STEP 3: Move workflow JSONs -> workflows/
# ============================================================
Write-Host "`n[3/8] Moving workflow JSONs -> workflows/..."

$wfs = @(
    "OSINT_01_Core_Router.json",
    "OSINT_02_Search_Engine.json",
    "OSINT_03_Company_Intel.json",
    "OSINT_04_Tender_Intel.json",
    "OSINT_05_Analyst.json",
    "OSINT_06_Report_Generator.json",
    "OSINT_07_Pinecone_Memory.json",
    "OSINT_08_Utilities.json"
)

foreach ($wf in $wfs) {
    $src = Join-Path $root $wf
    $dst = Join-Path $root "workflows\$wf"
    if (Test-Path $src) {
        Move-Item -Path $src -Destination $dst -Force
        Write-Host "  MOVED: $wf -> workflows\$wf"
    } else {
        Write-Host "  MISSING: $wf (skipped)"
    }
}

# ============================================================
# STEP 4: Show remaining root files
# ============================================================
Write-Host "`n[4/8] Root files after moves:"
Get-ChildItem -Path $root -File | ForEach-Object { Write-Host "  $($_.Name)" }

# ============================================================
# STEP 5: Create .gitkeep placeholders
# ============================================================
Write-Host "`n[5/8] Creating .gitkeep placeholders..."

$gitkeeps = @(
    "tasks\active\.gitkeep",
    "tasks\archive\.gitkeep",
    "escalations\open\.gitkeep",
    "escalations\resolved\.gitkeep",
    "archive\workflows\.gitkeep",
    "archive\documentation\.gitkeep",
    "docs\raw\error_history_sources\.gitkeep",
    "docs\raw\decision_sources\.gitkeep",
    "docs\standards\.gitkeep"
)

foreach ($gk in $gitkeeps) {
    $path = Join-Path $root $gk
    "" | Out-File -FilePath $path -Encoding UTF8
    Write-Host "  CREATED: $gk"
}

# ============================================================
# STEP 6: Simple directory listing
# ============================================================
Write-Host "`n[6/8] Final directory tree (dir /s):"
Write-Host ""
cmd /c "dir /s /b /a:D"

Write-Host ""
Write-Host "All files:"
cmd /c "dir /s /b /a:-D"

Write-Host "`n========================================"
Write-Host "PHASE 2 complete."
Write-Host "Next: Run 'git status' to review changes."
Write-Host "Then manually commit after confirmation."
Write-Host "========================================"
