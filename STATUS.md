# STATUS: Andric's Addon (updated 2026-11-10)

**Current release:** `v0.2.2`, https://github.com/ninepointlabs/andrics-addon/releases/tag/v0.2.2
**Repo:** `ninepointlabs/andrics-addon`. It has been **public** since 2026-11-09 at Tim's request. The topics `wow-addon` and `world-of-warcraft` are set, which OmaForge's GitHub search requires. Local checkout: `/home/tim/Projects/wow-forever-priest-addon`. The folder name comes from the original brief.
**Branching:** PR #1 (`feature/initial-addon`) was merged into `main` on 2026-11-09 at Tim's request, as merge commit `aca9d16`. Since then, small changes have been committed straight to `main`. Tim hasn't yet said whether future work should go through PRs.
**Website:** https://andricsaddon.myazerothlife.com, served by GitHub Pages from `main` /docs (see below).
**Install:** `omaforge install -c forever github:ninepointlabs/andrics-addon`, then `omaforge update -c forever` for later versions. On 2026-11-09 Tim's installed copy was v0.2.0.

## Releases

Every tag was made at Tim's request. Before each tag, `omaforge clients` was re-checked: it showed Forever `1.60.1.70862` / Interface `16001`, matching the TOC. Each release workflow passed and produced `release.json` = `{"flavor":"forever","interface":16001}`. OmaForge offered each new version afterwards.

| Tag | Commit | What's in it |
|---|---|---|
| `v0.2.2` | `859007b` (main) | Settings › About, named for Andric Grammaris, plus `/andric about`. Andric's full name also added to the website and README. |
| `v0.2.1` | `94df2e1` | Fixes from Tim's v0.2.0 screenshots: the "vv" version text, a white-square logo (now the spec icon), gear "req. 0" levels, huge percentages now read "much better", and a stale Fortitude tooltip. |
| `v0.2.0` | `f94ec86` | Window redesign (8 grouped screens, Home dashboard, sub-tabs, search, Sources & notes popups). Fortitude key binding set from Settings. The Fortitude macro was removed. |
| `v0.1.7` | `8cdf225` | Fortitude macro now runs the button's own command (it still didn't fire; removed in v0.2.0). |
| `v0.1.6` | `31d8449` | Fortitude button reaches strangers by name (`/targetexact`). **Tim confirmed the button casts.** |
| `v0.1.5` | `649b62c` | Fortitude button casts via a `/cast` macro line; per-press chat outcome; `/andric fort debug`. |
| `v0.1.4` | `d1f2fbc` | Fortitude "Buff next" button. CI installs Lua from Ubuntu packages. |
| `v0.1.3` | `31ff91e` | Gear details (where and how to get each item, map pins); Forever healing-stat parsing fix. |
| `v0.1.2` | `1fa3dca` | Tooltip "What improves / What you'd lose" and "Equip this"; bag upgrade highlights and alerts. |
| `v0.1.1` | `792dc06` | Dual-spec auto-switch, level-filtered rotation, talent builds drawn on the trees, gear views. |
| `v0.1.0` | `510ea2e` | First release. It confirmed that the BigWigs packager handles `_Forever.toc`. |

`v0.1.0`–`v0.2.1` were tagged on `feature/initial-addon` before the merge. OmaForge couldn't install `v0.1.0` while the repo was private, because it downloads release assets without auth. Making the repo public fixed that.

## Feature notes

- **Window (v0.2.0 redesign).** Tim's verdict on the old window was "cluttered, not intuitive". He approved this mockup: https://claude.ai/artifact/3cZdhHVFhtzGetS4j3byoN.
  - The window now has 8 grouped screens: Home · Play (Rotation, Gear) · Progress (Leveling, Talents) · Learn · What's new · Settings.
    - Trainer, Class quests and Riding & gold are sub-tabs of Leveling.
    - Reminders, About the data, Fortitude button, Tooltips & bags and About are sub-tabs of Settings.
  - Old slash names still work. For example, `/andric training` opens Leveling › Trainer.
