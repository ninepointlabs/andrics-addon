-- Main window: header (spec chip + profile A/B), sidebar tabs, scrolling content,
-- and the first-run spec picker overlay.
local _, ns = ...
local UI = ns.UI

ns.Panels = {}
ns.PanelOrder = {}

-- Panels register themselves: { key, label, icon, render(layout, ctx), badge() }
function UI.RegisterPanel(p)
    ns.Panels[p.key] = p
    table.insert(ns.PanelOrder, p.key)
end

local W, H, SIDE = 920, 620, 178
-- Fixed content width: GetWidth() on an anchored frame can be 0 before the first layout pass.
local CONTENT_W = W - SIDE - 2 - 18 - 30 - 24
local frame

local function ctx()
    local level = UnitLevel("player") or 1
    local _, faction = UnitFactionGroup("player")
    return {
        spec = ns.DB.ActiveSpec(),
        profile = ns.DB.Profile(),
        level = level,
        race = ns.Progress.PlayerRace(),
        faction = UnitFactionGroup("player") or faction,
        name = UnitName("player"),
    }
end
UI.Ctx = ctx

local function ApplyAccent()
    if not frame then return end
    local a = UI.Accent()
    frame.topLine:SetColorTexture(a[1], a[2], a[3], 0.9)
    frame.title:SetTextColor(a[1], a[2], a[3])
    local spec = ns.DB.ActiveSpec()
    local s = ns.Specs[spec]
    frame.specIcon:SetTexture(s and s.icon or "Interface\\Icons\\INV_Misc_QuestionMark")
    frame.specText:SetText(s and (UI.Hex(a) .. spec .. "|r  " .. UI.Hex(UI.C.dim) .. s.role .. "|r") or (UI.Hex(UI.C.dim) .. "No spec picked|r"))
    for _, id in ipairs(ns.DB.PROFILE_IDS) do
        local b = frame.profileButtons[id]
        local p = ns.DB.Profile(id)
        b.label:SetText(id .. (p.spec and (": " .. p.spec:sub(1, 4)) or ": -"))
        b.tip = ("Profile %s%s. Two profiles per character, ready for dual spec. Switch manually for now."):format(id, p.spec and (" (" .. p.spec .. ")") or "")
        b:SetActive(ns.DB.ActiveId() == id)
    end
end

local function UpdateTabs()
    for _, key in ipairs(ns.PanelOrder) do
        local tab = frame.tabs[key]
        local p = ns.Panels[key]
        local selected = frame.current == key
        local a = UI.Accent()
        tab.bar:SetColorTexture(a[1], a[2], a[3], selected and 1 or 0)
        tab.bg:SetColorTexture(1, 1, 1, selected and 0.06 or 0)
        tab.text:SetTextColor(unpack(selected and a or UI.C.text))
        local n = p.badge and p.badge() or 0
        if n and n > 0 then
            tab.badge.text:SetText(n > 99 and "99+" or tostring(n))
            tab.badge:SetWidth(math.max(18, tab.badge.text:GetStringWidth() + 10))
            tab.badge:Show()
        else
            tab.badge:Hide()
        end
    end
end

function UI.Refresh()
    if not frame or not frame:IsShown() then return end
    ApplyAccent()
    UpdateTabs()
    local key = frame.current
    local p = ns.Panels[key]
    local view = key and frame.views[key]
    if not view then return end
    view.layout:Reset(CONTENT_W)
    local ok, err = pcall(p.render, view.layout, ctx())
    if not ok then
        view.layout:Text(UI.Hex(UI.C.bad) .. "This panel hit an error: " .. tostring(err) .. "|r")
        ns.Debug(err)
    end
    view.layout:Finish()
    frame.picker:SetShown(not ns.DB.HasChosenSpec() or frame.forcePicker)
end

function UI.Select(key)
    if not ns.Panels[key] then key = "overview" end
    UI.Build()
    if frame.current and frame.views[frame.current] then frame.views[frame.current].content:Hide() end
    frame.current = key
    ns.db.char.window.tab = key
    local view = frame.views[key]
    if not view then
        local content = CreateFrame("Frame", nil, frame.scroll)
        content:SetSize(CONTENT_W + 20, 1)
        view = { content = content, layout = UI.NewLayout(content, CONTENT_W) }
        frame.views[key] = view
    end
    frame.scroll:SetScrollChild(view.content)
    view.content:Show()
    frame.scroll:SetVerticalScroll(0)
    UI.Refresh()
end

