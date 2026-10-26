-- Match Niri's consume-or-expel-window-left/right using native scrolling.
local M = {}
function M.rearrange(direction)
    local window = hl.get_active_window()
    if not window or window.floating or not window.workspace
        or window.workspace.tiled_layout ~= "scrolling" then return end
    hl.dispatch(hl.dsp.layout("consume_or_expel " .. direction))
end
return M
