$ErrorActionPreference = "Stop"

$content = Get-Content -Raw -Encoding UTF8 "DejaVu/DejaVu_Common/DispelBlacklist.lua"

if ($content -notmatch 'local function updateCell\(tableValue\)\s*[\r\n]+\s*tableValue = tableValue or \{\}\s*[\r\n]+\s*local i = 1') {
    throw "DB_MISSING_NIL_GUARD"
}

Write-Host "check_dispel_blacklist_nil_guard.ps1: ok"