local function BuildPicker(parent)
    local f = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    f:SetPoint("TOPLEFT", parent.body, "TOPLEFT")
    f:SetPoint("BOTTOMRIGHT", parent.body, "BOTTOMRIGHT")
    f:SetFrameLevel(parent:GetFrameLevel() + 20)
    UI.Backdrop(f, { 0.04, 0.04, 0.06, 0.98 }, { 0, 0, 0, 0 })
    f:EnableMouse(true)
    local title = UI.Text(f, 20)
    title:SetPoint("TOP", 0, -40)
    title:SetJustifyH("CENTER")
    f.title = title
    local sub = UI.Text(f, 12, UI.C.dim)
    sub:SetPoint("TOP", title, "BOTTOM", 0, -8)
    sub:SetWidth(560)
    sub:SetJustifyH("CENTER")
    sub:SetText("Every panel (leveling, talents, rotation, gear tips, reminders, lessons) adapts to this choice. Change it any time; profile B can hold a second spec for when Forever gets dual spec.")
    f.cards = {}
    local cardW, gap = 210, 18
    local total = cardW * 3 + gap * 2
    for i, key in ipairs(ns.SPEC_ORDER) do
        local s = ns.Specs[key]
        local c = CreateFrame("Button", nil, f, "BackdropTemplate")
        c:SetSize(cardW, 250)
        c:SetPoint("TOPLEFT", f, "TOP", -total / 2 + (i - 1) * (cardW + gap), -120)
        UI.Backdrop(c, UI.C.card, UI.C.border)
        local icon = c:CreateTexture(nil, "ARTWORK")
        icon:SetSize(64, 64)
        icon:SetPoint("TOP", 0, -24)
        icon:SetTexture(s.icon)
        icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
        local name = UI.Text(c, 18, s.accent)
        name:SetPoint("TOP", icon, "BOTTOM", 0, -14)
        name:SetJustifyH("CENTER")
        name:SetText(key)
        local role = UI.Text(c, 11, UI.C.dim)
        role:SetPoint("TOP", name, "BOTTOM", 0, -4)
        role:SetJustifyH("CENTER")
        role:SetText(s.role)
        local blurb = UI.Text(c, 12)
        blurb:SetPoint("TOP", role, "BOTTOM", 0, -12)
        blurb:SetWidth(cardW - 28)
        blurb:SetJustifyH("CENTER")
        blurb:SetText(s.blurb)
        c:SetScript("OnEnter", function(self) self:SetBackdropBorderColor(unpack(s.accent)) self:SetBackdropColor(unpack(UI.C.cardHover)) end)
        c:SetScript("OnLeave", function(self) self:SetBackdropBorderColor(unpack(UI.C.border)) self:SetBackdropColor(unpack(UI.C.card)) end)
        c:SetScript("OnClick", function()
            ns.DB.SetSpec(key)
            parent.forcePicker = false
            UI.Refresh()
        end)
        f.cards[key] = c
    end
    f:SetScript("OnShow", function()
        f.title:SetText(("Pick a spec for profile %s"):format(ns.DB.ActiveId()))
    end)
    f:Hide()
    return f
end

