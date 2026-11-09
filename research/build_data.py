import json
C="2026-11-09"
S={
"bz_deep":"https://news.blizzard.com/en-us/article/24301514/world-of-warcraft-forever-class-deep-dives-priest-and-warrior",
"bz_launch":"https://news.blizzard.com/en-us/article/24302093",
"bz_hotfix":"https://news.blizzard.com/en-us/article/24315281/wow-forever-hotfixes-november-6-2026",
"bz_dev":"https://us.forums.blizzard.com/en/wow/t/wow-forever-beta-development-notes-%E2%80%93-updated-november-2/2360696",
"bz_tuning":"https://us.forums.blizzard.com/en/wow/t/class-tuning-incoming-november-10/2404092",
"bz_dungxp":"https://us.forums.blizzard.com/en/wow/t/dungeon-enemy-xp-increased-november-8/2406595",
"bz_known":"https://us.forums.blizzard.com/en/wow/t/2402363",
"iv_overview":"https://www.icy-veins.com/wow-forever/priest-class-overview",
"iv_shadow_lvl":"https://www.icy-veins.com/wow-forever/shadow-priest-leveling",
"iv_disc_lvl":"https://www.icy-veins.com/wow-forever/discipline-priest-leveling",
"iv_holy_lvl":"https://www.icy-veins.com/wow-forever/holy-priest-leveling",
"iv_quests":"https://www.icy-veins.com/wow-forever/priest-class-quests",
"iv_forever":"https://www.icy-veins.com/wow-forever/wow-forever-overview",
"iv_roadmap":"https://www.icy-veins.com/wow-forever/roadmap",
"iv_raids":"https://www.icy-veins.com/wow-forever/raid-overview",
"iv_dungeons":"https://www.icy-veins.com/wow-forever/dungeons-overview",
"iv_zones":"https://www.icy-veins.com/wow-forever/zones-and-maps",
"iv_races":"https://www.icy-veins.com/wow-forever/race-guide",
"iv_prof":"https://www.icy-veins.com/wow-forever/professions-overview",
"iv_camping":"https://www.icy-veins.com/wow-forever/camping",
"iv_legacy":"https://www.icy-veins.com/wow-forever/legacy-system",
"ivdb":"https://db.icy-veins.com/wow-forever/",
"wh_shadow":"https://www.wowhead.com/forever/guide/classes/priest/shadow/overview",
"wh_abil":"https://www.wowhead.com/forever/guide/classes/priest/shadow/abilities",
"wh_talents":"https://www.wowhead.com/forever/guide/classes/priest/shadow/talent-builds",
"wh_disc_talents":"https://www.wowhead.com/forever/guide/classes/priest/discipline/talent-builds",
"wh_holy_talents":"https://www.wowhead.com/forever/guide/classes/priest/holy/talent-builds",
"wh_l20":"https://www.wowhead.com/forever/guide/classes/priest/shadow/level-20",
"wh_l30":"https://www.wowhead.com/forever/guide/classes/priest/shadow/level-30",
"wh_stats":"https://www.wowhead.com/forever/guide/classes/priest/shadow/stat-priority",
"wh_ench":"https://www.wowhead.com/forever/guide/classes/priest/shadow/enchants-consumables",
"wh_bis":"https://www.wowhead.com/forever/guide/classes/priest/shadow/bis-gear",
"wh_lvltips":"https://www.wowhead.com/forever/guide/classes/priest/shadow/leveling-tips",
"wh_riding":"https://www.wowhead.com/forever/guide/riding-mounts",
"wh_rss":"https://www.wowhead.com/news/rss/forever",
"wh_nogold":"https://www.wowhead.com/forever/news/quests-give-no-gold-at-level-60-in-wow-forever-intentional-change-according-to-383803",
"wh_taldramir":"https://www.wowhead.com/forever/news/taldramir-the-whispering-wood-revealed-as-wow-forever-legendary-383747",
"ui_src":"https://github.com/Gethe/wow-ui-source/tree/forever",
"taut":"https://github.com/Tautellini/TautelliniAddons/blob/main/docs/forever-addon-development.md",
"questie":"https://github.com/Questie/Questie",
"dbm":"https://github.com/DeadlyBossMods/DeadlyBossMods",
"details":"https://github.com/Tercioo/Details-Damage-Meter",
"bigwigs":"https://github.com/BigWigsMods/BigWigs",
"weakauras":"https://github.com/WeakAuras/WeakAuras2",
"fstatus":"https://foreverstatus.com/addons",
}
def R(src,**kw):
    d=dict(kw); d["source_url"]=S[src] if src in S else src; d["checked"]=C; return d

meta=R("ui_src",game="World of Warcraft: Forever",launch="2026-11-04 15:00 PST",
  client_version="1.60.1",latest_build_seen="1.60.1.70862 (wow-ui-source forever branch commit 2026-11-07T04:46Z = Nov 6, 10:46 PM CST)",
  launch_build="1.60.1.70790",toc_interface=16001,wow_project_id="18 (WOW_PROJECT_CAMELOT)",
  toc_suffixes=["_Forever.toc","_Camelot.toc"],toc_game_type=["forever","camelot"],toc_family="mainline",
  api_note="Mainline (modern) UI architecture; Midnight addon restrictions (secret values) apply per Tautellini doc - verify in client",
  max_level=60,notes="Interface/suffix/game-type values from Tautellini doc (community) cross-checked with Questie_Forever.toc, Details_Camelot.toc, BigWigs and DBM TOCs listing 16001.")

