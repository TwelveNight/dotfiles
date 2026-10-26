-- Fit mode clamps the negative camera offset needed to centre the first column.
-- Allow that offset only while the manually centred window retains focus.
local M = {}
local owner, previous_fit
local function restore()
    local window = hl.get_active_window()
    if owner and (not window or window.address ~= owner) then
        if previous_fit ~= nil and hl.get_config("scrolling.focus_fit_method") == 0 then
            hl.config({scrolling={focus_fit_method=previous_fit}})
        end
        owner, previous_fit = nil, nil
    end
end
function M.center()
    local window = hl.get_active_window()
    if not window then return end
    if not window.floating and window.workspace and window.workspace.tiled_layout == "scrolling" then
        if not owner then previous_fit=hl.get_config("scrolling.focus_fit_method") end
        owner=window.address
        hl.config({scrolling={focus_fit_method=0}})
        hl.dispatch(hl.dsp.layout("center"))
        -- Keep follow_mouse on the selected window as the viewport moves.
        hl.dispatch(hl.dsp.cursor.move({x=window.at.x+window.size.x/2,
                                      y=window.at.y+window.size.y/2}))
    else
        hl.dispatch(hl.dsp.window.center())
    end
end
hl.on("window.active", restore)
hl.on("workspace.active", restore)
return M
