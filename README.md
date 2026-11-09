# Andric's Addon

The do-everything **Priest** companion for **WoW Forever**. Pick **Holy**, **Discipline** or **Shadow** and every panel adapts: leveling, rotation help, talents, gear upgrade tips on item tooltips, class quests, training, mounts and gold goals, reminders, a full *Learn the Priest* mode, and *What's changed*.

Forever only: `AndricsAddon_Forever.toc`, `## Interface: 16001`, refuses to run unless `WOW_PROJECT_ID == 18`.

## Features

| Tab | What it does |
|---|---|
| Overview | Level, active spec/profile, next trainer visit, riding gold goal, next class quest, next milestone, unread badges |
| Rotation | Only spells you can use at your level; priority lists per spec for solo, dungeon and raid, plus an on-screen helper (next-spell suggestion for damage, priority list and cooldowns for healing) and a post-fight summary with mana tips. Advice only: nothing is automated |
| Learn the Priest | Every spell and talent (what, when, which rank, per spec), class mechanics, group play and etiquette, leveling per spec, common mistakes, and lessons that unlock as you level. Optional hint the first time you learn a spell |
| Leveling | Zones by level for your faction, dungeons near your level, new Forever zones, spec leveling notes, professions |
| Talents & builds | Each recommended build (leveling/raid/dungeon/PvP) drawn on Forever's three talent trees with points per talent and in-game tooltips, plus a list of what it takes; Forever talent changes, legacy talents |
| Gear | Spec weights; **For my level** (best researched gear you can equip now, per slot, plus what unlocks in the next 5 levels), **Best overall** (everything ranked for your spec), **By bracket** (level 20/30 lists, 40–60 and raid BiS placeholders), wands, consumables |
| Class quests | Level 4 robes and the level 10/20 racial quests with IDs and completion checks |
| Spells & training | Ranks by level, what's trainable now, next trainer level |
| Mounts & gold | 100g at 40 (Apprentice), 1000g at 60 (Journeyman) progress bars, race trainer, vendor and first-mount quest |
| Reminders | Fortitude, Inner Fire, Shadowform (Shadow), wand equipped, candles, consumables for your level |
| What's changed | Research changes plus whatever the companion poller found, with unread state |
| Sources & flags | Research gaps, conflicts between sources, addon assumptions, every source link |

**Tooltips:** hovering any item shows whether it's an upgrade for your active profile's spec versus what you have equipped in that slot, roughly how much, which stats change, and whether it's on a research gear list. If profile B has a different spec, it gets one compact line too.

**Dual-spec ready:** each character has two profiles (A/B) with their own spec, weights and rotation context. Switch manually from the header. `Core/DualSpec.lua` is the hook for automatic switching once Forever's dual-spec API is confirmed.

Slash: `/andric` (alias `/priest`), plus `/andric spec holy|disc|shadow`, `/andric profile A|B`, `/andric rotation|learn|gear|…`, `/andric hud`, `/andric reset-hud`, `/andric remind`.

## Data

Nothing is typed in by hand:

- `research/data.json`: structured Forever Priest facts; every record has `source_url` and `checked`
- `content/learn.json`: teaching text and rotation priorities, each entry sourced and flagged when unconfirmed (see `content/README.md`)
- `research/talents_priest.json`: Forever's Priest talent trees (Icy Veins calculator data for the current client build), refreshed by `tools/fetch_talents.py`. Wowhead build links are decoded onto these trees and validated (max ranks, row requirements, 51 points at 60); builds that don't fit show as a link only
- `tools/build_data.py` regenerates `Data/*.lua` from both (`--check` fails if stale)
- `tools/priest-changes-poller/` writes `Data/Changes.lua` from public feeds (see its README)

## Development

```sh
python3 tools/build_data.py                                  # regenerate Data/*.lua
lua5.1 tests/run.lua                                         # headless addon tests (strict WoW API mock)
python3 tools/priest-changes-poller/tests/test_poller.py     # poller tests
tools/install-dev.sh                                         # copy into the Forever AddOns folder
```

Releases: pushing a `v*` tag runs the BigWigs packager (`.github/workflows/release.yml`), which attaches the zip and `release.json` for OmaForge. Before tagging, run `omaforge clients` and match `## Interface` in both `.toc` files to the installed Forever client.

## License

MIT
