# content/learn.json

Hand-written teaching and rotation content for **Learn the Priest** and the **Rotation** tab. `tools/build_data.py` turns it into `Data/Learn.lua`.

Rules (the weekly recheck must keep to them):

- Only facts from `research/data.json` or the archived pages behind it. Every entry lists `sources`.
- Anything not stated by a source, stated by only one third-party site, or conflicting between sources gets `"unconfirmed": true` and a short `"flag"`. The addon shows the flag in-game.
- Don't invent numbers (costs, coefficients, cooldowns, durations).
- Spell keys must match `data.json` names exactly (`spells_by_level[].name`, `races_racials[].spell`); talent keys match `talent_and_other_spell_ids[].name` minus any parenthetical.

## Sections

`spells`, `talents`, `mechanics`, `roles`, `leveling` (per spec), `mistakes`, `lessons` (unlock at `level`, optional `spec`), `first_learn_hints`, `rotation`.

`rotation.<Spec>.<solo|dungeon|raid>` = `{ summary, kind: damage|healing, priority: [{spell, when, note}], tips, unconfirmed, flag, sources }`.

`when` must be one the engine (`Modules/Rotation.lua`) understands:
`always`, `buff_missing`, `debuff_missing`, `ready`, `no_weakened_soul`, `out_of_combat`, `mana_above:N`, `mana_below:N`, `target_hp_below:N`, `proc:<Buff name>`. `spell: "Wand"` means "use your wand". `tests/run.lua` fails if a step uses anything else or names a spell with no known ID.

After editing: `python3 tools/build_data.py && lua5.1 tests/run.lua`.
