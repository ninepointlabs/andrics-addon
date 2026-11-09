local _, ns = ...
local UI = ns.UI

-- Known conflicts called out by the brief, in addition to research gaps.
local CONFLICTS = {
    "Contingency Plan (Gnome lvl 20): Blizzard says 5 min cooldown, Wowhead says 10 min.",
    "Penance spell ID: Wowhead 402284 vs Icy Veins DB 402174.",
    "Prayer of Mending spell ID: 401863 / 401859 / 1240827 depending on the page.",
    "Tier 1 set bonuses are datamined placeholders (Wowhead).",
    "Dual spec: Blizzard's Priest deep dive (and wowforeverinfo) say it unlocks at 40, but it was not confirmed in the live client; the addon keeps manual A/B profiles until the API is verified.",
    "Prayer of Healing: Icy Veins lists a 5th rank at 60, likely from a book (unconfirmed).",
    "Divine Grace (Human lvl 10) cooldown: Blizzard 5 min vs Wowhead Discipline abilities page 10 min.",
    "Wand Specialization: Icy Veins 13% vs wowforeverinfo 25%.",
    "Out-of-casting mana regen: Spirit/4 + 12.5 (Wowhead Shadow) vs Spirit/4 + 13 (Wowhead Discipline).",
    "Meditation: Icy Veins says 50% regen while casting; Wowhead's Holy formula uses 15%.",
    "Shadow Protection duration: 10 min, 20 min or 1 hour depending on the page.",
    "Some Wowhead/Icy Veins pages still list removed talents (Binding Heal, Lightwell) and old cooldowns (Devouring Plague 1 min, SW:Death 15s); the addon follows Blizzard's latest notes.",
    "Downranking penalty: Blizzard says spells 'vastly below' your level lose bonus; Wowhead says 18 levels.",
    "Searing Light proc buff name (Holy solo rotation) is assumed, not confirmed.",
}

UI.RegisterPanel({
    key = "sources", label = "Sources & flags", icon = "Interface\\Icons\\INV_Misc_Note_06",
    render = function(L, c)
        local meta = ns.Data.Meta
        L:Header("Client")
        L:Text(("Built for %s, Interface %s, project id %s.\nResearch build: %s\nYour client: %s (WOW_PROJECT_ID %s)"):format(
            meta.game, tostring(meta.toc_interface), meta.wow_project_id, meta.latest_build_seen,
            table.concat({ GetBuildInfo() }, " / "), tostring(WOW_PROJECT_ID)))
        L:Text(UI.Hex(UI.C.dim) .. meta.api_note .. "|r", { size = 11 })

        L:Header("Research gaps", "Things the addon deliberately does not guess.")
        for _, g in ipairs(ns.Data.Gaps) do L:Flag(g.gap) end
        L:Header("Conflicts between sources")
        for _, t in ipairs(CONFLICTS) do L:Flag(t) end
        L:Header("Addon assumptions")
        L:Text("- Gear scores use rank-derived weights from each spec's stat priority, not simulations.\n- Hit/crit % are scaled by " .. ns.db.global.percentScale .. " points per 1% (Options).\n- Healing power counts 1/3 toward damage (Wowhead) when an item doesn't list damage.\n- Tooltip stat parsing reads English item text.")

        L:Header("Sources", "Click to copy. Every record in the addon keeps its source and check date.")
        local keys = {}
        for k in pairs(ns.Data.Sources) do table.insert(keys, k) end
        table.sort(keys)
        for _, k in ipairs(keys) do L:Link(k, ns.Data.Sources[k]) end
    end,
})
