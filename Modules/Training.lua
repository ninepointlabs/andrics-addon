-- Spell ranks by level and the next-trainer reminder.
-- Per-rank training costs are NOT published (research gap); only the
-- ~206-207g total for 1-60 from Blizzard's Nov 3 notes is shown.
local _, ns = ...

local Training = {}
ns.Training = Training

-- Spells (with rank numbers) that become trainable exactly at `level`.
function Training.At(level, spec)
    local out = {}
    for _, s in ipairs(ns.Data.Spells) do
        for rank, lvl in ipairs(s.rank_learn_levels) do
            if lvl == level then
                local talentOnly = s.talent
                -- Mind Flay is a Shadow talent; other specs can't train it.
                if not (talentOnly and spec and spec ~= "Shadow") then
                    table.insert(out, { spell = s, rank = rank, talent = talentOnly })
                end
            end
        end
    end
    return out
end

-- Next level > current with something to train (nil at/after the last one).
function Training.NextLevel(level, spec)
    for _, lvl in ipairs(ns.Data.TrainerLevels) do
        if lvl > level and #Training.At(lvl, spec) > 0 then return lvl end
    end
    return nil
end

-- Highest rank available at `level` for one spell record (0 if none yet).
function Training.RankAt(spell, level)
    local r = 0
    for rank, lvl in ipairs(spell.rank_learn_levels) do
        if lvl <= level then r = rank end
    end
    return r
end

function Training.IsKey(spell, spec)
    for _, name in ipairs(ns.Data.KeySpells[spec] or {}) do
        if name == spell.name then return true end
    end
    return false
end

-- Called on PLAYER_LEVEL_UP: chat + toast if the new level has training.
function Training.OnLevelUp(level)
    local spec = ns.DB.ActiveSpec()
    local list = Training.At(level, spec)
    if #list == 0 then
        local nextLvl = Training.NextLevel(level, spec)
        if nextLvl then ns.Print(("Next trainer visit: level %d."):format(nextLvl)) end
        return
    end
    local names = {}
    for _, e in ipairs(list) do table.insert(names, e.spell.display .. " r" .. e.rank) end
    ns.Print("|cff3fdc5aNew at your trainer:|r " .. table.concat(names, ", "))
    ns.Fire("TOAST", "Visit your Priest trainer", table.concat(names, ", "))
end
