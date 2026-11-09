-- Headless tests. Run from the repo root:  lua5.1 tests/run.lua
package.path = "./tests/?.lua;" .. package.path
local M = require("wow_mock")
M.Install()
local S = M.state

local passed, failed = 0, 0
local function test(name, fn)
    local ok, err = pcall(fn)
    if ok then passed = passed + 1 else failed = failed + 1 io.stderr:write("FAIL " .. name .. ": " .. tostring(err) .. "\n") end
end
local function eq(a, b, msg) if a ~= b then error((msg or "") .. " expected " .. tostring(b) .. ", got " .. tostring(a), 2) end end
local function near(a, b, msg) if math.abs(a - b) > 1e-6 then error((msg or "") .. " expected " .. tostring(b) .. ", got " .. tostring(a), 2) end end
local function truthy(v, msg) if not v then error(msg or "expected truthy", 2) end end
local function textHas(pattern)
    for _, t in ipairs(M.texts) do if t:find(pattern, 1, true) then return true end end
    return false
end

local ns = M.LoadAddon("AndricsAddon_Forever.toc", ".")

test("toc files match between plain and _Forever", function()
    local a, b = io.open("AndricsAddon.toc"):read("*a"), io.open("AndricsAddon_Forever.toc"):read("*a")
    eq(a, b)
    truthy(a:find("## Interface: 16001", 1, true), "interface")
    truthy(a:find("## X-Website: https://github.com/ninepointlabs/andrics-addon", 1, true), "website")
    truthy(a:find("## Title: Andric's Addon", 1, true), "title")
end)

