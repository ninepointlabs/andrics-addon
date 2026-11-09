// The Buff Button demo: the same picking order as the addon's UI/FortButton.lua.
// You first, then your group nearest first, then your target, then players with
// friendly nameplates. Skips anyone already buffed, out of range or dead.
(() => {
  const root = document.querySelector("#buff-demo");
  if (!root) return;
  const ICON = "https://render.worldofwarcraft.com/us/icons/56/spell_holy_wordfortitude.jpg";

  const START = [
    { name: "You", note: "Andric · level 24", order: 0 },
    { name: "Dax", note: "party · 8 yards", order: 1, dist: 8, buffed: true },
    { name: "Bram", note: "party · 12 yards", order: 1, dist: 12 },
    { name: "Cora", note: "party · 48 yards", order: 1, dist: 48, far: true },
    { name: "Eli", note: "party · dead", order: 1, dist: 5, dead: true },
    { name: "Thaelynn", note: "stranger · nameplate", order: 3 },
    { name: "Orsk", note: "stranger · nameplate", order: 3 },
  ];
  let people = [];
  const list = root.querySelector(".party");
  const btn = root.querySelector(".fort-btn");
  const status = root.querySelector(".demo-status");

  function eligible() {
    return people
      .filter((p) => !p.buffed && !p.dead && !p.far)
      .sort((a, b) => a.order - b.order || (a.dist ?? 0) - (b.dist ?? 0));
  }

  function reason(p) {
    if (p.dead) return ["dead · skipped", "skip"];
    if (p.far && !p.buffed) return ["out of range · skipped", "skip"];
    if (p.buffed) return ["has Fortitude", "ok"];
    return ["needs it", ""];
  }

  function render() {
    const queue = eligible();
    const next = queue[0];
    list.innerHTML = "";
    for (const p of people) {
      const li = document.createElement("li");
      li.className = "member" + (p.dead ? " dead" : "") + (p.buffed ? " buffed" : "") + (p === next ? " next" : "") + (p.flash ? " flash" : "");
      const [text, kind] = reason(p);
      li.innerHTML = `<div class="who"><b></b><span></span></div><div class="state"><span class="tag ${kind}"></span><img alt="" src="${ICON}"></div>`;
      li.querySelector("b").textContent = p.name;
      li.querySelector(".who span").textContent = p.note;
      li.querySelector(".tag").textContent = text;
      if (p.flash) {
        const f = document.createElement("span");
        f.className = "cast-float";
        f.textContent = "+ Fortitude";
        li.append(f);
        p.flash = false;
      }
      list.append(li);
    }
    btn.disabled = !next;
    status.innerHTML = next
      ? `<b>Next: ${next.name === "You" ? "you" : next.name}</b><span>${queue.length > 1 ? `${queue.length - 1} more after that` : "last one"} · press the button or <kbd>F</kbd></span>`
      : `<b>All buffed</b><span>Cora is out of range and Eli is dead, so they're skipped.</span><br><button type="button" class="wow-btn small ghost reset">Reset the demo</button>`;
    status.querySelector(".reset")?.addEventListener("click", reset);
  }

  function cast() {
    const next = eligible()[0];
    if (!next) return;
    next.buffed = true;
    next.flash = true;
    render();
    if (!eligible().length && window.andricsAchieve) {
      window.andricsAchieve("fortitude", "Fortitude for Everyone", "Buffed everyone in range with one button.", ICON, 10);
    }
  }

  function reset() {
    people = START.map((p) => ({ ...p }));
    render();
  }

  btn.addEventListener("click", cast);
  root.addEventListener("keydown", (e) => {
    if (e.key === "f" || e.key === "F") { e.preventDefault(); cast(); }
  });
  reset();
})();
