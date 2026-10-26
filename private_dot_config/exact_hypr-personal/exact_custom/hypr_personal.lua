-- Common personal behavior for all Hyprland shells. No shell is started here.
local M = {options={internal_output="eDP-2"}}
function M.configure(options)
    for key,value in pairs(options or {}) do M.options[key]=value end
    return M
end
function M.module(name) return require("hypr_personal." .. name) end
-- --verify-config has no compositor event loop; creating a native timer
-- there crashes Hyprland. Defer until outputs exist in a real session.
function M.timer(callback, options)
    if #hl.get_monitors()>0 then return hl.timer(callback,options) end
    local pending={}
    local function start()
        if not pending.handle and #hl.get_monitors()>0 then
            pending.handle=hl.timer(callback,options)
        end
    end
    hl.on("hyprland.start",start)
    hl.on("config.reloaded",start)
    return pending
end
function M.open_overview()
    local ok = pcall(function() hl.plugin.scrolloverview.overview("on") end)
    if not ok and M.options.overview then M.options.overview() end
end
function M.setup()
    if M.started then return end
    M.started=true
    hl.config({scrolling={explicit_column_widths="0.25,0.5,0.75"}})
    for _,name in ipairs({"monitor_policy","workspaces","edge_focus","spare_workspace","compact_workspaces"}) do M.module(name) end
    -- Enabled hyprpm plugins are shared by the compositor, independent of shell.
    M.plugin_timer=M.timer(function()
        if #hl.get_monitors()==0 or not hl.get_loaded_plugins then return end
        for _,plugin in ipairs(hl.get_loaded_plugins()) do
            if plugin.name=="scrolloverview" then return end
        end
        hl.exec_cmd("hyprpm reload -n")
    end,{timeout=1500,type="oneshot"})
end
-- Scrolling move changes column membership; swapping preserves existing slots.
function M.move_window(direction)
    local window=hl.get_active_window()
    if not window then return end
    if not window.floating and window.workspace and window.workspace.tiled_layout=="scrolling" then
        local directions={l="left",r="right",u="up",d="down"}
        hl.dispatch(hl.dsp.window.swap({direction=assert(directions[direction])}))
    else
        hl.dispatch(hl.dsp.window.move({direction=direction}))
    end
end
function M.bind(options)
    options=options or {}
    local function bind(keys,action,description,options)
        hl.unbind(keys)
        options=options or {}
        options.description=description
        hl.bind(keys,action,options)
    end
    local close=options.close or function() hl.dispatch(hl.dsp.window.close()) end
    bind("SUPER + Q",close,"Windows: Close window")
    bind("ALT + Q",close,"Windows: Close window")
    local fullscreen=hl.dsp.window.fullscreen({mode="fullscreen",action="toggle"})
    bind("ALT + M",fullscreen,"Windows: Fullscreen")
    bind("SUPER + SHIFT + F",fullscreen,"Windows: Fullscreen")
    bind("SUPER + O",hl.dsp.window.fullscreen({mode="maximized",action="toggle"}),"Windows: Maximize")
    bind("ALT + C",M.module("window_center").center,"Windows: Center current window")
    local columns=M.module("column_layout")
    bind("SUPER + BracketLeft",function() columns.rearrange("prev") end,"Windows: Join/split column left")
    bind("SUPER + BracketRight",function() columns.rearrange("next") end,"Windows: Join/split column right")
    bind("SUPER + R",function()
        local window=hl.get_active_window()
        if not window then return end
        if not window.floating and window.workspace and window.workspace.tiled_layout=="scrolling" then
            hl.dispatch(hl.dsp.layout("colresize +conf"))
        else
            local monitor=window.monitor or hl.get_active_monitor()
            if not monitor then return end
            local next_width=monitor.size.width*0.25
            for _,fraction in ipairs({0.25,0.5,0.75}) do
                local width=monitor.size.width*fraction
                if width>window.size.x+2 then next_width=width;break end
            end
            hl.dispatch(hl.dsp.window.resize({x=math.floor(next_width-window.size.x),y=0,relative=true}))
        end
    end,"Windows: Cycle width (1/4, 1/2, 3/4)")
    bind("SUPER + F",hl.dsp.exec_cmd(M.options.browser or "firefox"),"Apps: Browser")
    bind("CTRL + SHIFT + Escape",hl.dsp.exec_cmd("kitty --title btop -e btop"),"Apps: Resource monitor (btop)")
    local navigation=M.module("focus_navigation")
    for _,spec in ipairs({{"H","l",-30,0},{"J","d",0,30},{"K","u",0,-30},{"L","r",30,0}}) do
        bind("ALT + "..spec[1],function() navigation.focus(spec[2]) end,"Windows: Focus window in direction")
        bind("SUPER + "..spec[1],function() M.move_window(spec[2]) end,"Windows: Move/swap window in direction")
        bind("SUPER + SHIFT + "..spec[1],hl.dsp.window.resize({x=spec[3],y=spec[4],relative=true}),"Windows: Resize window",{repeating=true})
    end
    bind("ALT + mouse_up",function() navigation.focus("l",true) end,"Windows: Focus left in workspace")
    bind("ALT + mouse_down",function() navigation.focus("r",true) end,"Windows: Focus right in workspace")
end
function M.action(name)
    local action=assert(M.options.actions[name], "Missing personal shell action: "..name)
    return type(action)=="string" and hl.dsp.exec_cmd(action) or action
end
function M.shell(name) hl.dispatch(M.action(name)) end
function M.relocate()
    for _,spec in ipairs(M.options.relocations and M.options.relocations() or {}) do
        hl.unbind(spec[1]); hl.bind(spec[1],spec[2],{description=spec[3]})
    end
end
function M.variables() M.module("variables") end
function M.environment() M.module("env") end
function M.general() M.module("general"); M.setup() end
function M.rules() M.module("rules") end
function M.keybinds() M.module("keybinds") end
function M.autostart()
    hl.on("hyprland.start",function()
        hl.exec_cmd("sh ~/.config/hypr-personal/scripts/autostart.sh")
    end)
end
return M
