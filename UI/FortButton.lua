-- "Buff next" button: one press casts Power Word: Fortitude on the next friendly
-- player who needs it, nearest first.
--
-- Blizzard rules this follows:
--   * A secure action button (SecureActionButtonTemplate) does the cast; every
--     cast needs your click / key press. The addon never casts by itself.
--   * The addon may only change WHO the button targets out of combat. In combat
--     the button keeps its last target (and says so).
--   * Distances to players outside your group aren't available to addons, so
--     "nearest" = you, then group members (nearest first when the client reports
--     distance), your target, then friendly players with a visible nameplate.
--     Everyone must pass the client's own Fortitude range check.
local _, ns = ...
local UI = ns.UI

local Fort = {}
ns.Fort = Fort

Fort.SPELL_ID = 1243 -- Power Word: Fortitude (base id, research data.json)
Fort.PRAYER_ID = 21562 -- Prayer of Fortitude also counts as "has the buff"
Fort.RECENT_SECONDS = 4 -- skip someone we just buffed until their aura shows up

local btn, holder, current
local recent = {} -- guid -> GetTime() of our last cast on them

local function spellName(id, fallback)
    return ns.Auras.SpellName(id) or fallback
end

local function safe(fn, ...)
    local ok, a, b = pcall(fn, ...)
    if ok then return a, b end
    return nil
end

-- Does this unit already have Fortitude (or Prayer of Fortitude)? true/false/nil(unknown)
function Fort.HasBuff(unit)
    local fort = ns.Auras.Find(unit, spellName(Fort.SPELL_ID, "Power Word: Fortitude"), "HELPFUL")
    if fort then return true end
    local prayer = ns.Auras.Find(unit, spellName(Fort.PRAYER_ID, "Prayer of Fortitude"), "HELPFUL")
    if prayer then return true end
    if fort == nil or prayer == nil then return nil end
    return false
end

function Fort.InRange(unit)
    if UnitIsUnit("player", unit) then return true end
    if C_Spell and C_Spell.IsSpellInRange then
        local r = safe(C_Spell.IsSpellInRange, Fort.SPELL_ID, unit)
        if r ~= nil then return r end
        r = safe(C_Spell.IsSpellInRange, spellName(Fort.SPELL_ID, "Power Word: Fortitude"), unit)
        return r
    end
    return nil
end

-- Unit tokens to consider, in "nearest first" order.
function Fort.CandidateUnits()
    local list = { { unit = "player", order = 0 } }
    local group = {}
    if IsInRaid() then
        for i = 1, 40 do table.insert(group, "raid" .. i) end
    elseif IsInGroup() then
        for i = 1, 4 do table.insert(group, "party" .. i) end
    end
    for _, u in ipairs(group) do
        if UnitExists(u) then
            local d, checked = nil, false
            if UnitDistanceSquared then d, checked = safe(UnitDistanceSquared, u) end
            local dist = (checked and type(d) == "number" and not ns.Auras.IsSecret(d)) and d or nil
            table.insert(list, { unit = u, order = 1, dist = dist })
        end
    end
    table.insert(list, { unit = "target", order = 2 })
    for i = 1, 40 do
        local u = "nameplate" .. i
        if UnitExists(u) then table.insert(list, { unit = u, order = 3 }) end
    end
    return list
end

-- Pick the next unit to buff. Returns { unit, name, guid, rangeKnown, buffKnown } or nil, plus a reason.
function Fort.Pick(now)
    now = now or GetTime()
    local seen, eligible = {}, {}
    local inRangeButBuffed, outOfRange = 0, 0
    for _, c in ipairs(Fort.CandidateUnits()) do
        local u = c.unit
        local guid = UnitExists(u) and UnitGUID(u)
        if guid and not ns.Auras.IsSecret(guid) and not seen[guid] then
            seen[guid] = true
            local ok = UnitIsPlayer(u) and UnitCanAssist("player", u) and not UnitIsDeadOrGhost(u)
                and UnitIsConnected(u) and not (recent[guid] and now - recent[guid] < Fort.RECENT_SECONDS)
            if ok then
                local has = Fort.HasBuff(u)
                local range = Fort.InRange(u)
                if range == false then
                    if has ~= true then outOfRange = outOfRange + 1 end
                elseif has == true then
                    inRangeButBuffed = inRangeButBuffed + 1
                else
                    table.insert(eligible, { unit = u, guid = guid, name = UnitName(u), order = c.order, dist = c.dist,
                        buffKnown = has == false, rangeKnown = range == true })
                end
            end
        end
    end
    table.sort(eligible, function(a, b)
        -- Confirmed missing + confirmed in range first, then group order, then distance.
        local ak = (a.buffKnown and 0 or 1) + (a.rangeKnown and 0 or 2)
        local bk = (b.buffKnown and 0 or 1) + (b.rangeKnown and 0 or 2)
        if ak ~= bk then return ak < bk end
        if a.order ~= b.order then return a.order < b.order end
        if a.dist and b.dist then return a.dist < b.dist end
        return false
    end)
    local reason
    if #eligible == 0 then
        if outOfRange > 0 then reason = outOfRange .. " player(s) need it but are out of range"
        else reason = "everyone nearby is buffed" end
    end
    return eligible[1], reason, #eligible