- **Rotation.** Lists only spells usable at your current level:
  - Known spells show normally.
  - Spells your level allows but that aren't in the spellbook say "available - visit trainer".
  - Talents appear once taken.
  - Everything else is counted as "unlock later".
- **Talents & builds.** Builds are drawn on Forever's real talent trees.
  - Tree data is `research/talents_priest.json`, taken from Icy Veins' calculator for build 70862.
  - Wowhead build strings are decoded and validated: all 12 level-60 builds come to exactly 51 points. Discipline "Level 30" fails validation (5 points in Improved Inner Fire, whose max is 3), so the addon shows only its link.
- **Gear.** There are three views: *For my level*, *Best overall* and *By bracket*.
  - Each item's level is the higher of its required level and the level of its source: the quest's minimum level, the dungeon's low end, or the gear-list bracket minus 10. Rows say "from level N" when the level comes from the source.
  - Clicking an item shows *How to get it*: boss and drop chance, quest, crafting or vendor. **Mark on map** uses `C_Map.SetUserWaypoint` and the supertracked arrow.
- **Tooltips and bags.** Tooltips name the item you'd replace and list *What improves* / *What you'd lose*. A green **Equip this** line appears when it's an upgrade you can wear now.
  - Bag upgrades you can equip now get our own glow and arrow overlay, using the same bag hooks as Pawn.
  - A chat line and toast appear once per new upgrade.
- **Fortitude "Buff next" button** (`UI/FortButton.lua`). This is a secure action button (`AndricsFortButton`), re-aimed out of combat.
  - **Order:** you, then your group (nearest first), then your target, then players with friendly nameplates. Players who are dead, out of range or already buffed are skipped.
  - **Targets:** you and group members are cast on directly. Strangers are cast on with `/targetexact Name` + `/cast [@target,help,nodead]`, and your previous target is restored afterwards. Forever silently ignores `[@nameplateN]`.
  - **Key:** Settings › Fortitude button › **Set key**, or `/andric fort key`. It's applied with `SetOverrideBindingClick`, per character, out of combat. `Bindings.xml` was removed, so this is the only binding path.
  - **No macro:** Forever's `/click` refuses addon buttons, because it skips buttons with `HasAccessConstraints()` or the forbidden `ScriptedInput` aspect (wow-ui-source@forever `SlashCommands.lua`). A macro that mirrored the button's command didn't fire either. v0.2.0 deletes the old `AndricsFort` macro once, and only if its body is still the addon's.
- **About (v0.2.2).** Settings › About shows the version, who the addon is named for (Andric Grammaris), links, credits and the fan-project notice.

## Website

https://andricsaddon.myazerothlife.com is served from `docs/` on `main` by GitHub Pages, with HTTPS enforced.
- **Look:** styled like omaforge.ninepointlabs.com, which Tim preferred to the My Azeroth Life newspaper look. It reuses OmaForge's site CSS and JS (Nine Point Labs, MIT). Art is linked from omaforge.ninepointlabs.com and icons from Blizzard's public icon CDN; neither is copied.
- **Content:**
  - A Buff Button spotlight with an interactive demo.
  - A quest log of features using Tim's in-game screenshots, with other players' names pixelated.
  - "The Priest Who Started It All" section about Andric Grammaris.
  - A loot window for installs and a tavern FAQ.
- **Packaging:** `docs/` is excluded from the addon zip.

## Client check

| | Value |
|---|---|
| `omaforge clients` on TUF (2026-11-09) | Forever `1.60.1.70862`, Interface `16001`, path `~/Games/battlenet/drive_c/Program Files (x86)/World of Warcraft/_forever_` |
| `.toc` Interface used | `16001` (matches) |
| TOC files | `AndricsAddon_Forever.toc` plus an identical `AndricsAddon.toc` fallback |
| Runtime guard | It runs only when `WOW_PROJECT_ID == 18` (`WOW_PROJECT_CAMELOT`) and prints a message otherwise |

Before any tag, run `omaforge clients` again and update both `.toc` files if the Interface has changed. In game you can confirm with `/run print(GetBuildInfo()) print(WOW_PROJECT_ID)`.

