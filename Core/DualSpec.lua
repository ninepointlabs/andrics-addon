-- Dual-spec hook (STUB).
--
-- Blizzard's Priest deep dive says "Dual Specialization also becomes available at
-- level 40", but it was not verified in the live client and no Forever API for it
-- is known, so nothing is guessed here. The data model already keeps two profiles per
-- character (A/B). When Blizzard ships dual spec on Forever:
--
--   1. Confirm the real API/event in the Forever client (e.g. read
--      Interface/AddOns/Blizzard_* in Gethe/wow-ui-source@forever). Do NOT guess.
--   2. Set DualSpec.provider = { event = "<EVENT>", activeGroup = function() return <1|2> end }
--   3. Users opt in with the "Auto-switch profile" option (char.autoSwitch).
--
-- Until then nothing is registered and profile switching is manual.
local _, ns = ...

local DualSpec = {}
ns.DualSpec = DualSpec

DualSpec.provider = nil -- intentionally empty: no Forever dual-spec API is known yet
DualSpec.GROUP_TO_PROFILE = { [1] = "A", [2] = "B" }

function DualSpec.IsAvailable()
    return DualSpec.provider ~= nil
end

-- Single entry point for any future talent-group change notification.
function DualSpec.OnTalentGroupChanged(groupIndex)
    if not ns.DB.char.autoSwitch then return false end
    local id = DualSpec.GROUP_TO_PROFILE[groupIndex]
    if not id then return false end
    return ns.DB.SwitchProfile(id)
end

function DualSpec.Register(frame)
    local p = DualSpec.provider
    if not p or not p.event then return end
    frame:RegisterEvent(p.event)
    ns.On("WOW_" .. p.event, function()
        local ok, group = pcall(p.activeGroup)
        if ok then DualSpec.OnTalentGroupChanged(group) end
    end)
end
