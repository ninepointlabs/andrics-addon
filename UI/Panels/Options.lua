local _, ns = ...
local UI = ns.UI

UI.RegisterPanel({
    key = "options", label = "Options", icon = "Interface\\Icons\\INV_Misc_Gear_01",
    render = function(L, c)
        local g, ch = ns.db.global, ns.db.char
        L:Header("Profiles & dual spec", "Profile A = talent spec 1, profile B = talent spec 2. Each keeps its own spec, weights and rotation context.")
        for _, id in ipairs(ns.DB.PROFILE_IDS) do
            local p = ns.DB.Profile(id)
            local items = {}
            for _, spec in ipairs(ns.SPEC_ORDER) do
                table.insert(items, { label = spec, active = p.spec == spec, onClick = function()
                    ns.DB.SetSpec(spec, id)
                    UI.Refresh()
                end })
            end
            L:Text(("Profile %s%s"):format(id, ns.DB.ActiveId() == id and (UI.Hex(UI.C.good) .. "  (active)|r") or ""))
            L:Buttons(items, 110)
        end
        L:Buttons({ { label = "Switch to profile " .. ns.DB.OtherProfileId(), onClick = function() ns.DB.SwitchProfile(ns.DB.OtherProfileId()) UI.Refresh() end } }, 170)
        local cb = L:Check("Auto-switch profile with my talent spec", ch.autoSwitch, function(v)
            ch.autoSwitch = v
            if v then ns.DualSpec.Sync() end
            UI.Refresh()
        end, "Swapping talent specs (dual spec, level 40) swaps the addon profile: spec 1 -> A, spec 2 -> B.")
        if not ns.DualSpec.IsAvailable() then
            cb:Disable()
            L:Text(UI.Hex(UI.C.dim) .. "This client doesn't expose the talent-group API.|r", { size = 11, indent = 28 })
        else
            local g = ns.DualSpec.ActiveGroup()
            L:Text(UI.Hex(UI.C.dim) .. (ns.DualSpec.HasDualSpec() and ("Dual spec learned. Active talent spec: " .. tostring(g or "?") .. ".")
                or "Dual spec not learned yet (level 40, at your class trainer). Profile B is ready for it.") .. "|r", { size = 11, indent = 28 })
        end

        L:Header("Tooltips")
        L:Check("Show upgrade tips on item tooltips", g.tooltip.enabled, function(v) g.tooltip.enabled = v end)
        L:Check("Show what improves (stat changes) in tooltips", g.tooltip.showStats, function(v) g.tooltip.showStats = v end)
        L:Check("Highlight upgrades in my bags", g.bags.highlight, function(v) g.bags.highlight = v ns.Bags.RefreshAll() end,
            "Glow + arrow on bag items that beat what you're wearing for your active spec and that you can equip now.")
        L:Check("Tell me when an upgrade lands in my bags", g.bags.toast, function(v) g.bags.toast = v end)
        L:Buttons({ { label = "Hit/crit: " .. g.percentScale .. " pts per 1%", onClick = function()
            local steps = { 5, 8, 10, 12, 14, 20 }
            local nextV = steps[1]
            for i, v in ipairs(steps) do if v == g.percentScale then nextV = steps[i + 1] or steps[1] end end
            g.percentScale = nextV
            ns.Stats.ClearCache()
            UI.Refresh()
        end, tip = "Addon assumption (not from research): how many points of spell power/healing 1% hit or crit is worth. Click to cycle." } }, 220)

        L:Header("Rotation helper & fight summary")
        L:Check("Show rotation helper", ch.rotation.enabled, function(v) ch.rotation.enabled = v ns.Fire("HUD_TOGGLE") end)
        L:Check("Only in combat", ch.rotation.showInCombatOnly, function(v) ch.rotation.showInCombatOnly = v ns.Fire("HUD_TOGGLE") end)
        L:Check("Post-fight summary in chat", ch.summary.enabled, function(v) ch.summary.enabled = v end)
        L:Buttons({ { label = "Reset helper position", onClick = function() ch.rotation.point = nil ns.Fire("HUD_RESET") end } }, 170)

        L:Header("Learning")
        L:Check("Hint the first time I learn a spell", ch.learn.hints, function(v) ch.learn.hints = v end)

        L:Header("Minimap")
        L:Check("Show minimap button", not g.minimap.hide, function(v) g.minimap.hide = not v ns.Fire("MINIMAP_TOGGLE") end)
        L:Check("Debug messages", g.debug, function(v) g.debug = v end)
        L:Text(UI.Hex(UI.C.dim) .. "Slash: /andric (alias /priest)  ·  /andric spec · /andric rotation · /andric learn · /andric reset-hud|r", { size = 11 })
    end,
})
