-- ScrollOverview displays real workspaces, including persistent empty ones.
-- Keep one empty entry in each monitor's existing ten-workspace group.
local rules, selected = {}, {}
local function refresh()
    local present = {}
    for _, m in ipairs(hl.get_monitors()) do
        if m.dpms_status and not m.is_mirror and m.active_workspace then
            present[m.name] = true
            local first = math.floor((math.max(1,m.active_workspace.id)-1)/10)*10+1
            local occupied, highest = {}, first-1
            for _, ws in ipairs(hl.get_workspaces()) do
                if ws.monitor and ws.monitor.name == m.name and ws.id >= first and ws.id < first+10
                    and ws.windows > 0 then
                    occupied[ws.id] = true
                    highest = math.max(highest,ws.id)
                end
            end
            local id = highest+1
            if id >= first+10 then
                id = nil
                for n=first,first+9 do if not occupied[n] then id=n; break end end
            end
            local key = id and (m.name .. ":" .. id)
            if selected[m.name] ~= key then
                if selected[m.name] then rules[selected[m.name]]:set_enabled(false) end
                selected[m.name] = key
                if key then
                    if rules[key] then rules[key]:set_enabled(true)
                    else rules[key]=hl.workspace_rule({workspace=tostring(id),monitor=m.name,persistent=true}) end
                end
            end
        end
    end
    for name,key in pairs(selected) do
        if not present[name] then
            rules[key]:set_enabled(false)
            selected[name]=nil
        end
    end
end
return require("hypr_personal").timer(refresh, {timeout=500,type="repeat"})
