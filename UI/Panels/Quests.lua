-- Leveling › Class quests
local _, ns = ...
local UI = ns.UI

UI.LevelingSections = UI.LevelingSections or {}
local showAll = false

UI.LevelingSections["Class quests"] = function(L, c)
    L:Buttons({
        { label = "My race (" .. (c.race or "?") .. ")", active = not showAll, onClick = function() showAll = false UI.Refresh() end },
        { label = "All races", active = showAll, onClick = function() showAll = true UI.Refresh() end },
    })
    L:Text(UI.Hex(UI.C.dim) .. "Level 4 robes, then racial spells at 10 and 20. Turn them in to your Priest trainer.|r", { size = 12 })
    local race = not showAll and c.race or nil
    for _, q in ipairs(ns.Progress.ClassQuests(race, not showAll and c.faction or nil)) do
        local done = ns.Progress.IsQuestDone(q.quest_id)
        local chip
        if q.missing then chip = { text = "ID unknown", kind = "warn" }
        elseif done then chip = { text = "Done", kind = "good" }
        elseif c.level >= q.level then chip = { text = "Ready", kind = "info" }
        else chip = { text = "Level " .. q.level, kind = "neutral" } end
        local sub = {}
        if showAll then table.insert(sub, q.races) end
        if q.reward then table.insert(sub, "Reward: " .. q.reward) end
        if q.reward_spell then table.insert(sub, "Teaches " .. q.reward_spell) end
        if q.notes then table.insert(sub, q.notes) end
        if q.zone then table.insert(sub, q.zone .. (q.min_level and (" · from level " .. q.min_level) or "")) end
        if q.missing then L:Note(q.name .. ": quest ID not captured in the research (level-20 Night Elf racial).") end
        L:Row({
            chip = chip, title = q.name, sub = table.concat(sub, " · "),
            right = "level " .. q.level .. (q.quest_id and (" · #" .. q.quest_id) or ""),
            onEnter = q.reward_item_id and function(s)
                GameTooltip:SetOwner(s, "ANCHOR_RIGHT")
                GameTooltip:SetItemByID(q.reward_item_id)
                GameTooltip:Show()
            end or nil,
        })
    end
    L:Source(ns.Data.Quests[1])

    L:Label("Racial class spells")
    for _, r in ipairs(ns.Data.Racials) do
        if showAll or r.race == c.race then
            if r.spell == "Contingency Plan" then L:Note("Contingency Plan cooldown: Blizzard says 5 min, Wowhead says 10 min.") end
            L:Spell(r.wowhead_spell_id, r.spell, r.race .. " · level " .. r.level .. (r.effect and (" · " .. r.effect) or ""))
        end
    end
    L:Source(ns.Data.Racials[1])
    L:Label("Where to turn in")
    L:Text(table.concat(ns.Data.ClassTrainers.turn_in_npcs, " · "), { size = 12 })
    L:Note("Benediction/Anathema (Classic staff quest) is not confirmed for Forever.")
end
