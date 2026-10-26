-- Personal scrolling edge focus. All coordinates are compositor logical pixels.
-- A 200 ms dwell advances one column; leave the edge to arm it again.
local policy = require("hypr_personal.monitor_policy")
local edge, ticks, fired
local corner, corner_ticks, corner_fired = nil, 0, false
local function reset()
    edge, ticks, fired = nil, 0, false
end
reset()

local function poll()
    local p = hl.get_cursor_pos()
    local m = hl.get_active_monitor()
    -- DPMS does not remove an output from the desktop. Bring a cursor that
    -- entered a sleeping output back to the nearest awake output boundary.
    if p then
        local on_sleeping, nearest, nx, ny, distance
        for _, output in ipairs(hl.get_monitors()) do
            if p.x >= output.x and p.x < output.x+output.size.width
                and p.y >= output.y and p.y < output.y+output.size.height then
                on_sleeping = not policy.awake(output)
            end
            if policy.awake(output) then
                local x = math.max(output.x, math.min(p.x,output.x+output.size.width-1))
                local y = math.max(output.y, math.min(p.y,output.y+output.size.height-1))
                local d = (x-p.x)^2+(y-p.y)^2
                if not distance or d < distance then nearest,nx,ny,distance=output,x,y,d end
            end
        end
        if on_sleeping and nearest then
            hl.dispatch(hl.dsp.focus({monitor=nearest.name}))
            hl.dispatch(hl.dsp.cursor.move({x=nx,y=ny}))
            reset()
            return
        end
    end
    local ws = m and m.active_workspace
    if not p or not policy.awake(m) or not ws
        or m.active_special_workspace or hl.get_current_submap() ~= "" then
        corner, corner_ticks, corner_fired = nil, 0, false
        reset()
        return
    end
    local in_corner = p.x >= m.x and p.x < m.x+6 and p.y >= m.y and p.y < m.y+6
    if in_corner then
        if corner ~= m.name then corner,corner_ticks,corner_fired=m.name,0,false end
        corner_ticks=corner_ticks+1
        if corner_ticks >= 5 and not corner_fired then
            corner_fired=true
            require("hypr_personal").open_overview()
        end
        reset()
        return
    end
    corner,corner_ticks,corner_fired=nil,0,false
    local maximized = ws.has_fullscreen and ws.fullscreen_mode == 1
    if (ws.has_fullscreen and not maximized) or ws.tiled_layout ~= "scrolling" then reset(); return end
    local left, right = m.x, m.x + m.size.width
    local direction = p.x >= left and p.x < left + 2 and "l"
        or p.x < right and p.x >= right - 2 and "r"
    if not direction or p.y < m.y or p.y >= m.y + m.size.height then
        -- Small hand movements at the edge must not rearm a completed push.
        local key = m.name .. ":" .. ws.id .. ":"
        if fired and p.y >= m.y and p.y < m.y+m.size.height
            and ((edge == key.."l" and p.x >= left and p.x < left+24)
                or (edge == key.."r" and p.x < right and p.x >= right-24)) then
            return
        end
        reset()
        return
    end
    -- An output immediately across this edge must remain reachable normally.
    local outside = direction == "l" and left - 1 or right + 1
    for _, other in ipairs(hl.get_monitors()) do
        if other.name ~= m.name and other.dpms_status and not other.is_mirror
            and outside >= other.x and outside < other.x + other.size.width
            and p.y >= other.y and p.y < other.y + other.size.height then
            reset()
            return
        end
    end
    local key = m.name .. ":" .. ws.id .. ":" .. direction
    if edge ~= key then
        edge, ticks, fired = key, 0, false
    end
    ticks = ticks + 1
    if ticks < 5 or fired then return end
    fired = true

    -- The first clipped column counts even if its centre is already onscreen.
    -- Order by the inner window edge, not its centre (widths can differ).
    local target, distance, vertical
    local owner = maximized and ws.fullscreen_window
    local origin = owner and (owner.at.x+owner.size.x/2)
    for _, w in ipairs(hl.get_windows()) do
        if w.mapped and not w.hidden and not w.floating and w.workspace
            and w.workspace.id == ws.id then
            local x, end_x = w.at.x, w.at.x+w.size.x
            local clipped = direction == "l" and x < left or direction == "r" and end_x > right
            local d = direction == "l" and math.max(0,left-end_x) or math.max(0,x-right)
            if origin then
                -- A covered neighbour can still have onscreen coordinates.
                -- Use its direction from the maximized column, not clipping.
                d = direction == "l" and origin-(x+end_x)/2 or (x+end_x)/2-origin
                clipped = w.address ~= owner.address and d > 1
            end
            local dy = math.max(w.at.y-p.y, p.y-w.at.y-w.size.y, 0)
            if clipped and (not distance or d < distance or (d == distance and dy < vertical)) then
                target, distance, vertical = w, d, dy
            end
        end
    end
    if target then
        -- Super+O covers the neighbouring columns, so pointer focus cannot
        -- reach them. Transfer maximization explicitly after choosing the
        -- closest clipped window, without relying on fullscreen focus policy.
        if owner then
            hl.dispatch(hl.dsp.window.fullscreen({window=owner,mode="maximized",action="unset"}))
        end
        hl.dispatch(hl.dsp.focus({ window = target }))
        -- A pointer may already have focused this half-visible window before
        -- reaching the edge. Explicitly fit that same column, without advancing.
        hl.dispatch(hl.dsp.layout("fit_into_view"))
        if owner then
            hl.dispatch(hl.dsp.window.fullscreen({window=target,mode="maximized",action="set"}))
        end
        -- Leave the edge on the selected window: follow_mouse must not focus
        -- subsequent columns as the tape animates underneath a stationary mouse.
        local x = math.max(left+24,math.min(target.at.x+target.size.x/2,right-24))
        local y = math.max(m.y+8,math.min(p.y,m.y+m.size.height-8))
        y = math.max(target.at.y,math.min(y,target.at.y+target.size.y-1))
        hl.dispatch(hl.dsp.cursor.move({x=x,y=y}))
    end
end

-- No helper process or IPC polling; the timer belongs to this Lua config.
return require("hypr_personal").timer(poll, { timeout = 50, type = "repeat" })