racials=[
 R("bz_deep",race="Human",level=10,spell="Divine Grace",wowhead_spell_id=1277370,ivdb_spell_id=1277378,quest="Divine Grace",quest_id=94773,effect="Instant heal on an ally below 50% health that removes Weakened Soul; not usable on self; 5 min CD"),
 R("bz_deep",race="Human",level=20,spell="Feedback",wowhead_spell_id=13896,ivdb_spell_id=19275,quest="Arcane Feedback",quest_id=5676),
 R("bz_deep",race="Dwarf",level=10,spell="Desperate Prayer",wowhead_spell_id=13908,ivdb_spell_id=19243,quest="Desperate Prayer",quest_id=5634),
 R("bz_deep",race="Dwarf",level=20,spell="Chastise",wowhead_spell_id=1277331,ivdb_spell_id=1277335,quest="Chastise",quest_id=5641,effect="Damage + 2s root, Humanoids only, 2 min CD"),
 R("bz_deep",race="Gnome",level=10,spell="Confounding Flash",wowhead_spell_id=1277455,quest="Confounding Flash",quest_id=94817,effect="Confuses up to 5 enemies for 3s, 0.5s cast, 2 min CD"),
 R("bz_deep",race="Gnome",level=20,spell="Contingency Plan",wowhead_spell_id=1277462,ivdb_spell_id=1277640,quest="Contingency Plan",quest_id=94820,effect="Ward that triggers below 35% health: absorb + HoT. CD 5 min per Blizzard; Wowhead lists 10 min (conflict)"),
 R("bz_deep",race="Night Elf",level=10,spell="Starshards",wowhead_spell_id=10797,ivdb_spell_id=19305,quest="Stars of Elune",quest_id=5627,effect="Damage increased; now 30s CD"),
 R("bz_deep",race="Night Elf",level=20,spell="Elune's Grace",wowhead_spell_id=2651,quest=None,quest_id=None,effect="50% reduced chance to be hit by melee/ranged for 15s or 3 misses; 5 min CD"),
 R("bz_deep",race="Troll",level=10,spell="Hex of Weakness",wowhead_spell_id=9035,ivdb_spell_id=19285,quest="Hex of Weakness",quest_id=5652),
 R("bz_deep",race="Troll",level=20,spell="Shadowguard",wowhead_spell_id=18137,ivdb_spell_id=19312,quest="Shadowguard",quest_id=5642),
 R("bz_deep",race="Undead",level=10,spell="Touch of Weakness",wowhead_spell_id=2652,ivdb_spell_id=19266,quest="Touch of Weakness",quest_id=5658),
 R("bz_deep",race="Undead",level=20,spell="Dark Sacrifice",wowhead_spell_id=1277324,ivdb_spell_id=1277328,quest="Dark Sacrifice",quest_id=5644,effect="Converts health to mana, scales with Spirit; no longer breaks CC (Nov 3)"),
]
race_passive_changes=[R("bz_dev",date="2026-10-26/27",change=c) for c in [
 "Human: Spirit bonus 10% (was 5%); Ruthless 1% crit","Dwarf: gains Artisan's Precision +1% hit","Troll: Berserking lasts 15s","Undead: Touch of the Grave ICD 15s"]]
race_recs=R("iv_races",shadow="Alliance races roughly equal (Dwarf edge vs Beasts); Horde: Undead marginally ahead, Troll better vs Beasts / with Shadowguard",
  healer="Undead, Troll, Human, Gnome recommended; Gnome has Eureka! and Expansive Mind (+5% mana)",not_priest="Skyborne cannot be a Priest")

quests=[]
robe={"Night Elf":("In Favor of Elune",5622,"Garments of the Moon",5621,"Moon Robes of Elune",16604),
 "Human/Dwarf/Gnome":("In Favor of the Light",5623,"Garments of the Light",5624,"Friar's Robes of the Light",16605),
 "Troll":("In Favor of Spirituality",5649,"Garments of Spirituality",5648,"Juju Hex Robes",16606),
 "Undead":("In Favor of Darkness",5651,"Garments of Darkness",5650,"Acolyte's Sacrificial Robes",16607)}
for race,(a,ai,b,bi,it,iid) in robe.items():
    quests.append(R("iv_quests",type="class",level=4,races=race,name=a,quest_id=ai))
    quests.append(R("iv_quests",type="class",level=4,races=race,name=b,quest_id=bi,reward=it,reward_item_id=iid))
for r in racials:
    if r["quest_id"]: quests.append(R("iv_quests",type="class-racial",level=r["level"],races=r["race"],name=r["quest"],quest_id=r["quest_id"],reward_spell=r["spell"]))
quests.append(R(S["ivdb"]+"quests/95613",type="reagent",level=38,min_level=36,faction="Alliance",zone="Riverglades",name="Keeping the Light On",quest_id=95613,notes="Bring 5 Holy Candles to Sister Rowland, Farholde Keep"))
class_trainers=R("iv_quests",turn_in_npcs=["Laurena (Stormwind)","Rohan (Ironforge)","Mims (Ironforge, Gnome)","Alathea (Darnassus)","Ur'kyo (Orgrimmar)","Aelthalyste (Undercity)"])

