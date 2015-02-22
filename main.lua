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

T.Frame = CreateFrame("Frame")

T.Events = {}

local VELLUM_ID = 38682

local db
local cdb

local bank_open = false

function T:IsEnabled()
    return cdb.Enabled and db.Enabled
end

function T:RunCheck()
    if not bank_open or not self:IsEnabled() then return end

    for i = 1, GetContainerNumSlots(REAGENTBANK_CONTAINER) do
        local id = GetContainerItemID(REAGENTBANK_CONTAINER, i)
        if id == VELLUM_ID or db.Items[id] or cdb.Items[id] then
            UseContainerItem(REAGENTBANK_CONTAINER, i)
        end
    end
end

function T.Events.ADDON_LOADED(name)
    if name ~= NAME then return end
    
    if type(VellumWithdrawerDB) ~= "table" then
        VellumWithdrawerDB = {}
    end

    T.DB = VellumWithdrawerDB
    db = T.DB

    if type(db.Enabled) ~= "boolean" then
        db.Enabled = true
    end

    if type(db.Items) ~= "table" then
        db.Items = {}
    end

    if type(db.AutoDeposit) ~= "boolean" then
        db.AutoDeposit = false
    end

    if type(VellumWithdrawerCharDB) ~= "table" then
        VellumWithdrawerCharDB = {}
    end

    T.CDB = VellumWithdrawerCharDB
    cdb = T.CDB

    if type(cdb.Enabled) ~= "boolean" then
        cdb.Enabled = db.Enabled
    end

    if type(cdb.Items) ~= "table" then
        cdb.Items = {}
    end

    if type(cdb.AutoDeposit) ~= "boolean" then
        cdb.AutoDeposit = false
    end
end

function T.Events.BANKFRAME_OPENED()
    bank_open = true
    if db.AutoDeposit and cdb.AutoDeposit then
        DepositReagentBank()
    else
        T:RunCheck()
    end
end

function T.Events.BANKFRAME_CLOSED()
    bank_open = false
end

function T.Events.BAG_UPDATE_DELAYED()
    T:RunCheck()
end

T.Frame:SetScript("OnEvent", function(self, event, ...)
    if T.Events[event] then T.Events[event](...) end
end)

for k, _ in pairs(T.Events) do
    T.Frame:RegisterEvent(k)
end

SLASH_VELLUMWITHDRAWER1 = "/vellumwithdrawer"
SLASH_VELLUMWITHDRAWER2 = "/vw"

local function log(f, ...)
    DEFAULT_CHAT_FRAME:AddMessage(("|cff00FF00[VellumWithdrawer]|r %s"):format(tostring(f):format(...)))
end

SlashCmdList.VELLUMWITHDRAWER = function(msg, editBox)
    if msg:match("^c") then
        cdb.Enabled = not cdb.Enabled
        log("%s for this character", cdb.Enabled and "Enabled" or "Disabled")
    elseif msg:match("^n") then
        T:RunCheck()
    elseif msg:match("^o") then
        T.Options:Open()
    elseif msg:match("^d") then
        db.AutoDeposit = not db.AutoDeposit
        log("Auto deposit %s", db.AutoDeposit and "enabled" or "disabled")
    elseif msg:match("^d[%w%s]-c") then
        cdb.AutoDeposit = not cdb.AutoDeposit
        log("Auto deposit %s for this character", cdb.AutoDeposit and "enabled" or "disabled")
    else
        db.Enabled = not db.Enabled
        log("%s", db.Enabled and "Enabled" or "Disabled")
    end
end
