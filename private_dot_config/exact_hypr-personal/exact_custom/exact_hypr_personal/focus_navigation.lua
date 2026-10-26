local policy = require("hypr_personal.monitor_policy")
local M = {}
function M.focus(direction, workspace_only)
    local active = hl.get_active_window()
    local monitor = hl.get_active_monitor()
    if not active or not policy.awake(monitor) then return end
    local visible = {}
    for _, m in ipairs(hl.get_monitors()) do
        if policy.awake(m) then
            local ws = m.active_special_workspace or m.active_workspace
            if ws then visible[ws.id] = true end
        end
    end
    local ax, ay = active.at.x + active.size.x/2, active.at.y + active.size.y/2
    local target, score
    for _, w in ipairs(hl.get_windows()) do
        if w.address ~= active.address and w.mapped and not w.hidden and w.workspace
            and visible[w.workspace.id]
            and (not workspace_only or w.workspace.id == active.workspace.id) then
            local dx = w.at.x + w.size.x/2 - ax
            local dy = w.at.y + w.size.y/2 - ay
            local primary = direction == "l" and -dx or direction == "r" and dx
                or direction == "u" and -dy or dy
            local secondary = (direction == "l" or direction == "r") and math.abs(dy) or math.abs(dx)
            local cost = primary + 2*secondary
            if primary > 1 and (not score or cost < score) then
                target, score = w, cost
            end
        end
    end
    if target then
        hl.dispatch(hl.dsp.focus({window=target}))
        -- Focus can scroll the target, so obtain its updated position now.
        local m = target.monitor or monitor
        local x = math.max(m.x,math.min(target.at.x+target.size.x/2,m.x+m.size.width-1))
        local y = math.max(m.y,math.min(target.at.y+target.size.y/2,m.y+m.size.height-1))
        hl.dispatch(hl.dsp.cursor.move({x=x,y=y}))
    end
end
return M
