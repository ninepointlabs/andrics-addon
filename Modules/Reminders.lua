-- Out-of-combat reminders: buffs, wand, candles, consumables.
local _, ns = ...

local Reminders = {}
ns.Reminders = Reminders

local IDS = {
    fortitude = 1243, innerFire = 588, shadowform = 15473,
    prayerOfFortitude = 21562, prayerOfFortitude2 = 21564, prayerOfSpirit = 27681, prayerOfShadowProt = 27683,
}
Reminders.IDS = IDS

local function itemCount(id)
    if C_Item and C_Item.GetItemCount then
        local ok, n = pcall(C_Item.GetItemCount, id)
        if ok then return n or 0 end
    end
    return 0
end
Reminders.ItemCount = itemCount

local function reagent(name)
    for _, r in ipairs(ns.Data.Reagents) do
        if r.name == name then return r end
    end
end

local function wandEquipped()
    local link = GetInventoryItemLink("player", 18)
    if not link then return false end
    local _, _, _, _, _, classID, subclassID = C_Item.GetItemInfoInstant(link)
    return classID == 2 and subclassID == ns.Stats.WAND_SUBCLASS
end

-- Returns { {id, label, ok, detail, icon, applies} ... } for the active spec.
function Reminders.Evaluate()
    local cfg = ns.db.char.reminders
    local spec = ns.DB.ActiveSpec()
    local K = ns.Progress.KnowsSpell
    local out = {}
    local function add(id, enabled, applies, label, ok, detail, icon)
        if enabled and applies then
            table.insert(out, { id = id, label = label, ok = ok, detail = detail, icon = icon })
        end
    end

    local fortName = ns.Auras.SpellName(IDS.fortitude) or "Power Word: Fortitude"
    local has = ns.Auras.PlayerHas(fortName)
    if has == false then
        -- Prayer of Fortitude also counts.
        local pof = ns.Auras.SpellName(IDS.prayerOfFortitude)
        if pof and ns.Auras.PlayerHas(pof) then has = true end
    end
    add("fortitude", cfg.fortitude, K(IDS.fortitude), fortName, has ~= false, has == nil and "can't read auras right now" or nil,
        "Interface\\Icons\\Spell_Holy_WordFortitude")

    local ifName = ns.Auras.SpellName(IDS.innerFire) or "Inner Fire"
    has = ns.Auras.PlayerHas(ifName)
    add("innerFire", cfg.innerFire, K(IDS.innerFire), ifName, has ~= false, nil, "Interface\\Icons\\Spell_Holy_InnerFire")

    local sfName = ns.Auras.SpellName(IDS.shadowform) or "Shadowform"
    has = ns.Auras.PlayerHas(sfName)
    add("shadowform", cfg.shadowform, spec == "Shadow" and K(IDS.shadowform), sfName, has ~= false,
        "Shadow spells cost 50% less in Shadowform (Forever).", "Interface\\Icons\\Spell_Shadow_Shadowform")

    add("wand", cfg.wand, UnitLevel("player") >= 5, "Wand equipped", wandEquipped(),
        "Wands are your mana-free damage. They no longer scale with spell damage (Sep 24).", "Interface\\Icons\\INV_Wand_07")

    local knowsPoF1, knowsPoF2 = K(IDS.prayerOfFortitude), K(IDS.prayerOfFortitude2)
    local knowsSacred = knowsPoF2 or K(IDS.prayerOfSpirit) or K(IDS.prayerOfShadowProt)
    if knowsPoF1 and not knowsPoF2 then
        local r = reagent("Holy Candle")
        local n = itemCount(r.item_id)
        add("candles", cfg.candles, true, "Holy Candles", n >= cfg.candleMin, ("%d in bags (want %d+)"):format(n, cfg.candleMin),
            "Interface\\Icons\\INV_Misc_Candle_03")
    end
    if knowsSacred then
        local r = reagent("Sacred Candle")
        local n = itemCount(r.item_id)
        add("candles", cfg.candles, true, "Sacred Candles", n >= cfg.candleMin, ("%d in bags (want %d+)"):format(n, cfg.candleMin),
            "Interface\\Icons\\INV_Misc_Candle_02")
    end
    return out
end

-- Consumables recommended for the player's bracket (research: level 30 list only).
function Reminders.Consumables(level)
    local out = {}
    for _, c in ipairs(ns.Data.Consumables) do
        if c.type == "consumable" then
            local lvl = tonumber((c.bracket or ""):match("(%d+)"))
            table.insert(out, { item = c, count = c.item_id and itemCount(c.item_id) or 0, current = lvl and level >= lvl - 8 and level <= lvl + 9 })
        end
    end
    return out
end

function Reminders.Missing()
    if not ns.db.char.reminders.enabled or InCombatLockdown() then return {} end
    local miss = {}
    for _, r in ipairs(Reminders.Evaluate()) do
        if not r.ok then table.insert(miss, r) end
    end
    return miss
end