ranks=[("Smite",585,10934,[1,6,14,22,30,38,46,54]),("Power Word: Fortitude",1243,10938,[1,12,24,36,48,60]),("Lesser Heal",2050,2053,[1,4,10]),
("Shadow Word: Pain",589,10894,[4,10,18,26,34,42,50,58]),("Power Word: Shield",17,10901,[6,12,18,24,30,36,42,48,54,60]),
("Fade",586,10942,[8,20,30,40,50,60]),("Renew",139,25315,[8,14,20,26,32,38,44,50,56,60]),("Mind Blast",8092,10947,[10,16,22,28,34,40,46,52,58]),
("Resurrection",2006,20770,[10,22,34,46,58]),("Inner Fire",588,10952,[12,20,30,40,50,60]),("Cure Disease",528,2870,[14]),
("Psychic Scream",8122,10890,[14,28,42,56]),("Heal",2054,6064,[16,22,28,34]),("Dispel Magic",527,988,[18,36]),
("Devouring Plague",2944,19280,[20,28,36,44,52,60]),("Mind Flay (talent)",15407,18807,[20,28,36,44,52,60]),("Fear Ward",6346,6346,[20]),
("Flash Heal",2061,10917,[20,26,32,38,44,50,56]),("Holy Fire",14914,15261,[20,24,30,36,42,48,54,60]),("Mind Soothe",453,10953,[20,36,52]),
("Shackle Undead",9484,10955,[20,40,60]),("Mind Vision",2096,10909,[22,44]),("Mana Burn",8129,10876,[24,32,40,48,56]),
("Divine Spirit",14752,27841,[30,40,50,60]),("Shadow Protection",976,10958,[30,42,56]),("Mind Control",605,10912,[30,44,58]),
("Prayer of Healing",596,25316,[30,40,50,60]),("Shadow Word: Death",1309595,1309636,[32,40,48,56]),("Abolish Disease",552,552,[32]),
("Levitate",1706,1706,[34]),("Greater Heal",2060,25314,[40,46,52,58,60]),("Prayer of Fortitude",21562,21564,[48,60]),
("Prayer of Shadow Protection",27683,27683,[56]),("Prayer of Spirit",27681,27681,[60])]
spells=[R("iv_shadow_lvl",name=n,wowhead_base_spell_id=b,ivdb_max_rank_id=m,rank_learn_levels=l,id_source=S["wh_abil"]) for n,b,m,l in ranks]
spells[ [s["name"] for s in spells].index("Prayer of Healing") ]["notes"]="IV lists a 5th rank at 60, likely from a book (unconfirmed)"
spells[ [s["name"] for s in spells].index("Prayer of Fortitude") ]["notes"]="Taught by Codex: Prayer of Fortitude (17413) r1 / Codex II (17414) r2; Holy Candle r1, Sacred Candle r2"
spells[ [s["name"] for s in spells].index("Prayer of Shadow Protection") ]["notes"]="Taught by Codex 22393; Sacred Candle"
spells[ [s["name"] for s in spells].index("Shadow Word: Death") ]["notes"]="Baseline at 32 in Forever; 18s CD; backlash 30% max HP if target survives, none on miss (Nov 3)"
talent_spells=[R("wh_abil",name=n,spell_id=i) for n,i in [("Shadowform",15473),("Vampiric Embrace",15286),("Silence",15487),("Holy Nova",15237),("Inner Focus",14751),("Power Infusion",10060),("Penance (Wowhead id)",402284),("Penance (IV db id)",402174),("Prayer of Mending (Wowhead shadow page)",401863),("Prayer of Mending (IV db)",401859),("Prayer of Mending (Wowhead holy builds)",1240827),("Binding Heal (replaced by Holy Binding Nov 3)",401937),("Spirit Tap",15270),("Meditation",14521),("Wand Specialization (IV db)",6057),("Wand Specialization (Wowhead)",14524),("Twilight Focus",14913),("Shadow Focus",15260),("Blackout",15326),("Devouring Contagion",1309950),("Dark Inspiration",1326159),("Mental Strength",18551),("Twin Disciplines",1225132),("Divine Aegis",431622),("Renewed Hope",425280),("Litany of Light",1317006),("Holy Precision",1309957),("Spiritual Guidance",14901),("Spirit of Redemption",20711),("Inspiration",14892),("Soul Warding",402000),("Power in Light",1309969),("Searing Light",14909),("Improved Renew",14908),("Holy Specialization",14889),("Silent Resolve",14523),("Improved Power Word: Shield",14748)]]
milestones=R("iv_shadow_lvl",items=[{"level":10,"what":"Talents start; level-10 racial quest; Mind Blast"},{"level":12,"what":"Inner Fire"},{"level":20,"what":"Level-20 racial quest; Fear Ward + Devouring Plague baseline; earliest Mind Flay talent"},{"level":30,"what":"Divine Spirit + Shadow Protection"},{"level":32,"what":"Shadow Word: Death baseline"},{"level":40,"what":"Shadowform (31-pt Shadow); Dual Spec; Apprentice Riding"},{"level":60,"what":"Journeyman Riding (epic)"}],
  talent_milestones="11/16/21/31-point milestones (Blizzard deep dive)",trainer_costs="Total 1-60 training ~206-207g for every class (Blizzard Nov 3 notes); per-rank costs not sourced")

TC="https://www.wowhead.com/forever/talent-calc/priest/"
b=[("Shadow","Leveling","vkndmh02330500003-3-30542201201312051_t0/0B2CEFahJaaNmdQdddSt0cccDffM1A2p0fff","wh_talents"),
("Shadow","Raid","v200530400003-3-50042201251302051_t0/2AEFddddhJNmKQSt0CDffM1A0ff","wh_talents"),
("Shadow","Dungeon","v200530200003--50542201251302051_t0/2AEFddddhJNmKQSt0CDffM2C","wh_talents"),
("Shadow","PvP","v200530020033-3-55002221201312051_t0/2B0CDGKmm2EFahGJmN1A2aQpaaSt0m2a","wh_talents"),
("Discipline","Leveling","v2520015031333011-30505110102-005_t0/0BaaaeffffMjkNkkrq1AccEf2C0Haa1cccgM0f1j","wh_disc_talents"),
("Discipline","Raid","v2005005031330011531-0350501303_t0/0CFMKjqhhrSThv1CEHbbKbg","wh_disc_talents"),
("Discipline","Dungeon","v2025015021330011531-0150510303_t0/0BcccFeMjKqcrS1CEfHbK0Tcvhh","wh_disc_talents"),
("Discipline","PvP","v20053002013332115-320501320001-05_t0/0CDGjKMqPNr1AbbDGfhn2B0S1h","wh_disc_talents"),
("Discipline","Level 30","v2520013001305001_t0/0effkfkjAkNr","wh_disc_talents"),
("Holy","Leveling","vkndmh02500500103-03505103230121531_t5/1n","wh_holy_talents"),
("Holy","Raid","v200500500133001-10505103230121531_t0/0cccFKjM1CEHKfPRSqt0cc1naJ0q","wh_holy_talents"),
("Holy","Dungeon","v2025005001330011-0350510303002053_t0/0BcccFKjMqccr1CEHbbKfbPRS","wh_holy_talents"),
("Holy","PvP","v2005305201333011331-3020511302_t0/0CFKjMqNrsssTGv1AccEfgHkk0D","wh_holy_talents"),
("Holy","Level 30","v2-03505103200101_t0/1BccEcccfHJnq","wh_holy_talents")]
builds=[R(s,spec=a,purpose=p,talent_calc_url=TC+c) for a,p,c,s in b]
builds.append(R("iv_shadow_lvl",spec="Alt route",purpose="Leveling",notes="Disc/Meditation first, respec Shadow at 40 (respec 1g, rising). Order: 2 Wand Spec, 5 Spirit Tap, 5 Twin Disciplines, 3 Mental Strength, 3 Meditation",talent_calc_url="https://www.icy-veins.com/wow-forever/talent-calculator"))
builds.append(R("iv_disc_lvl",spec="Discipline",purpose="Leveling option",notes="Optional respec at 35 to go deep Discipline for Penance, keeping 5 Spirit Tap; Twilight Focus if solo / Silent Resolve in groups"))

