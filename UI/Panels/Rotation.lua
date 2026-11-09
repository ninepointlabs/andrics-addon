local _, ns = ...
local UI = ns.UI

local WHEN_TEXT = {
    always = "", buff_missing = "if the buff is missing", debuff_missing = "if your debuff is missing on the target",
    ready = "when off cooldown", no_weakened_soul = "if you don't have Weakened Soul", out_of_combat = "out of combat",
}
local function whenText(w)
    if not w then return "" end
    if WHEN_TEXT[w] then return WHEN_TEXT[w] end
    local k, v = w:match("^([%w_]+):(.+)$")
    if k == "mana_above" then return "while mana is above " .. v .. "%" end
    if k == "mana_below" then return "when mana is below " .. v .. "%" end
    if k == "target_hp_below" then return "when the target is below " .. v .. "% health" end
    if k == "proc" then return "when " .. v .. " procs" end
    return w
end
ns.Rotation.WhenText = whenText

UI.RegisterPanel({
    key = "rotation", label = "Rotation",
    setSub = function(sub)
        local key = sub and sub:lower()
        if key and ns.Rotation.CONTEXT_LABELS[key] then ns.DB.Profile().rotationContext = key end
    end,
    render = function(L, c)
        L:Title("Rotation", c.spec and (c.spec .. " · only spells you can use at level " .. c.level) or nil)
        if not c.spec then L:Text("Pick a spec first (spec pill at the top).") return end
        local p = c.profile
        local current = p.rotationContext or "solo"
        local tabs = {}
        for _, key in ipairs(ns.Rotation.CONTEXTS) do
            table.insert(tabs, { label = ns.Rotation.CONTEXT_LABELS[key], active = key == current, onClick = function()
                p.rotationContext = key
                ns.Fire("ROTATION_CONTEXT", key)
                UI.Refresh()
            end })
        end
        L:Tabs(tabs)

        local ctxData = ns.Rotation.Context(c.spec, current)
        if not ctxData then
            L:Flag("No rotation content for this spec and situation yet.")
            return
        end
        if ctxData.unconfirmed then L:Note(c.spec .. " " .. current .. ": " .. ((ctxData.flag ~= "" and ctxData.flag) or "unconfirmed")) end
        for _, s in ipairs(ctxData.sources or {}) do L:Source({ source_url = s }) end

        L:Columns({ 0.6, 0.4 })
        L:Text(UI.Hex(UI.C.dim) .. (ctxData.kind == "healing" and "A guide, not a script: who needs healing is your call." or "Top of the list wins. The on-screen helper lights up the next one.") .. "|r", { size = 12 })
        local n, hidden = 0, 0
        for _, step in ipairs(ctxData.priority or {}) do
            local avail = ns.Rotation.Availability(step.spell, c.level, c.race)
            if avail then
                n = n + 1
                local sub = whenText(step.when)
                if step.note and step.note ~= "" then sub = (sub ~= "" and (sub .. " - ") or "") .. step.note end
                local chip
                if avail == "trainable" then chip = { text = "Train it", kind = "warn" }
                elseif avail == "no_wand" then chip = { text = "No wand", kind = "warn" } end
                L:Spell(ns.Rotation.SpellId(step.spell), ("%d. %s"):format(n, (step.spell:gsub(" %(talent%)", ""))), sub, nil,
                    ns.Rotation.Icon(step.spell), chip and { chip = chip } or nil)
            else
                hidden = hidden + 1
            end
        end
        if n == 0 then L:Text(UI.Hex(UI.C.dim) .. "Nothing in this list is available at your level yet.|r") end
        if hidden > 0 then
            L:Text(UI.Hex(UI.C.dim) .. hidden .. " more step" .. (hidden == 1 and "" or "s") .. " unlock with levels or talents; they'll appear here when you can use them.|r", { size = 12 })
        end

        L:NextColumn()
        local hud = ns.db.char.rotation
        L:Row({ title = "On-screen helper", sub = hud.showInCombatOnly and "Shows in combat only" or "Next-spell icon near your character",
            button = { label = hud.enabled and "On" or "Off", onClick = function()
                hud.enabled = not hud.enabled
                ns.Fire("HUD_TOGGLE")
                UI.Refresh()
            end } })
        if ctxData.summary then
            L:Label("The plan")
            L:Text(ctxData.summary, { size = 12 })
        end
        if ctxData.tips and #ctxData.tips > 0 then
            L:Label("Tips")
            for _, t in ipairs(ctxData.tips) do L:Text("- " .. t, { size = 12 }) end
        end
        L:Label("Last fight")
        local last = ns.Summary.last
        if last then
            L:Text(("%ds · mana %s -> %s"):format(last.duration, last.manaStart and ("%.0f%%"):format(last.manaStart) or "?", last.manaEnd and ("%.0f%%"):format(last.manaEnd) or "?"), { size = 12 })
            L:Text(UI.Hex(UI.C.dim) .. ns.Summary.Text(last) .. "|r", { size = 12 })
            for _, t in ipairs(last.tips or {}) do L:Text("- " .. t, { size = 12 }) end
        else
            L:Text(UI.Hex(UI.C.dim) .. "After each fight: casts used, mana spent and a tip.|r", { size = 12 })
        end
        local mana = ns.Data.Rotations and ns.Data.Rotations.mana
        if mana then
            L:Label("Mana")
            L:Text(mana, { size = 12 })
        end
        L:EndColumns()
    end,
})
