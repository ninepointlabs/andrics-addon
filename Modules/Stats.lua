-- Item stat parsing, spec weights and upgrade comparison.
--
-- Stats come from the item's tooltip text (Forever items use Classic-style
-- "Equip: Increases damage and healing done by magical spells..." lines, which
-- C_Item.GetItemStats does not report reliably). enUS client text only.
--
-- Weights are DERIVED, not simulated: the research gives each spec an ordered
-- stat priority (Data/Gear.lua -> StatPriority). Rank r of n gets weight
-- (n - r + 1) / n. Percent stats (hit/crit) are multiplied by
-- AndricsAddonDB.percentScale (default 10 points per 1%), which is an addon
-- assumption and is flagged as such wherever a score is shown. Users can
-- override any weight per profile.
local _, ns = ...

local Stats = {}
ns.Stats = Stats

Stats.DEFAULT_PERCENT_SCALE = 10
Stats.PERCENT_KEYS = { SPELL_HIT = true, SPELL_CRIT = true }

Stats.LABELS = {
    DAMAGE = "Spell/Shadow damage", HEALING = "Healing power", SPELL_DAMAGE = "Spell damage",
    SPELL_HIT = "Spell hit %", SPELL_CRIT = "Spell crit %", INT = "Intellect",
    SPI = "Spirit", STA = "Stamina", MP5 = "Mana per 5",
}

-- Lower-cased patterns -> raw keys. Order matters: first match wins per line.
Stats.PATTERNS = {
    { "^%+(%d+) intellect$", "INT" },
    { "^%+(%d+) spirit$", "SPI" },
    { "^%+(%d+) stamina$", "STA" },
    { "^equip: increases damage and healing done by magical spells and effects by up to (%d+)%.?$", "SPELL_POWER" },
    { "^%+(%d+) damage and healing spells$", "SPELL_POWER" },
    { "^%+(%d+) spell damage and healing$", "SPELL_POWER" },
    { "^equip: increases healing done by up to (%d+) and damage done by up to (%d+) for all magical spells and effects%.?$", "HEALING", "HEALING_DMG" },
    { "^equip: increases healing done by spells and effects by up to (%d+)%.?$", "HEALING" },
    { "^equip: increases healing done by up to (%d+)%.?$", "HEALING" },
    { "^%+(%d+) healing spells$", "HEALING" },
    { "^%+(%d+) healing$", "HEALING" },
    { "^equip: increases damage done by magical spells and effects by up to (%d+)%.?$", "SPELL_DAMAGE" },
    { "^%+(%d+) spell damage$", "SPELL_DAMAGE" },
    { "^equip: increases damage done by shadow spells and effects by up to (%d+)%.?$", "SHADOW_DAMAGE" },
    { "^%+(%d+) shadow spell damage$", "SHADOW_DAMAGE" },
    { "^%+(%d+) shadow damage$", "SHADOW_DAMAGE" },
    { "^equip: increases the damage done by holy spells and effects by up to (%d+)%.?$", "HOLY_DAMAGE" },
    { "^equip: increases damage done by holy spells and effects by up to (%d+)%.?$", "HOLY_DAMAGE" },
    { "^equip: improves your chance to get a critical strike with spells by (%d+)%%%.?$", "SPELL_CRIT" },
    { "^equip: improves your chance to hit with spells by (%d+)%%%.?$", "SPELL_HIT" },
    { "^equip: restores (%d+) mana per 5 sec%.?$", "MP5" },
    { "^%+?(%d+) mana every 5 sec%.?$", "MP5" },
    { "^%+?(%d+) mana per 5 sec%.?$", "MP5" },
    { "^%+?(%d+) mana every 5 seconds$", "MP5" },
    { "^%(([%d%.]+) damage per second%)$", "WAND_DPS" },
}

local function clean(text)
    text = text:gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", "")
    return strtrim and strtrim(text):lower() or (text:match("^%s*(.-)%s*$")):lower()
end