function UI.Build()
    if frame then return frame end
    frame = CreateFrame("Frame", "AndricsAddonFrame", UIParent, "BackdropTemplate")
    frame:SetSize(W, H)
    frame:SetPoint("CENTER")
    frame:SetFrameStrata("HIGH")
    frame:SetToplevel(true)
    frame:SetClampedToScreen(true)
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", frame.StartMoving)
    frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
    UI.Backdrop(frame, UI.C.bg, UI.C.border)
    table.insert(UISpecialFrames, "AndricsAddonFrame")
    frame.views, frame.tabs = {}, {}

    -- Header
    frame.topLine = frame:CreateTexture(nil, "OVERLAY")
    frame.topLine:SetPoint("TOPLEFT", 1, -1)
    frame.topLine:SetPoint("TOPRIGHT", -1, -1)
    frame.topLine:SetHeight(2)
    local logo = frame:CreateTexture(nil, "ARTWORK")
    logo:SetSize(22, 22)
    logo:SetPoint("TOPLEFT", 14, -14)
    logo:SetTexture("Interface\\Icons\\Spell_Holy_WordFortitude")
    logo:SetTexCoord(0.07, 0.93, 0.07, 0.93)
    frame.title = UI.Text(frame, 17)
    frame.title:SetPoint("LEFT", logo, "RIGHT", 8, 0)
    frame.title:SetText(ns.TITLE)
    local ver = UI.Text(frame, 10, UI.C.dim)
    ver:SetPoint("LEFT", frame.title, "RIGHT", 8, -1)
    ver:SetText("v" .. ns.VERSION .. " · WoW Forever")

    local close = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
    close:SetPoint("TOPRIGHT", -4, -6)

    frame.specIcon = frame:CreateTexture(nil, "ARTWORK")
    frame.specIcon:SetSize(24, 24)
    frame.specIcon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
    frame.specText = UI.Text(frame, 13)
    frame.specText:SetWordWrap(false)

    frame.profileButtons = {}
    local prev
    for i = #ns.DB.PROFILE_IDS, 1, -1 do
        local id = ns.DB.PROFILE_IDS[i]
        local b = UI.Button(frame, id, 74, 24, function()
            ns.DB.SwitchProfile(id)
            UI.Refresh()
        end)
        if prev then b:SetPoint("RIGHT", prev, "LEFT", -6, 0) else b:SetPoint("TOPRIGHT", -40, -13) end
        frame.profileButtons[id] = b
        prev = b
    end
    local change = UI.Button(frame, "Change spec", 100, 24, function()
        frame.forcePicker = true
        UI.Refresh()
    end)
    change:SetPoint("RIGHT", prev, "LEFT", -12, 0)
    frame.specText:SetPoint("RIGHT", change, "LEFT", -12, 0)
    frame.specIcon:SetPoint("RIGHT", frame.specText, "LEFT", -8, 0)

    -- Sidebar
    local side = CreateFrame("Frame", nil, frame, "BackdropTemplate")
    side:SetPoint("TOPLEFT", 1, -50)
    side:SetPoint("BOTTOMLEFT", 1, 1)
    side:SetWidth(SIDE)
    UI.Backdrop(side, UI.C.side, { 0, 0, 0, 0 })
    for i, key in ipairs(ns.PanelOrder) do
        local p = ns.Panels[key]
        local t = CreateFrame("Button", nil, side)
        t:SetSize(SIDE, 32)
        t:SetPoint("TOPLEFT", 0, -6 - (i - 1) * 33)
        t.bg = t:CreateTexture(nil, "BACKGROUND")
        t.bg:SetAllPoints()
        t.bar = t:CreateTexture(nil, "ARTWORK")
        t.bar:SetPoint("TOPLEFT")
        t.bar:SetPoint("BOTTOMLEFT")
        t.bar:SetWidth(3)
        t.icon = t:CreateTexture(nil, "ARTWORK")
        t.icon:SetSize(18, 18)
        t.icon:SetPoint("LEFT", 14, 0)
        t.icon:SetTexture(p.icon)
        t.icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
        t.text = UI.Text(t, 12)
        t.text:SetPoint("LEFT", t.icon, "RIGHT", 10, 0)
        t.text:SetWordWrap(false)
        t.text:SetText(p.label)
        t.badge = CreateFrame("Frame", nil, t, "BackdropTemplate")
        t.badge:SetSize(22, 16)
        t.badge:SetPoint("RIGHT", -10, 0)
        UI.Backdrop(t.badge, { 0.85, 0.2, 0.2, 1 }, { 0, 0, 0, 0 })
        t.badge.text = UI.Text(t.badge, 10)
        t.badge.text:SetPoint("CENTER")
        t.badge.text:SetJustifyH("CENTER")
        t.badge:Hide()
        t:SetScript("OnEnter", function(s) if frame.current ~= key then s.bg:SetColorTexture(1, 1, 1, 0.03) end end)
        t:SetScript("OnLeave", function(s) if frame.current ~= key then s.bg:SetColorTexture(1, 1, 1, 0) end end)
        t:SetScript("OnClick", function() UI.Select(key) end)
        frame.tabs[key] = t
    end

    -- Body / scroll
    frame.body = CreateFrame("Frame", nil, frame)
    frame.body:SetPoint("TOPLEFT", side, "TOPRIGHT", 0, 0)
    frame.body:SetPoint("BOTTOMRIGHT", -1, 1)
    frame.scroll = CreateFrame("ScrollFrame", nil, frame.body, "UIPanelScrollFrameTemplate")
    frame.scroll:SetPoint("TOPLEFT", 18, -12)
    frame.scroll:SetPoint("BOTTOMRIGHT", -30, 12)

    frame.picker = BuildPicker(frame)
    frame:SetScript("OnShow", function() UI.Refresh() end)
    frame:Hide()

    ns.On("SPEC_CHANGED", function() UI.Refresh() end)
    ns.On("CHANGES_READ", function() UI.Refresh() end)
    return frame
end

function UI.Toggle(key)
    UI.Build()
    if frame:IsShown() and (not key or key == frame.current) then
        frame:Hide()
        return
    end
    frame:Show()
    UI.Select(key or frame.current or ns.db.char.window.tab or "overview")
end

function UI.Open(key)
    UI.Build()
    frame:Show()
    UI.Select(key or frame.current or ns.db.char.window.tab or "overview")
end

function UI.ShowPicker()
    UI.Open("overview")
    frame.forcePicker = true
    UI.Refresh()
end
