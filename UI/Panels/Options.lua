-- Settings: General · Fortitude button · Tooltips & bags · Reminders · About the data.
local _, ns = ...
local UI = ns.UI

UI.SettingsSections = UI.SettingsSections or {}
local S = UI.SettingsSections

local TABS = { "General", "Fortitude button", "Tooltips & bags", "Reminders", "About the data", "About" }
local tab = "General"

S.General = function(L, c)
    local g, ch = ns.db.global, ns.db.char
    L:Label("Specs & dual spec")
    for _, id in ipairs(ns.DB.PROFILE_IDS) do
        local p = ns.DB.Profile(id)
        local items = {}
        for _, spec in ipairs(ns.SPEC_ORDER) do
            table.insert(items, { label = spec, active = p.spec == spec, onClick = function()
                ns.DB.SetSpec(spec, id)
                UI.Refresh()
            end })
        end
        L:Text(("Profile %s · talent spec %s%s"):format(id, id == "A" and "1" or "2", ns.DB.ActiveId() == id and (UI.Hex(UI.C.good) .. "  (active)|r") or ""))
        L:Buttons(items, 110)
    end
    local cb = L:Check("Switch profile automatically with my talent spec", ch.autoSwitch, function(v)
        ch.autoSwitch = v
        if v then ns.DualSpec.Sync() end
        UI.Refresh()
    end, "Swapping talent specs (dual spec, level 40) swaps the addon profile: spec 1 -> A, spec 2 -> B.")
    if not ns.DualSpec.IsAvailable() then
        cb:Disable()
        L:Text(UI.Hex(UI.C.dim) .. "This client doesn't expose the talent-group API.|r", { size = 12, indent = 30 })
    else
        local grp = ns.DualSpec.ActiveGroup()
        L:Text(UI.Hex(UI.C.dim) .. (ns.DualSpec.HasDualSpec() and ("Dual spec learned. Active talent spec: " .. tostring(grp or "?") .. ".")
            or "Dual spec not learned yet (level 40, at your class trainer). Profile B is ready for it.") .. "|r", { size = 12, indent = 30 })
    end

    L:Label("Rotation helper & fight summary")
    L:Check("Show the on-screen rotation helper", ch.rotation.enabled, function(v) ch.rotation.enabled = v ns.Fire("HUD_TOGGLE") end)
    L:Check("Only in combat", ch.rotation.showInCombatOnly, function(v) ch.rotation.showInCombatOnly = v ns.Fire("HUD_TOGGLE") end)
    L:Check("Post-fight summary in chat", ch.summary.enabled, function(v) ch.summary.enabled = v end)
    L:Buttons({ { label = "Reset helper position", onClick = function() ch.rotation.point = nil ns.Fire("HUD_RESET") end } })

    L:Label("Learning & window")
    L:Check("Hint the first time I learn a spell", ch.learn.hints, function(v) ch.learn.hints = v end)
    L:Check("Show minimap button", not g.minimap.hide, function(v) g.minimap.hide = not v ns.Fire("MINIMAP_TOGGLE") end)
    L:Check("Debug messages", g.debug, function(v) g.debug = v end)
    L:Text(UI.Hex(UI.C.dim) .. "Slash: /andric (or /priest) · /andric spec holy|disc|shadow · /andric rotation · /andric gear · /andric fort key|r", { size = 12 })
end

