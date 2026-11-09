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
    truthy(M.events.ACTIVE_TALENT_GROUP_CHANGED, "dual-spec event registered")
    -- auto-switch follows the talent group (on by default) and can be turned off
    eq(ns.db.char.autoSwitch, true)
    eq(ns.DualSpec.IsAvailable(), true)
    S.numSpecGroups, S.specGroup = 2, 2
    eq(ns.DualSpec.HasDualSpec(), true)
    M.Fire("ACTIVE_TALENT_GROUP_CHANGED", 2, 1)
    eq(ns.DB.ActiveId(), "B")
    eq(ns.DB.ActiveSpec(), "Holy")
    S.specGroup = 1
    M.Fire("ACTIVE_TALENT_GROUP_CHANGED", 1, 2)
    eq(ns.DB.ActiveId(), "A")
    ns.db.char.autoSwitch = false
    M.Fire("ACTIVE_TALENT_GROUP_CHANGED", 2, 1)
    eq(ns.DB.ActiveId(), "A", "no switch when disabled")
    ns.db.char.autoSwitch = true
    S.specGroup = 2
    truthy(ns.DualSpec.Sync(), "sync to active group")
    eq(ns.DB.ActiveId(), "B")
    S.specGroup = 1
    ns.DualSpec.Sync()
    S.numSpecGroups = 1
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
    near(d.DAMAGE, 12 + 4 + 6, "explicit damage line present, so no extra 1/3 from healing")
    near(ns.Stats.Derive({ HEALING = 9 }).DAMAGE, 3, "healing-only item: 1/3 counts as damage")
    eq(d.HEALING, 21)
    local tbc = ns.Stats.ParseLines({ "x", "Equip: Increases healing done by up to 22 and damage done by up to 8 for all magical spells and effects." })
    near(ns.Stats.Derive(tbc).DAMAGE, 8, "explicit damage portion wins")
    eq(ns.Stats.ParseLines({ "x", "(16.5 damage per second)" }).WAND_DPS, 16.5)
    -- Forever wording (Death Speaker Robes): healing + its 1/3 damage on separate lines
    local fr = ns.Stats.ParseLines({ "Death Speaker Robes", "+11 Intellect",
        "Equip: Increases healing done by magical spells and effects by up to 20.",
        "Equip: Increases damage done by magical spells and effects by up to 7." })
    eq(fr.HEALING, 20, "Forever healing line parsed")
    local fd = ns.Stats.Derive(fr)
    eq(fd.HEALING, 20); eq(fd.DAMAGE, 7, "no double 1/3 conversion")
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
    truthy(all:find("UPGRADE", 1, true), all)
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