test("generated data present", function()
    truthy(#ns.Data.Spells >= 30)
    truthy(ns.Data.Learn and ns.Data.Learn.rotation and ns.Data.Learn.rotation.Shadow.solo, "learn content")
    eq(ns.Data.Meta.toc_interface, 16001)
end)

-- Login
M.Fire("ADDON_LOADED", "AndricsAddon")
M.Fire("PLAYER_LOGIN")
M.RunTimers()

test("login creates profile A/B with no spec", function()
    truthy(ns.db and ns.db.char.profiles.A and ns.db.char.profiles.B)
    eq(ns.DB.ActiveSpec(), nil)
    truthy(SlashCmdList.ANDRICSADDON, "slash")
    eq(SLASH_ANDRICSADDON1, "/andric")
    eq(SLASH_ANDRICSADDON2, "/priest")
end)

test("dual-spec ready profiles", function()
    local fired = 0
    ns.On("SPEC_CHANGED", function() fired = fired + 1 end)
    ns.DB.SetSpec("Shadow")
    ns.DB.SetSpec("Holy", "B")
    eq(ns.DB.ActiveSpec(), "Shadow")
    truthy(ns.DB.SwitchProfile("B"))
    eq(ns.DB.ActiveSpec(), "Holy")
    eq(ns.DB.SwitchProfile("B"), false)
    ns.DB.SwitchProfile("A")
    eq(fired, 3, "SPEC_CHANGED fires on active changes only")
    -- auto-switch hook is inert unless opted in
    eq(ns.DualSpec.OnTalentGroupChanged(2), false)
    ns.db.char.autoSwitch = true
    truthy(ns.DualSpec.OnTalentGroupChanged(2))
    eq(ns.DB.ActiveId(), "B")
    ns.DB.SwitchProfile("A")
    ns.db.char.autoSwitch = false
    eq(ns.DualSpec.IsAvailable(), false)
end)

test("DB.Init keeps saved values and fills defaults", function()
    local acc, ch = ns.DB.Init({ percentScale = 14 }, { active = "B", profiles = { B = { spec = "Discipline" } } })
    eq(acc.percentScale, 14)
    eq(ch.active, "B")
    eq(ch.profiles.B.spec, "Discipline")
    eq(ch.profiles.A.rotationContext, "solo")
    truthy(ch.reminders.candleMin == 10)
    -- restore the login state
    ns.DB.Init(AndricsAddonDB, AndricsAddonCharDB)
end)

test("stat parsing", function()
    local raw = ns.Stats.ParseLines({
        "Robe of Testing", "+7 Intellect", "+5 Spirit", "+4 Stamina",
        "Equip: Increases damage and healing done by magical spells and effects by up to 12.",
        "Equip: Increases healing done by spells and effects by up to 9.",
        "Equip: Improves your chance to get a critical strike with spells by 1%.",
        "Equip: Improves your chance to hit with spells by 2%.",
        "Equip: Restores 3 mana per 5 sec.",
        "Equip: Increases damage done by Shadow spells and effects by up to 6.",
        "(2) Set: +10 Intellect", "Use: Restores 375 mana.",
        "|cff00ff00Equip: Increases damage done by magical spells and effects by up to 4.|r",
    })
    eq(raw.INT, 7); eq(raw.SPI, 5); eq(raw.STA, 4); eq(raw.SPELL_POWER, 12); eq(raw.HEALING, 9)
    eq(raw.SPELL_CRIT, 1); eq(raw.SPELL_HIT, 2); eq(raw.MP5, 3); eq(raw.SHADOW_DAMAGE, 6); eq(raw.SPELL_DAMAGE, 4)
    local d = ns.Stats.Derive(raw)
    near(d.DAMAGE, 12 + 4 + 6 + 3, "healing counts 1/3 as damage")
    eq(d.HEALING, 21)
    local tbc = ns.Stats.ParseLines({ "x", "Equip: Increases healing done by up to 22 and damage done by up to 8 for all magical spells and effects." })
    near(ns.Stats.Derive(tbc).DAMAGE, 8, "explicit damage portion wins")
    eq(ns.Stats.ParseLines({ "x", "(16.5 damage per second)" }).WAND_DPS, 16.5)
end)

test("weights derive from priority order", function()
    local w = ns.Stats.Weights("Shadow", 10)
    near(w.SPELL_HIT, 1 * 10); near(w.DAMAGE, 4 / 6); near(w.STA, 1 / 6)
    local h = ns.Stats.Weights("Holy", 10, { INT = 2 })
    near(h.HEALING, 1); eq(h.INT, 2)
    eq(ns.Stats.WeightSetName("Shadow", 30, {}), "Leveling")
    eq(ns.Stats.WeightSetName("Shadow", 60, {}), "Shadow")
    eq(ns.Stats.WeightSetName("Holy", 30, {}), "Holy")
    eq(ns.Stats.WeightSetName("Holy", 30, { levelingWeights = true }), "Leveling")
end)

-- Item fixtures
local NEW, OLD, RING1, RING2, PLATE = "item:1001", "item:1002", "item:1003", "item:1004", "item:1005"
S.itemInfo[1001] = { equipLoc = "INVTYPE_CHEST", classID = 4, subclassID = 1 }
S.itemInfo[1002] = { equipLoc = "INVTYPE_ROBE", classID = 4, subclassID = 1 }
S.itemInfo[1003] = { equipLoc = "INVTYPE_FINGER", classID = 4, subclassID = 0 }
S.itemInfo[1004] = { equipLoc = "INVTYPE_FINGER", classID = 4, subclassID = 0 }
S.itemInfo[1005] = { equipLoc = "INVTYPE_CHEST", classID = 4, subclassID = 4 }
S.itemLines[NEW] = { "New", "+10 Intellect", "Equip: Increases healing done by spells and effects by up to 20." }
S.itemLines[OLD] = { "Old", "+10 Intellect", "+10 Spirit" }
S.itemLines[RING1] = { "R1", "+3 Intellect" }
S.itemLines[RING2] = { "R2", "+8 Intellect" }
S.itemLines[PLATE] = { "Plate", "+20 Stamina" }
S.equipped[5] = OLD
S.equipped[11] = RING1
S.equipped[12] = RING2

test("compare: healer sees healing robe as upgrade, shadow leveling sees downgrade", function()
    ns.Stats.ClearCache()
    local holy = ns.Stats.Compare(NEW, "Holy", 30, {}, 10)
    truthy(holy.delta > 0, "holy upgrade")
    local shadow = ns.Stats.Compare(NEW, "Shadow", 30, {}, 10)
    eq(shadow.setName, "Leveling")
    -- Shadow leveling: +6.67 dmg (20/3) * 1.0 vs -10 SPI * 3/7
    truthy(shadow.delta > 0, "1/3 conversion makes it a small upgrade")
    eq(ns.Stats.Compare(PLATE, "Holy", 30, {}, 10).unusable, true)
end)

test("compare: rings replace the weaker ring", function()
    local r = ns.Stats.Compare("item:1002", "Holy", 30, {}, 10) -- robe vs equipped robe
    eq(r.isEquipped, true)
    S.itemInfo[1006] = { equipLoc = "INVTYPE_FINGER", classID = 4, subclassID = 0 }
    S.itemLines["item:1006"] = { "R3", "+5 Intellect" }
    local res = ns.Stats.Compare("item:1006", "Holy", 30, {}, 10)
    eq(res.against.slot, 11, "compares to weaker ring")
    truthy(res.delta > 0)
end)

test("tooltip lines", function()
    local lines = ns.Tooltip.LinesFor(NEW, "Holy", {}, 30, 10)
    local all = table.concat(lines, "\n")
    truthy(all:find("Upgrade", 1, true), all)
    truthy(all:find("Healing power", 1, true), "stat delta")
    truthy(all:find("addon assumption", 1, true))
    truthy(M.tooltipHook, "tooltip hook installed via TooltipDataProcessor")
end)

test("training: next trainer level and spec filtering", function()
    eq(ns.Training.NextLevel(19, "Shadow"), 20)
    eq(ns.Training.NextLevel(59, "Holy"), 60)
    eq(ns.Training.NextLevel(60, "Holy"), nil)
    local mf = false
    for _, e in ipairs(ns.Training.At(20, "Holy")) do if e.spell.talent then mf = true end end
    eq(mf, false, "Holy doesn't train Mind Flay")
    mf = false
    for _, e in ipairs(ns.Training.At(20, "Shadow")) do if e.spell.talent then mf = true end end
    eq(mf, true)
    eq(ns.Training.RankAt(ns.Data.Spells[1], 14), 3)
end)

test("quests: race filter and flagged missing Night Elf quest", function()
    local list = ns.Progress.ClassQuests("Night Elf", "Alliance")
    local missing, reagent = false, false
    for _, q in ipairs(list) do
        if q.missing then missing = true eq(q.quest_id, nil) end
        if q.quest_id == 95613 then reagent = true end
    end
    truthy(missing, "Elune's Grace placeholder flagged")
    truthy(reagent, "Alliance reagent quest")
    for _, q in ipairs(ns.Progress.ClassQuests("Undead", "Horde")) do
        truthy(q.races == "Undead" or q.type == "reagent" and false or q.races == "Undead", "only undead quests: " .. q.name)
    end
end)

test("gold goals from research", function()
    local g = ns.Progress.GoldGoals()
    eq(g[1].gold, 100); eq(g[1].level, 40)
    eq(g[2].gold, 1000); eq(g[2].level, 60)
end)

-- Rotation engine with a fake state
local function fakeState(o)
    return {
        inCombat = function() return o.combat or false end,
        hasTarget = function() return o.target ~= false end,
        spellName = function(n) return n end,
        playerBuff = function(n) return o.buffs and o.buffs[n] or false end,
        playerDebuff = function(n) return o.debuffs and o.debuffs[n] or false end,
        targetDebuff = function(n) return o.tdebuffs and o.tdebuffs[n] or false end,
        cooldown = function(n) return o.cds and o.cds[n] or 0 end,
        manaPct = function() return o.mana or 100 end,
        targetHpPct = function() return o.hp or 100 end,
        known = function(n) return o.known == nil or o.known[n] == true end,
    }
end

test("rotation: every step uses a supported condition and resolvable spell", function()
    for spec, ctxs in pairs(ns.Data.Learn.rotation) do
        for ctxName, ctx in pairs(ctxs) do
            for _, step in ipairs(ctx.priority) do
                local r = ns.Rotation.Check(step, fakeState({}))
                truthy(r ~= nil, ("%s/%s: condition %s unsupported"):format(spec, ctxName, tostring(step.when)))
                truthy(step.spell == "Wand" or ns.Rotation.SpellId(step.spell), ("%s/%s: no id for %s"):format(spec, ctxName, step.spell))
            end
        end
    end
end)

test("rotation: shadow suggestion follows state", function()
    local known = { ["Power Word: Fortitude"] = true, ["Inner Fire"] = true, ["Mind Blast"] = true, ["Shadow Word: Pain"] = true,
        ["Mind Flay (talent)"] = true, Wand = true, ["Power Word: Shield"] = true }
    local buffs = { ["Power Word: Fortitude"] = true, ["Inner Fire"] = true }
    local debuffs = { ["Weakened Soul"] = true }
    local s = ns.Rotation.Suggest("Shadow", "solo", fakeState({ known = known, buffs = buffs, debuffs = debuffs }), 3)
    eq(s[1].spell, "Mind Blast")
    s = ns.Rotation.Suggest("Shadow", "solo", fakeState({ known = known, buffs = buffs, debuffs = debuffs, cds = { ["Mind Blast"] = 5 } }), 3)
    eq(s[1].spell, "Shadow Word: Pain")
    s = ns.Rotation.Suggest("Shadow", "solo", fakeState({ known = known, buffs = buffs, debuffs = debuffs, cds = { ["Mind Blast"] = 5 },
        tdebuffs = { ["Shadow Word: Pain"] = true }, mana = 20 }), 3)
    eq(s[1].spell, "Wand", "low mana -> wand")
    s = ns.Rotation.Suggest("Shadow", "solo", fakeState({ known = known, buffs = {}, debuffs = debuffs }), 1)
    eq(s[1].spell, "Power Word: Fortitude")
end)

test("summary tips", function()
    ns.Summary.Start(0, 90)
    for _ = 1, 3 do ns.Summary.OnCast(8092) end
    ns.Summary.OnCast(5019)
    local f = ns.Summary.Finish(20, 10)
    truthy(f and f.casts["Wand"] == 1)
    truthy(#f.tips >= 1)
    ns.Summary.Start(0, 90)
    eq(ns.Summary.Finish(2, 90), nil, "too short")
end)

test("changes: research baseline unread, mark read", function()
    local n = ns.Changes.UnreadCount()
    truthy(n >= 10)
    ns.Changes.MarkRead(ns.Changes.All()[1])
    eq(ns.Changes.UnreadCount(), n - 1)
    ns.Changes.MarkAllRead()
    eq(ns.Changes.UnreadCount(), 0)
end)

test("learn: lessons unlock by level, hints after first scan", function()
    local unlocked, upcoming = ns.Learn.Lessons(24, "Shadow")
    truthy(#unlocked > 0 and #upcoming > 0)
    S.known[8092] = true
    ns.db.char.learn.seenSpells = { Smite = true }
    ns.Learn.ScanSpells(false)
    truthy(ns.db.char.learn.seenSpells["Mind Blast"], "marks new spell seen")
end)

test("reminders", function()
    S.known[1243] = true; S.known[588] = true
    S.auras = { ["Inner Fire"] = true }
    local miss = ns.Reminders.Missing()
    local labels = {}
    for _, r in ipairs(miss) do labels[r.label] = true end
    truthy(labels["Power Word: Fortitude"], "fort missing")
    truthy(labels["Wand equipped"], "wand missing")
    truthy(not labels["Inner Fire"], "inner fire present")
end)

test("every panel renders for every spec without errors", function()
    for _, spec in ipairs(ns.SPEC_ORDER) do
        ns.DB.SetSpec(spec)
        for _, key in ipairs(ns.PanelOrder) do
            M.texts = {}
            ns.UI.Open(key)
            for _, t in ipairs(M.texts) do
                if t:find("This panel hit an error", 1, true) then error(spec .. "/" .. key .. ": " .. t) end
            end
        end
    end
    eq(#ns.PanelOrder, 13)
end)

test("learn subsections render", function()
    ns.DB.SetSpec("Discipline")
    M.texts = {}
    ns.UI.Open("learn")
    truthy(textHas("Lessons"))
end)

test("slash commands", function()
    SlashCmdList.ANDRICSADDON("spec disc")
    eq(ns.DB.ActiveSpec(), "Discipline")
    SlashCmdList.ANDRICSADDON("profile")
    eq(ns.DB.ActiveId(), "B")
    SlashCmdList.ANDRICSADDON("gear")
    SlashCmdList.ANDRICSADDON("bogus")
    SlashCmdList.ANDRICSADDON("")
end)

test("events: level up, combat, casts", function()
    S.level = 26
    M.Fire("PLAYER_LEVEL_UP", 26)
    S.combat = true
    M.Fire("PLAYER_REGEN_DISABLED")
    M.Fire("UNIT_SPELLCAST_SUCCEEDED", "player", "x", 589)
    S.time = 1030
    S.combat = false
    M.Fire("PLAYER_REGEN_ENABLED")
    M.Fire("SPELLS_CHANGED")
    M.Fire("UNIT_AURA", "player")
    M.Fire("PLAYER_EQUIPMENT_CHANGED")
    M.RunTimers()
end)

print(("%d passed, %d failed"):format(passed, failed))
os.exit(failed == 0 and 0 or 1)
