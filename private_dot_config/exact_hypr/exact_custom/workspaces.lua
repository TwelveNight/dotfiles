-- 单屏：内屏 1–10；双屏：外屏 1–10，内屏 11–20。
local rules = {}
local previous_layout

local function enable_group(monitor, first)
    for id = first, first + 9 do
        local key = monitor .. ":" .. id
        if not rules[key] then
            rules[key] = hl.workspace_rule({
                workspace = tostring(id),
                monitor = monitor,
                default = id == first,
                enabled = true,
            })
        else
            rules[key]:set_enabled(true)
        end
    end
end

local function update_workspaces()
    local internal, external
    for _, monitor in ipairs(hl.get_monitors()) do
        if monitor.name:match("^eDP") or monitor.name:match("^LVDS") then
            internal = monitor
        elseif not monitor.is_mirror and
            (monitor.name:match("^HDMI") or monitor.name:match("^DP")) then
            -- Prefer the existing HDMI layout when multiple externals are present.
            if not external or monitor.name == "HDMI-A-1" then
                external = monitor
            end
        end
    end

    for _, rule in pairs(rules) do
        rule:set_enabled(false)
    end
    local internal_name = internal and internal.name or "eDP-1"
    enable_group(external and external.name or internal_name, 1)
    if external and internal then
        enable_group(internal_name, 11)
    end

    local layout = internal_name .. ":" .. (external and external.name or "single")
    if layout == previous_layout then
        return
    end
    previous_layout = layout

    -- Existing workspaces also follow the new monitor assignment after hotplug.
    for _, workspace in ipairs(hl.get_workspaces()) do
        local target
        if workspace.id >= 1 and workspace.id <= 10 then
            target = external or internal
        elseif workspace.id >= 11 and workspace.id <= 20 then
            target = internal
        end
        if target and workspace.monitor and workspace.monitor.name ~= target.name then
            hl.dispatch(hl.dsp.workspace.move({workspace = workspace.id, monitor = target.name}))
        end
    end

    -- Return the laptop to the appropriate group without renumbering open windows.
    if internal then
        local active = internal.active_workspace
        local first = external and 11 or 1
        if not active or active.id < first or active.id > first + 9 then
            local focused = hl.get_active_monitor()
            hl.dispatch(hl.dsp.focus({workspace = first}))
            if focused and focused.name ~= internal.name then
                hl.dispatch(hl.dsp.focus({monitor = focused.name}))
            end
        end
    end
end

-- Runtime monitor queries are unavailable while parsing/validating the config.
-- Start with the laptop default, then detect outputs once the event loop runs.
enable_group("eDP-1", 1)

-- Defer reconciliation until Hyprland finishes adding/removing the output.
local refresh

local function schedule_refresh()
    -- --verify-config emits config.reloaded without a running output/event loop.
    if #hl.get_monitors() == 0 then
        return
    end
    if refresh then
        refresh:set_timeout(200)
        refresh:set_enabled(true)
    else
        refresh = hl.timer(update_workspaces, {timeout = 200, type = "oneshot"})
    end
end

hl.on("hyprland.start", schedule_refresh)
hl.on("config.reloaded", schedule_refresh)
hl.on("monitor.added", schedule_refresh)
hl.on("monitor.removed", schedule_refresh)
hl.on("monitor.layout_changed", schedule_refresh)
