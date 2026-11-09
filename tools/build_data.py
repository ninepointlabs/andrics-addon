#!/usr/bin/env python3
"""Regenerate the addon's static Lua data from the research JSON.

    python3 tools/build_data.py            # write Data/*.lua
    python3 tools/build_data.py --check    # exit 1 if Data/*.lua is stale

Inputs:
    research/data.json   structured Forever Priest facts (every record carries
                         source_url + checked; those are kept in the Lua so the
                         addon can cite them in-game)
    content/learn.json   teaching text + rotation priorities (hand-written,
                         sourced; see content/README.md)

Nothing in Data/*.lua is typed by hand: change the JSON and re-run this.
Data/Changes.lua is NOT written here; the change poller owns it.
"""
from __future__ import annotations

import argparse
import json
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
RESEARCH = ROOT / "research" / "data.json"
LEARN = ROOT / "content" / "learn.json"
TALENTS = ROOT / "research" / "talents_priest.json"
OUT = ROOT / "Data"

SPECS = ("Shadow", "Holy", "Discipline")

# --- stat priority -> stat keys ------------------------------------------------
# Each token of a research priority string ("Hit to 17% cap > Crit > ...") maps
# to one engine stat key. An unknown token is an error so a research update that
# introduces a new stat cannot be silently ignored.
STAT_TOKENS = [
    (r"^hit\b", "SPELL_HIT"),
    (r"^crit\b", "SPELL_CRIT"),
    (r"^spell/shadow damage$", "DAMAGE"),
    (r"^spell power$", "DAMAGE"),
    (r"^spell damage$", "SPELL_DAMAGE"),
    (r"^healing power$", "HEALING"),
    (r"^intellect$", "INT"),
    (r"^spirit$", "SPI"),
    (r"^stamina$", "STA"),
    (r"^mp5$", "MP5"),
]


def parse_priority(text: str) -> list[str]:
    keys = []
    for raw in text.split(">"):
        token = re.sub(r"\(.*?\)", "", raw).strip().lower()
        for pattern, key in STAT_TOKENS:
            if re.search(pattern, token):
                keys.append(key)
                break
        else:
            raise SystemExit(f"build_data: unknown stat token {raw.strip()!r} in priority {text!r}")
    return keys


# --- spell name aliases used in rotation strings ------------------------------
ALIASES = {
    "Shadow Word: Pain": ["SW:Pain", "SW:P", "Shadow Word: Pain"],
    "Power Word: Shield": ["PW:Shield", "PW:S", "Power Word: Shield"],
    "Power Word: Fortitude": ["Fortitude", "Fort"],
    "Mind Flay (talent)": ["Mind Flay"],
}


def key_spells(rotation_text: str, spell_names: list[str]) -> list[str]:
    found = []
    for name in spell_names:
        for alias in ALIASES.get(name, [name]):
            if re.search(r"(?<![\w])" + re.escape(alias) + r"(?![\w])", rotation_text):
                found.append(name)
                break
    return found


# --- talent builds --------------------------------------------------------------
# Wowhead Forever talent-calc URLs look like
#   .../talent-calc/priest/v2<disc>-<holy>-<shadow>_t0/<order>   or   v<letters><disc>-...
# "v" plus a version tag (one digit, or a run of lower-case letters), then one digit
# per talent (points spent) in grid order (row by row, empty cells skipped), trees
# separated by "-", trailing zeros/trees omitted. The rule was derived from the
# research builds: every level-60 build decodes to exactly 51 points with all max
# ranks and row requirements satisfied. Anything that fails validation is shipped
# as invalid (the addon then shows the link only).
BUILD_RE = re.compile(r"/talent-calc/priest/v(?:[a-z]+|\d)([0-9-]*)")


def decode_build(url: str, trees: list[dict]) -> dict:
    m = BUILD_RE.search(url or "")
    if not m:
        return {"valid": False, "reason": "not a Wowhead talent-calc build link"}
    parts = m.group(1).split("-")
    if len(parts) > len(trees):
        return {"valid": False, "reason": "more trees than the class has"}
    parts += [""] * (len(trees) - len(parts))
    out_trees, total = [], 0
    for tree, digits in zip(trees, parts):
        talents = tree["talents"]
        if len(digits) > len(talents):
            return {"valid": False, "reason": f"{tree['name']}: more talents than the tree has"}
        pts = [int(c) for c in digits] + [0] * (len(talents) - len(digits))
        for t, p in zip(talents, pts):
            if p > t["max_rank"]:
                return {"valid": False, "reason": f"{t['name']}: {p} points but max rank is {t['max_rank']} (tree changed?)"}
            above = sum(pp for tt, pp in zip(talents, pts) if tt["row"] < t["row"])
            if p and above < t["required_points"]:
                return {"valid": False, "reason": f"{t['name']} needs {t['required_points']} points above it"}
        spent = sum(pts)
        total += spent
        out_trees.append({"points": pts, "spent": spent})
    if total > 51:
        return {"valid": False, "reason": f"{total} points (max 51 at level 60)"}
    return {"valid": True, "total": total, "level": total + 9, "trees": out_trees}


