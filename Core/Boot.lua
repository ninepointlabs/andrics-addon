-- Events, slash commands, startup. Loaded last.
local ADDON, ns = ...

local f = CreateFrame("Frame")
ns.EventFrame = f

local function OnLogin()
    if ns.disabled then
        ns.Print(("This addon is for WoW Forever only (needs WOW_PROJECT_ID %d, this client reports %s). It will stay off."):format(
            ns.FOREVER_PROJECT_ID, tostring(WOW_PROJECT_ID)))
        return
    end
    AndricsAddonDB, AndricsAddonCharDB = ns.DB.Init(AndricsAddonDB, AndricsAddonCharDB)
    local _, class = UnitClass("player")
    ns.isPriest = (class == "PRIEST")

    ns.UI.MinimapButton()
    ns.UI.RegisterSettings()
    ns.Tooltip.Install() -- gear tips are useful on any class's tooltip for Priest gear; still spec-based
    pcall(ns.Bags.Install)
    pcall(ns.Fort.Refresh)
    ns.DualSpec.Register(f)

    for _, ev in ipairs({ "PLAYER_LEVEL_UP", "PLAYER_REGEN_DISABLED", "PLAYER_REGEN_ENABLED", "UNIT_AURA",
        "PLAYER_EQUIPMENT_CHANGED", "BAG_UPDATE_DELAYED", "SPELLS_CHANGED", "PLAYER_TARGET_CHANGED", "GET_ITEM_INFO_RECEIVED", "GROUP_ROSTER_UPDATE" }) do
        pcall(f.RegisterEvent, f, ev)
    end
    pcall(f.RegisterUnitEvent, f, "UNIT_SPELLCAST_SUCCEEDED", "player")

    if not ns.isPriest then
        ns.Print("You're not a Priest; the window still works for reading. Tooltip tips use the active profile's spec.")
    end
    ns.Learn.ScanSpells(true)
    ns.db.char.lastLevel = UnitLevel("player")

    if ns.isPriest and not ns.DB.HasChosenSpec() then
        C_Timer.After(3, function()
            ns.Print("Welcome! Pick Holy, Discipline or Shadow to tailor everything. (/andric)")
            ns.UI.ShowPicker()
        end)
    end
    local unread = ns.Changes.UnreadCount()
    if unread > 0 then
        C_Timer.After(5, function() ns.Print(("%d unread in What's changed. /andric changes"):format(unread)) end)
    end
    ns.Hud.Refresh()
    -- Upgrades already sitting in the bags: one summary line, no toast spam.
    C_Timer.After(6, function()
        local found = ns.Bags.Scan(true)
        if #found > 0 then
            ns.Print(("|cff3fdc5a%d upgrade(s) in your bags|r for %s, highlighted in your bags: %s"):format(#found, ns.DB.ActiveSpec(), found[1].link .. (#found > 1 and " ..." or "")))
        end
        ns.Bags.RefreshAll()
    end)
end

-- Reminder toast, throttled; out of combat only.
local lastReminder = 0
local function CheckReminders(force)
    if InCombatLockdown() or not ns.db then return end
    local now = GetTime()
    if not force and now - lastReminder < 60 then return end
    local miss = ns.Reminders.Missing()
    if #miss > 0 then
        lastReminder = now
        local names = {}
        for _, r in ipairs(miss) do table.insert(names, r.label) end
        ns.Hud.Toast("Reminder", "Missing: " .. table.concat(names, ", "), miss[1].icon)
    end
end
ns.CheckReminders = CheckReminders

local refreshPending
local function SoftRefresh()
    if refreshPending then return end
    refreshPending = true
    C_Timer.After(0.5, function()
        refreshPending = false
        ns.UI.Refresh()
        ns.UI.UpdateMinimap()
    end)
end

-- Bags: re-check highlights and announce new upgrades (throttled, out of combat).
local bagPending
local function BagRefresh()
    if bagPending then return end
    bagPending = true
    C_Timer.After(0.7, function()
        bagPending = false
        pcall(ns.Bags.RefreshAll)
        if not InCombatLockdown() then pcall(ns.Bags.Scan, false) end
    end)
end
ns.BagRefresh = BagRefresh

f:SetScript("OnEvent", function(_, event, ...)
    if event == "ADDON_LOADED" then
        if ... == ADDON then f:UnregisterEvent("ADDON_LOADED") end
        return
    end
    if event == "PLAYER_LOGIN" then
        OnLogin()
        return
    end
    if ns.disabled or not ns.db then return end
    ns.Fire("WOW_" .. event, ...)
    if event == "PLAYER_LEVEL_UP" then
        local level = ...
        ns.Training.OnLevelUp(level)
        for _, l in ipairs(ns.Learn.NewLessonsAt(level, ns.DB.ActiveSpec())) do
            ns.Hud.Toast("New lesson: " .. l.title, "Open Learn the Priest (/andric learn).", "Interface\\Icons\\INV_Misc_Book_07")
        end
        ns.db.char.lastLevel = level
        SoftRefresh()
        BagRefresh()
    elseif event == "PLAYER_REGEN_DISABLED" then
        if ns.db.char.summary.enabled then ns.Summary.Start(GetTime(), ns.Auras.PowerPct("player")) end
        ns.Hud.Refresh()
    elseif event == "PLAYER_REGEN_ENABLED" then
        local fight = ns.Summary.Finish(GetTime(), ns.Auras.PowerPct("player"))
        if fight and ns.db.char.summary.enabled then
            ns.Print(("Fight %ds: %s"):format(fight.duration, ns.Summary.Text(fight)))
            for _, t in ipairs(fight.tips) do print("  |cffffd200>|r " .. t) end
        end
        ns.Hud.Refresh()
        pcall(ns.Fort.Refresh)
        C_Timer.After(2, function() CheckReminders(false) end)
        SoftRefresh()
        BagRefresh()
    elseif event == "UNIT_SPELLCAST_SUCCEEDED" then
        local unit, _, spellID = ...
        if unit == "player" then ns.Summary.OnCast(spellID) end
    elseif event == "SPELLS_CHANGED" then
        ns.Learn.ScanSpells(false)
        pcall(ns.Fort.Refresh)
    elseif event == "GROUP_ROSTER_UPDATE" or event == "PLAYER_TARGET_CHANGED" then
        if not InCombatLockdown() then pcall(ns.Fort.Update) end
    elseif event == "UNIT_AURA" then
        local unit = ...
        if unit == "player" then SoftRefresh() end
    elseif event == "PLAYER_EQUIPMENT_CHANGED" then
        ns.Stats.ClearCache()
        SoftRefresh()
        BagRefresh()
    elseif event == "GET_ITEM_INFO_RECEIVED" then
        SoftRefresh() -- uncached items were never stored in the stat cache, so no clear needed
        BagRefresh()
    elseif event == "BAG_UPDATE_DELAYED" then
        SoftRefresh()
        BagRefresh()
    end
end)
f:RegisterEvent("ADDON_LOADED")
f:RegisterEvent("PLAYER_LOGIN")

ns.On("SPEC_CHANGED", function()
    ns.Stats.ClearCache()
    ns.Bags.Reset()
    BagRefresh()
    if ns.UI.UpdateMinimap then ns.UI.UpdateMinimap() end
    ns.Hud.Refresh()
end)
ns.On("HUD_TOGGLE", function() ns.Hud.Refresh() end)
ns.On("HUD_RESET", function() ns.Hud.Place() end)
ns.On("MINIMAP_TOGGLE", function() ns.UI.MinimapButton() end)
ns.On("CHANGES_READ", function() ns.UI.UpdateMinimap() end)
ns.On("TOAST", function(title, text, icon) ns.Hud.Toast(title, text, icon) end)
ns.On("REMINDERS_CHANGED", function() CheckReminders(true) end)

local function Slash(msg)
    if ns.disabled then
        ns.Print("Disabled: WoW Forever only.")
        return
    end
    msg = (msg or ""):lower():match("^%s*(.-)%s*$")
    local cmd, arg = msg:match("^(%S*)%s*(.*)$")
    local tabs = { overview = "overview", rotation = "rotation", learn = "learn", leveling = "leveling", talents = "talents",
        gear = "gear", quests = "quests", training = "training", spells = "training", mounts = "mounts", gold = "mounts",
        reminders = "reminders", changes = "changes", sources = "sources", options = "options", config = "options" }
    if cmd == "" then
        ns.UI.Toggle()
    elseif cmd == "spec" then
        local want = arg ~= "" and (arg:sub(1, 1):upper() .. arg:sub(2)) or nil
        if want == "Disc" then want = "Discipline" end
        if want and ns.Specs[want] then
            ns.DB.SetSpec(want)
            ns.Print("Profile " .. ns.DB.ActiveId() .. " is now " .. want .. ".")
        else
            ns.UI.ShowPicker()
        end
    elseif cmd == "profile" or cmd == "swap" then
        local id = arg ~= "" and arg:upper() or ns.DB.OtherProfileId()
        if ns.DB.SwitchProfile(id) then ns.Print("Switched to profile " .. id .. " (" .. (ns.DB.ActiveSpec() or "no spec") .. ").") end
    elseif cmd == "hud" then
        ns.db.char.rotation.enabled = not ns.db.char.rotation.enabled
        ns.Hud.Refresh()
    elseif cmd == "reset-hud" then
        ns.db.char.rotation.point = nil
        ns.Hud.Place()
    elseif cmd == "fort" then
        if arg == "macro" then ns.Fort.CreateMacro()
        else
            ns.db.char.fortButton.enabled = not ns.db.char.fortButton.enabled
            ns.Fort.Refresh()
            ns.Print("Fortitude button " .. (ns.db.char.fortButton.enabled and "shown" or "hidden") .. ".")
        end
    elseif cmd == "remind" then
        CheckReminders(true)
    elseif tabs[cmd] then
        ns.UI.Open(tabs[cmd])
    else
        ns.Print("/andric [overview|rotation|learn|leveling|talents|gear|quests|training|mounts|reminders|changes|sources|options]")
        ns.Print("/andric spec [holy|disc|shadow] · /andric profile [A|B] · /andric hud · /andric reset-hud · /andric remind · /andric fort [macro]")
    end
end

SLASH_ANDRICSADDON1 = "/andric"
SLASH_ANDRICSADDON2 = "/priest"
SlashCmdList.ANDRICSADDON = Slash
