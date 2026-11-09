local _, ns = ...
local UI = ns.UI

local PURPOSE_ICON = {
    Leveling = "Interface\\Icons\\INV_Misc_Map_01", Raid = "Interface\\Icons\\INV_Misc_Head_Dragon_01",
    Dungeon = "Interface\\Icons\\INV_Misc_Key_03", PvP = "Interface\\Icons\\Ability_DualWield",
}

UI.RegisterPanel({
    key = "talents", label = "Talents & builds", icon = "Interface\\Icons\\Ability_Marksmanship",
    render = function(L, c)
        local spec = c.spec
        if not spec then L:Text("Pick a spec first.") return end
        L:Header(spec .. " builds", "Wowhead talent calculator links. Click to copy, then paste in your browser.")
        for _, b in ipairs(ns.Data.Builds[spec] or {}) do
            L:Link(b.purpose, b.talent_calc_url, b.notes)
        end
        for _, b in ipairs(ns.Data.Builds.Other) do
            if b.spec == spec or (spec == "Shadow" and b.spec == "Alt route") then
                L:Row({ icon = PURPOSE_ICON.Leveling, title = b.spec .. ": " .. b.purpose, sub = b.notes, onClick = b.talent_calc_url and function() UI.CopyURL(b.talent_calc_url) end })
            end
        end
        L:Text(UI.Hex(UI.C.dim) .. "Talents start at level 10. Milestones: " .. ns.Data.Milestones.talent_milestones .. ". Respec at any class trainer in a major city.|r", { size = 11 })

        L:Header("What changed in Forever")
        local tree = ns.Specs[spec].tree
        for _, t in ipairs(ns.Data.TalentChanges) do
            if t.tree == tree or t.tree == "Baseline" then
                L:Row({ title = UI.Hex(t.tree == tree and UI.Accent() or UI.C.dim) .. t.tree .. "|r", sub = t.change })
            end
        end
        L:Text(UI.Hex(UI.C.dim) .. "Other trees:|r", { size = 11 })
        for _, t in ipairs(ns.Data.TalentChanges) do
            if t.tree ~= tree and t.tree ~= "Baseline" then L:Text(UI.Hex(UI.C.dim) .. t.tree .. ": " .. t.change .. "|r", { size = 11, indent = 8 }) end
        end
        L:Source(ns.Data.TalentChanges[1])

        L:Header("Legacy talents")
        for _, t in ipairs(ns.Data.LegacyTalents) do
            L:Spell(t.spell_id, t.name)
        end
        L:Flag("Penance and Prayer of Mending spell IDs differ between Wowhead and Icy Veins; hover tooltips use the Wowhead ID.")
    end,
})