# --- Lua serialisation ----------------------------------------------------------
LUA_IDENT = re.compile(r"^[A-Za-z_][A-Za-z0-9_]*$")
LUA_KEYWORDS = set("and break do else elseif end false for function if in local nil not or repeat return then true until while".split())


# The WoW default font (Friz Quadrata) lacks many Unicode glyphs; map typographic
# punctuation to ASCII so text never renders as boxes.
PUNCT = {"\u2014": "-", "\u2013": "-", "\u2018": "'", "\u2019": "'", "\u201c": '"', "\u201d": '"',
         "\u2026": "...", "\u2192": "->", "\u2022": "-", "\u00a0": " ", "\u2212": "-", "\u00d7": "x"}


def lua_str(s: str) -> str:
    for k, v in PUNCT.items():
        s = s.replace(k, v)
    s = s.replace("\\", "\\\\").replace('"', '\\"').replace("\n", "\\n").replace("\r", "")
    return f'"{s}"'


def lua(value, indent: int = 0) -> str:
    pad = "  " * indent
    inner = "  " * (indent + 1)
    if value is None:
        return "nil"
    if isinstance(value, bool):
        return "true" if value else "false"
    if isinstance(value, (int, float)):
        return repr(value)
    if isinstance(value, str):
        return lua_str(value)
    if isinstance(value, list):
        if not value:
            return "{}"
        if all(isinstance(v, (int, float, str, bool)) for v in value) and len(value) <= 12:
            return "{ " + ", ".join(lua(v) for v in value) + " }"
        return "{\n" + "".join(f"{inner}{lua(v, indent + 1)},\n" for v in value) + pad + "}"
    if isinstance(value, dict):
        items = [(k, v) for k, v in value.items() if v is not None]
        if not items:
            return "{}"
        out = []
        for k, v in items:
            if isinstance(k, str) and LUA_IDENT.match(k) and k not in LUA_KEYWORDS:
                key = k
            elif isinstance(k, int):
                key = f"[{k}]"
            else:
                key = f"[{lua_str(str(k))}]"
            out.append(f"{inner}{key} = {lua(v, indent + 1)},\n")
        return "{\n" + "".join(out) + pad + "}"
    raise TypeError(f"cannot serialise {type(value)}")


HEADER = """-- GENERATED by tools/build_data.py from {inputs}. Do not edit by hand.
-- Every record keeps source_url/checked from the research so the addon can cite it.
local _, ns = ...
ns.Data = ns.Data or {{}}
"""


def write(name: str, tables: dict, inputs: str, files: dict[str, str]) -> None:
    body = HEADER.format(inputs=inputs)
    for key, value in tables.items():
        body += f"\nns.Data.{key} = {lua(value)}\n"
    files[name] = body


# --- transforms -------------------------------------------------------------------
def to_int(v):
    try:
        return int(v)
    except (TypeError, ValueError):
        return v


