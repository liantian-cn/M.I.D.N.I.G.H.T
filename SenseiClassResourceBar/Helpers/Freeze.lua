local _, addonTable = ...

local Freeze = {}

-- Debufs are secrets now, so we will have to hook into the CDM to display the Freeze stacks.
Freeze.FREEZE_MAX_STACKS = 20

local FREEZE_SPELL_ID = 1246769

local _auraInstanceID    = nil
local _cdmFrame          = nil
local _lastKnownStacks   = 0

local function HasAuraInstanceID(value)
    if value == nil then return false end
    if issecretvalue and issecretvalue(value) then return true end
    return type(value) == "number" and value ~= 0
end

function Freeze:OnLoad()
end

function Freeze:OnEvent(_, event, ...)
end

function Freeze:GetStacks()
    for _, viewer in ipairs({BuffIconCooldownViewer, BuffBarCooldownViewer}) do
        if viewer then
            for _, frame in ipairs({viewer:GetChildren()}) do
                if frame.SetAuraInstanceInfo and not frame._hook_scrb_SetAuraInstanceInfo then
                    frame._hook_scrb_SetAuraInstanceInfo = true
                    hooksecurefunc(frame, "SetAuraInstanceInfo", function(f)
                        -- Re-validate at call time: CDM may have reassigned this frame to a different spell
                        local cdID = f.cooldownID
                        local info = cdID and C_CooldownViewer and C_CooldownViewer.GetCooldownViewerCooldownInfo(cdID)
                        if not (info and info.spellID == FREEZE_SPELL_ID) then return end

                        if f.auraDataUnit == "target" and HasAuraInstanceID(f.auraInstanceID) then
                            _auraInstanceID = f.auraInstanceID
                            _cdmFrame = f
                        end
                    end)
                end
                if frame.ClearAuraInstanceInfo and not frame._hook_scrb_ClearAuraInstanceInfo then
                    frame._hook_scrb_ClearAuraInstanceInfo = true
                    hooksecurefunc(frame, "ClearAuraInstanceInfo", function(f)
                        if f == _cdmFrame then
                            _auraInstanceID = nil
                            _cdmFrame = nil
                            _lastKnownStacks = 0
                        end
                    end)
                end
            end
        end
    end

    if not HasAuraInstanceID(_auraInstanceID) then
        return self.FREEZE_MAX_STACKS, 0
    end
    local auraData = C_UnitAuras.GetAuraDataByAuraInstanceID("target", _auraInstanceID)
    if auraData then
        _lastKnownStacks = auraData.applications or 0
        return self.FREEZE_MAX_STACKS, _lastKnownStacks
    end
    -- Return last known stacks to avoid a brief flash to 0.
    return self.FREEZE_MAX_STACKS, _lastKnownStacks
end

addonTable.Freeze = Freeze