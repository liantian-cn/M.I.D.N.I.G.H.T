local _, addonTable = ...

local L = addonTable.L

StaticPopupDialogs["SCRB_EXPORT_SETTINGS"] = StaticPopupDialogs["SCRB_EXPORT_SETTINGS"]
    or {
        text = L["EXPORT"],
        button1 = L["CLOSE"],
        hasEditBox = true,
        editBoxWidth = 320,
        timeout = 0,
        whileDead = true,
        hideOnEscape = true,
        preferredIndex = 3,
    }

StaticPopupDialogs["SCRB_IMPORT_SETTINGS"] = StaticPopupDialogs["SCRB_IMPORT_SETTINGS"]
    or {
        text = L["IMPORT"],
        button1 = L["OKAY"],
        button2 = L["CANCEL"],
        hasEditBox = true,
        editBoxWidth = 320,
        timeout = 0,
        whileDead = true,
        hideOnEscape = true,
        preferredIndex = 3,
    }
StaticPopupDialogs["SCRB_IMPORT_SETTINGS"].OnShow = function(self)
    self:SetFrameStrata("TOOLTIP")
    local editBox = self.editBox or self:GetEditBox()
    editBox:SetText("")
    editBox:SetFocus()
end
StaticPopupDialogs["SCRB_IMPORT_SETTINGS"].EditBoxOnEnterPressed = function(editBox)
    local parent = editBox:GetParent()
    if parent and parent.button1 then parent.button1:Click() end
end

StaticPopupDialogs["SCRB_RELOADUI"] = StaticPopupDialogs["SCRB_RELOADUI"]
    or {
        text = L["RELOADUI_TEXT"],
        button1 = L["RELOADUI"],
        button2 = L["CANCEL"],
        timeout = 0,
        whileDead = true,
        hideOnEscape = true,
        preferredIndex = 3,
    }
StaticPopupDialogs["SCRB_RELOADUI"].OnAccept = function()
    ReloadUI()
end