-- lines: array of strings. Returns raw stat table.
function Stats.ParseLines(lines)
    local raw = {}
    for _, line in ipairs(lines) do
        if type(line) == "string" and line ~= "" then
            local text = clean(line)
            -- Set bonuses only apply with the set; "Use:" effects are not passive stats.
            if not text:find("^%(%d%) set:") and not text:find("^set:") and not text:find("^use:") then
                for _, p in ipairs(Stats.PATTERNS) do
                    local a, b = text:match(p[1])
                    if a then
                        raw[p[2]] = (raw[p[2]] or 0) + tonumber(a)
                        if p[3] and b then raw[p[3]] = (raw[p[3]] or 0) + tonumber(b) end
                        break
                    end
                end
            end
        end
    end
    return raw
end

-- Combine raw tooltip stats into the keys the research priorities use.
-- Forever: "healing power also grants 1/3 as damage" (Wowhead stat-priority);
-- applied only when the item does not state its damage portion explicitly.
function Stats.Derive(raw)
    local heal = raw.HEALING or 0
    local healAsDamage = raw.HEALING_DMG or (heal / 3)
    return {
        DAMAGE = (raw.SPELL_POWER or 0) + (raw.SPELL_DAMAGE or 0) + (raw.SHADOW_DAMAGE or 0) + healAsDamage,
        HEALING = (raw.SPELL_POWER or 0) + heal,
        SPELL_DAMAGE = (raw.SPELL_DAMAGE or 0) + (raw.HOLY_DAMAGE or 0),
        SPELL_HIT = raw.SPELL_HIT or 0,
        SPELL_CRIT = raw.SPELL_CRIT or 0,
        INT = raw.INT or 0,
        SPI = raw.SPI or 0,
        STA = raw.STA or 0,
        MP5 = raw.MP5 or 0,
    }
end

-- Which research priority applies to a profile right now.
function Stats.WeightSetName(spec, level, profile)
    if not spec then return "Leveling" end
    local useLeveling = profile and profile.levelingWeights
    if useLeveling == nil then useLeveling = (spec == "Shadow") end
    local maxLevel = (ns.Data.Meta and ns.Data.Meta.max_level) or 60
    if useLeveling and level and level < maxLevel then return "Leveling" end
    return ns.Specs[spec].weights
end

function Stats.Weights(setName, percentScale, overrides)
    local prio = ns.Data.StatPriority[setName]
    local weights = {}
    if not prio then return weights end
    local n = #prio.keys
    for r, key in ipairs(prio.keys) do
        local w = (n - r + 1) / n
        if Stats.PERCENT_KEYS[key] then w = w * (percentScale or Stats.DEFAULT_PERCENT_SCALE) end
        weights[key] = w
    end
    if overrides then
        for k, v in pairs(overrides) do
            if type(v) == "number" then weights[k] = v end
        end
    end
    return weights
end

function Stats.Score(derived, weights)
    local s = 0
    for k, w in pairs(weights) do s = s + (derived[k] or 0) * w end
    return s
end

-- Equip location -> inventory slot ids.
Stats.SLOTS = {
    INVTYPE_HEAD = { 1 }, INVTYPE_NECK = { 2 }, INVTYPE_SHOULDER = { 3 },
    INVTYPE_CHEST = { 5 }, INVTYPE_ROBE = { 5 }, INVTYPE_WAIST = { 6 }, INVTYPE_LEGS = { 7 },
    INVTYPE_FEET = { 8 }, INVTYPE_WRIST = { 9 }, INVTYPE_HAND = { 10 }, INVTYPE_FINGER = { 11, 12 },
    INVTYPE_TRINKET = { 13, 14 }, INVTYPE_CLOAK = { 15 }, INVTYPE_WEAPON = { 16 },
    INVTYPE_WEAPONMAINHAND = { 16 }, INVTYPE_2HWEAPON = { 16 }, INVTYPE_WEAPONOFFHAND = { 17 },
    INVTYPE_HOLDABLE = { 17 }, INVTYPE_SHIELD = { 17 }, INVTYPE_RANGED = { 18 },
    INVTYPE_RANGEDRIGHT = { 18 }, INVTYPE_THROWN = { 18 },
}

-- Priests: cloth armor (plus misc: neck/rings/trinkets/held), staves, 1h maces, daggers, wands.
local ARMOR, WEAPON = 4, 2
local PRIEST_ARMOR = { [0] = true, [1] = true }
local PRIEST_WEAPON = { [4] = true, [10] = true, [15] = true, [19] = true }
Stats.WAND_SUBCLASS = 19

