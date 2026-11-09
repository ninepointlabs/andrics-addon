local _, ns = ...
local UI = ns.UI

UI.RegisterPanel({
    key = "mounts", label = "Mounts & gold", icon = "Interface\\Icons\\Ability_Mount_RidingHorse",
    render = function(L, c)
        local money = GetMoney()
        local goldNow = money / 10000
        L:Header("Savings goals", ("You have %s."):format(ns.Progress.MoneyText(money)))
        for _, g in ipairs(ns.Progress.GoldGoals()) do
            local known = ns.Progress.KnowsSpell(g.spell_id)
            L:Row({ icon = g.level >= 60 and "Interface\\Icons\\Ability_Mount_WhiteTiger" or "Interface\\Icons\\Ability_Mount_RidingHorse",
                title = ("%s · level %d · %dg training"):format(g.name, g.level, g.gold),
                sub = ("%s speed · mount: %s"):format(g.speed or "?", g.mount or "?"),
                right = known and (UI.CHECK_ICON .. " learned") or (c.level >= g.level and UI.Hex(UI.C.good) .. "level ok|r" or ("in " .. (g.level - c.level) .. " lvls")) })
            if not known then
                L:Progress(("%s: %dg"):format(g.name, g.gold), goldNow, g.gold, ("%dg / %dg"):format(math.floor(goldNow), g.gold))
            end
        end
        local notes = ns.Progress.RidingNotes()
        if notes then L:Text(notes.notes) end
        L:Flag("Reports say quests give no gold at level 60 (a streamer citing Blizzard; not officially confirmed). Plan your 1000g before 60.")
        L:Source(ns.Data.Riding[1])

        L:Header("Your riding trainer & first mount")
        local m = ns.Progress.MountForRace(c.race)
        if m then
            L:Row({ icon = "Interface\\Icons\\INV_Misc_Book_08", title = "Trainer: " .. m.trainer, sub = m.location .. " · NPC #" .. m.trainer_npc_id })
            L:Row({ icon = "Interface\\Icons\\INV_Misc_Bag_10", title = "Vendor: " .. m.vendor, sub = "NPC #" .. m.vendor_npc_id })
            local done = ns.Progress.IsQuestDone(m.quest_id)
            L:Row({ icon = "Interface\\GossipFrame\\AvailableQuestIcon", title = (done and (UI.CHECK_ICON .. " ") or "") .. "First mount quest: " .. m.first_mount_quest,
                sub = "Quest #" .. m.quest_id .. " · your first mount is free via this quest", right = "level 40" })
            L:Text("Mounts sold:")
            for _, id in ipairs(m.mount_item_ids) do L:Item(id, (C_Item.GetItemNameByID and C_Item.GetItemNameByID(id)) or ("Item " .. id), "Apprentice mount") end
            for _, id in ipairs(m.epic_mount_item_ids) do L:Item(id, (C_Item.GetItemNameByID and C_Item.GetItemNameByID(id)) or ("Item " .. id), "Epic mount (Journeyman)") end
        else
            L:Text("No riding data for your race in the research.")
        end
        for _, x in ipairs(ns.Data.Mounts) do
            if x.race == "Any" then L:Text(UI.Hex(UI.C.dim) .. x.notes .. "|r", { size = 11 }) end
        end
        L:Text(UI.Hex(UI.C.dim) .. "There is no Priest class mount in Forever.|r", { size = 11 })
    end,
})