talent_changes=[R("bz_deep",tree=t,change=c) for t,c in [
("Discipline","Penance is the 21-point talent (2s channel, 12s CD); Power Infusion requires Penance"),("Discipline","Soul Warding is the 16-point talent"),
("Discipline","New: Divine Aegis, Renewed Hope, Twin Disciplines, Power in Light, Holy Precision (up to 18% hit)"),
("Discipline","Wand Specialization 2 points / 13%; Mental Strength = 2-10% Intellect (Oct 16)"),("Discipline","Removed: Unbreakable Will, Improved PW:Fortitude, Force of Will"),
("Holy","Twilight Focus (was Healing Focus): 3 pts, 70% pushback protection, all spells"),("Holy","Prayer of Mending 31-point: 10s CD, 5 jumps"),
("Holy","Binding Heal replaced by Holy Binding (Nov 3): Flash Heal on others heals you for 50%"),("Holy","New Litany of Light; Spiritual Guidance damage ~1/3 of healing bonus; removed Improved Prayer of Healing and Lightwell"),
("Shadow","Shadow Focus gives hit; Vampiric Embrace 16-point (30s, 30s CD, unresistable)"),("Shadow","New: Improved Mind Flay (each tick +10/20%), Devouring Contagion (spreads DP to 2), Early Demise, Dark Inspiration (party Spirit 3-15%)"),
("Shadow","Shadowform: Shadow spells 50% cheaper, +100% crit damage bonus, non-healing spells usable"),("Baseline","Fade threat reduction doubled; Prayer of Healing heals target's party; Renew from multiple Priests stacks")]]

rot=R("wh_lvltips",shadow="Buffs (Fortitude, Inner Fire) > PW:Shield > Mind Blast > SW:Pain > Devouring Plague* > Mind Flay* (*mana allowing) > wand. Before Mind Flay open with Smite. AoE = multi-dot SW:Pain.",
 holy=("Fort + Inner Fire > PW:S > Holy Fire > Smite > Mind Blast > SW:P > wand; AoE: Holy Nova on Searing Light procs", S["iv_holy_lvl"]),
 disc_heal=("PW:S as needed > Penance (first tick instant) > Heal > Renew", S["iv_disc_lvl"]),
 mana="Five-second rule; out-of-casting regen = Spirit/4 + 12.5 per 2s (Wowhead). Wands do not scale with spell damage (Sep 24 dev notes).")

zones=[R("iv_zones",levels=l,alliance=a,horde=h,dungeons=d) for l,a,h,d in [
("10-13","Loch Modan / Darkshore","The Barrens","Hall of Thanes / Ragefire Chasm"),("14-17","Westfall / Darkshore","Silverpine Forest","Hall of Thanes / Ragefire + Ruins of Lordaeron"),
("18-20","Westfall / Redridge","The Barrens / Stonetalon","Hall of Thanes / Wailing Caverns"),("21-23","Redridge / Duskwood","Hillsbrad / Stonetalon","Stockade / Shadowfang + Wailing Caverns"),
("24-26","Ashenvale / Duskwood","Ashenvale / Duskwood","BFD + Stockade / BFD + Shadowfang"),("27-28","Wetlands / Ashenvale","Hillsbrad / Wetlands","Excavation Site + BFD"),
("29-30","Wetlands / Ashenvale","Wetlands / Thousand Needles","Excavation Site + Gnomeregan / Excavation Site + Razorfen Kraul")]]
new_zones=[R("iv_forever",zone=z,levels=l,notes=n) for z,l,n in [("Zephras Isle","1-12","Skyborne start"),("Riverglades","35-45",""),("Shen'Dralas","?","Between Mulgore/Desolace and Feralas; quests for Maraudon and Razorfen Downs"),("Mount Hyjal","60","Barrow Deeps / Hyjal Summit raids")]]
D=[("Ragefire Chasm","13-18",0),("Hall of Thanes","13-20",1),("Ruins of Lordaeron","15-22",1),("Wailing Caverns","15-24",0),("The Deadmines","17-26",0),("Shadowfang Keep","20-30",0),("Blackfathom Deeps","24-32",0),("The Stockade","24-32",0),("Excavation Site: Wetlands","26-33",1),("City of Dalaran","28-35",1),("Gnomeregan","29-38",0),("Razorfen Kraul","29-38",0),("SM Graveyard","30-38",0),("SM Library","33-41",0),("The Drowned City","35-40",1),("SM Armory","36-44",0),("Razorfen Downs","37-46",0),("SM Cathedral","38-46",0),("Krol'dok Stronghold","40-45",1),("Uldaman","41-51",0),("Zul'Farrak","44-54",0),("Maraudon","46-55",0),("Alcaz Island Prison","48-53",1),("Sunken Temple","50-60",0),("Blackrock Depths","52-60",0),("Dire Maul East","54-60",0),("Blackmaw Hold","55-60",1),("Lower Blackrock Spire","55-60",0),("Dire Maul North/West","56-60",0),("Scholomance","58-60",0),("Shaper's Terrace","58-60",1),("Stratholme","58-60",0),("Upper Blackrock Spire","59-60",0)]
dungeons=[R("iv_dungeons",name=n,levels=l,new_in_forever=bool(x)) for n,l,x in D]
raids=[R("iv_roadmap",name="Barrow Deeps",size=10,bosses=8,location="Mount Hyjal",opens="2026-12-09"),R("iv_roadmap",name="Hyjal Summit",size=20,bosses=13,location="Mount Hyjal",opens="2026-12-09",notes="Has a legendary"),R("iv_roadmap",name="Onyxia's Lair",size=40,location="Dustwallow Marsh",opens="2026-12-09")]
raid_rules=R("iv_raids",rules=["No world buffs in raids","No heroic/flex modes","Item stats hidden until first looted"])
roadmap=[R("iv_roadmap",when=w,what=x) for w,x in [("2026-11-04","Launch: level 60 cap, dungeons, PvP"),("2026-12-09","Raids: Barrow Deeps, Hyjal Summit, Onyxia's Lair"),("Winter 2026","Hardcore ruleset"),("Spring 2027","2 raids (10/20), 2 dungeons, new zone/quests, legendary questline, PvP season refresh"),("Summer 2027","Revamped iconic raid, new raid, 2 dungeons, profession and Legacy updates")]]