test("talent builds decode onto Forever's trees", function()
    truthy(#ns.Data.TalentTrees == 3, "three trees")
    local valid60 = 0
    for _, b in ipairs(ns.Data.DecodedBuilds) do
        if b.valid then
            for ti, tree in ipairs(ns.Data.TalentTrees) do
                eq(#b.trees[ti].points, #tree.talents, "points per talent")
                for i, t in ipairs(tree.talents) do truthy(b.trees[ti].points[i] <= t.max_rank) end
            end
            if b.level == 60 then valid60 = valid60 + 1 eq(b.total, 51) end
        end
        if b.spec == "Discipline" and b.purpose == "Level 30" then eq(b.valid, false, "stale build flagged") end
    end
    eq(valid60, 12)
    ns.DB.SetSpec("Shadow")
    M.texts = {}
    ns.UI.Open("talents")
    truthy(textHas("Shadowform"), "build list names talents")
    truthy(textHas("51 points"), "summary line")
end)

test("rotation shows only spells usable at your level", function()
    local saved = { level = S.level, known = S.known }
    S.level, S.known = 6, { [585] = true }
    eq(ns.Rotation.Availability("Smite", 6, "Undead"), "known")
    eq(ns.Rotation.Availability("Shadow Word: Pain", 6, "Undead"), "trainable")
    eq(ns.Rotation.Availability("Mind Blast", 6, "Undead"), nil)
    eq(ns.Rotation.Availability("Mind Flay (talent)", 30, "Undead"), nil, "talent not taken")
    eq(ns.Rotation.Availability("Starshards", 30, "Undead"), nil, "other race's racial")
    eq(ns.Rotation.Availability("Touch of Weakness", 12, "Undead"), "trainable")
    ns.DB.SetSpec("Shadow")
    ns.DB.Profile().rotationContext = "solo"
    M.texts = {}
    ns.UI.Open("rotation")
    truthy(not textHas(". Mind Blast"), "Mind Blast step hidden at level 6")
    truthy(textHas(". Smite"), "Smite step shown")
    truthy(textHas("unlock with levels or talents"))
    S.level, S.known = saved.level, saved.known
end)

test("gear: my-level view vs best overall", function()
    S.level = 24
    S.itemInfo[270261] = { equipLoc = "INVTYPE_ROBE", classID = 4, subclassID = 1, minLevel = 18 } -- Robes of the Disgraced Thane
    S.itemInfo[6682] = { equipLoc = "INVTYPE_ROBE", classID = 4, subclassID = 1, minLevel = 31 }   -- Death Speaker Robes
    S.itemLines["item:270261"] = { "Robes", "+6 Intellect", "+5 Spirit" }
    S.itemLines["item:6682"] = { "Robes", "+12 Intellect", "+10 Spirit" }
    ns.Stats.ClearCache()
    ns.DB.SetSpec("Holy")
    ns.UI.SetGearView("mine")
    M.texts = {}
    ns.UI.Open("gear")
    truthy(textHas("Robes of the Disgraced Thane"), "attainable item shown")
    truthy(not textHas("Death Speaker Robes"), "level-31 item hidden at 24")
    ns.UI.SetGearView("best")
    M.texts = {}
    ns.UI.Refresh()
    truthy(textHas("Death Speaker Robes"), "best overall includes higher-level items")
    ns.UI.SetGearView("mine")
end)

test("tooltip: what improves + equip call-out + level gate", function()
    ns.DB.SetSpec("Holy")
    ns.Stats.ClearCache()
    S.level = 30
    local all = table.concat(ns.Tooltip.LinesFor(NEW, "Holy", {}, 30, 10), "\n")
    truthy(all:find("What improves:", 1, true), all)
    truthy(all:find("+20 Healing power", 1, true), "healing gain line")
    truthy(all:find("What you'd lose:", 1, true), "spirit loss listed")
    truthy(all:find("-10 Spirit", 1, true))
    truthy(all:find("Equip this", 1, true), "equip call-out")
    eq(ns.Stats.Effect("INT", 10), "+150 max mana, +0.17% spell crit")
    eq(ns.Stats.Effect("SPI", 4), "+1.0 mana per 2 sec while not casting")
    -- same item but level 40 required
    S.itemInfo[1001].minLevel = 40
    ns.Stats.ClearCache()
    all = table.concat(ns.Tooltip.LinesFor(NEW, "Holy", {}, 30, 10), "\n")
    truthy(not all:find("Equip this", 1, true), "can't equip yet")
    truthy(all:find("Upgrade once you reach level 40", 1, true), all)
    S.itemInfo[1001].minLevel = nil
    ns.Stats.ClearCache()
end)

test("bags: highlight + one-time announcement", function()
    ns.DB.SetSpec("Holy")
    S.level = 30
    S.bagSlots = { [0] = { NEW, PLATE } }
    ns.Bags.Reset()
    local printed = 0
    local realPrint = ns.Print
    ns.Print = function(m) if tostring(m):find("Upgrade in your bags", 1, true) then printed = printed + 1 end end
    local found = ns.Bags.Scan(false)
    eq(#found, 1, "robe is an upgrade, plate is not")
    ns.Bags.Scan(false)
    eq(printed, 1, "announced once")
    ns.Print = realPrint
    ns.Bags.RefreshAll()
    truthy(rawget(M.bagButtons[1], "AndricsUpgrade") and rawget(M.bagButtons[1], "AndricsUpgrade").__shown, "upgrade highlighted")
    truthy(not (rawget(M.bagButtons[2], "AndricsUpgrade") and rawget(M.bagButtons[2], "AndricsUpgrade").__shown), "plate not highlighted")
    ns.db.global.bags.highlight = false
    ns.Bags.RefreshAll()
    truthy(not rawget(M.bagButtons[1], "AndricsUpgrade").__shown, "toggle off hides it")
    ns.db.global.bags.highlight = true
    S.bagSlots = {}
end)

test("gear detail: sources, quest pin, dungeon entrance pin", function()
    -- fixtures shaped like research/item_sources.json
    ns.Data.ItemSources[6629] = { drops = { { npc = "Lady Anacondra", npc_id = 3671, chance = "12%" } }, source_url = "https://db.icy-veins.com/wow-forever/items/6629", checked = "2026-11-09" }
    ns.Data.ItemSources[15444] = { quests = { { name = "Hidden Enemies", quest_id = 5730, choice = true } }, source_url = "x", checked = "2026-11-09" }
    ns.Data.QuestSources[5730] = { level = 20, faction = "Horde", zone = "Riverglades", start_npc = "Thrall",
        pins = { { zone = "Riverglades", label = "Start: Thrall", x = 31.5, y = 37.8 } }, source_url = "y", checked = "2026-11-09" }
    S.faction = "Horde"
    ns.DB.SetSpec("Holy")
    ns.UI.OpenGearDetail(6629) -- Sporid Cape, Wailing Caverns in the research
    M.texts = {}
    ns.UI.Open("gear")
    truthy(textHas("Drops from Lady Anacondra in Wailing Caverns"), "drop + dungeon")
    truthy(textHas("Entrance: Wailing Caverns"), "entrance found from client map data")
    local e = ns.Map.FindDungeonEntrance("Wailing Caverns")
    M.waypoints = {}
    truthy(ns.Map.SetWaypoint(e.mapID, e.x, e.y, "WC"))
    eq(M.waypoints[1].mapID, 10); eq(M.superTracked, true)
    ns.UI.OpenGearDetail(15444)
    M.texts = {}
    ns.UI.Refresh()
    truthy(textHas("Quest reward: Hidden Enemies"), "quest source")
    truthy(textHas("Starts with Thrall in Riverglades"), "quest giver")
    truthy(textHas("gear guide lists quest 5726"), "research/IV quest id mismatch flagged")
    eq(ns.Map.FindZone("Riverglades"), 2200)
    ns.UI.OpenGearDetail(nil)
end)

test("fortitude button: picks the next player who needs it", function()
    local saved = { target = S.target, known = S.known, auras = S.auras }
    S.target = false
    S.known = { [1243] = true }
    S.units = {
        party1 = { guid = "G1", name = "Bram", player = true, friend = true, range = true, buffs = {}, dist = 400 },
        party2 = { guid = "G2", name = "Cora", player = true, friend = true, range = false, buffs = {}, dist = 4000 },
        party3 = { guid = "G3", name = "Dax", player = true, friend = true, range = true, buffs = { ["Power Word: Fortitude"] = true }, dist = 100 },
        party4 = { guid = "G4", name = "Eli", player = true, friend = true, range = true, buffs = {}, dist = 50, dead = true },
        nameplate1 = { guid = "N1", name = "Stranger", player = true, friend = true, range = true, buffs = {} },
        nameplate2 = { guid = "N2", name = "Wolf", player = false, friend = false, range = true, buffs = {} },
    }
    S.auras = {} -- you lack it too
    local pick = ns.Fort.Pick(100)
    eq(pick.unit, "player", "yourself first")
    S.auras = { ["Power Word: Fortitude"] = true }
    pick = ns.Fort.Pick(100)
    eq(pick.unit, "party1", "nearest group member who needs it (Dax has it, Eli dead, Cora out of range)")
    -- button attributes follow the pick
    ns.Fort.Refresh()
    local b = _G.AndricsFortButton
    eq(b:GetAttribute("type"), "macro"); eq(b:GetAttribute("unit"), "party1")
    eq(b:GetAttribute("macrotext"), "/cast [@party1,help,nodead] Power Word: Fortitude")
    eq(b:GetAttribute("useOnKeyDown"), nil, "acts on release")
    -- pressing it moves on to the next (stranger with nameplate) right away
    b.__scripts.PostClick(b, "LeftButton", false)
    pick = ns.Fort.Pick(GetTime())
    eq(pick.unit, "nameplate1", "after casting on Bram, next is the stranger")
    -- strangers are reached by name, then the old target is restored/cleared
    ns.Fort.Update()
    eq(b:GetAttribute("macrotext"), "/targetexact Stranger\n/cast [@target,help,nodead] Power Word: Fortitude\n/cleartarget")
    S.units.nameplate1.realm = "Argent Dawn"
    S.target = true
    eq(ns.Fort.MacroText("nameplate1", "Stranger-Argent Dawn", true), "/targetexact Stranger-Argent Dawn\n/cast [@target,help,nodead] Power Word: Fortitude\n/targetlasttarget")
    S.target = false
    eq(ns.Fort.MacroText("party2", "Cora", false), "/cast [@party2,help,nodead] Power Word: Fortitude", "group members stay direct")
    eq(ns.Fort.ConditionCheck("party1"), "pass (party1)")
    -- in combat the target can't change
    S.combat = true
    S.units.nameplate1.buffs = { ["Power Word: Fortitude"] = true }
    ns.Fort.Update()
    eq(b:GetAttribute("unit"), "nameplate1", "frozen in combat on the last pick")
    S.combat = false
    -- everyone buffed except Cora (out of range)
    S.units.party1.buffs = { ["Power Word: Fortitude"] = true }
    local none, reason = ns.Fort.Pick(GetTime() + 10)
    eq(none, nil)
    truthy(reason:find("out of range", 1, true), reason)
    S.units.party2.buffs = { ["Prayer of Fortitude"] = true }
    none, reason = ns.Fort.Pick(GetTime() + 10)
    eq(reason, "everyone nearby is buffed", "Prayer of Fortitude counts")
    ns.Fort.Update()
    eq(b:GetAttribute("type"), nil, "button disarmed when nobody needs it")
    -- click diagnostics: error text, blocked action, nothing at all, success
    local said = {}
    local realPrint = ns.Print
    ns.Print = function(m) table.insert(said, tostring(m)) end
    S.units.party1.buffs = {}
    ns.Fort.Update()
    b.__scripts.PostClick(b, "LeftButton", false)
    M.Fire("UI_ERROR_MESSAGE", 51, "Target is too low level")
    M.RunTimers()
    truthy(table.concat(said, "\n"):find("failed:|r Target is too low level", 1, true), table.concat(said, "\n"))
    said = {}
    ns.Fort.Watch({ name = "Bram", unit = "party1" })
    M.Fire("ADDON_ACTION_BLOCKED", "AndricsAddon", "CastSpellByName()")
    M.RunTimers()
    truthy(table.concat(said, "\n"):find("blocked", 1, true))
    said = {}
    ns.Fort.Watch({ name = "Bram", unit = "party1" })
    M.RunTimers()
    truthy(table.concat(said, "\n"):find("no cast started", 1, true))
    said = {}
    ns.Fort.Watch({ name = "Bram", unit = "party1" })
    S.spellNames = { [1243] = "Power Word: Fortitude", [10938] = "Power Word: Fortitude" }
    M.Fire("UNIT_SPELLCAST_SENT", "player", "Bram", "guid", 10938)
    M.RunTimers()
    eq(#said, 0, "success is silent")
    S.spellNames = nil
    ns.Print = realPrint
    ns.Fort.Debug()
    -- key binding: override click on the button, saved per character
    eq(ns.Fort.KeyString("LSHIFT"), nil, "modifier alone ignored")
    S.shift = true
    eq(ns.Fort.KeyString("F"), "SHIFT-F")
    S.shift = false
    ns.Fort.SetKey("SHIFT-F")
    eq(M.overrides["SHIFT-F"], "AndricsFortButton:LeftButton")
    eq(ns.db.char.fortButton.key, "SHIFT-F")
    eq(b.hotkey:GetText(), "SHIFT-F", "shown on the button")
    ns.Fort.SetKey(nil)
    eq(next(M.overrides), nil, "cleared")
    S.combat = true
    ns.Fort.SetKey("G")
    eq(ns.db.char.fortButton.key, nil, "can't rebind in combat")
    S.combat = false
    ns.Fort.StartKeyCapture()
    local cap = _G.AndricsFortKeyCapture
    cap.__scripts.OnKeyDown(cap, "G")
    eq(ns.db.char.fortButton.key, "G", "captured key saved")
    ns.Fort.SetKey(nil)
    -- old macro cleanup: removes ours, keeps someone else's
    M.macros = { { name = "AndricsFort", body = "#showtooltip Power Word: Fortitude\n/click AndricsFortButton" } }
    ns.db.char.fortButton.macroRemoved = false
    ns.Fort.RemoveOldMacro()
    eq(#M.macros, 0, "old macro removed")
    M.macros = { { name = "AndricsFort", body = "/say hi" } }
    ns.db.char.fortButton.macroRemoved = false
    ns.Fort.RemoveOldMacro()
    eq(#M.macros, 1, "user's own macro with that name is kept")
    M.macros = {}
    S.units, S.target, S.known, S.auras = {}, saved.target, saved.known, saved.auras
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
