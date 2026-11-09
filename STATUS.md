# STATUS: Andric's Addon (2026-11-09)

**PR:** https://github.com/ninepointlabs/andrics-addon/pull/1 (branch `feature/initial-addon`). Not merged. Tag/release `v0.1.0` cut on the PR branch at Tim's request (see below).
**Repo:** `ninepointlabs/andrics-addon` (**public** since 2026-11-09, at Tim's request). Topics `wow-addon` and `world-of-warcraft` are set, which OmaForge's GitHub search requires. Local checkout: `/home/tim/Projects/wow-forever-priest-addon`. The folder name was kept from the original brief; rename it if you like.

**Website:** https://andricsaddon.myazerothlife.com, GitHub Pages from `docs/`, styled like omaforge.ninepointlabs.com (Tim preferred it to the My Azeroth Life newspaper look): a loading-screen hero, a quest log of features, a loot window for installs and a tavern FAQ. It reuses OmaForge's site CSS and JS (Nine Point Labs, MIT); art is linked from omaforge.ninepointlabs.com and icons from Blizzard's public icon CDN, none copied. HTTPS is enforced (certificate approved) and the DNS CNAME to `ninepointlabs.github.io` was already in place. **Pages currently builds from `feature/initial-addon`; after the PR merges, switch it to `main` /docs** (Settings → Pages, or `gh api -X PUT repos/ninepointlabs/andrics-addon/pages -f "source[branch]=main" -f "source[path]=/docs"`). `docs/` is excluded from the addon zip.

**Release `v0.2.0`** (2026-11-09, at Tim's request): tag at `f94ec86`. Release workflow passed; `release.json` = forever / 16001; OmaForge shows `v0.1.7 -> v0.2.0`. Window redesign (8 grouped screens, Home dashboard, sub-tabs, search, Sources & notes popups), the Fortitude key binding set from Settings, the macro removed. **Look and feel still to be confirmed in game.** https://github.com/ninepointlabs/andrics-addon/releases/tag/v0.2.0

**Release `v0.1.7`** (2026-11-09, at Tim's request): tag at `8cdf225`. Release workflow passed; `release.json` = forever / 16001; OmaForge shows `v0.1.6 -> v0.1.7`. Fortitude button confirmed working in v0.1.6. The `AndricsFort` macro now mirrors the button's command instead of `/click`; Tim must re-create it once from Options. **Macro and key binding still to be confirmed in game.** https://github.com/ninepointlabs/andrics-addon/releases/tag/v0.1.7

**Release `v0.1.6`** (2026-11-09, at Tim's request): tag at `31d8449`. Release workflow passed; `release.json` = forever / 16001; OmaForge shows `v0.1.5 -> v0.1.6`. Fortitude button now reaches strangers by name (`/targetexact`); the failure message includes the game's macro-condition check. **Waiting for Tim's in-game result.** https://github.com/ninepointlabs/andrics-addon/releases/tag/v0.1.6

**Release `v0.1.5`** (2026-11-09, at Tim's request): tag at `649b62c`. Release workflow passed; `release.json` = forever / 16001; OmaForge shows `v0.1.4 -> v0.1.5`. Fortitude button fix attempt: Tim reported clicks and the macro didn't cast, so the button now casts via a `/cast [@unit,help,nodead]` macro line, reports the outcome of each press in chat, and has `/andric fort debug`. **Still unverified in-game; waiting for Tim's chat output.** https://github.com/ninepointlabs/andrics-addon/releases/tag/v0.1.5

**Release `v0.1.4`** (2026-11-09): tag on `feature/initial-addon` at `d1f2fbc`. Release workflow passed; `release.json` = forever / 16001; OmaForge on TUF shows `-> v0.1.4`. Adds the Fortitude "Buff next" button (key binding + macro). CI now installs Lua from Ubuntu packages because the lua.org downloads kept timing out. https://github.com/ninepointlabs/andrics-addon/releases/tag/v0.1.4

**Release `v0.1.3`** (2026-11-09, at Tim's request): tag on `feature/initial-addon` at `31ff91e`. Release workflow passed; `release.json` = forever / 16001; OmaForge on TUF shows `v0.1.2 -> v0.1.3`. Adds gear details (where and how to get each item, map pins) and the Forever healing-stat parsing fix. https://github.com/ninepointlabs/andrics-addon/releases/tag/v0.1.3

**Release `v0.1.2`** (2026-11-09, at Tim's request): tag on `feature/initial-addon` at `1fa3dca`. Release workflow passed; `release.json` = forever / 16001; OmaForge on TUF shows `-> v0.1.2`. Adds the tooltip "What improves / What you'd lose" + "Equip this" lines and the bag upgrade highlight and alerts. https://github.com/ninepointlabs/andrics-addon/releases/tag/v0.1.2

**Release `v0.1.1`** (2026-11-09, at Tim's request): tag on `feature/initial-addon` at `792dc06`. Release workflow passed; `release.json` = forever / 16001; OmaForge on TUF shows `v0.1.0 -> v0.1.1`. Contains dual-spec auto-switch, the level-filtered rotation, talent builds drawn on the trees, and the gear views. https://github.com/ninepointlabs/andrics-addon/releases/tag/v0.1.1

## Release v0.1.0 (cut at Tim's request, 2026-11-09)

- Tag `v0.1.0` on `feature/initial-addon` (commit `510ea2e`); `main` is untouched and the PR is still open.
- The release workflow passed. Assets: `AndricsAddon-v0.1.0.zip` and `release.json` = `{"flavor":"forever","interface":16001}`. The TOC version is stamped `v0.1.0`. This confirms the BigWigs packager handles `_Forever.toc`.
- `omaforge clients` re-checked before tagging: Forever 1.60.1.70862 / 16001, matching the TOC.
- **Resolved by making the repo public (2026-11-09):** unauthenticated `release.json` now returns HTTP 200. Background: OmaForge install was blocked while the repo was private. OmaForge sends the GitHub token only to `api.github.com`. It fetches `release.json` and the zip from `browser_download_url` with no auth (`omaforge/core/providers/github.py:128,166`; `download_headers()` returns `{}`), and GitHub returns **404** for those URLs on a private repo (verified). Adding a token alone won't fix it. Options:
  1. Make the repo public: `gh repo edit ninepointlabs/andrics-addon --visibility public --accept-visibility-change-consequences`.
  2. Change OmaForge's GitHub provider to download private assets through the API (`/repos/{repo}/releases/assets/{id}` with `Accept: application/octet-stream` and the token).
- Once access works: `omaforge install -c forever github:ninepointlabs/andrics-addon`.

## Changes after v0.1.0 (Tim's in-game feedback, 2026-11-09)

- **Rotation** lists only spells usable at your level. Known spells show normally; spells your level allows but that aren't detected in the spellbook say "available - visit trainer"; talents appear only once taken; the rest are counted as "unlock later".
- **Talents & builds** draws each build on Forever's real talent trees, with points per talent, in-game spell tooltips and a "what this build takes" list. Tree data: `research/talents_priest.json` from Icy Veins' calculator for build 70862 (`tools/fetch_talents.py`). Wowhead's talent-calc is blocked for scripts (403), so its build strings are decoded and validated: all 12 level-60 builds come to exactly 51 points with valid ranks and rows, and Holy Level 30 to 21. **Discipline "Level 30" fails validation** (5 points in Improved Inner Fire, max 3), so it shows the link only.
- **Tooltip** now names the item you'd replace and lists *What improves* / *What you'd lose*. Int shows max mana and crit %, and Spirit shows regen; both use only the documented conversions (1 Int = 15 mana, 59.2 Int = 1% crit, Spirit/4 per 2s), parsed from `data.json`. A green **Equip this** line appears when it's an upgrade you can wear now; otherwise you see "Upgrade once you reach level N".
- **Bags**: upgrades you can equip now get a glow and an arrow on their bag slot. This is our own overlay, so it doesn't fight Pawn's green arrow, and it uses the same bag hooks Pawn uses on Forever. A new upgrade in your bags triggers a chat line and a toast, once per item. At login you get one summary line. Toggles are in Options. Not yet checked in-game: whether the overlay sits well on the combined-bag and separate-bag frames.
- **Fortitude button debugging (Tim, in game):**
  - **v0.1.4:** the `type=spell` button picked targets correctly, but clicks and the macro didn't cast.
  - **v0.1.5** (`/cast` macro line): `/andric fort debug` showed everything armed (macro on `nameplate1`, in range, unbuffed, out of combat), yet each press reported "pressed but no cast started": no error, no block.
  - **Working theory:** Forever ignores `[@nameplateN]` macro conditions.
  - **v0.1.6:** strangers are reached by name (`/targetexact Name` then `/cast [@target,...]`, then the previous target is restored or cleared). Group members and you stay direct. The failure line now includes the game's own `SecureCmdOptionParse` check for that unit.
- **Fortitude button v0.1.6:** Tim confirmed the on-screen button works ("the buff goes out"). The action-bar macro (`/click AndricsFortButton`) did nothing, because Forever's `/click` handler skips buttons with `HasAccessConstraints()` or the forbidden `ScriptedInput` aspect (wow-ui-source@forever `SlashCommands.lua`). **v0.1.7:** the `AndricsFort` macro body is now the button's own command, rewritten via `EditMacro` out of combat whenever the target changes. Casts from the macro also advance the button (`UNIT_SPELLCAST_SENT`). Still untested: the key binding (CLICK binding), which may face the same restriction.
- **Fixes from Tim's v0.2.0 screenshots (2026-11-09):**
  - The header showed "vv0.2.0".
  - The logo was a plain white square (Discipline accent); it's now the spec icon.
  - Gear showed "req. 0" and treated level-30 quest or crafted items as wearable at level 7. Items now get an effective level from their source: the quest's minimum level, the dungeon's lower bound, or the gear-list bracket minus 10. Rows say "from level N" when the level is derived.
  - Percentages of 300% or more (e.g. "+5175%" against a near-empty slot) now read "much better".
  - The Fortitude tooltip went stale while hovering; it now refreshes as the target changes.
- **Window redesign (v0.2.0, Tim: "cluttered, not intuitive"; mockup approved: https://claude.ai/artifact/3cZdhHVFhtzGetS4j3byoN):**
  - **Navigation:** 13 flat tabs become 8 grouped screens: Home · Play (Rotation, Gear) · Progress (Leveling, Talents) · Learn · What's new · Settings. Trainer, Class quests and Riding & gold are Leveling sub-tabs. Reminders and Sources are Settings sub-tabs.
  - **New pieces:** a Home dashboard, a standard sub-tab bar, cards and chips, two-column layouts, the Gear slot list with a detail panel, sidebar search, and a header spec pill plus A/B switch.
  - **Sources and minor research notes** are collected behind one "Sources & notes" link per screen.
  - **Styling:** bigger, higher-contrast text, and new accents (Shadow purple, Holy gold, Discipline silver-blue).
  - **Compatibility:** old slash names still work (`/andric training` opens Leveling › Trainer, and so on).
  - **Bug fixed:** an item opened from search that wasn't in the current gear list showed a different item.
  - **Untested in game:** layout and spacing, the search box, and how cards equalise their heights.
- **Fortitude v0.1.7:** the button works, but the action-bar macro didn't fire, even with the macro body mirroring the button's command. **v0.1.8 (Tim: "remove the macro, allow a keybind"):** the macro is gone, and the old `AndricsFort` macro is deleted once, only if its body is still ours. Options → **Set key** captures a key (modifiers and extra mouse buttons allowed) and applies it with `SetOverrideBindingClick` on the button, per character, out of combat. The key is shown on the button. `Bindings.xml` was removed so there's one binding path. `/andric fort key`.
- **Fortitude "Buff next" button** (`UI/FortButton.lua`):
  - **What it is:** a secure action button (`AndricsFortButton`) that's re-aimed out of combat every 0.5s and after each press. It targets the next friendly, alive, online player who lacks Fortitude or Prayer of Fortitude and passes `C_Spell.IsSpellInRange`.
  - **Order:** you, then your group (nearest first via `UnitDistanceSquared` when available), then your target, then `nameplate1-40`. Each press casts once.
  - **In combat:** the target is frozen to the last pick.
  - **Ways to use it:** key binding (`Bindings.xml`, CLICK binding), an Options button that creates and picks up the macro `AndricsFort`, `/andric fort [macro]`, and a drag handle.
  - **Unverified in-game:** whether Forever allows reading other players' buffs and friendly nameplates in the open world. If the buff state is unknown, those players are tried after confirmed ones. Also unverified: that the key binding and the macro fire the cast.
- **Gear details**: clicking a gear item opens a detail view with the comparison and *How to get it*: boss and drop chance plus dungeon level range; quest reward with level, faction, giver, zone and coordinates; crafting profession, skill and reagents; or vendor. Data: `research/item_sources.json` (Icy Veins Forever DB, early access, via `tools/fetch_item_sources.py`). **Mark on map** uses `C_Map.SetUserWaypoint` and the supertracked arrow. Quest-giver pins use Icy Veins coordinates matched to a game zone by name. Dungeon-entrance pins come from the client (`C_EncounterJournal.GetDungeonEntrancesForMap`, which Forever's own world map uses). It's flagged when the gear guide's quest ID differs from Icy Veins'. Not yet checked in-game: zone-name matching and whether every dungeon has an entrance pin.
- **Tooltip parser fix**: Forever words healing as "healing done by *magical* spells and effects", which wasn't parsed before. Items that print healing and its ⅓ damage on separate lines no longer double-count.
- **Gear** has three views: *For my level* (researched items you can equip now, per slot, best first, plus "coming up" for the next 5 levels), *Best overall*, and *By bracket*. Required level and slot come from the client's item info.



| | Value |
|---|---|
| `omaforge clients` on TUF (2026-11-09) | Forever `1.60.1.70862`, Interface `16001`, path `~/Games/battlenet/drive_c/Program Files (x86)/World of Warcraft/_forever_` |
| `.toc` Interface used | `16001` (matches) |
| TOC files | `AndricsAddon_Forever.toc` plus an identical `AndricsAddon.toc` fallback |
| Runtime guard | It runs only when `WOW_PROJECT_ID == 18` (`WOW_PROJECT_CAMELOT`) and prints a message otherwise |

Before any tag, run `omaforge clients` again and update both `.toc` files if the Interface changes. In game you can confirm with `/run print(GetBuildInfo()) print(WOW_PROJECT_ID)`. The addon's *Sources & flags* tab shows the same information.

## Install and test on TUF

```sh
cd ~/Projects/wow-forever-priest-addon
git fetch && git checkout feature/initial-addon
tools/install-dev.sh            # copies to …/_forever_/Interface/AddOns/AndricsAddon
```

Then log into a Priest on Forever (or `/reload`) and work through this list:

1. **First run:** about 3 seconds after login the spec picker opens. Pick a spec, and the window accent changes (gold for Holy/Disc, purple for Shadow).
2. **`/andric` and `/priest`:** each toggles the window. Try the minimap button (left-click opens, right-click goes to Options, drag moves it) and the addon compartment entry.
3. **Profiles / dual spec:** pick a spec for profile A, then for profile B (Options). On a 40+ character with dual spec, swap talent specs: chat says "switched to profile B" and every panel follows. Below 40 the header A/B buttons switch by hand.
4. **Tooltips:** hover bag items, vendor items and the Gear tab rows. You should see "Andric's Addon · <spec>", Upgrade or Downgrade versus equipped, stat deltas, and "Recommended: …" for listed items. Rings and trinkets compare against your weaker one.
5. **Rotation:** the on-screen helper appears once a spec is set; drag it to move. Attack a mob, and Shadow should suggest Mind Blast / SW:Pain / wand. After combat, chat shows a fight summary with tips. Healers see a priority list plus cooldowns. If the helper shows "some info hidden", Forever is returning secret values for auras or cooldowns. Please tell me where it happened.
6. **Learn the Priest:** check lessons (unlocked and coming up), Spells, Talents, Mechanics, Group play, Leveling and Mistakes. The first time you train a new spell, a hint toast should appear.
7. **Reminders:** remove Inner Fire or unequip your wand; out of combat a toast appears within about a minute, or right away with `/andric remind`.
8. **Quests / Mounts:** your race's quests should show completed checkmarks, and the gold bars should match your money.
9. **What's changed:** the badge counts unread items. Click to mark one read or use "Mark all read".
10. Watch for Lua errors (`/console scriptErrors 1`) and send them to me.

**Change poller (optional):** `python3 tools/priest-changes-poller/poller.py -v --output "<AddOns>/AndricsAddon/Data/Changes.lua"` then `/reload`. The timer setup is in `tools/priest-changes-poller/README.md`; it is **not enabled**.

**Regenerate data:** `python3 tools/build_data.py` (CI and `--check` fail if it's stale).

## What works (verified headlessly, not in the client)

- `lua5.1 tests/run.lua`: 23/23 pass. A strict WoW API mock loads every TOC file, logs in, renders all 13 panels × 3 specs, and covers stat parsing, scoring, A/B profiles, training, the rotation engine, the fight summary, reminders, slash commands and events.
- `python3 tools/priest-changes-poller/tests/test_poller.py`: 4/4 pass. A live dry-run reached 8 of 9 feeds (the Wowhead hub page is skipped on purpose) and produced 20 relevant items.
- `python3 tools/build_data.py --check`: up to date.

**Not verified:** anything in the real client (layout, fonts, the tooltip hook, aura/cooldown reads under the Midnight-style restrictions). The BigWigs packager is now verified by the real v0.1.0 release run (see above).

## Decisions and assumptions

- **Name:** Andric's Addon, folder and TOC `AndricsAddon`, repo `andrics-addon`, `/andric` with `/priest` as an alias (Addendum 2).
- **No Ace3:** built on the Blizzard API only, with no embedded libraries. This keeps it light and avoids lib-compatibility risk on Forever.
- **Gear weights:** the research gives stat priority *order*, not numbers. Weight = (n − rank + 1)/n. Hit and crit % are multiplied by **10 points per 1%**. That factor is an addon assumption (changeable in Options) and is labeled in-game. Healing power counts ⅓ toward damage (Wowhead) when an item doesn't state its damage part. Shadow uses leveling weights below 60 by default; Holy and Disc use healer weights (there's a toggle).
- **Tooltip stats** are parsed from English item text (`C_TooltipInfo`), because Forever items use Classic-style "Equip:" lines.
- **Fight summary** uses `UNIT_SPELLCAST_SUCCEEDED` for the player only, not the combat log. Casts the client hides are counted as hidden.
- **What's changed read-state** is account-wide; profiles and reminders are per character.
- **`research/raw/`** is gitignored (16 MB of third-party HTML). `data.json`, `sources.md` and `build_data.py` are committed.
- **Repo bootstrap:** GitHub created `main` with its default README (`--add-readme`), so the PR has a base. I never pushed to `main`.

## Open questions / gaps

1. **Dual spec: resolved.** Tim confirmed it's available at 40. `Core/DualSpec.lua` now uses the same API as Blizzard's own Forever talent frame (`C_SpecializationInfo.GetActiveSpecGroup()`, `GetNumSpecGroups()`, event `ACTIVE_TALENT_GROUP_CHANGED`; source: Gethe/wow-ui-source@forever, build 70862). Talent spec 1 maps to profile A and spec 2 to B. Auto-switch is on by default and can be turned off in Options. Still needs an in-game check: swap specs at 40+ and the header should flip A/B.
2. **Percent-stat factor** (10 per 1% hit/crit): fine as a default, or do you have a preferred value?
3. **Gaps the addon flags instead of filling:** zones for 30–60, per-rank trainer costs (only the ~206–207g total), the Night Elf level-20 Elune's Grace quest ID, 40–60 gear lists, raid BiS (raids open Dec 9), and Benediction/Anathema. WeakAuras support is unconfirmed (not used).
4. **Conflicts shown in-game:**
   - Contingency Plan CD (5 vs 10 min) and Divine Grace CD (5 vs 10 min)
   - Penance and Prayer of Mending spell IDs
   - Tier 1 set bonuses are placeholders
   - Wand Specialization (13% vs 25%)
   - The regen formula (12.5 vs 13)
   - Meditation (50% vs 15%)
   - Shadow Protection duration
   - Stale pages that still list Binding Heal and Lightwell
   - The downranking penalty
5. **Research attribution errors** (found while writing the teaching content; not edited in `data.json`):
   - The dual-spec milestone is credited to Icy Veins, which never mentions it.
   - The Vampiric Embrace 30s CD and Twilight Focus 70% are credited to Blizzard's deep dive (actual sources: the dev notes and Icy Veins).
   - The Holy and Disc stat priorities cite the Shadow stat page.
6. **Unconfirmed teaching items** (flagged in-game):
   - The "Searing Light" proc buff name in the Holy solo rotation
   - All three raid rotations, which are based on pre-launch guides
   - A handful of spells, talents and mechanics, listed via the ⚠ flags in Learn the Priest
7. **Localization:** tooltip stat parsing is enUS only.
