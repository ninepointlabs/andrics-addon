-- Leveling › Riding & gold
local _, ns = ...
local UI = ns.UI

UI.LevelingSections = UI.LevelingSections or {}

UI.LevelingSections["Riding & gold"] = function(L, c)
    local money = GetMoney()
    local gold = math.floor(money / 10000)
    local cards = {}
    for _, g in ipairs(ns.Progress.GoldGoals()) do
        local known = ns.Progress.KnowsSpell(g.spell_id)
        table.insert(cards, {
            label = g.name .. " · level " .. g.level,
            title = known and "Learned" or ("%dg of %dg"):format(math.min(gold, g.gold), g.gold),
            progress = not known and { value = gold, max = g.gold } or nil,
            body = ("%s speed · mount: %s"):format(g.speed or "?", g.mount or "?")
                .. (not known and c.level < g.level and (" · in " .. (g.level - c.level) .. " levels") or ""),
        })
    end
    L:Text(("You have %s."):format(ns.Progress.MoneyText(money)), { size = 14 })
    L:CardRow(cards)
    local notes = ns.Progress.RidingNotes()
    if notes then L:Text(UI.Hex(UI.C.dim) .. notes.notes .. "|r", { size = 12 }) end
    L:Flag("Reports say quests give no gold at level 60 (not officially confirmed). Plan your 1000g before 60.")
    L:Source(ns.Data.Riding[1])

    L:Label("Your riding trainer & first mount")
    local m = ns.Progress.MountForRace(c.race)
    if m then
        local done = ns.Progress.IsQuestDone(m.quest_id)
        L:Row({ title = "Trainer: " .. m.trainer, sub = m.location })
        L:Row({ title = "Vendor: " .. m.vendor })
        L:Row({ chip = done and { text = "Done", kind = "good" } or { text = "Level 40", kind = "neutral" },
            title = "First mount quest: " .. m.first_mount_quest, sub = "Quest #" .. m.quest_id .. " · your first mount is free" })
        L:Label("Mounts sold")
        for _, id in ipairs(m.mount_item_ids) do L:Item(id, (C_Item.GetItemNameByID and C_Item.GetItemNameByID(id)) or ("Item " .. id), "Apprentice mount") end
        for _, id in ipairs(m.epic_mount_item_ids) do L:Item(id, (C_Item.GetItemNameByID and C_Item.GetItemNameByID(id)) or ("Item " .. id), "Epic mount (Journeyman)") end
    else
        L:Text("No riding data for your race in the research.")
    end
    for _, x in ipairs(ns.Data.Mounts) do
        if x.race == "Any" then L:Note(x.notes) end
    end
    L:Note("There is no Priest class mount in Forever.")
end
