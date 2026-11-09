-- Theme + small widget kit + a pooled vertical layout used by every panel.
local _, ns = ...

local UI = {}
ns.UI = UI

local WHITE = "Interface\\Buttons\\WHITE8x8"
UI.WHITE = WHITE

UI.C = {
    bg = { 0.055, 0.055, 0.075, 0.97 },
    side = { 0.075, 0.075, 0.10, 1 },
    card = { 0.105, 0.105, 0.135, 1 },
    cardHover = { 0.14, 0.14, 0.18, 1 },
    border = { 0.22, 0.22, 0.28, 1 },
    text = { 0.92, 0.92, 0.95 },
    dim = { 0.62, 0.62, 0.68 },
    good = { 0.25, 0.86, 0.35 },
    bad = { 1.00, 0.35, 0.35 },
    warn = { 1.00, 0.76, 0.25 },
}

UI.FLAG_ICON = "|TInterface\\DialogFrame\\UI-Dialog-Icon-AlertNew:14:14:0:0|t"
UI.CHECK_ICON = "|TInterface\\RaidFrame\\ReadyCheck-Ready:14:14:0:0|t"
UI.CROSS_ICON = "|TInterface\\RaidFrame\\ReadyCheck-NotReady:14:14:0:0|t"
UI.WAIT_ICON = "|TInterface\\RaidFrame\\ReadyCheck-Waiting:14:14:0:0|t"

function UI.Hex(c)
    return ("|cff%02x%02x%02x"):format(c[1] * 255, c[2] * 255, c[3] * 255)
end

function UI.Accent()
    return ns.SpecAccent()
end

function UI.Backdrop(frame, bg, border)
    if not frame.SetBackdrop then Mixin(frame, BackdropTemplateMixin) end
    frame:SetBackdrop({ bgFile = WHITE, edgeFile = WHITE, edgeSize = 1 })
    frame:SetBackdropColor(unpack(bg or UI.C.card))
    frame:SetBackdropBorderColor(unpack(border or UI.C.border))
end

local FONT = "Fonts\\FRIZQT__.TTF"
function UI.Font(fs, size, flags)
    fs:SetFont(FONT, size or 12, flags or "")
    return fs
end

function UI.Text(parent, size, color, layer)
    local fs = parent:CreateFontString(nil, layer or "OVERLAY")
    UI.Font(fs, size or 12)
    fs:SetTextColor(unpack(color or UI.C.text))
    fs:SetJustifyH("LEFT")
    fs:SetWordWrap(true)
    return fs
end

-- Flat button with hover + optional accent.
function UI.Button(parent, label, width, height, onClick)
    local b = CreateFrame("Button", nil, parent, "BackdropTemplate")
    b:SetSize(width or 100, height or 24)
    UI.Backdrop(b, UI.C.card, UI.C.border)
    b.label = UI.Text(b, 12)
    b.label:SetPoint("CENTER")
    b.label:SetJustifyH("CENTER")
    b.label:SetWordWrap(false)
    b.label:SetText(label or "")
    b:SetScript("OnEnter", function(self)
        self:SetBackdropColor(unpack(UI.C.cardHover))
        self:SetBackdropBorderColor(unpack(UI.Accent()))
        if self.tip then
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:SetText(self.tip, 1, 1, 1, 1, true)
            GameTooltip:Show()
        end
    end)
    b:SetScript("OnLeave", function(self)
        self:SetBackdropColor(unpack(self.active and UI.C.cardHover or UI.C.card))
        self:SetBackdropBorderColor(unpack(self.active and UI.Accent() or UI.C.border))
        GameTooltip:Hide()
    end)
    if onClick then b:SetScript("OnClick", onClick) end
    function b:SetActive(on)
        self.active = on
        self:SetBackdropColor(unpack(on and UI.C.cardHover or UI.C.card))
        self:SetBackdropBorderColor(unpack(on and UI.Accent() or UI.C.border))
        self.label:SetTextColor(unpack(on and UI.Accent() or UI.C.text))
    end
    return b
