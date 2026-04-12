local textureState = {}
local lastCurveReadKind = nil

local function assertEqual(actual, expected, message)
    if actual ~= expected then
        error(string.format("%s: expected %s, got %s", message, tostring(expected), tostring(actual)), 2)
    end
end

local function CreateColor(r, g, b, a)
    local color = {
        r = r,
        g = g,
        b = b,
        a = a or 1,
    }

    function color:GetRGBA()
        lastCurveReadKind = rawget(self, "_readKind")
        return self.r, self.g, self.b, self.a
    end

    return color
end

local function buildTexture()
    local texture = {
        calls = {},
    }

    function texture:SetAllPoints()
    end

    function texture:Show()
    end

    function texture:SetTexture(path)
        self.texturePath = path
        table.insert(self.calls, { method = "SetTexture", path = path })
    end

    function texture:SetColorTexture(r, g, b, a)
        if lastCurveReadKind == "curve" then
            self.visible = { 0, 0, 0, a or 1 }
        else
            self.visible = { r, g, b, a or 1 }
        end
        table.insert(self.calls, { method = "SetColorTexture", r = r, g = g, b = b, a = a })
        lastCurveReadKind = nil
    end

    function texture:SetVertexColor(r, g, b, a)
        self.visible = { r, g, b, a or 1 }
        table.insert(self.calls, { method = "SetVertexColor", r = r, g = g, b = b, a = a })
        lastCurveReadKind = nil
    end

    textureState.texture = texture
    return texture
end

local function buildFrame()
    local frame = {}

    function frame:SetPoint()
    end

    function frame:SetFrameLevel()
    end

    function frame:SetSize()
    end

    function frame:Show()
    end

    function frame:CreateTexture()
        return buildTexture()
    end

    return frame
end

local env = {
    _G = {},
    CreateColor = CreateColor,
    CreateFrame = function()
        return buildFrame()
    end,
    C_CurveUtil = {
        EvaluateColorFromBoolean = function(isTrue, trueColor, falseColor)
            if isTrue then
                return trueColor
            end
            return falseColor
        end,
    },
    issecretvalue = function()
        return false
    end,
}

env._G = env
env._G["DejaVu"] = {}

local addonTable = {
    MartixFrame = {
        GetFrameLevel = function()
            return 100
        end,
    },
    SIZE = {
        CELL = 4,
    },
}

local chunk = assert(loadfile("DejaVu_Matrix/Cell.lua", "t", env))
chunk("DejaVu_Matrix", addonTable)

local Cell = env._G["DejaVu"].Cell
local cell = Cell:New(51, 14)
local curveColor = CreateColor(0.25, 0.5, 0.75, 1)
curveColor._readKind = "curve"

cell:setCell(curveColor)

assertEqual(textureState.texture.texturePath, "Interface\\Buttons\\WHITE8X8", "Cell texture should use a stable white texture")
assertEqual(textureState.texture.visible[1], 0.25, "Cell red channel should preserve curve color")
assertEqual(textureState.texture.visible[2], 0.5, "Cell green channel should preserve curve color")
assertEqual(textureState.texture.visible[3], 0.75, "Cell blue channel should preserve curve color")
assertEqual(textureState.texture.visible[4], 1, "Cell alpha channel should preserve curve color")

local lastCall = textureState.texture.calls[#textureState.texture.calls]
assertEqual(lastCall.method, "SetVertexColor", "Curve colors should update the texture through vertex color")

print("cell_vertex_color_test.lua: ok")
