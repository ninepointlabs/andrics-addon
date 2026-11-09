-- Minimal, strict WoW API mock for headless tests (Lua 5.1).
-- Undefined globals raise an error so typos and unmocked APIs surface here
-- instead of in the client. Optional APIs the addon feature-tests are listed in
-- OPTIONAL and read as nil.
local M = {}

M.texts = {}       -- every SetText call, for assertions
M.events = {}      -- frames registered per event
M.timers = {}
M.state = {
    level = 24, race = "Scourge", class = "PRIEST", faction = "Horde", money = 345678,
    projectId = 18, combat = false, known = {}, auras = {}, targetAuras = {}, target = true,
    mana = 80, targetHp = 60, cooldowns = {}, equipped = {}, itemLines = {}, itemInfo = {},
    questsDone = {}, bags = {},
}

local function newObject(kind)
    local o = { __kind = kind, __shown = true, __scripts = {}, __w = 100, __h = 20 }
    return setmetatable(o, {
        __index = function(t, k)
            if k == "SetText" then
                return function(self, s) self.__text = s table.insert(M.texts, tostring(s or "")) end
            elseif k == "GetText" then
                return function(self) return self.__text end
            elseif k == "SetScript" then
                return function(self, ev, fn) self.__scripts[ev] = fn end
            elseif k == "GetScript" then
                return function(self, ev) return self.__scripts[ev] end
            elseif k == "HookScript" then
                return function(self, ev, fn) self.__scripts[ev] = fn end
            elseif k == "RegisterEvent" or k == "RegisterUnitEvent" then
                return function(self, ev) M.events[ev] = M.events[ev] or {} table.insert(M.events[ev], self) end
            elseif k == "UnregisterEvent" then
                return function() end
            elseif k == "Show" then
                return function(self) self.__shown = true if self.__scripts.OnShow then self.__scripts.OnShow(self) end end
            elseif k == "Hide" then
                return function(self) self.__shown = false end
            elseif k == "SetShown" then
                return function(self, v) if v then self:Show() else self:Hide() end end
            elseif k == "IsShown" or k == "IsVisible" then
                return function(self) return self.__shown end
            elseif k == "SetWidth" then
                return function(self, w) self.__w = w end
            elseif k == "SetHeight" then
                return function(self, h) self.__h = h end
            elseif k == "SetSize" then
                return function(self, w, h) self.__w, self.__h = w, h end
            elseif k == "GetWidth" then
                return function(self) return self.__w end
            elseif k == "GetHeight" then
                return function(self) return self.__h end
            elseif k == "GetStringHeight" then
                return function() return 14 end
            elseif k == "GetStringWidth" then
                return function(self) return #(tostring(self.__text or "")) * 6 end
            elseif k == "GetChecked" then
                return function(self) return self.__checked end
            elseif k == "SetChecked" then
                return function(self, v) self.__checked = v end
            elseif k == "GetFrameLevel" then
                return function() return 1 end
            elseif k == "GetPoint" then
                return function() return "CENTER", nil, "CENTER", 0, 0 end
            elseif k == "GetCenter" then
                return function() return 0, 0 end
            elseif k == "GetEffectiveScale" then
                return function() return 1 end
            elseif k == "GetItem" then
                return function(self) return "Item", self.__item end
            elseif k:match("^Create") then
                return function() return newObject(k) end
            elseif k:match("^Is") or k:match("^Can") then
                return function() return false end
            else
                return function() return nil end
            end
        end,
    })
end
M.newObject = newObject

function M.Fire(event, ...)
    for _, f in ipairs(M.events[event] or {}) do
        local fn = f.__scripts.OnEvent
        if fn then fn(f, event, ...) end
    end
end

function M.RunTimers()
    local list = M.timers
    M.timers = {}
    for _, t in ipairs(list) do if not t.cancelled then t.fn() end end
end

local S = M.state
local G = {}

