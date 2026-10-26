-- Execute the real default + custom load order, without a compositor/services.
local source = assert(arg[1])
package.path = source .. "/hypr/?.lua;" .. source .. "/hypr/?/init.lua;" .. package.path
local saw_personal_appearance=false
local binds, events, configs, gestures, dispatched = {}, {}, {}, {}, {}
local submap, active, monitors, workspaces, windows = "", nil, {}, {}, {}
local focused_window, execs = nil, {}
local function key(value)
    local parts = {}
    for part in value:gmatch("[^+]+") do parts[#parts + 1] = part:gsub("%s+", ""):upper() end
    local physical = { TAB="CODE:23", EQUAL="CODE:21", MINUS="CODE:20", SPACE="SPACE" }
    for i,p in ipairs(parts) do
        parts[i] = physical[p] or p
        if p:match("^%d$") then parts[i] = "CODE:" .. (p == "0" and 19 or tonumber(p) + 9) end
    end
    table.sort(parts)
    return table.concat(parts, "+")
end
local function namespace(path)
    return setmetatable({}, { __index = function(_, name)
        if name == "window" or name == "workspace" or name == "cursor" then return namespace(name) end
        return function(...) return { kind=path .. "." .. name, args={...} } end
    end })
end
local function merge(a,b)
    for k,v in pairs(b) do
        if type(v) == "table" then
            if type(a[k]) ~= "table" then a[k] = {} end
            merge(a[k],v)
        else a[k]=v end
    end
end
hl = {
    get_loaded_plugins=function() return {} end,
    dsp=namespace("dsp"),
    bind=function(chord,action,options)
        local id = submap .. "|" .. key(chord)
        binds[id] = binds[id] or {}
        table.insert(binds[id], {action=action, options=options or {}, chord=chord})
    end,
    unbind=function(chord)
        -- Hyprland removes the chord in every submap, not just the active one.
        for id in pairs(binds) do
            if id:match("|(.+)$") == key(chord) then binds[id] = nil end
        end
    end,
    define_submap=function(name,callback)
        local old=submap; submap=name; callback(); submap=old
    end,
    dispatch=function(action)
        dispatched[#dispatched+1]=action
        if action.kind == "dsp.submap" then
            submap=action.args[1] == "reset" and "" or action.args[1]
            for _,cb in ipairs(events["keybinds.submap"] or {}) do cb() end
        end
    end,
    config=function(spec)
        if spec.general and spec.general.gaps_in==10 and spec.decoration and spec.decoration.rounding==18 then saw_personal_appearance=true end
        merge(configs,spec)
    end,
    get_config=function(name)
        if name=="scrolling.focus_fit_method" then
            return configs.scrolling and configs.scrolling.focus_fit_method or 1
        end
        return 1
    end,
    env=function() end, monitor=function() end, device=function() end,
    curve=function() end, animation=function() end, layer_rule=function() end,
    window_rule=function() end, exec_cmd=function(cmd) execs[#execs+1]=cmd end,
    workspace_rule=function(spec)
        return { spec=spec, set_enabled=function(self,value) self.enabled=value end }
    end,
    gesture=function(spec)
        local id=spec.fingers .. ":" .. spec.direction
        if spec.action == "unset" then gestures[id]=nil else
            assert(not gestures[id], "duplicate gesture " .. id); gestures[id]=spec
        end
    end,
    on=function(event,callback)
        events[event]=events[event] or {}; table.insert(events[event],callback)
    end,
    get_windows=function() return windows end,
    get_current_submap=function() return submap end,
    get_monitors=function() return monitors end,
    get_workspaces=function() return workspaces end,
    get_active_monitor=function() return monitors[1] end,
    get_active_workspace=function() return active end,
    get_active_window=function() return focused_window end,
    timer=function() return {} end,
}

dofile(source .. "/hypr/hyprland.lua")
for _,cmd in ipairs(execs) do
    assert(not cmd:find("Failed to load",1,true),cmd)
end
local function binding(chord)
    local entries=assert(binds["|"..key(chord)],"missing "..chord)
    assert(#entries==1,"duplicate personal chord "..chord.." (including physical aliases)")
    return entries[1]
end
return {
    binds=binds, key=key, binding=binding, gestures=gestures, dispatched=dispatched,
    submap=function() return submap end,
}