def items(src,bracket,rows):
    return [R(src,bracket=bracket,name=n,item_id=i,source=s) for n,i,s in rows]
gear=items("wh_l20","level 20",[("Ephemeral Choker",270227,"Hall of Thanes"),("Aetherwisp Bracers",271096,"Hall of Thanes"),("Golemheart Stave",270228,"Hall of Thanes"),("Fang of Magmatus",271095,"Hall of Thanes"),("Robes of the Disgraced Thane",270261,"Hall of Thanes"),
("Crystalline Cuffs",14148,"Ragefire Chasm"),("Robe of Evocation",14150,"Ragefire Chasm"),("Searing Dagger",273003,"Ragefire Chasm"),("Satyrskin Cloak",273005,"Ragefire Chasm"),
("Leftover Abomination Skin",271206,"Ruins of Lordaeron"),("Tuskwrap Belt",271210,"Ruins of Lordaeron"),("Rotmender's Treads",271214,"Ruins of Lordaeron"),("Coldspire Staff",271215,"Ruins of Lordaeron"),("Rotmender's Leggings",271207,"Ruins of Lordaeron"),
("Snake Eye Kaleidoscope",273088,"Wailing Caverns"),("Slither Cord",273089,"Wailing Caverns"),("Sporid Cape",6629,"Wailing Caverns"),("Slime-encrusted Pads",6461,"Wailing Caverns"),("Deep Fathom Ring",6463,"Wailing Caverns"),("Feyscale Cloak",6632,"Wailing Caverns"),("Firebelcher",5243,"Wailing Caverns"),
("Buzzer Blade",2169,"Deadmines"),("Lavishly Jeweled Ring",1156,"Deadmines"),("Emberstone Staff",5201,"Deadmines"),("Cookie's Stirring Rod",5198,"Deadmines"),("Lookie's Spyglass",273298,"Deadmines"),
("Deepblaze",279896,"Quest (Hall of Thanes)"),("Dwarven Tome",279898,"Quest"),("Tomb Robber's Gloves",280096,"Quest"),("Staff of Orgrimmar",15444,"Quest 5726 Hidden Enemies"),("Featherbead Bracers",15452,"Quest 5724"),("Ghastly Trousers",15449,"Quest 5725"),
("Blight Gloves",279877,"Quest"),("Slain Baron's Signet",279867,"Quest"),("Gnarled Necromancer's Staff",251534,"Quest"),("Tabitha's Cuffs",251486,"Quest"),("Sizzle Stick",8071,"Quest 1487"),("Talbar Mantle",10657,"Quest 6981"),("Crescent Staff",6505,"Quest 914"),("Apothecary Gloves",10919,"Quest 962"),("Sable Wand",7607,"Quest 2040"),("Staff of Westfall",2042,"Quest 166"),
("Greater Magic Wand",11288,"Enchanting"),("Novice Arcanist's Sash",253885,"Tailoring"),("Spidersilk Boots",4320,"Tailoring"),("Woolen Boots",2583,"Tailoring")])
gear+=items("wh_l30","level 30",[("Ghamoo-ra's Bind",6908,"BFD"),("Cursed Murloc Eye",273840,"BFD"),("Glowing Thresher Cape",6901,"BFD"),("Rod of the Sleepwalker",1155,"BFD"),("Gaze Dreamer Pants",6903,"BFD"),
("Glinteye Slippers",273024,"Excavation Site"),("Raptor's Gaze",273027,"Excavation Site"),("Ring of Power Regulation",273030,"Excavation Site"),("Dark Horde Band",273806,"Stockade"),
("Hydrocane",9452,"Gnomeregan"),("Acidic Walkers",9454,"Gnomeregan"),("Electrocutioner Lagnut",9447,"Gnomeregan"),("Spidertank Oilrag",9448,"Gnomeregan"),("Thermaplugg Medal of Honor",274068,"Gnomeregan"),
("Thornweaver Drape",274149,"Razorfen Kraul"),("Roogug's Severed Head",274152,"Razorfen Kraul"),("Death Prophet Spine",274158,"Razorfen Kraul"),("Death Speaker Scepter",2816,"Razorfen Kraul"),("Death Speaker Mantle",6685,"Razorfen Kraul"),("Death Speaker Robes",6682,"Razorfen Kraul"),("Swinetusk Shank",6691,"Razorfen Kraul"),("Agamaggan's Clutch",6693,"Razorfen Kraul"),("Batwing Mantle",6697,"Razorfen Kraul"),
("Bloodmage Mantle",7684,"SM Graveyard"),("Blighted Leggings",7709,"SM Graveyard"),("Necrotic Wand",7708,"SM Graveyard"),("Embalmed Shroud",7691,"SM Graveyard"),
("Chestnut Mantle",17695,"Quest 6565"),("Gravestone Scepter",7001,"Quest 1200/6561"),("Witch's Finger",16887,"Quest 6922"),("Curl of Life",271670,"Quest 95646"),("Explorer's League Dustcover",271716,"Quest 98824"),("Healer's Staff",271767,"Quest 98824"),("Daewyn's Girdle",271769,"Quest 95795"),("Knife-Polishing Rag",271740,"Quest 95682"),("Furs of the Earthen Ring",271719,"Quest 98823"),("Hardened Root Staff",1317,"Quest 386"),("Town Clerk's Mittens",270029,"Quest 377"),("Magistrate's Pantaloons",270036,"Quest 378"),("Shilly Mitts",9609,"Quest 2928"),("Fairywing Mantle",9536,"Quest 2904"),("Talvash's Gold Ring",9538,"Quest 2948"),("Civinad Robes",9623,"Quest 2841"),("Nogg's Gold Ring",9588,"Quest 2950"),("Snake Hoop",6750,"Quest 1144"),("Berylline Pads",4197,"Quest 1102"),("Mantle of Woe",7750,"Quest 1051"),
("Glimmering Staff",249392,"Crafted"),("Soulstaff",249393,"Crafted"),("Orb of Mystic Insight",249394,"Crafted"),("Greater Mystic Wand",217287,"Enchanting"),("Filigreed Shadow Circlet",253981,"Tailoring"),("Shadow Gown",253967,"Tailoring"),("Shadow Gloves",253919,"Tailoring"),("Shadow Sash",253931,"Tailoring"),("Shadow Leggings",253993,"Tailoring"),("Black Slippers",254007,"Tailoring"),
("Green Lens",10504,"Engineering"),("Spellpower Goggles Xtreme Plus",15999,"Engineering"),("Minor Recombobulator",4381,"Engineering"),("Mechanical Dragonling",4396,"Engineering"),("Hillman's Cloak",3719,"Leatherworking")])
quest_ids={"Quest 5726 Hidden Enemies":5726}
W=[("Necrotic Wand",7708,33.2,"Azshir the Sleepless, SM Graveyard"),("Wand of Mana Concentration",273043,31.2,"City of Dalaran"),("Gyromatic Icemaker",9489,30.4,"Gnomeregan"),("Unstable Power Core",279847,29.7,"Quest: Source of Power (Dalaran)"),("Gravestone Scepter",7001,29.0,"Quest: Blackfathom Villainy"),("Excavation Rod",5246,24.2,"Quest: Ormer's Revenge"),("Moonbeam Wand",5818,24.2,"Quest: Answered Questions"),("Firebelcher",5243,23.2,"Wailing Caverns"),("Cookie's Stirring Rod",5198,22.3,"Deadmines"),("Spellcrafter Wand",6677,20.3,""),("Deepblaze",279896,18.5,"Hall of Thanes quest"),("Sizzle Stick",8071,17.6,"Quest"),("Sable Wand",7607,16.9,"Quest"),("Torchlight Wand",5240,15.8,""),("Flaring Baton",5326,13.7,""),("Spark of the People's Militia",12296,12.8,""),("Cinder Wand",5242,11.8,""),("Elven Wand",5604,9.4,""),("Riptear's Spare Arm",286743,9.4,""),("Windbough Wand",263430,7.2,"")]
wands=[R("iv_shadow_lvl",name=n,item_id=i,dps=d,source=s) for n,i,d,s in W]
wands+= [R("wh_l20",name=n,item_id=i,source="Enchanting",dps=d,required_level=l) for n,i,d,l in [("Novice's Practice Wand",247789,None,1),("Lesser Magic Wand",11287,11.3,5),("Greater Magic Wand",11288,17.5,13),("Lesser Mystic Wand",11289,25.4,None),("Greater Mystic Wand",217287,None,None)]]
for w in wands[-5:]: w["source_url"]=S["iv_prof"]
other_weapons_note=R("iv_shadow_lvl",note="IV leveling guide also lists staves/main-hands/off-hands with spell power (e.g. Staff of the Shade 2549 +37 Shadow, Swinetusk Shank 6691 +40). See raw/www_icy_veins_com_wow_forever_shadow_priest_leveling.md.")

