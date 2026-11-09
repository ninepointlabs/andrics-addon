local _, ns = ...
local UI = ns.UI

UI.RegisterPanel({
    key = "changes", label = "What's changed", icon = "Interface\\Icons\\INV_Letter_15",
    badge = function() return ns.db and ns.Changes.UnreadCount() or 0 end,
    render = function(L, c)
        L:Buttons({ { label = "Mark all read", onClick = function() ns.Changes.MarkAllRead() end } }, 130)
        local gen = ns.Changes.Generated()
        L:Text(UI.Hex(UI.C.dim) .. (gen and ("Companion poller last updated this list " .. gen .. ".") or
            "The companion poller (tools/priest-changes-poller) hasn't written Data/Changes.lua yet. Showing changes from the research.") ..
            " Addons can't go online; the poller runs on your PC and you /reload to see new items.|r", { size = 11 })
        L:Space(4)
        for _, it in ipairs(ns.Changes.All()) do
            local unread = not ns.Changes.IsRead(it)
            local title = (unread and (UI.Hex(UI.C.good) .. "NEW|r  ") or "") .. (it.title or "?")
            local sub = (it.source or "") .. (it.summary and it.summary ~= "" and (" · " .. it.summary) or "")
            if it.url then sub = sub .. "\n" .. UI.Hex(UI.C.dim) .. "click to mark read · shift-click to copy link|r" end
            L:Row({ icon = unread and "Interface\\Icons\\INV_Letter_15" or "Interface\\Icons\\INV_Letter_02", title = title, sub = sub, right = it.date or "",
                tint = unread and UI.Accent() or nil,
                onClick = function()
                    ns.Changes.MarkRead(it)
                    if IsShiftKeyDown() and it.url then UI.CopyURL(it.url) end
                end })
        end
    end,
})