S["Fortitude button"] = function(L, c)
    local fb = ns.db.char.fortButton
    L:Text("One press casts Power Word: Fortitude on the nearest friendly player who doesn't have it: you, your group, your target, then players with friendly nameplates shown (Shift+V).", { size = 13 })
    L:Check("Show the Fortitude button", fb.enabled, function(v) fb.enabled = v ns.Fort.Refresh() end)
    L:Row({ title = "Key", sub = fb.key and "Pressing it presses the button, even if the key is bound to something else in Blizzard's menu." or "No key set.",
        right = fb.key and (UI.Hex(UI.C.good) .. fb.key .. "|r") or (UI.Hex(UI.C.dim) .. "none|r") })
    L:Buttons({
        { label = "Set key", onClick = function() ns.Fort.StartKeyCapture() end, tip = "Press any key (Shift/Ctrl/Alt work). Esc cancels." },
        { label = "Clear key", onClick = function() ns.Fort.SetKey(nil) UI.Refresh() end },
        { label = "Reset button position", onClick = function() fb.point = nil ns.Fort.Place() end },
    })
    L:Text(UI.Hex(UI.C.dim) .. "Drag the small bar above the button to move it. It shows once you know Fortitude. Who it targets and its key only change out of combat (Blizzard rule).|r", { size = 12 })
end

S["Tooltips & bags"] = function(L, c)
    local g = ns.db.global
    L:Check("Upgrade tips on item tooltips", g.tooltip.enabled, function(v) g.tooltip.enabled = v end)
    L:Check("Show what improves (stat changes) in tooltips", g.tooltip.showStats, function(v) g.tooltip.showStats = v end)
    L:Check("Highlight upgrades in my bags", g.bags.highlight, function(v) g.bags.highlight = v ns.Bags.RefreshAll() end,
        "Glow + arrow on bag items that beat what you're wearing for your active spec and that you can equip now.")
    L:Check("Tell me when an upgrade lands in my bags", g.bags.toast, function(v) g.bags.toast = v end)
    L:Space(6)
    L:Row({ title = "Hit/crit value", sub = "How many points of spell power/healing 1% hit or crit is worth. An addon assumption, not from the research.",
        button = { label = g.percentScale .. " per 1%", onClick = function()
            local steps = { 5, 8, 10, 12, 14, 20 }
            local nextV = steps[1]
            for i, v in ipairs(steps) do if v == g.percentScale then nextV = steps[i + 1] or steps[1] end end
            g.percentScale = nextV
            ns.Stats.ClearCache()
            UI.Refresh()
        end } })
end

S.About = function(L, c)
    local version = tostring(ns.VERSION)
    if not version:match("^v") then version = "v" .. version end
    L:Row({ icon = "Interface\\Icons\\Spell_Holy_WordFortitude", title = ns.TITLE .. " " .. version,
        sub = "The do-everything Priest companion for World of Warcraft: Forever." })
    L:Label("Named for")
    L:Row({ icon = "Interface\\Icons\\Spell_Holy_HolyBolt", title = "Andric Grammaris",
        sub = "The Human Priest who started it all. This addon was built for him and tested on him, and every screenshot on its website and GitHub page is his." })
    L:Text(UI.Hex(UI.C.dim) .. "If you see a Human Priest handing out Fortitude to everyone around him, say hello. May the Light guide your heals.|r", { size = 12 })
    L:Label("Links")
    L:Link("Website", "https://andricsaddon.myazerothlife.com")
    L:Link("Source, releases and issues", "https://github.com/ninepointlabs/andrics-addon")
    L:Label("Credits")
    L:Row({ title = "Made by Nine Point Labs", sub = "Free and open source, MIT licence." })
    L:Row({ title = "Information from Blizzard, Icy Veins and Wowhead", sub = "Credited per fact: see About the data, or the Sources & notes link on each screen." })
    L:Text(UI.Hex(UI.C.dim) .. "Andric's Addon is an unofficial fan project, not affiliated with or endorsed by Blizzard Entertainment. World of Warcraft and Warcraft are trademarks of Blizzard Entertainment, Inc.|r", { size = 11 })
end

UI.RegisterPanel({
    key = "settings", label = "Settings",
    setSub = function(sub) for _, t in ipairs(TABS) do if t == sub then tab = sub end end end,
    render = function(L, c)
        L:Title("Settings")
        local items = {}
        for _, t in ipairs(TABS) do
            table.insert(items, { label = t, active = tab == t, onClick = function() tab = t UI.Refresh() end })
        end
        L:Tabs(items)
        local fn = S[tab] or S.General
        fn(L, c)
    end,
})
