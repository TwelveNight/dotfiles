-- Close numeric workspace gaps independently in each display's ten-ID group.
-- Renumber whole workspaces: moving individual windows would rebuild columns.
local policy = require("hypr_personal.monitor_policy")
local previous, stable = nil, 0

local function refresh()
    if hl.get_current_submap() ~= "" then previous, stable = nil, 0; return end
    local workspaces, monitors = hl.get_workspaces(), hl.get_monitors()
    local by_id, groups, signature = {}, {}, {}
    for _, ws in ipairs(workspaces) do by_id[ws.id] = ws end
    for _, m in ipairs(monitors) do
        if policy.awake(m) and m.active_workspace and not m.active_special_workspace then
            local first = math.floor((math.max(1, m.active_workspace.id)-1)/10)*10+1
            local occupied = {}
            for id = first, first+9 do
                local ws = by_id[id]
                -- A named workspace is an explicit user choice; do not renumber it.
                if ws and (not ws.monitor or ws.monitor.name ~= m.name
                    or (ws.name and ws.name ~= tostring(id))) then
                    occupied = nil; break
                end
                if ws and ws.windows > 0 then occupied[#occupied+1] = id end
            end
            if occupied then
                groups[#groups+1] = {first=first, occupied=occupied}
                signature[#signature+1] = m.name .. ":" .. first .. ":" .. table.concat(occupied, ",")
            end
        end
    end
    table.sort(signature)
    local key = table.concat(signature, "|")
    if previous ~= key then previous, stable = key, 0; return end
    stable = stable+1
    -- Leave time to create windows or move them from the overview before packing.
    if stable < 3 then return end
    for _, group in ipairs(groups) do
        for index, source in ipairs(group.occupied) do
            local target = group.first+index-1
            if source ~= target then
                local empty = by_id[target]
                local temporary
                if empty then
                    -- change_id requires an unused ID, even for an empty target.
                    temporary = 100001
                    while by_id[temporary] do temporary=temporary+1 end
                    hl.dispatch(hl.dsp.workspace.change_id({workspace=target,id=temporary}))
                end
                hl.dispatch(hl.dsp.workspace.change_id({workspace=source,id=target}))
                if empty then
                    hl.dispatch(hl.dsp.workspace.change_id({workspace=temporary,id=source}))
                end
                by_id[target], by_id[source] = by_id[source], empty
            end
        end
    end
end

return require("hypr_personal").timer(refresh, {timeout=500,type="repeat"})