## Verified in game (Tim, 2026-11-09)

- The addon installs and updates through OmaForge.
- The Fortitude button casts, including on strangers (since v0.1.6).
- Tim's screenshots of the v0.2.0 window covered Home, Rotation, Gear, Trainer, Talents, Learn, What's new, Settings and the Fortitude tooltip and cast. The bugs they showed were fixed in v0.2.1.

## Still to check in game

1. **Fortitude key binding** (`SetOverrideBindingClick`): it might hit the same Forever restriction that blocked `/click`.
2. **Dual spec:** at 40+, swap talent specs. Chat should say "switched to profile B" and the header should flip A/B.
3. **Window details:** layout and spacing, the search box, and how cards equalise their heights.
4. **Bag overlay** on both the combined-bag and separate-bag frames.
5. **Map pins:** zone-name matching for quest givers, and whether every dungeon has an entrance pin.
6. **Hidden values:** whether Forever hides other players' buffs, auras or cooldowns (the Midnight-style secret values). The rotation helper says "some info hidden" when it does.
7. **Lua errors:** watch for them with `/console scriptErrors 1`.

## Dev loop

```sh
cd ~/Projects/wow-forever-priest-addon
tools/install-dev.sh            # copies to …/_forever_/Interface/AddOns/AndricsAddon
python3 tools/build_data.py     # regenerate Data/*.lua (--check fails if stale)
lua5.1 tests/run.lua            # headless tests
```

**Change poller (optional, not enabled):** `python3 tools/priest-changes-poller/poller.py -v --output "<AddOns>/AndricsAddon/Data/Changes.lua"`, then `/reload`. The systemd timer examples are in `tools/priest-changes-poller/README.md`.

## What works (verified headlessly, 2026-11-10)

- `lua5.1 tests/run.lua`: **34/34 pass**. A strict WoW API mock loads every TOC file and logs in. It renders every screen and sub-tab for all three specs. It covers stat parsing, scoring, gear levels, A/B profiles, dual spec, training, the rotation engine, the fight summary, reminders, the Fortitude button, bags, slash commands and Settings › About.
- `python3 tools/priest-changes-poller/tests/test_poller.py`: **4/4 pass**.
- `python3 tools/build_data.py --check`: up to date.
- CI (`.github/workflows/test.yml`) runs the tests on pull requests. `release.yml` packages on `v*` tags.

## Decisions and assumptions

- **Name:** Andric's Addon, folder and TOC `AndricsAddon`, repo `andrics-addon`, `/andric` with `/priest` as an alias (Addendum 2).
- **No Ace3:** built on the Blizzard API only, with no embedded libraries. This keeps it light and avoids lib-compatibility risk on Forever.
- **Gear weights:** the research gives stat priority *order*, not numbers. Weight = (n − rank + 1)/n. Hit and crit % are multiplied by **10 points per 1%**. That factor is an addon assumption (changeable in Settings › Tooltips & bags) and is labeled in-game. Healing power counts ⅓ toward damage (Wowhead) when an item doesn't state its damage part. Shadow uses leveling weights below 60 by default; Holy and Disc use healer weights (there's a toggle).
- **Tooltip stats** are parsed from English item text (`C_TooltipInfo`), because Forever items use Classic-style "Equip:" lines.
- **Fight summary** uses `UNIT_SPELLCAST_SUCCEEDED` for the player only, not the combat log. Casts the client hides are counted as hidden.
- **What's changed read-state** is account-wide; profiles and reminders are per character.
- **`research/raw/`** is gitignored (16 MB of third-party HTML). `data.json`, `sources.md` and `build_data.py` are committed.

## Open questions / gaps

1. **Dual spec: resolved.** Tim confirmed it unlocks at 40. `Core/DualSpec.lua` uses the same API as Blizzard's own Forever talent frame: `C_SpecializationInfo.GetActiveSpecGroup()`, `GetNumSpecGroups()` and the event `ACTIVE_TALENT_GROUP_CHANGED`. Talent spec 1 maps to profile A and spec 2 to profile B. Auto-switch is on by default. It still needs the in-game check listed above.
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
