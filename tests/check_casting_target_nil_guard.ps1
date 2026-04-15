$ErrorActionPreference = "Stop"

$content = Get-Content -Raw -Encoding UTF8 "DejaVu/DejaVu_Party/CastingTarget.lua"

if ($content -notmatch 'local function updateClearCastingTarget\(unitToken\)\s*[\r\n]+\s*if not unitToken or not cell\[unitToken\] then\s*[\r\n]+\s*return\s*[\r\n]+\s*end') {
    throw "CT_MISSING_CLEAR_GUARD"
}

if ($content -notmatch 'function eventFrame:UNIT_SPELLCAST_SENT\(unitTarget, targetName, castGUID, spellID\)[\s\S]*?local previousCastingTarget = currentCastingTarget\s*[\r\n]+\s*currentCastingTarget = nil') {
    throw "CT_MISSING_SENT_RESET"
}

Write-Host "check_casting_target_nil_guard.ps1: ok"