bis=R("wh_bis",status="Phase 1 BiS pages are placeholders on Wowhead (raids open Dec 9; item stats hidden until first looted)",
  tier1_datamined_placeholder={"healer":{"2":"+10 Spirit","3":"Fear Ward CD -60s","4":"+26 healing / +9 damage","5":"Penance & Prayer of Mending CD -1s"},
  "shadow":{"2":"+1% hit","3":"Shackle +10s","4":"+21 damage vs Undead","5":"Devouring Plague CD -60s"}},flag="Wowhead marks Tier 1 bonuses as placeholder datamining")
stats=[R("wh_stats",spec="Shadow",priority="Hit to 17% cap (Shadow Focus covers part) > Crit > Spell/Shadow damage > Intellect > Spirit > Stamina"),
 R("wh_stats",spec="Holy",priority="Healing Power > Intellect > MP5 > Spirit > Crit > Stamina"),
 R("wh_stats",spec="Discipline",priority="Healing Power > Intellect > Spirit > Crit > Spell Damage > Stamina"),
 R("iv_shadow_lvl",spec="Leveling",priority="Spell power > Crit > Hit > Intellect > Spirit > Stamina > MP5"),
 R("wh_stats",spec="Conversions",priority="1 Int = 15 mana; 59.2 Int = 1% spell crit; healing power also grants 1/3 as damage in Forever")]
