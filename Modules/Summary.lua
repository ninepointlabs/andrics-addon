-- Post-fight summary: what you cast and mana tips.
-- Uses UNIT_SPELLCAST_SUCCEEDED for the player only (no combat log). If the
-- client hides spell ids as secret values in combat, those casts are counted as
-- "hidden" and the summary says so instead of guessing.
local _, ns = ...

local Summary = {}
ns.Summary = Summary

local fight

function Summary.Start(now, manaPct)
    fight = { start = now, manaStart = manaPct, casts = {}, order = {}, hidden = 0 }
end

function Summary.OnCast(spellID, name)
    if not fight then return end
    if spellID == nil or ns.Auras.IsSecret(spellID) then
        fight.hidden = fight.hidden + 1
        return
    end
    name = name or ns.Auras.SpellName(spellID) or tostring(spellID)
    if spellID == ns.Rotation.SHOOT_ID then name = "Wand" end
    if not fight.casts[name] then
        fight.casts[name] = 0
        table.insert(fight.order, name)
    end
    fight.casts[name] = fight.casts[name] + 1
end

-- Rule-based tips. Each tip references a mechanic in content/learn.json.
function Summary.Tips(f, spec, context)
    local tips = {}
    local dur = f.duration or 0
    local used = f.manaStart and f.manaEnd and (f.manaStart - f.manaEnd) or nil
    local c = f.casts
    local function n(name) return c[name] or 0 end
    if spec == "Shadow" and dur >= 10 and n("Shadow Word: Pain") == 0 and ns.Progress.KnowsSpell(589) then
        table.insert(tips, "No Shadow Word: Pain this fight. Put it up early: it ticks while you cast other spells.")
    end
    if spec == "Shadow" and dur >= 15 and n("Mind Flay") == 0 and ns.Progress.KnowsSpell(15407) then
        table.insert(tips, "No Mind Flay. It's your main filler once Mind Blast and DoTs are rolling.")
    end
    if f.manaEnd and f.manaEnd < 20 then
        if context == "solo" and n("Wand") == 0 then
            table.insert(tips, "Mana ended under 20% and you never used your wand. Finish mobs with the wand so Spirit regen can kick in (five-second rule).")
        else
            table.insert(tips, "Mana ended under 20%. Lower spell ranks cost less; a short drink between pulls saves a wipe.")
        end
    end
    if ns.IsHealer(spec) and n("Flash Heal") >= 5 and n("Flash Heal") > n("Heal") + n("Greater Heal") + n("Lesser Heal") then
        table.insert(tips, "Mostly Flash Heal. It's fast but mana-hungry: use Heal / Greater Heal (or lower ranks) when the damage isn't urgent.")
    end
    if spec == "Discipline" and dur >= 10 and n("Penance") == 0 and ns.Progress.KnowsSpell(ns.Rotation.SpellId("Penance")) then
        table.insert(tips, "Penance wasn't used. It's Discipline's signature heal/damage on a short cooldown.")
    end
    if used and used > 0 and dur > 0 and #tips == 0 then
        table.insert(tips, ("Mana used: %.0f%% over %ds. Nice and tidy."):format(used, dur))
    end
    if f.hidden > 0 then
        table.insert(tips, ("%d cast(s) were hidden by the client's addon restrictions and aren't counted."):format(f.hidden))
    end
    return tips
end

function Summary.Finish(now, manaPct)
    if not fight then return nil end
    local f = fight
    fight = nil
    f.duration = math.floor((now - f.start) + 0.5)
    f.manaEnd = manaPct
    local total = 0
    for _, v in pairs(f.casts) do total = total + v end
    if f.duration < 4 or (total == 0 and f.hidden == 0) then return nil end
    local spec = ns.DB.ActiveSpec()
    f.tips = Summary.Tips(f, spec, ns.DB.Profile().rotationContext)
    Summary.last = f
    return f
end

function Summary.Text(f)
    local parts = {}
    table.sort(f.order, function(a, b) return f.casts[a] > f.casts[b] end)
    for _, name in ipairs(f.order) do table.insert(parts, name .. " x" .. f.casts[name]) end
    return table.concat(parts, ", ")
end
