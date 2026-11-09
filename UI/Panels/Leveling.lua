local _, ns = ...
local UI = ns.UI

local function bracketRange(levels)
    local lo, hi = levels:match("(%d+)%-(%d+)")
    return tonumber(lo), tonumber(hi)
end

UI.RegisterPanel({
    key = "leveling", label = "Leveling", icon = "Interface\\Icons\\INV_Misc_Map_01",
    render = function(L, c)
        local horde = c.faction == "Horde"
        L:Header("Where to quest", (c.faction or "?") .. " zones by level (Icy Veins). Your bracket is highlighted.")
        for _, z in ipairs(ns.Data.Zones) do
            local lo, hi = bracketRange(z.levels)
            local here = lo and c.level >= lo and c.level <= hi
            L:Row({ icon = here and "Interface\\Icons\\INV_Misc_Map02" or nil, title = (here and UI.Hex(UI.Accent()) or "") .. z.levels .. "  " .. (horde and z.horde or z.alliance) .. (here and "|r" or ""),
                sub = "Dungeons: " .. z.dungeons, tint = here and UI.Accent() or nil })
        end
        L:Flag("Zones for levels 30-60 are not in the research yet (Wowhead zone pages were blocked). Use Questie or the Dungeons list below.")
        L:Source(ns.Data.Zones[1])

        L:Header("Dungeons near your level")
        local any = false
        for _, d in ipairs(ns.Data.Dungeons) do
            local lo, hi = bracketRange(d.levels)
            if lo and c.level >= lo - 3 and c.level <= hi then
                any = true
                L:Row({ title = d.name .. (d.new_in_forever and ("  " .. UI.Hex(UI.C.good) .. "NEW in Forever|r") or ""), right = d.levels })
            end
        end
        if not any then L:Text(UI.Hex(UI.C.dim) .. "None in range right now.|r") end
        L:Text(UI.Hex(UI.C.dim) .. "Dungeon enemy XP was raised 50% on Nov 8.|r", { size = 11 })

        L:Header("New zones in Forever")
        for _, z in ipairs(ns.Data.NewZones) do
            L:Row({ title = z.zone, right = "levels " .. z.levels, sub = z.notes ~= "" and z.notes or nil })
        end

        if c.spec then
            L:Header("Leveling as " .. c.spec)
            local content = ns.Learn.Content()
            for _, e in ipairs(content and content.leveling and content.leveling[c.spec] or {}) do
                L:Text(UI.Hex(UI.Accent()) .. e.title .. "|r\n" .. e.body .. (e.unconfirmed and ("\n" .. UI.FLAG_ICON .. " " .. (e.flag or "Unconfirmed")) or ""))
            end
            for _, b in ipairs(ns.Data.Builds.Other) do
                if b.notes then
                    L:Row({ icon = "Interface\\Icons\\Ability_Marksmanship", title = b.spec .. " - " .. b.purpose, sub = b.notes })
                end
            end
            L:Header("Stat priority while leveling")
            L:Text(ns.Data.StatPriority.Leveling.text)
            L:Source(ns.Data.StatPriority.Leveling)
        end

        L:Header("Professions")
        local pr = ns.Data.Professions
        L:Text(("Leveling: %s\nRaiding: %s\nAlternatives: %s"):format(pr.leveling, pr.raiding, table.concat(pr.alternatives, ", ")))
        L:Source(pr)
    end,
})