end

-- Copyable URL popup (addons cannot open a browser).
StaticPopupDialogs["ANDRICS_ADDON_COPY_URL"] = {
    text = "Andric's Addon: press Ctrl+C to copy this link.",
    button1 = CLOSE or "Close",
    hasEditBox = true,
    editBoxWidth = 380,
    OnShow = function(self, data)
        local eb = self.editBox or self.EditBox or (self.GetEditBox and self:GetEditBox())
        if eb then
            eb:SetText(data or "")
            eb:HighlightText()
            eb:SetFocus()
        end
    end,
    EditBoxOnEscapePressed = function(self) self:GetParent():Hide() end,
    EditBoxOnEnterPressed = function(self) self:GetParent():Hide() end,
    timeout = 0, whileDead = true, hideOnEscape = true, preferredIndex = 3,
}

function UI.CopyURL(url)
    if url and url ~= "" then StaticPopup_Show("ANDRICS_ADDON_COPY_URL", nil, nil, url) end
end

----------------------------------------------------------------------------
-- Layout: pooled vertical flow inside a scroll child.
----------------------------------------------------------------------------
local Layout = {}
Layout.__index = Layout
UI.Layout = Layout

function UI.NewLayout(content, width)
    local l = setmetatable({ content = content, width = width, y = 0, pools = {}, used = {} }, Layout)
    return l
end

function Layout:Acquire(kind, make)
    self.pools[kind] = self.pools[kind] or {}
    self.used[kind] = (self.used[kind] or 0) + 1
    local obj = self.pools[kind][self.used[kind]]
    if not obj then
        obj = make()
        self.pools[kind][self.used[kind]] = obj
    end
    obj:ClearAllPoints()
    obj:Show()
    return obj
end

function Layout:Reset(width)
    for _, pool in pairs(self.pools) do
        for _, obj in ipairs(pool) do obj:Hide() end
    end
    self.used = {}
    self.y = 0
    if width then self.width = width end
end

function Layout:Finish()
    self.content:SetHeight(math.max(1, self.y + 16))
end

function Layout:Space(h)
    self.y = self.y + (h or 8)
end

local PAD = 4

-- Plain paragraph. opts: size, color, indent
function Layout:Text(text, opts)
    opts = opts or {}
    local fs = self:Acquire("text", function() return UI.Text(self.content, 12) end)
    UI.Font(fs, opts.size or 12)
    fs:SetTextColor(unpack(opts.color or UI.C.text))
    local indent = opts.indent or 0
    fs:SetWidth(self.width - indent)
    fs:SetPoint("TOPLEFT", self.content, "TOPLEFT", indent, -self.y)
    fs:SetText(text or "")
    self.y = self.y + fs:GetStringHeight() + (opts.gap or PAD)
    return fs
end

function Layout:Header(text, sub)
    self:Space(6)
    self:Text(UI.Hex(UI.Accent()) .. text .. "|r", { size = 16 })
    local line = self:Acquire("rule", function()
        local t = self.content:CreateTexture(nil, "ARTWORK")
        t:SetTexture(WHITE)
        return t
    end)
    line:SetColorTexture(UI.Accent()[1], UI.Accent()[2], UI.Accent()[3], 0.35)
    line:SetPoint("TOPLEFT", self.content, "TOPLEFT", 0, -self.y)
    line:SetSize(self.width, 1)
    self.y = self.y + 6
    if sub then self:Text(sub, { color = UI.C.dim, size = 11 }) end
end

function Layout:Flag(text)
    return self:Text(UI.FLAG_ICON .. " " .. UI.Hex(UI.C.warn) .. text .. "|r", { size = 11 })
end