G.WOW_PROJECT_ID = function() return S.projectId end -- resolved below
G.CreateFrame = function(kind, name) local f = newObject(kind) if name then _G[name] = f end return f end
G.UIParent = newObject("UIParent")
G.Minimap = newObject("Minimap")
G.GameTooltip = newObject("GameTooltip")
G.ItemRefTooltip = newObject("ItemRefTooltip")
G.UISpecialFrames = {}
G.StaticPopupDialogs = {}
G.StaticPopup_Show = function() end
G.SlashCmdList = {}
G.CLOSE = "Close"
G.Mixin = function(o, m) for k, v in pairs(m) do o[k] = v end return o end
G.BackdropTemplateMixin = {}
G.Settings = { RegisterCanvasLayoutCategory = function() return {} end, RegisterAddOnCategory = function() end }
G.SettingsPanel = newObject("SettingsPanel")
G.HideUIPanel = function() end
G.Enum = { TooltipDataType = { Item = 0 } }
G.TooltipDataProcessor = { AddTooltipPostCall = function(_, fn) M.tooltipHook = fn end }
G.C_Timer = {
    After = function(_, fn) table.insert(M.timers, { fn = fn }) end,
    NewTimer = function(_, fn) local t = { fn = fn, Cancel = function(self) self.cancelled = true end } table.insert(M.timers, t) return t end,
    NewTicker = function(_, fn) return { Cancel = function() end } end,
}
G.C_AddOns = { GetAddOnMetadata = function() return "test" end }
G.C_Item = {
    GetItemInfoInstant = function(id)
        local info = S.itemInfo[id] or S.itemInfo[tonumber(tostring(id):match("item:(%d+)") or id)]
        if not info then return nil end
        return id, "Armor", "Cloth", info.equipLoc, 134400, info.classID, info.subclassID
    end,
    GetItemInfo = function(id) return "Item", S.itemInfo[id] and ("|Hitem:" .. id .. "|h") or nil end,
    GetItemIconByID = function() return 134400 end,
    GetItemNameByID = function(id) return "Item " .. id end,
    GetItemCount = function(id) return S.bags[id] or 0 end,
}
G.C_Spell = {
    GetSpellName = function(id) return S.spellNames and S.spellNames[id] or nil end,
    GetSpellTexture = function() return 136207 end,
    GetSpellCooldown = function(name)
        local left = S.cooldowns[name] or 0
        return { startTime = 100, duration = left > 0 and (left + 0) or 0 }
    end,
}
G.C_UnitAuras = {
    GetAuraDataBySpellName = function(unit, name)
        local set = unit == "player" and S.auras or S.targetAuras
        return set[name] and { name = name } or nil
    end,
}
G.C_QuestLog = { IsQuestFlaggedCompleted = function(id) return S.questsDone[id] == true end }
G.C_TooltipInfo = {
    GetHyperlink = function(link)
        local lines = S.itemLines[link]
        if not lines then return nil end
        local out = {}
        for i, l in ipairs(lines) do out[i] = { leftText = l } end
        return { lines = out }
    end,
}
G.UnitLevel = function() return S.level end
G.UnitRace = function() return S.race, S.race end
G.UnitClass = function() return "Priest", S.class end
G.UnitName = function() return "Andric" end
G.UnitFactionGroup = function() return S.faction, S.faction end
G.UnitExists = function(u) return u == "player" or (u == "target" and S.target) end
G.UnitCanAttack = function() return true end
G.UnitIsDead = function() return false end
G.UnitAffectingCombat = function() return S.combat end
G.UnitPower = function() return S.mana end
G.UnitPowerMax = function() return 100 end
G.UnitHealth = function() return S.targetHp end
G.UnitHealthMax = function() return 100 end
G.InCombatLockdown = function() return S.combat end
G.GetMoney = function() return S.money end
G.GetBuildInfo = function() return "1.60.1", "70862", "Nov 6 2026", 16001 end
G.GetInventoryItemLink = function(_, slot) return S.equipped[slot] end
G.IsPlayerSpell = function(id) return S.known[id] == true end
G.IsSpellKnown = function(id) return S.known[id] == true end
G.GetTime = function() return S.time or 1000 end
G.GetCursorPosition = function() return 0, 0 end
G.IsShiftKeyDown = function() return false end
G.IsModifiedClick = function() return false end
G.ChatEdit_InsertLink = function() end
G.hooksecurefunc = function() end

local OPTIONAL = {
    issecretvalue = true, WOW_PROJECT_CAMELOT = true, AuraUtil = true, GetSpellInfo = true, strtrim = true,
    AndricsAddonDB = true, AndricsAddonCharDB = true, AndricsAddonFrame = true, AndricsAddonHud = true,
    AndricsAddonMinimapButton = true, SLASH_ANDRICSADDON1 = true, SLASH_ANDRICSADDON2 = true,
    AndricsAddon_OnCompartmentClick = true,
}

function M.Install()
    for k, v in pairs(G) do rawset(_G, k, v) end
    rawset(_G, "WOW_PROJECT_ID", S.projectId)
    setmetatable(_G, {
        __index = function(_, k)
            if OPTIONAL[k] then return nil end
            error("undefined global: " .. tostring(k), 2)
        end,
    })
end

-- Load every file listed in the TOC with (addonName, ns) varargs.
function M.LoadAddon(tocPath, root)
    local ns = {}
    for line in io.lines(tocPath) do
        if not line:match("^##") and line:match("%S") then
            local path = root .. "/" .. line:gsub("\\", "/"):gsub("%s+$", "")
            local chunk = assert(loadfile(path))
            chunk("AndricsAddon", ns)
        end
    end
    return ns
end

return M
