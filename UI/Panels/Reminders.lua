local _, ns = ...
local UI = ns.UI

UI.RegisterPanel({
    key = "reminders", label = "Reminders", icon = "Interface\\Icons\\Spell_Holy_InnerFire",
    badge = function()
        if not ns.db then return 0 end
        return #ns.Reminders.Missing()
    end,
    render = function(L, c)
        local cfg = ns.db.char.reminders
        L:Header("Right now", "Checked out of combat. Missing items also pop up on screen.")
        local list = ns.Reminders.Evaluate()
        if #list == 0 then L:Text(UI.Hex(UI.C.dim) .. "Nothing to check yet at your level.|r") end
        for _, r in ipairs(list) do
            L:Row({ icon = r.icon, title = (r.ok and UI.CHECK_ICON or UI.CROSS_ICON) .. "  " .. r.label, sub = r.detail, tint = (not r.ok) and UI.C.warn or nil })
        end

        L:Header("Consumables for your level", "From Wowhead's level 30 consumables list (the only bracket published).")
        for _, e in ipairs(ns.Reminders.Consumables(c.level)) do
            L:Item(e.item.item_id, e.item.name, e.current and (UI.Hex(UI.C.good) .. "for your level|r") or e.item.bracket, e.count .. " in bags")
        end
        L:Header("Reagents")
        for _, r in ipairs(ns.Data.Reagents) do
            L:Item(r.item_id, r.name, r.used_by .. (r.vendors and ("\n" .. r.vendors) or ""), ns.Reminders.ItemCount(r.item_id) .. " in bags")
        end

        L:Header("Settings")
        L:Check("Enable reminders", cfg.enabled, function(v) cfg.enabled = v ns.Fire("REMINDERS_CHANGED") UI.Refresh() end)
        L:Check("Power Word: Fortitude", cfg.fortitude, function(v) cfg.fortitude = v ns.Fire("REMINDERS_CHANGED") end)
        L:Check("Inner Fire", cfg.innerFire, function(v) cfg.innerFire = v ns.Fire("REMINDERS_CHANGED") end)
        L:Check("Shadowform (Shadow only)", cfg.shadowform, function(v) cfg.shadowform = v ns.Fire("REMINDERS_CHANGED") end)
        L:Check("Wand equipped", cfg.wand, function(v) cfg.wand = v ns.Fire("REMINDERS_CHANGED") end)
        L:Check("Candles (once you know Prayer spells)", cfg.candles, function(v) cfg.candles = v ns.Fire("REMINDERS_CHANGED") end)
        L:Buttons({
            { label = "Candles: want " .. cfg.candleMin .. "+", onClick = function()
                cfg.candleMin = (cfg.candleMin >= 40) and 5 or (cfg.candleMin + 5)
                UI.Refresh()
            end, tip = "Click to cycle 5-40." },
        }, 160)
    end,
})
