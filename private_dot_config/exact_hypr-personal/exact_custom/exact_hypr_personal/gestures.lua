-- II owns an exact-match registry; use it so Settings can replace personal defaults.
local personal=require("hypr_personal")
local entries={}
local function gesture(spec)
    if ii_gestures then
        local entry={fingers=spec.fingers,direction=spec.direction}
        if type(spec.action)=="function" then
            local name="personal_"..#entries
            ii_gestures.handlers[name]=spec.action
            entry.kind="lua";entry.action=name
        else entry.kind="hyprland";entry.action=spec.action end
        entries[#entries+1]=entry
    else hl.gesture(spec) end
end
if not ii_gestures then
    for _,spec in ipairs(personal.options.gesture_defaults or {}) do
        hl.gesture({fingers=spec[1],direction=spec[2],action="unset"})
    end
end
gesture({ fingers = 4, direction = "swipe", action = "move" })
gesture({ fingers = 4, direction = "pinch", action = "float" })
gesture({ fingers = 3, direction = "horizontal", action = "workspace" })

local last_sent
local function in_scratchpad(win)
    return win and win.workspace and win.workspace.name == "special:special"
end
local function scratchpad(direction)
    local monitor = hl.get_active_monitor()
    if not monitor then return end
    local special, win = monitor.active_special_workspace, hl.get_active_window()
    if direction == "down" then
        if special then
            hl.dispatch(hl.dsp.workspace.toggle_special(special.name:sub(9)))
        elseif win then
            hl.dispatch(hl.dsp.window.move({ workspace = "special:special", window = win, follow = false }))
            if in_scratchpad(win) then last_sent = win end
        end
    elseif special and special.name == "special:special" then
        if in_scratchpad(win) and monitor.active_workspace then
            hl.dispatch(hl.dsp.window.move({ workspace = monitor.active_workspace, window = win }))
            last_sent = nil
        else
            local target = in_scratchpad(last_sent) and last_sent or nil
            if not target then
                for _, candidate in ipairs(hl.get_windows()) do
                    if in_scratchpad(candidate) then target = candidate; break end
                end
            end
            if target then hl.dispatch(hl.dsp.focus({ window = target }))
            else hl.dispatch(hl.dsp.workspace.toggle_special("special")) end
        end
    else
        hl.dispatch(hl.dsp.workspace.toggle_special("special"))
        if in_scratchpad(last_sent) then hl.dispatch(hl.dsp.focus({ window = last_sent })) end
    end
end
gesture({ fingers = 3, direction = "up", action = function() scratchpad("up") end })
gesture({ fingers = 3, direction = "down", action = function() scratchpad("down") end })
gesture({ fingers = 5, direction = "down", action = function()
    require("hypr_personal").shell("launcher")
end })
gesture({ fingers = 5, direction = "up", action = function()
    hl.dispatch(hl.dsp.window.fullscreen({ mode = "maximized", action = "toggle" }))
end })

if ii_gestures then
    ii_gestures.defaults=entries
    -- The registry reads Settings itself; never overwrite a saved list or off state.
    assert(ii_gestures.reload()=="ok", "Invalid personal gestures")
end
