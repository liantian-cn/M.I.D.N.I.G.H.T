$ErrorActionPreference = "Stop"

$content = Get-Content -Raw -Encoding UTF8 "DejaVu/DejaVu_Common/SpellStopList.lua"

if ($content -notmatch 'local function updateCell\(tableValue\)\s*[\r\n]+\s*tableValue = tableValue or \{\}\s*[\r\n]+\s*local i = 1') {
    throw "SSL_MISSING_NIL_GUARD"
}

Write-Host "check_spell_stop_list_nil_guard.ps1: ok"
