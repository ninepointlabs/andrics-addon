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
    key = "rotation", label = "Rotation", icon = "Interface\\Icons\\Spell_Shadow_UnholyFrenzy",
    render = function(L, c)
        if not c.spec then L:Text("Pick a spec first.") return end
        local p = c.profile
        local current = p.rotationContext or "solo"
        local items = {}
        for _, key in ipairs(ns.Rotation.CONTEXTS) do
            table.insert(items, { label = ns.Rotation.CONTEXT_LABELS[key], active = key == current, onClick = function()
                p.rotationContext = key
                ns.Fire("ROTATION_CONTEXT", key)
                UI.Refresh()
            end })
        end
        L:Buttons(items, 130)
        local hud = ns.db.char.rotation
        L:Buttons({
            { label = hud.enabled and "Hide helper" or "Show helper", active = hud.enabled, onClick = function()
                hud.enabled = not hud.enabled
                ns.Fire("HUD_TOGGLE")
                UI.Refresh()
            end, tip = "The on-screen rotation helper suggests your next spell (damage) or shows your priority list and cooldowns (healing). Drag to move." },
            { label = hud.showInCombatOnly and "Helper: combat only" or "Helper: always", onClick = function()
                hud.showInCombatOnly = not hud.showInCombatOnly
                ns.Fire("HUD_TOGGLE")
                UI.Refresh()
            end },
        }, 150)

        local ctxData = ns.Rotation.Context(c.spec, current)
        if not ctxData then
            L:Flag("No rotation content for this spec/context yet (content/learn.json).")
            return
        end
        L:Header(c.spec .. " · " .. ns.Rotation.CONTEXT_LABELS[current], ctxData.kind == "healing" and "Healing priorities are a guide: who needs healing is your call." or "Top of the list wins. The helper checks these conditions live.")
        if ctxData.unconfirmed then L:Flag(ctxData.flag ~= "" and ctxData.flag or "Unconfirmed") end
        if ctxData.summary then L:Text(ctxData.summary) end
        L:Space(4)
        -- Only spells usable at your level; the rest unlock as you level/talent.
        local n, hidden = 0, 0
        for _, step in ipairs(ctxData.priority or {}) do
            local avail = ns.Rotation.Availability(step.spell, c.level, c.race)
            if avail then
                n = n + 1
                local id = ns.Rotation.SpellId(step.spell)
                local sub = whenText(step.when)
                if step.note and step.note ~= "" then sub = (sub ~= "" and (sub .. " - ") or "") .. step.note end
                local right = ""
                if avail == "trainable" then right = UI.Hex(UI.C.warn) .. "available - visit trainer|r"
                elseif avail == "no_wand" then right = UI.Hex(UI.C.warn) .. "equip a wand|r" end
                L:Spell(id, ("%d. %s"):format(n, step.spell:gsub(" %(talent%)", "")), sub, right, ns.Rotation.Icon(step.spell))
            else
                hidden = hidden + 1
            end
        end
        if n == 0 then L:Text(UI.Hex(UI.C.dim) .. "Nothing in this list is available at your level yet.|r") end
        if hidden > 0 then
            L:Text(UI.Hex(UI.C.dim) .. hidden .. " more step(s) unlock with levels or talents; they'll appear here when you can use them.|r", { size = 11 })
        end
        if ctxData.tips and #ctxData.tips > 0 then
            L:Header("Tips")
            for _, t in ipairs(ctxData.tips) do L:Text("- " .. t) end
        end
        local mana = ns.Data.Rotations and ns.Data.Rotations.mana
        if mana then
            L:Header("Mana")
            L:Text(mana)
        end
        local last = ns.Summary.last
        L:Header("Last fight")
        if last then
            L:Text(("%ds · mana %s -> %s"):format(last.duration, last.manaStart and ("%.0f%%"):format(last.manaStart) or "?", last.manaEnd and ("%.0f%%"):format(last.manaEnd) or "?"))
            L:Text(UI.Hex(UI.C.dim) .. ns.Summary.Text(last) .. "|r", { size = 11 })
            for _, t in ipairs(last.tips or {}) do L:Text("- " .. t) end
        else
            L:Text(UI.Hex(UI.C.dim) .. "Fight something; a summary of your casts and mana tips appears here and in chat.|r")
        end
        for _, s in ipairs(ctxData.sources or {}) do L:Source({ source_url = s }) end
    end,
})
