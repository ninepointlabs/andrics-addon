-- Settings › Reminders: live status + what to remind about.
local _, ns = ...
local UI = ns.UI

UI.SettingsSections = UI.SettingsSections or {}

UI.SettingsSections.Reminders = function(L, c)
    local cfg = ns.db.char.reminders
    L:Columns({ 0.5, 0.5 })
    L:Label("Right now")
    local list = ns.Reminders.Evaluate()
    if #list == 0 then L:Text(UI.Hex(UI.C.dim) .. "Nothing to check yet at your level.|r") end
    for _, r in ipairs(list) do
        L:Row({ chip = r.ok and { text = "OK", kind = "good" } or { text = "Missing", kind = "warn" }, title = r.label, sub = r.detail })
    end
    L:Text(UI.Hex(UI.C.dim) .. "Checked out of combat; missing items pop up on screen (also /andric remind).|r", { size = 12 })
    L:NextColumn()
    L:Label("Remind me about")
    L:Check("Reminders on", cfg.enabled, function(v) cfg.enabled = v ns.Fire("REMINDERS_CHANGED") UI.Refresh() end)
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
    })
    L:EndColumns()
end
