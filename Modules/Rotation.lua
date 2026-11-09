-- Rotation helper: priority lists per spec/context from content/learn.json and a
-- next-spell suggestion for damage contexts. Advice only: nothing here casts,
-- targets or presses anything (Blizzard forbids automation; we only read state).
local _, ns = ...

local Rotation = {}
ns.Rotation = Rotation

Rotation.CONTEXTS = { "solo", "dungeon", "raid" }
Rotation.CONTEXT_LABELS = { solo = "Solo leveling", dungeon = "Dungeon", raid = "Raid" }
Rotation.WAND = "Wand"
Rotation.SHOOT_ID = 5019 -- "Shoot" (wand auto-attack), long-standing Blizzard spell ID

-- name -> spell id, built from research (base spell ids; talents; racials).
local idByName
function Rotation.SpellId(name)
    if not idByName then
        idByName = {}
        for _, s in ipairs(ns.Data.Spells) do
            idByName[s.name] = s.wowhead_base_spell_id
            idByName[s.display] = s.wowhead_base_spell_id
        end
        for _, t in ipairs(ns.Data.TalentSpells) do
            local clean = t.name:gsub("%s*%(.-%)%s*$", "")
            -- Conflicting ids (Penance, Prayer of Mending): keep the first (Wowhead) one; flagged in Sources.
            if not idByName[clean] then idByName[clean] = t.spell_id end
        end
        for _, r in ipairs(ns.Data.Racials) do
            idByName[r.spell] = idByName[r.spell] or r.wowhead_spell_id
        end
    end
    return idByName[name]
end

function Rotation.Context(spec, context)
    local learn = ns.Data.Learn
    local bySpec = learn and learn.rotation and learn.rotation[spec]
    return bySpec and bySpec[context]
end

-- Spell icon (texture id/path) or a question mark.
function Rotation.Icon(name)
    if name == Rotation.WAND then return "Interface\\Icons\\INV_Wand_07" end
    local id = Rotation.SpellId(name)
    if id and C_Spell and C_Spell.GetSpellTexture then
        local ok, tex = pcall(C_Spell.GetSpellTexture, id)
        if ok and tex then return tex end
    end
    return "Interface\\Icons\\INV_Misc_QuestionMark"
end

-- Is this step's spell usable by the player at all?
function Rotation.Known(name)
    if name == Rotation.WAND then
        local link = GetInventoryItemLink("player", 18)
        return link ~= nil
    end
    local id = Rotation.SpellId(name)
    if not id then return false end
    return ns.Progress.KnowsSpell(id)
end

-- Evaluate one condition. state: table of readers (injectable for tests).
-- Returns true/false, or nil when the client won't tell us (secret/unknown).
function Rotation.Check(step, state)
    local when = step.when or "always"
    local name = step.spell
    if when == "always" then return true end
    if when == "out_of_combat" then return not state.inCombat() end
    if when == "buff_missing" then
        local has = state.playerBuff(state.spellName(name))
        if has == nil then return nil end
        return has == false
    end
    if when == "debuff_missing" then
        if not state.hasTarget() then return false end
        local has = state.targetDebuff(state.spellName(name))
        if has == nil then return nil end
        return has == false
    end
    if when == "ready" then
        local left = state.cooldown(name)
        if left == nil then return nil end
        return left <= 0.1
    end
    if when == "no_weakened_soul" then
        local has = state.playerDebuff(state.spellName("Weakened Soul") or "Weakened Soul")
        if has == nil then return nil end
        return has == false
    end
    local kind, num = when:match("^([%w_]+):(.+)$")
    num = tonumber(num) or num
    if kind == "mana_above" or kind == "mana_below" then
        local pct = state.manaPct()
        if pct == nil then return nil end
        if kind == "mana_above" then return pct > num else return pct < num end
    end
    if kind == "target_hp_below" then
        local pct = state.targetHpPct()
        if pct == nil then return nil end
        return pct < num
    end
    if kind == "proc" then
        local has = state.playerBuff(num)
        if has == nil then return nil end
        return has ~= false
    end
    return nil
end

-- Live readers backed by Modules/Auras.lua.
Rotation.LiveState = {
    inCombat = function() return UnitAffectingCombat("player") end,
    hasTarget = function() return UnitExists("target") and UnitCanAttack("player", "target") and not UnitIsDead("target") end,
    spellName = function(name)
        local id = Rotation.SpellId(name)
        return (id and ns.Auras.SpellName(id)) or name
    end,
    playerBuff = function(n) return ns.Auras.Find("player", n, "HELPFUL") end,
    playerDebuff = function(n) return ns.Auras.Find("player", n, "HARMFUL") end,
    targetDebuff = function(n) return ns.Auras.TargetHasMine(n) end,
    cooldown = function(name)
        if name == Rotation.WAND then return 0 end
        local id = Rotation.SpellId(name)
        return ns.Auras.CooldownLeft(id or name)
    end,
    manaPct = function() return ns.Auras.PowerPct("player") end,
    targetHpPct = function() return ns.Auras.HealthPct("target") end,
    known = function(name) return Rotation.Known(name) end,
}

-- Steps that are "ready" conditions on any step also feed the cooldown bar.
function Rotation.Cooldowns(ctx)
    local seen, out = {}, {}
    for _, step in ipairs(ctx and ctx.priority or {}) do
        if step.when == "ready" and not seen[step.spell] then
            seen[step.spell] = true
            table.insert(out, step.spell)
        end
    end
    return out
end

-- Returns suggestion list (up to `max` steps whose conditions currently pass),
-- plus a flag when some conditions could not be read.
function Rotation.Suggest(spec, context, state, max)
    state = state or Rotation.LiveState
    local ctx = Rotation.Context(spec, context)
    if not ctx then return {}, false, nil end
    local out, blocked = {}, false
    for _, step in ipairs(ctx.priority or {}) do
        if state.known(step.spell) then
            local ok = Rotation.Check(step, state)
            if ok == nil then blocked = true end
            if ok then
                table.insert(out, step)
                if #out >= (max or 3) then break end
            end
        end
    end
    return out, blocked, ctx
end
