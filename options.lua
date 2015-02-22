--[[
    Copyright (c) 2014 by Adam Hellberg.

    Permission is hereby granted, free of charge, to any person obtaining a copy
    of this software and associated documentation files (the "Software"), to deal
    in the Software without restriction, including without limitation the rights
    to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
    copies of the Software, and to permit persons to whom the Software is
    furnished to do so, subject to the following conditions:

    The above copyright notice and this permission notice shall be included in
    all copies or substantial portions of the Software.

    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
    IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
    FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
    AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
    LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
    OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
    THE SOFTWARE.
]]

local NAME, T = ...

T.Options = {}

local panel = CreateFrame("Frame")
panel.name = NAME
panel:Hide()

local GetItemInfo = GetItemInfo

local function strsplit(str, sep)
    local sep = sep or ","
    local fields = {}
    local pattern = string.format("([^%s]+)", sep)
    str:gsub(pattern, function(c) fields[#fields+1] = c end)
    return fields
end

local function ResetItemsTable(tbl)
    for id, _ in pairs(tbl) do
        tbl[id] = nil
    end
end

local function MakeItemsString(tbl)
    local out = ""
    for id, enabled in pairs(tbl) do
        if enabled then
            local _, link = GetItemInfo(id)
            out = out .. link .. ","
        end
    end
    return out:gsub(",$", "")
end

local function TrimEditBox(box)
    local text = box:GetText()
    text:gsub("^[%s,]+", ""):gsub("[%s,]+$", "")
    box:SetText(text)
end

local checkCounter = 0
local function checkbox(label, onclick)
    local check = CreateFrame("CheckButton", NAME .. "Checkbox" .. checkCounter, panel, "InterfaceOptionsCheckButtonTemplate")
    check:SetScript("OnClick", function(self)
        local checked = self:GetChecked()
        PlaySound(checked and "igMainMenuOptionCheckBoxOn" or "igMainMenuOptionCheckBoxOff")
        onclick(self, checked and true or false)
    end)
    check.label = _G[check:GetName() .. "Text"]
    check.label:SetText(label)
    checkCounter = checkCounter + 1
    return check
end

panel:SetScript("OnShow", function(self)
    local title = self:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", 16, -16)
    title:SetText(NAME .. " Options")

    local enabledCheck = checkbox("Enabled", function(check, checked)
        T.DB.Enabled = checked
    end)
    enabledCheck:SetPoint("TOPLEFT", title, "BOTTOMLEFT", -2, -16)

    local charEnabledCheck = checkbox("Enabled on this character", function(check, checked)
        T.CDB.Enabled = checked
    end)
    charEnabledCheck:SetPoint("LEFT", enabledCheck, "RIGHT", 250, 0)

    local autoDepositCheck = checkbox("Auto deposit", function(check, checked)
        T.DB.AutoDeposit = checked
    end)
    autoDepositCheck:SetPoint("TOPLEFT", enabledCheck, "BOTTOMLEFT", 0, -16)

    local charAutoDepositCheck = checkbox("Auto deposit on this character", function(check, checked)
        T.CDB.AutoDeposit = checked
    end)
    charAutoDepositCheck:SetPoint("LEFT", autoDepositCheck, "RIGHT", 250, 0)

    local itemsDesc = self:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    itemsDesc:SetPoint("TOPLEFT", autoDepositCheck, "BOTTOMLEFT", 0, -16)
    itemsDesc:SetText("Additional items to withdraw (item ID, name, or link, separate with commas).|nPress <ENTER> or the apply button to apply changes.")
    itemsDesc:SetTextColor(1, 1, 1)

    local function applyItemBoxChanges(box, db)
        ResetItemsTable(db.Items)

        TrimEditBox(box)

        -- Get the text and trim whitespace at beginning and end
        local text = box:GetText()

        if not text or text == "" then
            box:ClearFocus()
            return
        end

        -- The gsub takes care of removing whitespace and excessive commas between commas and item ids or links
        local items = strsplit((text:gsub("[%s,]*,[%s]*", ",")))
        
        for _, item in pairs(items) do
            local id = tonumber(item)
            if not id then
                local _, link = GetItemInfo(item)
                id = tonumber(link:match("|Hitem:(%d+):"))
            end
            if type(id) == "number" then db.Items[id] = true end
        end
        box:ClearFocus()
        box:SetText(MakeItemsString(db.Items))
    end

    local itemsBox = CreateFrame("EditBox", NAME .. "ItemsEditBox", self, "InputBoxTemplate")
    itemsBox:SetHeight(22)
    itemsBox:SetPoint("TOPLEFT", itemsDesc, "BOTTOMLEFT", 0, -8)
    itemsBox:SetPoint("RIGHT", self, "RIGHT", -110, 0)
    itemsBox:SetAutoFocus(false)
    itemsBox:EnableMouse(true)
    itemsBox:SetScript("OnEditFocusGained", nil)
    itemsBox:SetScript("OnEditFocusLost", function(box) applyItemBoxChanges(box, T.DB) end)
    itemsBox:SetScript("OnEnterPressed", function(box) box:ClearFocus() end)

    local itemsApply = CreateFrame("Button", nil, self, "UIPanelButtonTemplate")
    itemsApply:SetPoint("LEFT", itemsBox, "RIGHT", 5, 0)
    itemsApply:SetWidth(100)
    itemsApply:SetHeight(24)
    itemsApply:SetText("Apply")
    itemsApply:SetScript("OnClick", function() itemsBox:ClearFocus() end)

    local charItemsDesc = self:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    charItemsDesc:SetPoint("TOPLEFT", itemsBox, "BOTTOMLEFT", 0, -16)
    charItemsDesc:SetText("Additional items to withdraw for the current character only")
    charItemsDesc:SetTextColor(1, 1, 1)

    local charItemsBox = CreateFrame("EditBox", NAME .. "CharItemsEditBox", self, "InputBoxTemplate")
    charItemsBox:SetHeight(22)
    charItemsBox:SetPoint("TOPLEFT", charItemsDesc, "BOTTOMLEFT", 0, -8)
    charItemsBox:SetPoint("RIGHT", self, "RIGHT", -110, 0)
    charItemsBox:SetAutoFocus(false)
    charItemsBox:EnableMouse(true)
    charItemsBox:SetScript("OnEditFocusGained", nil)
    charItemsBox:SetScript("OnEditFocusLost", function(box) applyItemBoxChanges(box, T.CDB) end)
    charItemsBox:SetScript("OnEnterPressed", function(box) box:ClearFocus() end)

    local charItemsApply = CreateFrame("Button", nil, self, "UIPanelButtonTemplate")
    charItemsApply:SetPoint("LEFT", charItemsBox, "RIGHT", 5, 0)
    charItemsApply:SetWidth(100)
    charItemsApply:SetHeight(24)
    charItemsApply:SetText("Apply")
    charItemsApply:SetScript("OnClick", function() charItemsBox:ClearFocus() end)

    local resetHelp = self:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    resetHelp:SetPoint("TOPLEFT", charItemsBox, "BOTTOMLEFT", 0, -16)
    resetHelp:SetText("To easily clear out additional withdraw items, just empty the edit box and apply|n(Ctrl-A and then either delete or backspace)")
    resetHelp:SetTextColor(1, 1, 1)

    -- Hook containers to capture shift clicks on items
    local function insertLink(link)
        if itemsBox:HasFocus() then
            TrimEditBox(itemsBox)
            if itemsBox:GetText() ~= "" then
                itemsBox:Insert(",")
            end
            itemsBox:Insert(link)
            HideUIPanel(StackSplitFrame)
        elseif charItemsBox:HasFocus() then
            TrimEditBox(charItemsBox)
            if charItemsBox:GetText() ~= "" then
                charItemsBox:Insert(",")
            end
            charItemsBox:Insert(link)
            HideUIPanel(StackSplitFrame)
        end
    end

    local function containerHook(btn)
        if not IsShiftKeyDown() or not self:IsVisible() then return end
        local link = GetContainerItemLink(btn:GetParent():GetID(), btn:GetID())
        insertLink(link)
    end

    local function bankHook(btn)
        if not IsShiftKeyDown() or not self:IsVisible() then return end
        local link = GetContainerItemLink(BANK_CONTAINER, btn:GetID())
        insertLink(link)
    end

    hooksecurefunc("ContainerFrameItemButton_OnModifiedClick", containerHook)
    hooksecurefunc("BankFrameItemButtonGeneric_OnModifiedClick", bankHook)

    local function refresh()
        enabledCheck:SetChecked(T.DB.Enabled)
        charEnabledCheck:SetChecked(T.CDB.Enabled)
        itemsBox:SetText(MakeItemsString(T.DB.Items))
        charItemsBox:SetText(MakeItemsString(T.CDB.Items))
    end

    refresh()

    self:SetScript("OnShow", function()
        refresh()
    end)
end)

InterfaceOptions_AddCategory(panel)

function T.Options:Open()
    ShowUIPanel(InterfaceOptionsFrame)
    InterfaceOptionsFrame_OpenToCategory(panel)
end