cons=[R("wh_ench",type="consumable",bracket="level 30",name=n,item_id=i) for n,i in [("Greater Healing Potion",1710),("Mana Potion",3827),("Briny Seafood Stew",274971),("Sweet Nectar",1708),("Lesser Wizard Oil",20746),("Spellblasting Potion",250934),("Lesser Arcane Elixir",250342)]]
cons+=[R("wh_ench",type="enchant",slot=s,name=n,spell_id=i) for s,n,i in [("Weapon","Revelation (Shadow)",1248805),("Weapon","Insight",1248757),("Bracer","Spirit",13642),("Chest","Greater Intellect",13663),("Cloak","Greater Defense",13746),("Boots","Lesser Spirit",13687)]]
cons+=[R("wh_ench",type="camp",name=n,item_id=i,profession=p,notes=x) for n,i,p,x in [("Camp Tent",279978,"Leatherworking",""),("Mana Well",279956,"Alchemy",""),("Enchanted Lute",279976,"Enchanting",""),("Incense Candle",279962,"Herbalism",""),("First Aid Kit",279968,"First Aid","Does not stack with Fortitude"),("Faction Banner",279972,"","Does not stack with Divine Spirit")]]
cons.append(R("bz_dev",type="note",name="Wizard Oils",notes="Minor 8 / Lesser 16 / Wizard Oil 24 spell power (reverted to Era values)"))
reagents=[R(S["ivdb"]+"items/17028",name="Holy Candle",item_id=17028,item_level=48,stack=20,used_by="Prayer of Fortitude r1"),R(S["ivdb"]+"items/17029",name="Sacred Candle",item_id=17029,item_level=60,stack=20,used_by="Prayer of Fortitude r2, Prayer of Spirit, Prayer of Shadow Protection",vendors="Reagent vendors e.g. Brother Cassius (Stormwind), Barim Jurgenstaad (Ironforge), Chepi (Thunder Bluff), Alaindia (Darnassus)")]
legacy=[R("wh_ench",name=n,spell_id=i) for n,i in [("Well Rested",1225478),("Talented",1225474),("The Quick and the Dead",1225500),("High Alert",1225477)]]
prof=R("iv_prof",leveling="Tailoring + Enchanting",raiding="Engineering + Alchemy",alternatives=["Alchemy + Herbalism","Engineering + Mining"],gnome_engineering_spec_spell=20593)

riding=[R("wh_riding",skill="Apprentice Riding",spell_id=33388,level=40,speed="60%",training="100g",mount_cost="20g (first mount free via quest)"),
 R("wh_riding",skill="Journeyman Riding",spell_id=33391,level=60,speed="100%",training="1000g",mount_cost="200g epic"),
 R("wh_riding",skill="Discounts/rules",notes="Honored with home faction = 10% off; Exalted lets you learn another race's riding for 100g; no Priest class mount; no WoW Token")]
M=[("Human","Randal Hunter",4732,"Eastvale Logging Camp 84.2,65.0","Katie Hunter",384,"Your First Horse",97045,[5655,5656,2414],[18776,18777,18778]),
("Dwarf","Ultham Ironhorn",4772,"Gol'Bolar Quarry 63.8,50.2","Veron Amberstill",1261,"(first mount quest)",97017,[5864,5872,5873],[18787,18786,18785]),
("Night Elf","Jartsam",4753,"Darnassus 38.6,16.0","Lelanai",4730,"(first mount quest)",95511,[8629,8631,8632,274706],[18902,18766,18767]),
("Gnome","Binjy Featherwhistle",7954,"Kharanos 49.2,48.0","Milli Featherwhistle",7955,"(first mount quest)",97046,[8563,8595,13321,13322],[18774,18773,18772]),
("Undead","Velma Warnam",4773,"Brill 60.0,52.6","Zachariah Post",4731,"(first mount quest)",96997,[13331,13332,13333,276063],[274799,18791,13334]),
("Troll","Xar'Ti",7953,"Sen'jin Village 55.2,75.6","Zjolnir",7952,"(first mount quest)",96989,[8588,8591,8592],[18790,18789,18788])]
mounts=[R("wh_riding",race=r,trainer=t,trainer_npc_id=ti,location=l,vendor=v,vendor_npc_id=vi,first_mount_quest=q,quest_id=qi,mount_item_ids=m,epic_mount_item_ids=e) for r,t,ti,l,v,vi,q,qi,m,e in M]
mounts.append(R("bz_launch",race="Any",notes="Cerulean Prideclaw pre-purchase mount still requires riding skill"))

addons=[R("questie",name="Questie",status="Forever TOC (Questie_Forever.toc, Interface 16001)"),R("dbm",name="Deadly Boss Mods",status="16001 in DBM-Core TOC"),
 R("details",name="Details!",status="Details_Camelot.toc 16001"),R("bigwigs",name="BigWigs",status="16001 in TOC"),
 R("weakauras",name="WeakAuras",status="NOT confirmed: Vanilla TOC 11509 only"),
 R("fstatus",name="ElvUI, Bartender4, Dominos, Plater, BetterBags, UnitFramesImproved",status="Listed as working by foreverstatus.com (third party, unverified)"),
 R("iv_forever",name="Built-in Cooldown Manager",status="Blizzard UI has Blizzard_CooldownViewer; Priest tracks all spells by default")]
addon_dev=R("taut",notes=["Forever is Mainline-family; Classic Era addons don't load","Midnight-style restrictions incl. secret values apply (verify)","TOC lookup: _Forever/_Camelot, then _Mainline, then plain .toc","Use '## Interface: 16001'; dual: '120105, 16001'","Runtime: WOW_PROJECT_ID == 18","Check in game: /run print(GetBuildInfo()) print('project', WOW_PROJECT_ID)","Install folder _forever_ (verify)"])

