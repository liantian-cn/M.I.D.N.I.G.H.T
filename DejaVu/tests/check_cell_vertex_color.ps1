$content = Get-Content -Raw -Encoding UTF8 "DejaVu_Matrix/Cell.lua"

if ($content -notlike '*SetTexture(WHITE_TEXTURE)*') {
    throw "Cell.lua is not using a stable white texture for Cell rendering."
}

if ($content -notlike '*SetVertexColor(r, g, b, a)*') {
    throw "Cell.lua is not applying dynamic color updates through SetVertexColor."
}

Write-Host "check_cell_vertex_color.ps1: ok"