def build(data: dict, learn: dict | None, talents: dict | None = None) -> dict[str, str]:
    files: dict[str, str] = {}
    src = "research/data.json"

    meta = dict(data["meta"])
    meta["toc_interface"] = to_int(meta["toc_interface"])
    meta["max_level"] = to_int(meta["max_level"])
    write("Meta.lua", {"Meta": meta, "Sources": data["sources"]}, src, files)

    # Spells: rank levels, ids, plus per-spec key-spell flags derived from the
    # research rotation strings.
    spells = []
    for s in data["spells_by_level"]:
        rec = dict(s)
        rec["talent"] = "(talent)" in s["name"]
        rec["display"] = s["name"].replace(" (talent)", "")
        spells.append(rec)
    names = [s["name"] for s in data["spells_by_level"]]
    rot = data["rotations"]
    shadow_text = rot["shadow"]
    holy_text = rot["holy"][0] if isinstance(rot["holy"], list) else rot["holy"]
    disc_text = rot["disc_heal"][0] if isinstance(rot["disc_heal"], list) else rot["disc_heal"]
    key = {
        "Shadow": key_spells(shadow_text, names),
        "Holy": key_spells(holy_text, names),
        "Discipline": key_spells(disc_text, names),
    }
    trainer_levels = sorted({lvl for s in data["spells_by_level"] for lvl in s["rank_learn_levels"]})
    write("Spells.lua", {
        "Spells": spells,
        "TrainerLevels": trainer_levels,
        "KeySpells": key,
        "TalentSpells": data["talent_and_other_spell_ids"],
        "Milestones": data["milestones"],
        "LegacyTalents": data["legacy_talents"],
    }, src, files)

    write("Quests.lua", {
        "Quests": data["quests"],
        "Racials": data["races_racials"],
        "RacialPassives": data["racial_passive_changes"],
        "RaceNotes": data["race_recommendations"],
        "ClassTrainers": data["class_trainers"],
    }, src, files)

    builds = {spec: [] for spec in SPECS}
    builds["Other"] = []
    for b in data["builds"]:
        builds[b["spec"] if b["spec"] in SPECS else "Other"].append(b)
    write("Builds.lua", {
        "Builds": builds,
        "TalentChanges": data["talent_changes"],
        "Rotations": data["rotations"],
    }, src, files)

    priorities = {}
    for p in data["stat_priority"]:
        if p["spec"] == "Conversions":
            continue
        priorities[p["spec"]] = {"keys": parse_priority(p["priority"]), "text": p["priority"],
                                 "source_url": p["source_url"], "checked": p["checked"]}
    conversions = next((p for p in data["stat_priority"] if p["spec"] == "Conversions"), None)

    brackets: dict[str, list] = {}
    for g in data["gear_by_bracket"]:
        brackets.setdefault(g["bracket"], []).append(g)
    write("Gear.lua", {
        "GearBrackets": brackets,
        # Brackets the UI always shows; any without data renders as "not published yet".
        "GearBracketOrder": ["level 20", "level 30", "level 40", "level 50", "level 60 pre-raid", "raid BiS"],
        "Wands": data["wands"],
        "OtherWeapons": data["other_weapons"],
        "BiS": data["bis"],
        "StatPriority": priorities,
        "StatConversions": conversions,
        "Consumables": data["consumables_enchants"],
        "Reagents": data["reagents"],
        "Professions": data["professions"],
    }, src, files)

    write("World.lua", {
        "Zones": data["zones_by_level"],
        "NewZones": data["new_zones"],
        "Dungeons": [dict(d, new_in_forever=str(d["new_in_forever"]).lower() == "true", levels=d["levels"]) for d in data["dungeons"]],
        "Raids": data["raids"],
        "RaidRules": data["raid_rules"],
        "Roadmap": data["roadmap"],
        "Riding": data["riding"],
        "Mounts": data["mounts"],
    }, src, files)

    write("Notes.lua", {
        "Gaps": data["gaps"],
        "ChangesLog": data["changes_log"],
        "ChangeSources": data["change_sources"],
        "Addons": data["addons"],
        "AddonDev": data["addon_dev"],
    }, src, files)

    if talents is not None:
        trees = talents["trees"]
        decoded = []
        for b in data["builds"]:
            if not b.get("talent_calc_url"):
                continue
            rec = {"spec": b["spec"], "purpose": b["purpose"], "url": b["talent_calc_url"],
                   "source_url": b["source_url"], "checked": b["checked"]}
            rec.update(decode_build(b["talent_calc_url"], trees))
            decoded.append(rec)
        meta = {k: talents[k] for k in ("version", "client_build", "source_url", "page_url", "checked")}
        write("Talents.lua", {"TalentTrees": trees, "TalentTreesMeta": meta, "DecodedBuilds": decoded},
              "research/talents_priest.json + research/data.json builds", files)

    if learn is not None:
        write("Learn.lua", {"Learn": learn}, "content/learn.json", files)
    else:
        files["Learn.lua"] = HEADER.format(inputs="(content/learn.json missing)") + "\nns.Data.Learn = nil\n"
    return files


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--check", action="store_true", help="fail if generated files are out of date")
    ap.add_argument("--data", type=Path, default=RESEARCH)
    ap.add_argument("--learn", type=Path, default=LEARN)
    ap.add_argument("--talents", type=Path, default=TALENTS)
    ap.add_argument("--out", type=Path, default=OUT)
    args = ap.parse_args()

    data = json.loads(args.data.read_text(encoding="utf-8"))
    learn = json.loads(args.learn.read_text(encoding="utf-8")) if args.learn.exists() else None
    talents = json.loads(args.talents.read_text(encoding="utf-8")) if args.talents.exists() else None
    files = build(data, learn, talents)

    args.out.mkdir(parents=True, exist_ok=True)
    stale = []
    for name, body in files.items():
        path = args.out / name
        if path.exists() and path.read_text(encoding="utf-8") == body:
            continue
        stale.append(name)
        if not args.check:
            path.write_text(body, encoding="utf-8")
    if args.check:
        if stale:
            print("stale:", ", ".join(stale))
            return 1
        print("Data/*.lua up to date")
        return 0
    print(f"wrote {len(stale)} file(s): {', '.join(stale) or 'none changed'}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
