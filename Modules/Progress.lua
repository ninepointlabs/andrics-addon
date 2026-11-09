-- Class quests, riding/gold goals and milestones.
local _, ns = ...

local Progress = {}
ns.Progress = Progress

Progress.RACE_NAMES = {
    Human = "Human", Dwarf = "Dwarf", Gnome = "Gnome", NightElf = "Night Elf",
    Scourge = "Undead", Undead = "Undead", Troll = "Troll",
}

function Progress.PlayerRace()
    local _, english = UnitRace("player")
    return Progress.RACE_NAMES[english] or english
end

local function raceMatches(field, race)
    if not field or not race then return false end
    for part in field:gmatch("[^/]+") do
        if part == race then return true end
    end
    return false
end
Progress.RaceMatches = raceMatches

function Progress.IsQuestDone(id)
    if not id then return nil end
    if C_QuestLog and C_QuestLog.IsQuestFlaggedCompleted then
        local ok, done = pcall(C_QuestLog.IsQuestFlaggedCompleted, id)
        if ok then return done end
    end
    return nil
end

-- Class quests relevant to a race (all races if race is nil). Adds the missing
-- Night Elf level-20 Elune's Grace quest as a flagged placeholder (research gap:
-- quest ID not captured), never as an invented ID.
function Progress.ClassQuests(race, faction)
    local out = {}
    for _, q in ipairs(ns.Data.Quests) do
        local ok = (race == nil) or raceMatches(q.races, race)
        if q.type == "reagent" then ok = (faction == nil or q.faction == faction) end
        if ok then table.insert(out, q) end
    end
    for _, r in ipairs(ns.Data.Racials) do
        if r.quest_id == nil and (race == nil or r.race == race) then
            table.insert(out, {
                type = "class-racial", level = r.level, races = r.race, name = r.spell .. " (quest)",
                reward_spell = r.spell, quest_id = nil, missing = true, source_url = r.source_url, checked = r.checked,
            })
        end
    end
    table.sort(out, function(a, b)
        if a.level ~= b.level then return a.level < b.level end
        return a.name < b.name
    end)
    return out
end

-- The next class quest at or above level-ish that isn't completed.
function Progress.NextClassQuest(race, faction, level)
    for _, q in ipairs(Progress.ClassQuests(race, faction)) do
        if q.missing or not Progress.IsQuestDone(q.quest_id) then
            if q.level >= (level or 1) - 10 then return q end
        end
    end
    return nil
end

-- Gold goals. Values come from research riding data (training cost text "100g").
local function goldFromText(text)
    local g = text and tonumber(tostring(text):match("(%d+)g"))
    return g
end

function Progress.GoldGoals()
    local goals = {}
    for _, r in ipairs(ns.Data.Riding) do
        local cost = goldFromText(r.training)
        if cost and r.level then
            table.insert(goals, {
                name = r.skill, level = r.level, gold = cost, speed = r.speed,
                mount = r.mount_cost, spell_id = r.spell_id, source_url = r.source_url, checked = r.checked,
            })
        end
    end
    table.sort(goals, function(a, b) return a.level < b.level end)
    return goals
end

function Progress.RidingNotes()
    for _, r in ipairs(ns.Data.Riding) do
        if r.notes then return r end
    end
end

function Progress.MountForRace(race)
    for _, m in ipairs(ns.Data.Mounts) do
        if m.race == race then return m end
    end
end

function Progress.KnowsSpell(id)
    if not id then return false end
    if IsPlayerSpell then
        local ok, known = pcall(IsPlayerSpell, id)
        if ok and known then return true end
    end
    if IsSpellKnown then
        local ok, known = pcall(IsSpellKnown, id)
        if ok and known then return true end
    end
    return false
end

-- Next unmet gold goal (skipping skills already learned).
function Progress.NextGoldGoal(level)
    for _, g in ipairs(Progress.GoldGoals()) do
        if not Progress.KnowsSpell(g.spell_id) then return g end
    end
end

function Progress.NextMilestone(level)
    for _, m in ipairs(ns.Data.Milestones.items) do
        if m.level > level then return m end
    end
end

-- Blizzard's Priest deep dive says Dual Specialization unlocks at 40; it was not
-- seen in the client when this addon was written. Flag rather than assert.
function Progress.MilestoneFlag(m)
    if m and m.what and m.what:find("Dual Spec") then
        return "Blizzard's pre-launch deep dive says Dual Specialization unlocks at 40; not verified in the live client yet."
    end
end

function Progress.MoneyText(copper)
    copper = copper or 0
    local g = math.floor(copper / 10000)
    local s = math.floor((copper % 10000) / 100)
    return ("%dg %ds"):format(g, s)
end
