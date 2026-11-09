# Andric's Addon

**Website:** https://andricsaddon.myazerothlife.com (GitHub Pages from `docs/`, styled like [My Azeroth Life](https://myazerothlife.com/))

The do-everything **Priest** companion for **WoW Forever**. Pick **Holy**, **Discipline** or **Shadow** and every panel adapts: leveling, rotation help, talents, gear upgrade tips on item tooltips, class quests, training, mounts and gold goals, reminders, a full *Learn the Priest* mode, and *What's changed*.

Forever only: `AndricsAddon_Forever.toc`, `## Interface: 16001`, refuses to run unless `WOW_PROJECT_ID == 18`.

## Features

The window has a grouped sidebar (with search for spells, talents, items, quests and dungeons), a spec pill and an A/B profile switch in the header, and one sub-tab bar per screen. Sources and research notes sit behind a "Sources & notes" link on each screen.

| Screen | Sub-tabs / what it does |
|---|---|
| **Home** | "Do next" cards (trainer, riding savings, next class quest), "Needs attention" (missing buffs, upgrades in your bags, unread news and lessons), your rotation at a glance, latest changes |
| **Play › Rotation** | Solo · Dungeon · Raid. Only spells you can use at your level; on-screen helper toggle, the plan, tips, last-fight summary. Advice only: nothing is automated |
| **Play › Gear** | For my level · Best overall (best item per slot + detail panel: what it gives you, how to get it, map pin, other options) · By bracket · Consumables · Weights |
| **Progress › Leveling** | Path (what's next by level) · Zones & dungeons · Trainer · Class quests · Riding & gold |
| **Progress › Talents** | Recommended builds drawn on Forever's talent trees, what each build takes, Forever talent changes, legacy talents |
| **Learn the Priest** | Lessons · Spells · Talents · How the class works · In a group · Leveling · Common mistakes |
| **What's new** | Research changes plus what the companion poller found, with unread state |
| **Settings** | General · Fortitude button · Tooltips & bags · Reminders · About the data (gaps, conflicts, assumptions, sources) |

**Tooltips:** hovering any item shows whether it's an upgrade for your active profile's spec versus what you have equipped in that slot (named), roughly how much, a **What improves / What you'd lose** list (e.g. "+10 Intellect (+150 max mana, +0.17% spell crit)", using only documented conversions), and a green **Equip this** line when it's an upgrade you can wear now (or "Upgrade once you reach level N"). If profile B has a different spec, it gets one compact line too.

**Gear details:** click any item in the Gear tab for its comparison, who drops it (and the drop chance) in which dungeon, which quest rewards it (level, faction, quest giver and coordinates), or how it's crafted. **Mark on map** sets a map pin with the guide arrow on the quest giver or the dungeon entrance (entrances come from the game's own map data).

**Fortitude button ("Buff next"):** a small on-screen button. Each press casts Power Word: Fortitude on the next friendly player who doesn't have it (Prayer of Fortitude counts) and is in range. Order: you, your group (nearest first when the game reports distance), your target, then players whose friendly nameplates are showing. Set a key for it in Options ("Set key", or `/andric fort key`); `/andric fort` shows/hides it. (There's no action-bar macro: Forever's `/click` won't press addon buttons, and a self-rewriting macro didn't fire either.) Blizzard rules: one cast per press, and the target can only change out of combat.

**Bags:** upgrades you can equip now get a green glow and arrow on their bag slot (our own overlay, so it doesn't fight Pawn's arrow). When a new one lands in your bags you get a chat line and a toast, once per item. Both can be turned off in Options.

**Dual-spec ready:** each character has two profiles (A/B) with their own spec, weights and rotation context. Switch manually from the header. `Core/DualSpec.lua` is the hook for automatic switching once Forever's dual-spec API is confirmed.

Slash: `/andric` (alias `/priest`), plus `/andric spec holy|disc|shadow`, `/andric profile A|B`, `/andric rotation|learn|gear|…`, `/andric hud`, `/andric reset-hud`, `/andric remind`.

## Data

Nothing is typed in by hand:

- `research/data.json`: structured Forever Priest facts; every record has `source_url` and `checked`
- `content/learn.json`: teaching text and rotation priorities, each entry sourced and flagged when unconfirmed (see `content/README.md`)
- `research/talents_priest.json`: Forever's Priest talent trees (Icy Veins calculator data for the current client build), refreshed by `tools/fetch_talents.py`. Wowhead build links are decoded onto these trees and validated (max ranks, row requirements, 51 points at 60); builds that don't fit show as a link only
- `research/item_sources.json`: where each researched item comes from (boss + drop chance, quest + giver + coordinates, crafting profession + reagents, vendor), from the Icy Veins Forever DB via `tools/fetch_item_sources.py`. Gaps stay empty, never guessed
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
