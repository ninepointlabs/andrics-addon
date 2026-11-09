local _, ns = ...
local UI = ns.UI

local SLOT_NAMES = {
    INVTYPE_HEAD = "Head", INVTYPE_NECK = "Neck", INVTYPE_SHOULDER = "Shoulder", INVTYPE_CHEST = "Chest", INVTYPE_ROBE = "Chest",
    INVTYPE_WAIST = "Waist", INVTYPE_LEGS = "Legs", INVTYPE_FEET = "Feet", INVTYPE_WRIST = "Wrist", INVTYPE_HAND = "Hands",
    INVTYPE_FINGER = "Ring", INVTYPE_TRINKET = "Trinket", INVTYPE_CLOAK = "Back", INVTYPE_WEAPON = "One-hand",
    INVTYPE_WEAPONMAINHAND = "Main hand", INVTYPE_2HWEAPON = "Two-hand", INVTYPE_HOLDABLE = "Off hand",
    INVTYPE_RANGEDRIGHT = "Wand", INVTYPE_RANGED = "Ranged",
}

local function upgradeText(id, c)
    local _, link = C_Item.GetItemInfo(id)
    if not link then return UI.Hex(UI.C.dim) .. "hover to load|r" end
    local res = ns.Stats.Compare(link, c.spec, c.level, c.profile, ns.db.global.percentScale)
    if not res or res.pending then return "" end
    if res.unusable then return UI.Hex(UI.C.dim) .. "not for priests|r" end
    if res.isEquipped then return UI.Hex(UI.C.good) .. "equipped|r" end
    if res.against and res.against.empty then return UI.Hex(UI.C.good) .. "upgrade (empty)|r" end
    if not res.delta then return "" end
    if res.delta > 0.05 then return UI.Hex(UI.C.good) .. (res.pct and ("+%.0f%%"):format(res.pct) or "upgrade") .. "|r" end
    if res.delta < -0.05 then return UI.Hex(UI.C.bad) .. (res.pct and ("%.0f%%"):format(res.pct) or "worse") .. "|r" end
    return UI.Hex(UI.C.dim) .. "same|r"
end

local bracketSel
local gearView -- "mine" | "best" | "bracket"
local detailId -- item id shown in the detail view (nil = list)

local function openDetail(id)
    return function() detailId = id UI.Refresh() end
end
UI.OpenGearDetail = function(id) detailId = id end

local SLOT_GROUPS = {
    { "Head", { INVTYPE_HEAD = true } }, { "Neck", { INVTYPE_NECK = true } },
    { "Shoulder", { INVTYPE_SHOULDER = true } }, { "Back", { INVTYPE_CLOAK = true } },
    { "Chest", { INVTYPE_CHEST = true, INVTYPE_ROBE = true } }, { "Wrist", { INVTYPE_WRIST = true } },
    { "Hands", { INVTYPE_HAND = true } }, { "Waist", { INVTYPE_WAIST = true } },
    { "Legs", { INVTYPE_LEGS = true } }, { "Feet", { INVTYPE_FEET = true } },
    { "Rings", { INVTYPE_FINGER = true } }, { "Trinkets", { INVTYPE_TRINKET = true } },
    { "Weapon", { INVTYPE_WEAPON = true, INVTYPE_WEAPONMAINHAND = true, INVTYPE_2HWEAPON = true } },
    { "Off hand", { INVTYPE_HOLDABLE = true, INVTYPE_WEAPONOFFHAND = true } },
    { "Wand", { INVTYPE_RANGEDRIGHT = true, INVTYPE_RANGED = true } },
}

