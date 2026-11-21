RDL_BankCache = RDL_BankCache or {}
RDL_ReagentBankCache = RDL_ReagentBankCache or {}
RDL_Core = {}

local bankOpen, guildBankOpen = false, false
local qSpell, qName, qRem = nil, nil, 0
local lastCraftedGearID = nil
local pendingBankStoreID = nil
local timerFrame = CreateFrame("Frame")
local countCache = {}

local BANK_BAGS = { -1, 5, 6, 7, 8, 9, 10, 11 }

function RDL_Core.ClearCountCache()
    wipe(countCache)
end

function RDL_Core.SetBankOpen(s)
    bankOpen = s
    if not s then
        pendingBankStoreID = nil
        lastCraftedGearID = nil
    end
end

function RDL_Core.IsBankOpen() return bankOpen end
function RDL_Core.SetGuildBankOpen(s) guildBankOpen = s end

function RDL_Core.ScanBank()
    if not bankOpen then return end
    local t = {}
    for s = 1, 28 do
        local id = GetContainerItemID(-1, s)
        if id then local _, c = GetContainerItemInfo(-1, s); t[id] = (t[id] or 0) + (c or 1) end
    end
    for b = 5, 11 do
        for s = 1, GetContainerNumSlots(b) do
            local id = GetContainerItemID(b, s)
            if id then local _, c = GetContainerItemInfo(b, s); t[id] = (t[id] or 0) + (c or 1) end
        end
    end
    RDL_BankCache = t
    wipe(countCache)
end

function RDL_Core.ScanReagentVault()
    if not guildBankOpen then return end
    local tabName = GetGuildBankTabInfo(1) or ""
    if tabName ~= "Banco de Componentes" and tabName ~= "Reagent Bank" and IsInGuild() then return end
    local t = {}
    for s = 1, 98 do
        local link = GetGuildBankItemLink(1, s)
        if link then
            local id = tonumber(link:match("item:(%d+)"))
            local _, count = GetGuildBankItemInfo(1, s)
            if id then t[id] = (t[id] or 0) + (count or 1) end
        end
    end
    RDL_ReagentBankCache = t
    wipe(countCache)
end

function RDL_Core.GetBreakdownCounts(id)
    if not id then return 0, 0, 0 end
    local cached = countCache[id]
    if cached then
        return cached[1], cached[2], cached[3]
    end
    local inBags = GetItemCount(id, false) or 0
    local inPersonal = bankOpen and ((GetItemCount(id, true) or 0) - inBags) or (RDL_BankCache[id] or 0)
    local inVault = RDL_ReagentBankCache[id] or 0
    countCache[id] = { inBags, inPersonal, inVault }
    return inBags, inPersonal, inVault
end

function RDL_Core.TotalCount(id)
    local b, p, v = RDL_Core.GetBreakdownCounts(id)
    return b + p + v
end

local function FindFreeBankSlot()
    for _, bag in ipairs(BANK_BAGS) do
        local slots = GetContainerNumSlots(bag)
        if slots and slots > 0 then
            for slot = 1, slots do
                if not GetContainerItemID(bag, slot) then
                    return bag, slot
                end
            end
        end
    end
    return nil, nil
end

-- Mueve a los huecos libres del banco cualquier pieza de ropa/arma recien creada que este en mochila
function RDL_Core.TryStoreCraftedGearInBank()
    if not bankOpen or not pendingBankStoreID then return end
    if InCombatLockdown() or CursorHasItem() then return end

    local movedAny = false
    for bag = 0, 4 do
        for slot = 1, GetContainerNumSlots(bag) do
            if GetContainerItemID(bag, slot) == pendingBankStoreID then
                local _, _, locked = GetContainerItemInfo(bag, slot)
                if not locked then
                    local destBag, destSlot = FindFreeBankSlot()
                    if not destBag or not destSlot then
                        pendingBankStoreID = nil
                        return
                    end
                    PickupContainerItem(bag, slot)
                    PickupContainerItem(destBag, destSlot)
                    movedAny = true
                end
            end
        end
    end

    if movedAny then
        pendingBankStoreID = nil
    end
end

local function TrackCraftedItem(skillIndex)
    lastCraftedGearID = nil
    if not skillIndex or skillIndex <= 0 then return end
    local itemLink = GetTradeSkillItemLink(skillIndex)
    if not itemLink then return end
    local itemID = tonumber(itemLink:match("item:(%d+)"))
    if not itemID then return end

    local _, _, _, _, _, itemType, _, _, equipLoc = GetItemInfo(itemLink)
    local isGear = (itemType == "Armor" or itemType == "Weapon" or itemType == "Armadura" or itemType == "Arma") and equipLoc ~= ""
    if isGear then
        lastCraftedGearID = itemID
    end
end

local function ScheduleNextCraft()
    local elapsed = 0
    timerFrame:SetScript("OnUpdate", function(self, dt)
        elapsed = elapsed + dt
        if elapsed >= 0.15 then
            self:SetScript("OnUpdate", nil)
            if qSpell and qRem > 0 then
                qRem = qRem - 1
                SendAddonMessage("RDL_CRAFT", qSpell .. ":1", "WHISPER", UnitName("player"))
            else
                qSpell, qName, qRem = nil, nil, 0
            end
        end
    end)
end

function RDL_Core.Craft(id, n)
    local _, _, avail = GetTradeSkillInfo(id)
    n = math.max(1, n or 1)
    TrackCraftedItem(id)

    if (avail or 0) >= n then
        DoTradeSkill(id, n)
        return
    end
    local link = GetTradeSkillRecipeLink(id) or ""
    local sp = link:match("enchant:(%d+)") or link:match("spell:(%d+)")
    local skillName = GetTradeSkillInfo(id)
    if sp and skillName then
        qSpell, qName, qRem = tonumber(sp), skillName, n - 1
        timerFrame:SetScript("OnUpdate", nil)
        SendAddonMessage("RDL_CRAFT", sp .. ":1", "WHISPER", UnitName("player"))
    end
end

function RDL_Core.OnSpellSucceeded(spellName)
    -- Si estamos con el banco abierto y hemos fabricado una pieza de equipo, marcamos para guardarla al caer en bolsa
    if bankOpen and lastCraftedGearID then
        local sel = GetTradeSkillSelectionIndex()
        local currentSkillName = sel and sel > 0 and GetTradeSkillInfo(sel)
        if spellName == qName or spellName == currentSkillName then
            pendingBankStoreID = lastCraftedGearID
        end
    end

    if not qName or spellName ~= qName then return end
    local sel = GetTradeSkillSelectionIndex()
    if sel and sel > 0 then
        for i = 1, GetTradeSkillNumReagents(sel) do
            local _, _, req = GetTradeSkillReagentInfo(sel, i)
            local link = GetTradeSkillReagentItemLink(sel, i)
            local itemID = link and tonumber(link:match("item:(%d+)"))
            if itemID and req and RDL_ReagentBankCache[itemID] then
                RDL_ReagentBankCache[itemID] = math.max(0, RDL_ReagentBankCache[itemID] - req)
            end
        end
    end
    wipe(countCache)
    if qRem > 0 then ScheduleNextCraft() else qSpell, qName, qRem = nil, nil, 0 end
end

function RDL_Core.OnSpellStopped(spellName)
    if qName and spellName == qName then
        timerFrame:SetScript("OnUpdate", nil)
        qSpell, qName, qRem = nil, nil, 0
    end
end