-- Card row: icon, title, subtitle, right text. opts: onClick, onEnter, height, tint
function Layout:Row(opts)
    local row = self:Acquire("row", function()
        local f = CreateFrame("Button", nil, self.content, "BackdropTemplate")
        UI.Backdrop(f, UI.C.card, UI.C.border)
        f.icon = f:CreateTexture(nil, "ARTWORK")
        f.icon:SetSize(28, 28)
        f.icon:SetPoint("TOPLEFT", 8, -6)
        f.icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
        f.title = UI.Text(f, 13)
        f.sub = UI.Text(f, 11, UI.C.dim)
        f.right = UI.Text(f, 12)
        f.right:SetJustifyH("RIGHT")
        f.right:SetWordWrap(false)
        f.right:SetPoint("TOPRIGHT", -10, -8)
        f:SetScript("OnEnter", function(s)
            s:SetBackdropBorderColor(unpack(UI.Accent()))
            if s.onEnter then s.onEnter(s) end
        end)
        f:SetScript("OnLeave", function(s)
            s:SetBackdropBorderColor(unpack(s.tint or UI.C.border))
            GameTooltip:Hide()
        end)
        f:SetScript("OnClick", function(s) if s.onClick then s.onClick(s) end end)
        return f
    end)
    row.onClick, row.onEnter, row.tint = opts.onClick, opts.onEnter, opts.tint
    row:SetBackdropBorderColor(unpack(opts.tint or UI.C.border))
    local left = 10
    if opts.icon then
        row.icon:SetTexture(opts.icon)
        row.icon:Show()
        left = 44
    else
        row.icon:Hide()
    end
    row.right:SetText(opts.right or "")
    local rightW = opts.right and math.min(row.right:GetStringWidth() + 16, 220) or 0
    row.title:ClearAllPoints()
    row.title:SetPoint("TOPLEFT", left, -7)
    row.title:SetWidth(self.width - left - 10 - rightW)
    row.title:SetText(opts.title or "")
    row.sub:ClearAllPoints()
    row.sub:SetPoint("TOPLEFT", row.title, "BOTTOMLEFT", 0, -3)
    row.sub:SetWidth(self.width - left - 10 - rightW)
    row.sub:SetText(opts.sub or "")
    local h = 7 + row.title:GetStringHeight() + (opts.sub and opts.sub ~= "" and (3 + row.sub:GetStringHeight()) or 0) + 8
    h = math.max(h, opts.icon and 40 or 26)
    row:SetSize(self.width, h)
    row:SetPoint("TOPLEFT", self.content, "TOPLEFT", 0, -self.y)
    self.y = self.y + h + PAD
    return row
end

-- Progress bar with label.
function Layout:Progress(label, value, max, rightText)
    local bar = self:Acquire("bar", function()
        local f = CreateFrame("Frame", nil, self.content, "BackdropTemplate")
        UI.Backdrop(f, UI.C.card, UI.C.border)
        f:SetHeight(22)
        f.fill = f:CreateTexture(nil, "ARTWORK")
        f.fill:SetTexture(WHITE)
        f.fill:SetPoint("TOPLEFT", 1, -1)
        f.fill:SetPoint("BOTTOMLEFT", 1, 1)
        f.label = UI.Text(f, 11)
        f.label:SetPoint("LEFT", 8, 0)
        f.label:SetWordWrap(false)
        f.right = UI.Text(f, 11)
        f.right:SetPoint("RIGHT", -8, 0)
        f.right:SetJustifyH("RIGHT")
        return f
    end)
    bar:SetWidth(self.width)
    bar:SetPoint("TOPLEFT", self.content, "TOPLEFT", 0, -self.y)
    local pct = (max and max > 0) and math.min(1, math.max(0, value / max)) or 0
    local a = UI.Accent()
    bar.fill:SetColorTexture(a[1], a[2], a[3], 0.45)
    bar.fill:SetWidth(math.max(1, (self.width - 2) * pct))
    bar.label:SetText(label or "")
    bar.right:SetText(rightText or ("%d%%"):format(pct * 100))
    self.y = self.y + 22 + PAD
    return bar
end

