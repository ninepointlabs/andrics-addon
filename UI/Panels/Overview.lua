local _, ns = ...
local UI = ns.UI

UI.RegisterPanel({
    key = "overview", label = "Overview", icon = "Interface\\Icons\\INV_Misc_Book_09",
    render = function(L, c)
        local a = UI.Accent()
        local specName = c.spec or "no spec yet"
        L:Text(("%s%s|r  ·  level %d %s Priest  ·  %s"):format(UI.Hex(a), c.name or "?", c.level, c.race or "", specName), { size = 15 })
        L:Text(UI.Hex(UI.C.dim) .. ("Profile %s is active. Profile %s: %s."):format(ns.DB.ActiveId(), ns.DB.OtherProfileId(),
            ns.DB.Profile(ns.DB.OtherProfileId()).spec or "not set") .. "|r", { size = 11 })

        -- Client sanity: build vs research.
        local build = select(1, GetBuildInfo())
        local fullBuild = build and (build .. "." .. (select(2, GetBuildInfo()) or "")) or "?"
        local meta = ns.Data.Meta
        if meta and meta.latest_build_seen and not meta.latest_build_seen:find(fullBuild, 1, true) then
            L:Flag(("Client build %s differs from the research snapshot (%s). Data may be stale until the next recheck."):format(fullBuild, meta.latest_build_seen:match("^(%S+)") or "?"))
        end

        L:Header("Next up")
        local nextLvl = ns.Training.NextLevel(c.level, c.spec)
        local nowList = ns.Training.At(c.level, c.spec)
        if #nowList > 0 then
            local names = {}
            for _, e in ipairs(nowList) do table.insert(names, e.spell.display .. " r" .. e.rank) end
            L:Row({ icon = "Interface\\Icons\\INV_Misc_Book_11", title = "Trainable now (level " .. c.level .. ")", sub = table.concat(names, ", "),
                onClick = function() UI.Select("training") end })
        end
        if nextLvl then
            local names = {}
            for _, e in ipairs(ns.Training.At(nextLvl, c.spec)) do table.insert(names, e.spell.display .. " r" .. e.rank) end
            L:Row({ icon = "Interface\\Icons\\INV_Misc_Book_11", title = "Next trainer visit: level " .. nextLvl, sub = table.concat(names, ", "),
                right = (nextLvl - c.level) .. " level(s)", onClick = function() UI.Select("training") end })
        end
        local goal = ns.Progress.NextGoldGoal(c.level)
        if goal then
            local money = GetMoney()
            L:Row({ icon = "Interface\\Icons\\INV_Misc_Coin_01", title = ("%s at level %d: %dg"):format(goal.name, goal.level, goal.gold),
                sub = ("You have %s."):format(ns.Progress.MoneyText(money)), onClick = function() UI.Select("mounts") end })
            L:Progress("Savings toward " .. goal.name, money / 10000, goal.gold, ("%dg / %dg"):format(math.floor(money / 10000), goal.gold))
        end
        local q = ns.Progress.NextClassQuest(c.race, c.faction, c.level)
        if q then
            L:Row({ icon = "Interface\\GossipFrame\\AvailableQuestIcon", title = ("Class quest (level %d): %s"):format(q.level, q.name),
                sub = q.missing and (UI.FLAG_ICON .. " quest ID not captured in research") or ("Quest ID " .. q.quest_id),
                onClick = function() UI.Select("quests") end })
        end
        local m = ns.Progress.NextMilestone(c.level)
        if m then
            local flag = ns.Progress.MilestoneFlag(m)
            L:Row({ icon = "Interface\\Icons\\Achievement_Level_10", title = ("Level %d milestone"):format(m.level), sub = m.what .. (flag and ("\n" .. UI.FLAG_ICON .. " " .. flag) or "") })
        end

        L:Header("Inbox")
        local unread = ns.Changes.UnreadCount()
        L:Row({ icon = "Interface\\Icons\\INV_Letter_15", title = "What's changed", right = unread > 0 and (UI.Hex(UI.C.bad) .. unread .. " unread|r") or "all read",
            sub = ns.Changes.Generated() and ("Poller last ran " .. ns.Changes.Generated()) or "Companion poller hasn't run yet; showing research changes.",
            onClick = function() UI.Select("changes") end })
        local lessons = ns.Learn.UnreadLessonCount(c.level, c.spec)
        L:Row({ icon = "Interface\\Icons\\INV_Misc_Book_07", title = "Learn the Priest", right = lessons > 0 and (lessons .. " new lesson(s)") or "",
            sub = "Spells, talents, mechanics, group play and lessons that unlock as you level.", onClick = function() UI.Select("learn") end })
        local miss = ns.Reminders.Missing()
        if #miss > 0 then
            local names = {}
            for _, r in ipairs(miss) do table.insert(names, r.label) end
            L:Row({ icon = "Interface\\Icons\\Spell_Holy_InnerFire", title = "Reminders", sub = "Missing: " .. table.concat(names, ", "),
                tint = UI.C.warn, onClick = function() UI.Select("reminders") end })
        end

        if c.spec then
            L:Header("Your spec at a glance")
            local prio = ns.Data.StatPriority[ns.Stats.WeightSetName(c.spec, c.level, c.profile)]
            if prio then L:Text("Stat priority: " .. prio.text) end
            local ctxData = ns.Rotation.Context(c.spec, c.profile.rotationContext or "solo")
            if ctxData and ctxData.summary then L:Text("Rotation (" .. ns.Rotation.CONTEXT_LABELS[c.profile.rotationContext or "solo"] .. "): " .. ctxData.summary) end
        end
        L:Space(6)
        L:Text(UI.Hex(UI.C.dim) .. "Type /andric (or /priest) to toggle this window. Data checked " .. (meta and meta.checked or "?") .. "; research gaps are flagged with " .. UI.FLAG_ICON .. "|r", { size = 11 })
    end,
})