function Stats.PriestCanUse(classID, subclassID, equipLoc)
    if equipLoc == "INVTYPE_CLOAK" then return true end
    if classID == ARMOR then return PRIEST_ARMOR[subclassID] == true end
    if classID == WEAPON then return PRIEST_WEAPON[subclassID] == true end
    return false
end

-- Tooltip line provider; replaced in tests.
function Stats.LinesForLink(link)
    if C_TooltipInfo and C_TooltipInfo.GetHyperlink then
        local ok, data = pcall(C_TooltipInfo.GetHyperlink, link)
        if ok and data and data.lines then
            local lines = {}
            for i, line in ipairs(data.lines) do lines[i] = line.leftText or "" end
            return lines
        end
    end
    return nil
end

local cache = {}
function Stats.RawForLink(link)
    if not link then return nil end
    if cache[link] then return cache[link] end
    local lines = Stats.LinesForLink(link)
    if not lines or #lines < 2 then return nil end -- item not cached yet
    local raw = Stats.ParseLines(lines)
    cache[link] = raw
    return raw
end

function Stats.ClearCache() cache = {} end

-- Compare an item link against what is equipped. Returns a result table or nil.
-- equippedLink(slot) is injectable for tests.
function Stats.Compare(link, spec, level, profile, percentScale, itemInfo, equippedLink)
    itemInfo = itemInfo or function(l)
        local _, _, _, equipLoc, _, classID, subclassID = C_Item.GetItemInfoInstant(l)
        return equipLoc, classID, subclassID
    end
    equippedLink = equippedLink or function(slot) return GetInventoryItemLink("player", slot) end

    local equipLoc, classID, subclassID = itemInfo(link)
    local slots = equipLoc and Stats.SLOTS[equipLoc]
    if not slots then return nil end
    local result = { equipLoc = equipLoc }
    if not Stats.PriestCanUse(classID, subclassID, equipLoc) then
        result.unusable = true
        return result
    end
    local raw = Stats.RawForLink(link)
    if not raw then result.pending = true return result end

    local setName = Stats.WeightSetName(spec, level, profile)
    local weights = Stats.Weights(setName, percentScale, profile and profile.weights)
    local new = Stats.Derive(raw)
    result.setName, result.weights, result.derived = setName, weights, new
    result.score = Stats.Score(new, weights)
    result.isWand = (classID == WEAPON and subclassID == Stats.WAND_SUBCLASS)
    result.wandDps = raw.WAND_DPS

    -- Pick the equipped item this would replace (weakest of a ring/trinket pair).
    local best
    for _, slot in ipairs(slots) do
        local eqLink = equippedLink(slot)
        if eqLink == link then result.isEquipped = true return result end
        local eqRaw = eqLink and Stats.RawForLink(eqLink)
        local eqScore, eqDerived = 0, Stats.Derive(eqRaw or {})
        if eqRaw then eqScore = Stats.Score(eqDerived, weights) end
        -- A two-hander replaces main hand + off hand.
        if equipLoc == "INVTYPE_2HWEAPON" and slot == 16 then
            local ohLink = equippedLink(17)
            local ohRaw = ohLink and Stats.RawForLink(ohLink)
            if ohRaw then
                local ohDerived = Stats.Derive(ohRaw)
                eqScore = eqScore + Stats.Score(ohDerived, weights)
                for k, v in pairs(ohDerived) do eqDerived[k] = (eqDerived[k] or 0) + v end
            end
        end
        local cand = { slot = slot, link = eqLink, score = eqScore, derived = eqDerived, raw = eqRaw, empty = eqLink == nil }
        if not best or cand.score < best.score then best = cand end
    end
    result.against = best
    result.delta = result.score - best.score
    if best.score > 0 then result.pct = result.delta / best.score * 100 end
    if result.isWand and best.raw then result.wandDelta = (raw.WAND_DPS or 0) - (best.raw.WAND_DPS or 0) end
    result.statDelta = {}
    for k in pairs(weights) do
        local d = (new[k] or 0) - (best.derived[k] or 0)
        if math.abs(d) > 0.001 then result.statDelta[k] = d end
    end
    return result
end