-- A row of buttons (segmented control). items: { {label, value, active, onClick, tip} }
function Layout:Buttons(items, width)
    local x = 0
    local h = 24
    for _, it in ipairs(items) do
        local b = self:Acquire("btn", function() return UI.Button(self.content, "", 100, 24) end)
        local w = width or math.max(70, (#it.label * 7) + 20)
        b:SetSize(w, h)
        b.label:SetText(it.label)
        b.tip = it.tip
        b:SetScript("OnClick", it.onClick)
        b:SetActive(it.active)
        if x + w > self.width then
            x = 0
            self.y = self.y + h + PAD
        end
        b:SetPoint("TOPLEFT", self.content, "TOPLEFT", x, -self.y)
        x = x + w + 6
    end
    self.y = self.y + h + PAD + 2
end

-- Checkbox line for options.
function Layout:Check(label, checked, onToggle, tip)
    local cb = self:Acquire("check", function()
        local c = CreateFrame("CheckButton", nil, self.content, "UICheckButtonTemplate")
        c:SetSize(24, 24)
        c.text = UI.Text(c, 12)
        c.text:SetPoint("LEFT", c, "RIGHT", 4, 0)
        c.text:SetWordWrap(false)
        c:SetScript("OnEnter", function(s)
            if s.tip then
                GameTooltip:SetOwner(s, "ANCHOR_RIGHT")
                GameTooltip:SetText(s.tip, 1, 1, 1, 1, true)
                GameTooltip:Show()
            end
        end)
        c:SetScript("OnLeave", function() GameTooltip:Hide() end)
        return c
    end)
    cb:SetPoint("TOPLEFT", self.content, "TOPLEFT", 0, -self.y)
    cb.text:SetText(label)
    cb:SetChecked(checked and true or false)
    cb.tip = tip
    cb:SetScript("OnClick", function(s) onToggle(s:GetChecked() and true or false) end)
    self.y = self.y + 26
    return cb
end

-- Item row helper (icon from item id, tooltip shows our upgrade tip).
function Layout:Item(id, name, sub, right, onClick)
    local icon = (C_Item and C_Item.GetItemIconByID and C_Item.GetItemIconByID(id)) or "Interface\\Icons\\INV_Misc_QuestionMark"
    return self:Row({
        icon = icon, title = name, sub = sub, right = right,
        onEnter = function(s)
            GameTooltip:SetOwner(s, "ANCHOR_RIGHT")
            GameTooltip:SetItemByID(id)
            GameTooltip:Show()
        end,
        onClick = function()
            if IsModifiedClick and IsModifiedClick("CHATLINK") then
                local _, link = C_Item.GetItemInfo(id)
                if link then ChatEdit_InsertLink(link) end
            elseif onClick then
                onClick()
            end
        end,
    })
end

function Layout:Spell(id, title, sub, right, iconOverride)
    local icon = iconOverride
    if not icon and id and C_Spell and C_Spell.GetSpellTexture then
        local ok, tex = pcall(C_Spell.GetSpellTexture, id)
        if ok then icon = tex end
    end
    return self:Row({
        icon = icon or "Interface\\Icons\\INV_Misc_QuestionMark", title = title, sub = sub, right = right,
        onEnter = id and function(s)
            GameTooltip:SetOwner(s, "ANCHOR_RIGHT")
            pcall(GameTooltip.SetSpellByID, GameTooltip, id)
            GameTooltip:Show()
        end or nil,
    })
end

function Layout:Link(title, url, sub)
    return self:Row({
        icon = "Interface\\Icons\\INV_Misc_Note_01", title = title, sub = sub or url,
        right = UI.Hex(UI.C.dim) .. "copy link|r",
        onClick = function() UI.CopyURL(url) end,
    })
end

-- Source citation line.
function Layout:Source(rec)
    if not rec or not rec.source_url then return end
    local host = rec.source_url:match("^https?://([^/]+)") or rec.source_url
    self:Text(UI.Hex(UI.C.dim) .. "Source: " .. host .. (rec.checked and (" · checked " .. rec.checked) or "") .. "|r", { size = 10 })
end
