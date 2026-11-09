-- Item tooltip: spec-aware upgrade tips vs. the equipped item in the same slot.
local _, ns = ...

local Tooltip = {}
ns.Tooltip = Tooltip

local GREEN, RED, GREY, GOLD = "|cff3fdc5a", "|cffff5050", "|cff9a9a9a", "|cffffd200"

-- itemID -> research notes (gear lists, wands) so the tooltip can say "recommended".
local index
local function ResearchIndex()
    if index then return index end
    index = {}
    for bracket, list in pairs(ns.Data.GearBrackets or {}) do
        for _, g in ipairs(list) do
            index[g.item_id] = index[g.item_id] or {}
            table.insert(index[g.item_id], bracket .. " list (" .. (g.source or "?") .. ")")
        end
    end
    for _, w in ipairs(ns.Data.Wands or {}) do
        index[w.item_id] = index[w.item_id] or {}
        if w.dps then table.insert(index[w.item_id], ("wand list: %.1f DPS"):format(w.dps)) end
    end
    return index
end
Tooltip.ResearchIndex = ResearchIndex

local function pctText(v) return ("%+.1f%%"):format(v) end

-- Build tooltip lines for a link and spec. Pure (returns strings) for testing.
function Tooltip.LinesFor(link, spec, profile, level, percentScale, opts)
    opts = opts or {}
    local lines = {}
    local res = ns.Stats.Compare(link, spec, level, profile, percentScale, opts.itemInfo, opts.equippedLink)
    if not res then return lines end
    local head = GOLD .. ns.TITLE .. "|r " .. GREY .. "· " .. (spec or "no spec picked") .. "|r"
    if res.unusable then
        table.insert(lines, head .. "  " .. RED .. "Priests can't use this|r")
        return lines
    end
    if res.pending then
        table.insert(lines, head .. "  " .. GREY .. "loading item data...|r")
        return lines
    end
    local setLabel = (res.setName == "Leveling") and "leveling weights" or (res.setName .. " weights")
    table.insert(lines, head .. GREY .. " (" .. setLabel .. ")|r")
    if res.isEquipped then
        table.insert(lines, GREY .. "Equipped|r")
        return lines
    end
    local against = res.against
    if against.empty then
        table.insert(lines, GREEN .. "Upgrade: slot is empty|r")
    elseif math.abs(res.delta) < 0.05 then
        table.insert(lines, GREY .. "= Sidegrade vs equipped|r")
    elseif res.delta > 0 then
        table.insert(lines, GREEN .. "Upgrade " .. (res.pct and pctText(res.pct) or ("+" .. ("%.1f"):format(res.delta) .. " score")) .. " vs equipped|r")
    else
        table.insert(lines, RED .. "Downgrade " .. (res.pct and pctText(res.pct) or (("%.1f"):format(res.delta) .. " score")) .. " vs equipped|r")
    end
    if res.wandDelta and math.abs(res.wandDelta) > 0.05 then
        table.insert(lines, (res.wandDelta > 0 and GREEN or RED) .. ("Wand DPS %+.1f|r"):format(res.wandDelta))
    end
    if opts.showStats ~= false then
        local parts = {}
        local prio = ns.Data.StatPriority[res.setName]
        for _, key in ipairs(prio and prio.keys or {}) do
            local d = res.statDelta[key]
            if d then
                local txt = (d > 0 and "+" or "") .. (d % 1 == 0 and tostring(d) or ("%.1f"):format(d))
                table.insert(parts, (d > 0 and GREEN or RED) .. txt .. " " .. ns.Stats.LABELS[key] .. "|r")
            end
        end
        if #parts > 0 then table.insert(lines, table.concat(parts, GREY .. ", |r")) end
    end
    local itemID = tonumber(link:match("item:(%d+)"))
    local notes = itemID and ResearchIndex()[itemID]
    if notes then table.insert(lines, GOLD .. "Recommended: |r" .. table.concat(notes, "; ")) end
    table.insert(lines, GREY .. "Estimate from research stat priority order; % stats ×" .. (percentScale or 10) .. " (addon assumption)|r")
    return lines
end

local function OnItem(tooltip, needShow)
    if not ns.db or not ns.db.global.tooltip.enabled then return end
    if tooltip ~= GameTooltip and tooltip ~= ItemRefTooltip then return end
    local ok, _, link = pcall(tooltip.GetItem, tooltip)
    if not ok or not link then return end
    local level = UnitLevel("player")
    local g = ns.db.global
    local spec = ns.DB.ActiveSpec()
    local lines = Tooltip.LinesFor(link, spec, ns.DB.Profile(), level, g.percentScale, { showStats = g.tooltip.showStats })
    if #lines == 0 then return end
    tooltip:AddLine(" ")
    for _, l in ipairs(lines) do tooltip:AddLine(l, 1, 1, 1, true) end
    -- Second profile (dual-spec ready): one compact line if it has a different spec.
    local other = ns.DB.Profile(ns.DB.OtherProfileId())
    if other.spec and other.spec ~= spec then
        local res = ns.Stats.Compare(link, other.spec, level, other, g.percentScale)
        if res and res.delta and not res.isEquipped then
            local col = res.delta > 0.05 and GREEN or (res.delta < -0.05 and RED or GREY)
            local txt = res.against.empty and "upgrade (empty slot)" or (res.pct and ("%+.1f%%"):format(res.pct) or ("%+.1f"):format(res.delta))
            tooltip:AddLine(GREY .. "Profile " .. ns.DB.OtherProfileId() .. " (" .. other.spec .. "): |r" .. col .. txt .. "|r")
        end
    end
    if needShow then tooltip:Show() end -- legacy hook path needs a resize; the data processor lays out itself
end

function Tooltip.Install()
    if Tooltip.installed then return end
    Tooltip.installed = true
    if TooltipDataProcessor and TooltipDataProcessor.AddTooltipPostCall and Enum and Enum.TooltipDataType then
        TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Item, function(tt) pcall(OnItem, tt) end)
    else
        GameTooltip:HookScript("OnTooltipSetItem", function(tt) pcall(OnItem, tt, true) end)
    end
end