changes=[R("bz_dev",date=d,change=c) for d,c in [
("2026-09-24","Wands no longer gain damage from spell damage; Wizard Oils reverted to Era values"),
("2026-10-01","Devouring Plague can crit; SW:Death Early Demise fix; Inner Focus crit no longer applies to periodic effects"),
("2026-10-08","Penance: damage/healing reduced (2s channel bug), rank 1 mana +50%, ranks 2/4 healing increased"),
("2026-10-15/16","DP CD 24s (was 60s); SW:D CD 18s (was 12s); VE 30s CD, unresistable; Mental Strength 2-10% Int (row 2); Improved PW:S row 3; Twin Disciplines covers SW:D/Mind Flay/Starshards/Penance; Dark Inspiration added; Improved Mind Flay reworked; Devouring Contagion 2 targets; Improved Fade and Shadow Infinity removed; Power in Light buffs Smite/Penance on Holy Fire/SW:P targets"),
("2026-10-26/27","Racial passives: Human Spirit 10%, Dwarf +1% hit, Troll Berserking 15s, Undead Touch of the Grave 15s ICD"),
("2026-11-02/03","PW:S overwritable by equal/higher rank; SW:D backlash 30% max HP, none on miss; Dark Sacrifice no longer breaks CC; Holy Binding replaces Binding Heal; Devouring Contagion not from critters; VE healing can't crit; Cure/Abolish Disease no longer cancel Shadowform; training 1-60 ~206-207g; low-rank talent proc penalty removed; higher-level creature HP/damage raised")]]
changes.append(R("bz_hotfix",date="2026-11-06",change="Hotfixes: no Priest spell changes; The Quick and the Dead legacy talent fixed"))
changes.append(R("bz_dungxp",date="2026-11-08",change="Dungeon enemy XP +50%"))
changes.append(R("bz_tuning",date="2026-11-10 (scheduled)",change="Class tuning: Hunter/Warlock pets, Affliction, Enhancement - no Priest changes. Future tuning on Tuesdays"))
changes.append(R("wh_nogold",date="2026-11-07",change="Quests give no gold at 60 (reported intentional by a streamer; not Blizzard-confirmed) - affects saving for 1000g epic riding"))

watch=[R(u,name=n,type=t) for n,t,u in [
("Blizzard Tracker RSS (blue posts incl. Forever hotfixes/tuning)","rss","https://us.forums.blizzard.com/en/wow/groups/blizzard-tracker/posts.rss"),
("Forever Development Notes thread RSS","rss","https://us.forums.blizzard.com/en/wow/t/wow-forever-beta-development-notes-%E2%80%93-updated-november-2/2360696.rss"),
("Wowhead Forever news RSS","rss","https://www.wowhead.com/news/rss/forever"),
("Wowhead Forever hub","page","https://www.wowhead.com/forever"),
("Blizzard hotfixes article (updated in place)","page",S["bz_hotfix"]),
("Blizzard WoW news feed","rss (returned HTML on test - verify)","https://news.blizzard.com/en-us/feed/world-of-warcraft"),
("Gethe/wow-ui-source forever branch commits (build number changes)","atom","https://github.com/Gethe/wow-ui-source/commits/forever.atom"),
("Icy Veins roadmap + priest guides (Last Updated / changelog)","page",S["iv_roadmap"]),
("Discourse JSON for any thread (append .json)","api",S["bz_dev"]+".json")]]

gaps=[R("bz_dev",gap=g) for g in [
"Zones by level 30-60: Wowhead /forever/zones pages blocked (403) this run; Icy Veins only covers 10-30",
"Pre-raid/Phase 1 BiS: Wowhead pages are placeholders; item stats hidden until looted",
"Per-rank trainer costs not found (only ~206-207g total 1-60)",
"Night Elf level-20 Elune's Grace quest ID not captured",
"Contingency Plan CD: Blizzard 5 min vs Wowhead 10 min",
"Penance/Prayer of Mending spell IDs differ between Wowhead and Icy Veins DB",
"Benediction/Anathema (Classic Molten Core/Kazzak quest) - not confirmed for Forever; Molten Core is not in the announced roadmap",
"WeakAuras Forever support unconfirmed",
"Level 40-60 gear lists (Wowhead only has level 20 and 30 pages so far)"]]

data=dict(meta=meta,sources=S,races_racials=racials,racial_passive_changes=race_passive_changes,race_recommendations=race_recs,
 class_trainers=class_trainers,quests=quests,spells_by_level=spells,talent_and_other_spell_ids=talent_spells,milestones=milestones,
 talent_changes=talent_changes,builds=builds,rotations=rot,stat_priority=stats,zones_by_level=zones,new_zones=new_zones,dungeons=dungeons,raids=raids,
 raid_rules=raid_rules,roadmap=roadmap,gear_by_bracket=gear,wands=wands,other_weapons=other_weapons_note,bis=bis,consumables_enchants=cons,
 reagents=reagents,legacy_talents=legacy,professions=prof,riding=riding,mounts=mounts,addons=addons,addon_dev=addon_dev,changes_log=changes,
 change_sources=watch,gaps=gaps)
json.dump(data,open("/workspace/wow/priest-forever/data.json","w"),indent=1,ensure_ascii=False)
def chk(o,p=""):
    if isinstance(o,dict):
        if "checked" in o: assert o.get("source_url"),p
        for k,v in o.items(): chk(v,p+"."+k)
    elif isinstance(o,list):
        for i,v in enumerate(o):
            if isinstance(v,dict) and p not in(".sources",): assert "checked" in v or p.endswith("rank_learn_levels") or "level" in v and "what" in v, (p,v)
            chk(v,f"{p}[{i}]")
chk(data); print("ok", {k:len(v) for k,v in data.items() if isinstance(v,list)})
