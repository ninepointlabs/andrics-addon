-- Spec definitions: names, roles, palette, icons.
local _, ns = ...

ns.SPEC_ORDER = { "Holy", "Discipline", "Shadow" }

-- Colours: white/gold for Holy & Discipline, purple for Shadow (brief).
ns.Specs = {
    Holy = {
        key = "Holy", role = "Healer",
        icon = "Interface\\Icons\\Spell_Holy_HolyBolt",
        accent = { 1.00, 0.82, 0.30 }, accent2 = { 1.00, 0.97, 0.86 },
        tree = "Holy", weights = "Holy",
        blurb = "Big heals, group healing and Holy damage (Holy Fire, Holy Nova). Dungeon and raid healer.",
    },
    Discipline = {
        key = "Discipline", role = "Healer",
        icon = "Interface\\Icons\\Spell_Holy_PowerWordShield",
        accent = { 0.96, 0.86, 0.55 }, accent2 = { 0.90, 0.93, 1.00 },
        tree = "Discipline", weights = "Discipline",
        blurb = "Shields, Penance and mana efficiency. Healer who mixes in damage.",
    },
    Shadow = {
        key = "Shadow", role = "Damage",
        icon = "Interface\\Icons\\Spell_Shadow_ShadowWordPain",
        accent = { 0.62, 0.40, 1.00 }, accent2 = { 0.80, 0.68, 1.00 },
        tree = "Shadow", weights = "Shadow",
        blurb = "Damage over time, Mind Flay and Shadowform. Fastest solo leveling spec.",
    },
}

-- Neutral palette used before a spec is picked.
ns.NeutralAccent = { 0.85, 0.85, 0.90 }

function ns.SpecAccent(spec)
    local s = ns.Specs[spec or (ns.DB and ns.DB.char and ns.DB.ActiveSpec())]
    return s and s.accent or ns.NeutralAccent
end

function ns.IsHealer(spec)
    local s = ns.Specs[spec]
    return s and s.role == "Healer"
end
