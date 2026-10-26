-- A closed laptop lid is not necessarily DPMS-off in Hyprland. Remove that
-- output from desktop geometry while an external screen is awake. Keep an
-- internal-only / external-DPMS-off streaming setup available.
local M = {}
local disabled = {}
local function internal(m)
    return m.name:match("^eDP") or m.name:match("^LVDS")
end
local function lid_closed()
    for _, name in ipairs({"LID0", "LID", "LID1"}) do
        local f = io.open("/proc/acpi/button/lid/" .. name .. "/state")
        if f then
            local state = f:read("*a")
            f:close()
            return state:match("closed") ~= nil
        end
    end
    return false
end
function M.awake(m)
    return m and m.dpms_status and not m.is_mirror
end
function M.reconcile()
    local monitors = hl.get_monitors()
    local external_awake = false
    for _, m in ipairs(monitors) do
        if not internal(m) and not m.is_mirror then
            external_awake = external_awake or M.awake(m)
        end
    end
    local closed = lid_closed()
    if closed and external_awake then
        for _, m in ipairs(monitors) do
            if internal(m) then
                disabled[m.name] = disabled[m.name] or {
                    output=m.name, disabled=false,
                    mode=string.format("%dx%d@%.3f", m.width, m.height, m.refresh_rate),
                    position=string.format("%dx%d", m.x, m.y),
                    scale=m.scale, transform=m.transform,
                }
                hl.monitor({output=m.name, disabled=true})
            end
        end
    else
        for name, spec in pairs(disabled) do
            hl.monitor(spec)
            disabled[name] = nil
        end
    end
end
M.timer = require("hypr_personal").timer(M.reconcile, {timeout=500, type="repeat"})
return M