end

local function setLook(active)
    if not btn then return end
    btn.icon:SetDesaturated(not active)
    btn.icon:SetAlpha(active and 1 or 0.45)
    btn:SetBackdropBorderColor(unpack(active and UI.Accent() or UI.C.border))
end

-- Re-aim the secure button (out of combat only).
function Fort.Update()
    if not btn then return end
    if InCombatLockdown() then
        btn.status:SetText(current and (UI.Hex(UI.C.dim) .. "in combat: " .. (current.name or "?") .. "|r") or (UI.Hex(UI.C.dim) .. "in combat|r"))
        return
    end
    local pick, reason, count = Fort.Pick()
    current = pick
    if pick then
        btn:SetAttribute("type", "spell")
        btn:SetAttribute("spell", spellName(Fort.SPELL_ID, "Power Word: Fortitude"))
        btn:SetAttribute("unit", pick.unit)
        btn.status:SetText((UnitIsUnit(pick.unit, "player") and "you" or (pick.name or "?")) .. (count > 1 and (UI.Hex(UI.C.dim) .. " +" .. (count - 1) .. "|r") or ""))
        setLook(true)
    else
        btn:SetAttribute("type", nil)
        btn:SetAttribute("unit", nil)
        btn.status:SetText(UI.Hex(UI.C.dim) .. (reason == "everyone nearby is buffed" and "all buffed" or "none in range") .. "|r")
        setLook(false)
    end
    btn.reason = reason
    btn.count = count
end

function Fort.ShouldShow()
    local cfg = ns.db and ns.db.char.fortButton
    return cfg and cfg.enabled and ns.Progress.KnowsSpell(Fort.SPELL_ID)
end

function Fort.Place()
    if not holder then return end
    holder:ClearAllPoints()
    local p = ns.db.char.fortButton.point
    if p then holder:SetPoint(p[1], UIParent, p[2], p[3], p[4]) else holder:SetPoint("CENTER", UIParent, "CENTER", -160, -190) end
end

