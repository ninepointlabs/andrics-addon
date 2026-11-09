local _, ns = ...
local UI = ns.UI

local showAll = false

UI.RegisterPanel({
    key = "quests", label = "Class quests", icon = "Interface\\GossipFrame\\AvailableQuestIcon",
    render = function(L, c)
        L:Buttons({
            { label = "My race (" .. (c.race or "?") .. ")", active = not showAll, onClick = function() showAll = false UI.Refresh() end },
            { label = "All races", active = showAll, onClick = function() showAll = true UI.Refresh() end },
        }, 150)
        L:Header("Priest class quests", "Level 4 robes, then racial spells at 10 and 20. Turn in to your Priest trainer.")
        local race = not showAll and c.race or nil
        local quests = ns.Progress.ClassQuests(race, not showAll and c.faction or nil)
        for _, q in ipairs(quests) do
            local done = ns.Progress.IsQuestDone(q.quest_id)
            local status = q.missing and UI.FLAG_ICON or (done and UI.CHECK_ICON or (c.level >= q.level and UI.WAIT_ICON or ""))
            local sub = {}
            if showAll then table.insert(sub, q.races) end
            if q.reward then table.insert(sub, "Reward: " .. q.reward) end
            if q.reward_spell then table.insert(sub, "Teaches: " .. q.reward_spell) end
            if q.notes then table.insert(sub, q.notes) end
            if q.zone then table.insert(sub, q.zone .. (q.min_level and (" · from level " .. q.min_level) or "")) end
            if q.missing then table.insert(sub, UI.Hex(UI.C.warn) .. "Quest ID not captured in research (gap). Spell is the level-20 Night Elf racial.|r") end
            L:Row({
                icon = q.reward_item_id and C_Item.GetItemIconByID and C_Item.GetItemIconByID(q.reward_item_id) or "Interface\\GossipFrame\\AvailableQuestIcon",
                title = ("%s  %s"):format(status, q.name), sub = table.concat(sub, " · "),
                right = ("lvl %d%s"):format(q.level, q.quest_id and (" · #" .. q.quest_id) or ""),
                onEnter = q.reward_item_id and function(s)
                    GameTooltip:SetOwner(s, "ANCHOR_RIGHT")
                    GameTooltip:SetItemByID(q.reward_item_id)
                    GameTooltip:Show()
                end or nil,
            })
        end
        L:Text(UI.Hex(UI.C.dim) .. "Checkmark = completed on this character (C_QuestLog). Hourglass = you're high enough level.|r", { size = 11 })
        L:Source(ns.Data.Quests[1])

        L:Header("Racial class spells")
        for _, r in ipairs(ns.Data.Racials) do
            if showAll or r.race == c.race then
                local sub = r.effect or ""
                if r.spell == "Contingency Plan" then sub = sub .. "\n" .. UI.FLAG_ICON .. " Cooldown conflict: Blizzard says 5 min, Wowhead says 10 min." end
                L:Spell(r.wowhead_spell_id, r.spell .. " (" .. r.race .. ", level " .. r.level .. ")", sub)
            end
        end
        L:Source(ns.Data.Racials[1])

        L:Header("Where to turn in")
        L:Text(table.concat(ns.Data.ClassTrainers.turn_in_npcs, "\n"))

        L:Header("Racial passives changed for Forever")
        for _, r in ipairs(ns.Data.RacialPassives) do L:Text("- " .. r.change) end
        L:Header("Race picks")
        local rn = ns.Data.RaceNotes
        L:Text("Shadow: " .. rn.shadow .. "\nHealer: " .. rn.healer .. "\n" .. rn.not_priest)
        L:Flag("Benediction/Anathema (Classic staff quest) is not confirmed for Forever.")
    end,
})
