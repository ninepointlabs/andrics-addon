-- Leveling › Trainer
local _, ns = ...
local UI = ns.UI

UI.LevelingSections = UI.LevelingSections or {}

UI.LevelingSections.Trainer = function(L, c)
    local now = ns.Training.At(c.level, c.spec)
    local nextLvl = ns.Training.NextLevel(c.level, c.spec)
    local function names(list)
        local t = {}
        for _, e in ipairs(list) do table.insert(t, e.spell.display .. " r" .. e.rank) end
        return table.concat(t, ", ")
    end
    local cards = {}
    if #now > 0 then table.insert(cards, { label = "Train now (level " .. c.level .. ")", title = #now .. " spell" .. (#now == 1 and "" or "s"), body = names(now) }) end
    if nextLvl then table.insert(cards, { label = "Next visit", title = "Level " .. nextLvl, body = names(ns.Training.At(nextLvl, c.spec)) }) end
    table.insert(cards, { label = "Cost", title = "~206-207g for 1-60", body = "Total for every class (Blizzard). Per-rank costs aren't published." })
    L:CardRow(cards)
    L:Note(ns.Data.Milestones.trainer_costs)
    L:Note("Prayer of Fortitude, Prayer of Shadow Protection and higher Prayer ranks come from Codex books, not the trainer.")

    L:Label("All spells")
    for _, s in ipairs(ns.Data.Spells) do
        local rank = ns.Training.RankAt(s, c.level)
        local total = #s.rank_learn_levels
        local nextRank = s.rank_learn_levels[rank + 1]
        local key = c.spec and ns.Training.IsKey(s, c.spec)
        local talentOther = s.talent and c.spec and c.spec ~= "Shadow"
        local chip
        if key then chip = { text = "Key for " .. c.spec, kind = "info" } end
        if s.talent then chip = { text = "Shadow talent", kind = "neutral" } end
        local sub = "Ranks at " .. table.concat(s.rank_learn_levels, ", ")
        if s.notes then L:Note(s.display .. ": " .. s.notes) end
        local right = rank > 0 and ("rank %d/%d"):format(rank, total) or ("at level " .. s.rank_learn_levels[1])
        if nextRank and rank > 0 then right = right .. UI.Hex(UI.C.dim) .. (" · next at %d|r"):format(nextRank) end
        L:Spell(s.wowhead_base_spell_id, (talentOther and UI.Hex(UI.C.dim) or "") .. s.display .. (talentOther and "|r" or ""), sub, right, nil, chip and { chip = chip } or nil)
    end
    L:Source(ns.Data.Spells[1])
end