function Fort.Build()
    if btn then return btn end
    -- Non-secure holder so it can be dragged (out of combat) without interfering with clicks.
    holder = CreateFrame("Frame", "AndricsFortHolder", UIParent)
    holder:SetSize(56, 70)
    holder:SetMovable(true)
    holder:SetClampedToScreen(true)
    holder.handle = CreateFrame("Frame", nil, holder, "BackdropTemplate")
    holder.handle:SetSize(46, 8)
    holder.handle:SetPoint("TOP", 0, 0)
    UI.Backdrop(holder.handle, { 0.2, 0.2, 0.25, 0.8 }, { 0, 0, 0, 0 })
    holder.handle:EnableMouse(true)
    holder.handle:RegisterForDrag("LeftButton")
    holder.handle:SetScript("OnDragStart", function() if not InCombatLockdown() then holder:StartMoving() end end)
    holder.handle:SetScript("OnDragStop", function()
        holder:StopMovingOrSizing()
        local point, _, rel, x, y = holder:GetPoint()
        ns.db.char.fortButton.point = { point, rel, x, y }
    end)
    holder.handle:SetScript("OnEnter", function(s)
        GameTooltip:SetOwner(s, "ANCHOR_TOP")
        GameTooltip:SetText("Drag to move (out of combat)", 1, 1, 1)
        GameTooltip:Show()
    end)
    holder.handle:SetScript("OnLeave", function() GameTooltip:Hide() end)

    btn = CreateFrame("Button", "AndricsFortButton", holder, "SecureActionButtonTemplate, BackdropTemplate")
    btn:SetSize(40, 40)
    btn:SetPoint("TOP", holder.handle, "BOTTOM", 0, -2)
    UI.Backdrop(btn, { 0, 0, 0, 0.7 }, UI.C.border)
    -- Mouse, key binding and /click all act on release (see SecureActionButton_OnClick).
    btn:RegisterForClicks("AnyUp", "AnyDown")
    btn:SetAttribute("useOnKeyDown", false)
    btn.icon = btn:CreateTexture(nil, "ARTWORK")
    btn.icon:SetPoint("TOPLEFT", 1, -1)
    btn.icon:SetPoint("BOTTOMRIGHT", -1, 1)
    btn.icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
    btn.icon:SetTexture("Interface\\Icons\\Spell_Holy_WordFortitude")
    btn:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square", "ADD")
    btn.status = UI.Text(holder, 10)
    btn.status:SetPoint("TOP", btn, "BOTTOM", 0, -2)
    btn.status:SetWidth(110)
    btn.status:SetJustifyH("CENTER")
    btn.status:SetWordWrap(false)
    btn:SetScript("OnEnter", function(s)
        GameTooltip:SetOwner(s, "ANCHOR_RIGHT")
        GameTooltip:SetText("Buff next: Power Word: Fortitude", 1, 0.82, 0)
        if current then
            GameTooltip:AddLine("Next: " .. (current.name or "?") .. (current.rangeKnown and "" or " (range unknown)") .. (current.buffKnown and "" or " (buff state unknown)"), 1, 1, 1)
            if (s.count or 0) > 1 then GameTooltip:AddLine((s.count - 1) .. " more after that", 0.7, 0.7, 0.7) end
        else
            GameTooltip:AddLine("Nobody to buff: " .. (s.reason or "?"), 0.7, 0.7, 0.7)
        end
        GameTooltip:AddLine("Click or use your key binding: one cast per press.", 0.6, 0.6, 0.6, true)
        GameTooltip:AddLine("Nearest = you, your group, your target, then players with friendly nameplates shown (Shift+V).", 0.6, 0.6, 0.6, true)
        if InCombatLockdown() then GameTooltip:AddLine("In combat the target can't change until combat ends.", 1, 0.5, 0.3, true) end
        GameTooltip:Show()
    end)
    btn:SetScript("OnLeave", function() GameTooltip:Hide() end)
    -- After a press, remember who we just buffed and move on.
    btn:HookScript("PostClick", function()
        if current and current.guid then recent[current.guid] = GetTime() end
        C_Timer.After(0.3, Fort.Update)
    end)
    Fort.Place()
    holder:Hide()
    return btn
end

local ticker
function Fort.Refresh()
    if InCombatLockdown() then return end -- show/hide of secure frames is blocked in combat
    Fort.Build()
    local show = Fort.ShouldShow()
    holder:SetShown(show and true or false)
    if show and not ticker then
        ticker = C_Timer.NewTicker(0.5, function() pcall(Fort.Update) end)
    elseif not show and ticker then
        ticker:Cancel()
        ticker = nil
    end
    if show then Fort.Update() end
end

-- Action-bar macro that presses the button (/click). Created on request.
Fort.MACRO_NAME = "AndricsFort"
function Fort.MacroBody()
    return "#showtooltip " .. spellName(Fort.SPELL_ID, "Power Word: Fortitude") .. "\n/click AndricsFortButton"
end

function Fort.CreateMacro()
    if InCombatLockdown() then ns.Print("Can't create macros in combat.") return end
    local index = GetMacroIndexByName(Fort.MACRO_NAME)
    if index == 0 then
        local ok, res = pcall(CreateMacro, Fort.MACRO_NAME, "INV_MISC_QUESTIONMARK", Fort.MacroBody(), nil)
        if not ok or not res then
            ns.Print("Couldn't create the macro (your general macro slots may be full).")
            return
        end
        index = res
        ns.Print("Created macro '" .. Fort.MACRO_NAME .. "'. It's on your cursor: drop it on an action bar.")
    else
        pcall(EditMacro, index, Fort.MACRO_NAME, "INV_MISC_QUESTIONMARK", Fort.MacroBody())
        ns.Print("Macro '" .. Fort.MACRO_NAME .. "' is on your cursor: drop it on an action bar.")
    end
    PickupMacro(index)
end

-- Key binding labels (Bindings.xml).
BINDING_HEADER_ANDRICSADDON = "Andric's Addon"
_G["BINDING_NAME_CLICK AndricsFortButton:LeftButton"] = "Buff next player with Power Word: Fortitude"