-- Every researched item (gear lists + wands), deduped, with where it comes from.
local function candidates()
    local seen, out = {}, {}
    local function add(id, name, source, bracket)
        if not id then return end
        if seen[id] then
            if bracket and not seen[id].bracket then seen[id].bracket = bracket end
            return
        end
        seen[id] = { id = id, name = name, source = source, bracket = bracket }
        table.insert(out, seen[id])
    end
    for bracket, list in pairs(ns.Data.GearBrackets) do
        for _, g in ipairs(list) do add(g.item_id, g.name, g.source, bracket) end
    end
    for _, w in ipairs(ns.Data.Wands) do add(w.item_id, w.name, w.source ~= "" and w.source or "wand list", nil) end
    return out
end

-- Fill in slot, required level and spec score. Returns false if the client
-- hasn't cached the item yet (a refresh follows GET_ITEM_INFO_RECEIVED).
local function evaluate(it, c)
    local _, _, _, equipLoc = C_Item.GetItemInfoInstant(it.id)
    it.equipLoc = equipLoc
    local _, link, _, _, minLevel = C_Item.GetItemInfo(it.id)
    if not link then
        if C_Item.RequestLoadItemDataByID then pcall(C_Item.RequestLoadItemDataByID, it.id) end
        return false
    end
    it.link, it.minLevel = link, minLevel or 1
    local res = ns.Stats.Compare(link, c.spec, c.level, c.profile, ns.db.global.percentScale)
    if not res or res.pending then return false end
    it.res = res
    it.score = res.score or 0
    return true
end

function UI.SetGearView(v) gearView = v end

local function renderSlots(L, c, view)
    local all, pending = candidates(), 0
    local ready = {}
    for _, it in ipairs(all) do
        if evaluate(it, c) then
            if not it.res.unusable then table.insert(ready, it) end
        else
            pending = pending + 1
        end
    end
    local soon = {}
    if view == "mine" then
        L:Text(UI.Hex(UI.C.dim) .. ("Researched gear you can equip at level %d, best first for %s. Right column = vs. what you wear now."):format(c.level, c.spec or "your spec") .. "|r", { size = 11 })
    else
        L:Text(UI.Hex(UI.C.dim) .. "Every researched item ranked for " .. (c.spec or "your spec") .. ", regardless of level. Right column = required level and vs. equipped.|r", { size = 11 })
    end
    if pending > 0 then L:Text(UI.Hex(UI.C.dim) .. pending .. " item(s) still loading from the server; the list fills in by itself.|r", { size = 11 }) end
    local shownAny = false
    for _, group in ipairs(SLOT_GROUPS) do
        local list = {}
        for _, it in ipairs(ready) do
            if group[2][it.equipLoc] then
                if view == "best" or it.minLevel <= c.level then
                    table.insert(list, it)
                elseif it.minLevel <= c.level + 5 then
                    table.insert(soon, it)
                end
            end
        end
        table.sort(list, function(a, b) return a.score > b.score end)
        if #list > 0 then
            shownAny = true
            L:Text(UI.Hex(UI.Accent()) .. group[1] .. "|r", { size = 12 })
            for i, it in ipairs(list) do
                if view == "mine" and i > 4 then break end
                local sub = (it.source or "") .. (it.bracket and (" · " .. it.bracket .. " list") or "") .. " · req. " .. it.minLevel
                local right = upgradeText(it.id, c)
                if view == "best" and it.minLevel > c.level then right = UI.Hex(UI.C.warn) .. "at " .. it.minLevel .. "|r  " .. right end
                if i == 1 and view == "mine" then sub = UI.Hex(UI.C.good) .. "Best for you · |r" .. sub end
                L:Item(it.id, it.name, sub, right, openDetail(it.id))
            end
        end
    end
    if not shownAny and pending == 0 then L:Text("No researched gear fits this view yet.") end
    if view == "mine" and #soon > 0 then
        table.sort(soon, function(a, b) return a.minLevel < b.minLevel end)
        L:Header("Coming up (next 5 levels)")
        for _, it in ipairs(soon) do
            L:Item(it.id, it.name, (it.source or "") .. " · req. " .. it.minLevel, upgradeText(it.id, c), openDetail(it.id))
        end
    end
    L:Flag("The research only has Wowhead's level 20 and 30 gear lists (plus wands). Level 40-60 lists and raid BiS aren't published yet.")
