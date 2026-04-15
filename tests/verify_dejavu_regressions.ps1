$ErrorActionPreference = "Stop"

function Assert-Contains {
    param(
        [string]$Content,
        [string]$Needle,
        [string]$Code
    )

    if (-not $Content.Contains($Needle)) {
        throw $Code
    }
}

function Assert-NotContains {
    param(
        [string]$Content,
        [string]$Needle,
        [string]$Code
    )

    if ($Content.Contains($Needle)) {
        throw $Code
    }
}

function Assert-RegexCount {
    param(
        [string]$Content,
        [string]$Pattern,
        [int]$ExpectedCount,
        [string]$Code
    )

    $matches = [regex]::Matches($Content, $Pattern, [System.Text.RegularExpressions.RegexOptions]::Multiline)
    if ($matches.Count -ne $ExpectedCount) {
        throw "${Code}:$($matches.Count)"
    }
}

$playerHarmful = Get-Content -Raw -Encoding UTF8 "DejaVu/DejaVu_Aura/PlayerHarmful.lua"
$playerHelpful = Get-Content -Raw -Encoding UTF8 "DejaVu/DejaVu_Aura/PlayerHelpful.lua"
$mouseoverHarmful = Get-Content -Raw -Encoding UTF8 "DejaVu/DejaVu_Aura/MouseoverHarmful.lua"
$flash = Get-Content -Raw -Encoding UTF8 "DejaVu/DejaVu_Common/Flash.lua"
$spellQueueWindow = Get-Content -Raw -Encoding UTF8 "DejaVu/DejaVu_Common/SpellQueueWindow.lua"
$styleDoc = Get-Content -Raw -Encoding UTF8 ".context/DejaVu/09_personal_style_cell_event_comments.md"

Assert-Contains $playerHarmful "function eventFrame.UNIT_AURA(unitTarget, updateInfo)" "PH_UNIT_AURA_SIG"
Assert-Contains $playerHelpful "function eventFrame.UNIT_AURA(unitTarget, updateInfo)" "PF_UNIT_AURA_SIG"
Assert-Contains $mouseoverHarmful "function eventFrame.UNIT_AURA(unitTarget, updateInfo)" "MH_UNIT_AURA_SIG"
Assert-Contains $mouseoverHarmful "function eventFrame.UNIT_FLAGS(unitTarget)" "MH_UNIT_FLAGS_SIG"

Assert-Contains $playerHarmful "self[event](...)" "PH_ROUTE"
Assert-Contains $playerHelpful "self[event](...)" "PF_ROUTE"
Assert-Contains $mouseoverHarmful "self[event](...)" "MH_ROUTE"

Assert-NotContains $playerHarmful "frame[event](frame, ...)" "PH_BAD_ROUTE"
Assert-NotContains $playerHelpful "frame[event](frame, ...)" "PF_BAD_ROUTE"
Assert-NotContains $mouseoverHarmful "frame[event](frame, ...)" "MH_BAD_ROUTE"

Assert-RegexCount $flash '^\s*updateCell\(\)\s*$' 1 "FLASH_CALL_COUNT"
Assert-Contains $spellQueueWindow "cell:setCellRGBA(20 / 255)" "SQW_SENTINEL"
Assert-NotContains $spellQueueWindow "updateSpellQueueWindow(spell_queue_window:get_value())" "SQW_NO_INIT_OVERRIDE"

Assert-Contains $styleDoc "eventFrame.EVENT_NAME" "DOC_DOT_HANDLER"
Assert-Contains $styleDoc "self[event](...)" "DOC_ROUTE"
Assert-Contains $styleDoc "unused warning" "DOC_NO_UNDERSCORE"

Write-Host "DejaVu regression checks passed."
