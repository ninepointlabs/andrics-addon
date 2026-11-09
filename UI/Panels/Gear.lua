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

UI.RegisterPanel({
    key = "gear", label = "Gear", icon = "Interface\\Icons\\INV_Chest_Cloth_17",
    render = function(L, c)
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

        L:Header("Recommended gear by bracket", "From Wowhead's Forever Priest level 20/30 guides. Right column = vs. what you wear now.")
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
                    L:Item(g.item_id, g.name, SLOT_NAMES[equipLoc] or "", upgradeText(g.item_id, c))
                end
            end
            L:Source(list[1])
        end

        L:Header("Wands", "Mana-free damage while leveling. Wands don't scale with spell damage in Forever.")
        local wands = {}
        for _, w in ipairs(ns.Data.Wands) do table.insert(wands, w) end
        table.sort(wands, function(a, b) return (a.dps or 0) > (b.dps or 0) end)
        for _, w in ipairs(wands) do
            L:Item(w.item_id, w.name, (w.source ~= "" and w.source or "") .. (w.required_level and (" · req. " .. w.required_level) or ""), w.dps and ("%.1f DPS"):format(w.dps) or "DPS ?")
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