end

----------------------------------------------------------------------------
-- Item detail: comparison + where/how to get it + map pins.
----------------------------------------------------------------------------

-- Research list labels for an item (bracket + source text).
local function researchLabels(id)
    local out = {}
    for bracket, list in pairs(ns.Data.GearBrackets) do
        for _, g in ipairs(list) do
            if g.item_id == id then table.insert(out, { bracket = bracket, source = g.source, rec = g }) end
        end
    end
    for _, w in ipairs(ns.Data.Wands) do
        if w.item_id == id then table.insert(out, { bracket = "wand list", source = w.source, rec = w }) end
    end
    return out
end

local function findDungeon(label)
    if not label then return nil end
    local key = ns.Map.Norm(label)
    key = ns.Map.DUNGEON_ALIASES[key] or key
    for _, d in ipairs(ns.Data.Dungeons) do
        local dn = ns.Map.Norm(d.name)
        if dn == key or dn:find(key, 1, true) or (key:find("scarlet monastery", 1, true) and dn:find("^sm ")) then return d end
    end
    return nil
end

local function renderDetail(L, c, id)
    L:Buttons({ { label = "< Back to the list", onClick = function() detailId = nil UI.Refresh() end } }, 160)
    local name, link, _, _, minLevel = C_Item.GetItemInfo(id)
    local labels = researchLabels(id)
    name = name or (labels[1] and labels[1].rec.name) or ("Item " .. id)
    local _, _, _, equipLoc = C_Item.GetItemInfoInstant(id)
    L:Item(id, name, (SLOT_NAMES[equipLoc] or "") .. (minLevel and (" · requires level " .. minLevel) or ""), upgradeText(id, c))

    -- Comparison (same lines as the tooltip, minus the header).
    if link then
        local lines = ns.Tooltip.LinesFor(link, c.spec, c.profile, c.level, ns.db.global.percentScale)
        for i = 2, #lines do L:Text(lines[i], { size = 12 }) end
    else
        L:Text(UI.Hex(UI.C.dim) .. "Loading item data...|r")
    end

    L:Header("How to get it")
    local src = ns.Data.ItemSources[id]
    local any = false
    local researchLabel = labels[1] and labels[1].source

    for _, d in ipairs(src and src.drops or {}) do
        any = true
        local dungeon = findDungeon(researchLabel)
        local where = dungeon and (" in " .. dungeon.name .. " (levels " .. dungeon.levels .. (dungeon.new_in_forever and ", new in Forever" or "") .. ")") or ""
        L:Row({ icon = "Interface\\Icons\\INV_Misc_Bag_10_Black", title = "Drops from " .. d.npc .. where,
            sub = (d.chance and (d.chance .. " drop chance") or "drop chance unknown") .. " · NPC #" .. d.npc_id })
        if dungeon then
            local e = ns.Map.FindDungeonEntrance(dungeon.name)
            if e then
                L:Text(("Entrance: %s (%s %.1f, %.1f)"):format(e.name, ns.Map.MapName(e.mapID), e.x * 100, e.y * 100), { indent = 10 })
                L:Buttons({
                    { label = "Mark entrance on map", onClick = function() ns.Map.SetWaypoint(e.mapID, e.x, e.y, e.name .. " entrance") end },
                    { label = "Open map", onClick = function() ns.Map.Open(e.mapID) end },
                }, 170)
            else
                L:Text(UI.Hex(UI.C.dim) .. "The game's map data didn't return an entrance for this dungeon, so it can't be pinned.|r", { size = 11, indent = 10 })
            end
            if c.level < (tonumber(dungeon.levels:match("^(%d+)")) or 0) then
                L:Text(UI.Hex(UI.C.warn) .. "You're below this dungeon's level range.|r", { size = 11, indent = 10 })
            end
        end
    end

    local playerFaction = c.faction
    for _, q in ipairs(src and src.quests or {}) do
        any = true
        local qd = ns.Data.QuestSources[q.quest_id] or {}
        local done = ns.Progress.IsQuestDone(q.quest_id)
        local title = (done and (UI.CHECK_ICON .. " ") or "") .. "Quest reward: " .. q.name .. (q.choice and " (choose it as your reward)" or "")
        local parts = {}
        if qd.level then table.insert(parts, "level " .. qd.level) end
        if qd.min_level then table.insert(parts, "from level " .. qd.min_level) end
        local factionOnly = qd.faction and qd.faction ~= "Both" and qd.faction
        if factionOnly then table.insert(parts, factionOnly .. " only") end
        table.insert(parts, "quest #" .. q.quest_id)
        local sub = table.concat(parts, " · ")
        if qd.start_npc then sub = sub .. "\nStarts with " .. qd.start_npc .. (qd.zone and (" in " .. qd.zone) or "") end
        if done then sub = sub .. "\n" .. UI.Hex(UI.C.good) .. "You've already completed this quest.|r" end
        if factionOnly and playerFaction and factionOnly ~= playerFaction then sub = sub .. "\n" .. UI.Hex(UI.C.bad) .. "Not available to " .. playerFaction .. ".|r" end
        L:Row({ icon = "Interface\\GossipFrame\\AvailableQuestIcon", title = title, sub = sub })
        -- One spot per NPC label (the DB lists some NPCs at several spots); quest giver first.
        local pins, seenLabel = {}, {}
        for _, pin in ipairs(qd.pins or {}) do
            if not seenLabel[pin.label] then
                seenLabel[pin.label] = true
                table.insert(pins, pin)
            end
        end
        table.sort(pins, function(a, b)
            local as, bs = a.label:find("^Start") and 0 or 1, b.label:find("^Start") and 0 or 1
            return as < bs
        end)
        local btns = {}
        for _, pin in ipairs(pins) do
            local zone = pin.zone or qd.zone
            local mapID = ns.Map.FindZone(zone)
            L:Text(("%s: %s %.1f, %.1f"):format(pin.label, zone or "?", pin.x, pin.y), { size = 11, indent = 10 })
            if mapID and #btns < 2 then
                local who = pin.label:gsub("^[^:]*:%s*", "")
                table.insert(btns, { label = (pin.label:find("^Start") and "Mark quest giver" or ("Mark " .. who)), onClick = function()
                    ns.Map.SetWaypoint(mapID, pin.x / 100, pin.y / 100, pin.label)
                end })
            elseif not mapID then
                L:Text(UI.Hex(UI.C.dim) .. "Couldn't match zone '" .. tostring(zone) .. "' to a game map.|r", { size = 11, indent = 10 })
            end
        end
        if #btns > 0 then L:Buttons(btns, 150) end
        if not qd.pins and qd.zone then
            L:Text(UI.Hex(UI.C.dim) .. "No coordinates published for this quest yet.|r", { size = 11, indent = 10 })
        end
        if qd.source_url then L:Source(qd) end
    end
    -- Research says "Quest NNNN" but the item DB lists other quest ids: flag it.
    local rq = researchLabel and tonumber(researchLabel:match("Quest (%d+)"))
    if rq and src and src.quests then
        local match = false
        for _, q in ipairs(src.quests) do if q.quest_id == rq then match = true end end
        if not match then L:Flag(("The gear guide lists quest %d; the Icy Veins DB lists the quest(s) above. Same chain, different step?"):format(rq)) end
    end

    if src and src.crafted then
        any = true
        local cr = src.crafted
        local reagents = {}
        for _, r in ipairs(cr.reagents or {}) do table.insert(reagents, r.count .. " " .. r.name) end
        L:Row({ icon = "Interface\\Icons\\Trade_Tailoring", title = "Crafted with " .. cr.profession .. (cr.skill and (" (skill " .. cr.skill .. ")") or ""),
            sub = (#reagents > 0 and ("Reagents: " .. table.concat(reagents, ", ")) or "Reagents not listed") .. "\nMake it yourself or ask a " .. cr.profession:lower() .. " crafter (trade chat / crafting orders)." })
    end
    for _, v in ipairs(src and src.sold_by or {}) do
        any = true
        L:Row({ icon = "Interface\\Icons\\INV_Misc_Coin_02", title = "Sold by " .. v.npc, sub = "NPC #" .. v.npc_id })
    end

    if not any then
        L:Text("Gear guide says: " .. (researchLabel or "?"))
        local dungeon = findDungeon(researchLabel)
        if dungeon then
            local e = ns.Map.FindDungeonEntrance(dungeon.name)
            if e then L:Buttons({ { label = "Mark " .. dungeon.name .. " entrance", onClick = function() ns.Map.SetWaypoint(e.mapID, e.x, e.y, e.name .. " entrance") end } }, 240) end
        end
        L:Flag("The Icy Veins item database (early access) doesn't list a source for this item yet.")
    end
    if src then L:Source(src) end

    L:Header("On the gear lists")
    for _, l in ipairs(labels) do
        L:Text(("%s: %s"):format(l.bracket, l.source ~= "" and l.source or "?"), { size = 11 })
    end
    if labels[1] then L:Source(labels[1].rec) end
end

UI.RegisterPanel({
    key = "gear", label = "Gear", icon = "Interface\\Icons\\INV_Chest_Cloth_17",
    render = function(L, c)
        if detailId then
            renderDetail(L, c, detailId)
            return
        end
        local setName = ns.Stats.WeightSetName(c.spec, c.level, c.profile)
        local prio = ns.Data.StatPriority[setName]
        L:Header("Stat weights: " .. setName, c.spec and ("Used for item tooltips while " .. (c.spec or "") .. " is active.") or "Pick a spec to use spec weights.")
        if prio then
            L:Text(prio.text)
            local weights = ns.Stats.Weights(setName, ns.db.global.percentScale, c.profile.weights)
            local parts = {}
            for _, k in ipairs(prio.keys) do table.insert(parts, ("%s %.2f"):format(ns.Stats.LABELS[k], weights[k])) end
            L:Text(UI.Hex(UI.C.dim) .. "Per-point weights: " .. table.concat(parts, " · ") .. "|r", { size = 11 })
            L:Flag("Weights come from the priority ORDER (rank-based), not from simulations. Hit/crit % use an assumed " .. ns.db.global.percentScale .. " points per 1% (Options).")
            L:Source(prio)
        end
        if c.spec then
            local useLeveling = c.profile.levelingWeights
            if useLeveling == nil then useLeveling = (c.spec == "Shadow") end
            L:Check("Use leveling weights below 60", useLeveling, function(v)
                c.profile.levelingWeights = v
                ns.Stats.ClearCache()
                UI.Refresh()
            end, "Leveling priority (Icy Veins): Spell power > Crit > Hit > Intellect > Spirit > Stamina > MP5")
        end

        L:Header("Gear", "Researched items scored with your spec's weights. Click any item for where and how to get it.")
        gearView = gearView or "mine"
        L:Buttons({
            { label = "For my level", active = gearView == "mine", onClick = function() gearView = "mine" UI.Refresh() end },
            { label = "Best overall", active = gearView == "best", onClick = function() gearView = "best" UI.Refresh() end },
            { label = "By bracket", active = gearView == "bracket", onClick = function() gearView = "bracket" UI.Refresh() end },
        }, 130)
        if gearView ~= "bracket" then
            renderSlots(L, c, gearView)
            return
        end
        L:Text(UI.Hex(UI.C.dim) .. "From Wowhead's Forever Priest level 20/30 guides. Right column = vs. what you wear now.|r", { size = 11 })
        local order = ns.Data.GearBracketOrder
        bracketSel = bracketSel or (c.level >= 25 and "level 30" or "level 20")
        local items = {}
        for _, b in ipairs(order) do
            local has = ns.Data.GearBrackets[b] ~= nil or (b == "raid BiS")
            table.insert(items, { label = b:gsub("^level ", "Lvl "), active = bracketSel == b, onClick = function() bracketSel = b UI.Refresh() end,
                tip = has and nil or "Not published yet" })
        end
        L:Buttons(items)
        local list = ns.Data.GearBrackets[bracketSel]
        if bracketSel == "raid BiS" then
            local bis = ns.Data.BiS
            L:Flag(bis.status)
            L:Text("Raids open " .. (ns.Data.Raids[1] and ns.Data.Raids[1].opens or "?") .. ". Raid rule: item stats are hidden until first looted.")
            L:Header("Tier 1 set bonuses (datamined placeholder)")
            L:Flag(bis.flag)
            for role, bonuses in pairs(bis.tier1_datamined_placeholder or {}) do
                local lines = {}
                for pieces = 2, 8 do
                    local b = bonuses[tostring(pieces)] or bonuses[pieces]
                    if b then table.insert(lines, ("(%d) %s"):format(pieces, b)) end
                end
                L:Row({ title = role == "healer" and "Healer set" or "Shadow set", sub = table.concat(lines, "\n") })
            end
            L:Source(bis)
        elseif not list then
            L:Flag("Not published yet. Wowhead only has level 20 and 30 Priest gear pages so far; this bracket fills in automatically when research/data.json gains it (tools/build_data.py).")
        else
            local bySource = {}
            local sourcesOrder = {}
            for _, g in ipairs(list) do
                local src = g.source or "?"
                if not bySource[src] then bySource[src] = {} table.insert(sourcesOrder, src) end
                table.insert(bySource[src], g)
            end
            for _, src in ipairs(sourcesOrder) do
                L:Text(UI.Hex(UI.Accent()) .. src .. "|r", { size = 12 })
                for _, g in ipairs(bySource[src]) do
                    local _, _, _, equipLoc = C_Item.GetItemInfoInstant(g.item_id)
                    L:Item(g.item_id, g.name, SLOT_NAMES[equipLoc] or "", upgradeText(g.item_id, c), openDetail(g.item_id))
                end
            end
            L:Source(list[1])
        end

        L:Header("Wands", "Mana-free damage while leveling. Wands don't scale with spell damage in Forever.")
        local wands = {}
        for _, w in ipairs(ns.Data.Wands) do table.insert(wands, w) end
        table.sort(wands, function(a, b) return (a.dps or 0) > (b.dps or 0) end)
        for _, w in ipairs(wands) do
            L:Item(w.item_id, w.name, (w.source ~= "" and w.source or "") .. (w.required_level and (" · req. " .. w.required_level) or ""), w.dps and ("%.1f DPS"):format(w.dps) or "DPS ?", openDetail(w.item_id))
        end
        L:Text(UI.Hex(UI.C.dim) .. ns.Data.OtherWeapons.note .. "|r", { size = 11 })

        L:Header("Consumables & enchants")
        for _, e in ipairs(ns.Data.Consumables) do
            if e.type == "enchant" then
                L:Spell(e.spell_id, e.slot .. ": " .. e.name)
            elseif e.type == "camp" then
                L:Item(e.item_id, e.name, "Camp item · " .. (e.profession ~= "" and e.profession or "any") .. ((e.notes and e.notes ~= "") and (" · " .. e.notes) or ""))
            elseif e.type == "note" then
                L:Text(UI.Hex(UI.C.dim) .. e.name .. ": " .. e.notes .. "|r", { size = 11 })
            end
        end
    end,
})
