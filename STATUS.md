# STATUS: Andric's Addon (2026-11-09)

**PR:** https://github.com/ninepointlabs/andrics-addon/pull/1 (branch `feature/initial-addon`). Not merged, no tag, no release.
**Repo:** `ninepointlabs/andrics-addon` (private). Local checkout: `/home/tim/Projects/wow-forever-priest-addon`. The folder name was kept from the original brief; rename it if you like.

## Client / Interface

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
3. **Profiles:** use the header buttons A/B. Set B to another spec under Options, switch, and every panel should follow.
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

**Not verified:** anything in the real client (layout, fonts, the tooltip hook, aura/cooldown reads under the Midnight-style restrictions). I also could not run the BigWigs packager locally (auto-mode blocked downloading and running its script), so it is unconfirmed whether the packager handles the `_Forever.toc` suffix next to the plain `.toc`. Storytracker's plain `.toc` produced `release.json` with `flavor: forever / 16001`.

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

1. **Dual spec: the brief and Blizzard disagree.** Blizzard's Priest deep dive says *"Dual Specialization also becomes available at level 40."* The brief says Forever doesn't have it yet. In-game it's flagged, not asserted. On a level-40+ character, can you check whether a second talent spec exists? If it does, I need the real API or event name to wire `Core/DualSpec.lua` (nothing has been guessed).
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
