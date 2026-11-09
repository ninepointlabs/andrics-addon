local _, ns = ...
local UI = ns.UI

UI.RegisterPanel({
    key = "training", label = "Spells & training", icon = "Interface\\Icons\\INV_Misc_Book_11",
    render = function(L, c)
        local nextLvl = ns.Training.NextLevel(c.level, c.spec)
        L:Header("Trainer", ("You are level %d."):format(c.level))
        local now = ns.Training.At(c.level, c.spec)
        if #now > 0 then
            local names = {}
            for _, e in ipairs(now) do table.insert(names, e.spell.display .. " r" .. e.rank) end
            L:Row({ icon = "Interface\\Icons\\INV_Misc_Book_11", title = "New at level " .. c.level, sub = table.concat(names, ", "), tint = UI.Accent() })
        end
        if nextLvl then
            local names = {}
            for _, e in ipairs(ns.Training.At(nextLvl, c.spec)) do table.insert(names, e.spell.display .. " r" .. e.rank) end
            L:Row({ icon = "Interface\\Icons\\INV_Misc_PocketWatch_01", title = "Next visit: level " .. nextLvl, sub = table.concat(names, ", ") })
        end
        L:Text(ns.Data.Milestones.trainer_costs)
        L:Flag("Per-rank training costs aren't published for Forever; only the ~206-207g total for 1-60.")

        L:Header("All spells", c.spec and ("Highlighted = key spell for " .. c.spec .. " (from the research rotation).") or nil)
        for _, s in ipairs(ns.Data.Spells) do
            local rank = ns.Training.RankAt(s, c.level)
            local total = #s.rank_learn_levels
            local nextRank = s.rank_learn_levels[rank + 1]
            local key = c.spec and ns.Training.IsKey(s, c.spec)
            local skip = s.talent and c.spec and c.spec ~= "Shadow"
            local title = (key and UI.Hex(UI.Accent()) or (skip and UI.Hex(UI.C.dim) or "")) .. s.display .. ((key or skip) and "|r" or "")
            if s.talent then title = title .. UI.Hex(UI.C.dim) .. " (Shadow talent)|r" end
            local sub = "Ranks at: " .. table.concat(s.rank_learn_levels, ", ")
            if s.notes then sub = sub .. "\n" .. UI.Hex(UI.C.dim) .. s.notes .. "|r" end
            local right = rank > 0 and ("rank %d/%d"):format(rank, total) or ("level " .. s.rank_learn_levels[1])
            if nextRank and rank > 0 then right = right .. UI.Hex(UI.C.dim) .. (" · next %d|r"):format(nextRank) end
            L:Spell(s.wowhead_base_spell_id, title, sub, right)
        end
        L:Source(ns.Data.Spells[1])
        L:Text(UI.Hex(UI.C.dim) .. "Prayer of Fortitude, Prayer of Shadow Protection and higher Prayer ranks come from Codex books, not the trainer.|r", { size = 11 })
    end,
})
