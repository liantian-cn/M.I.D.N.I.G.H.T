$megaCell = Get-Content -Raw -Encoding UTF8 "DejaVu_Matrix/MegaCell.lua"
$badgeCell = Get-Content -Raw -Encoding UTF8 "DejaVu_Matrix/BadgeCell.lua"

if ($megaCell -notlike '*SetTexture(WHITE_TEXTURE)*') {
    throw "MegaCell.lua is not using a stable white texture for MegaCell background rendering."
}

if ($megaCell -notlike '*SetVertexColor(backgroundColor:GetRGBA())*') {
    throw "MegaCell.lua is not applying backgroundColor through SetVertexColor."
}

if ($badgeCell -notlike '*SetTexture(WHITE_TEXTURE)*') {
    throw "BadgeCell.lua is not using a stable white texture for BadgeCell rendering."
}

if ($badgeCell -notlike '*SetVertexColor(BLACK:GetRGBA())*') {
    throw "BadgeCell.lua background is not initialized through SetVertexColor."
}

if ($badgeCell -notlike '*SetVertexColor(color:GetRGBA())*') {
    throw "BadgeCell.lua badge color is not applied through SetVertexColor."
}

Write-Host "check_matrix_texture_rendering.ps1: ok"
