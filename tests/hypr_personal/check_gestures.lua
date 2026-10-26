-- arg[2]: off, custom, empty or defaults; snapshot seeded by test caller.
local state=dofile(assert(arg[0]:match("^(.*)/")).."/fixtures/load_ii.lua")
local function verify()
    local count=0
    for _ in pairs(state.gestures) do count=count+1 end
    local case=assert(arg[2])
    if case=="off" or case=="empty" then
        assert(count==0, "Settings "..case.." snapshot overwritten by personal defaults: "..count)
    elseif case=="custom" then
        assert(count==2, "custom Settings list must stay exact, got "..count)
        local native=assert(state.gestures["2:horizontal"], "custom native gesture lost")
        assert(native.action=="resize" and native.mods=="SUPER" and native.scale==2)
        assert(native.disable_inhibit==true, "custom attributes lost")
        local shell=assert(state.gestures["5:left"], "custom shell gesture lost")
        shell.action()
        assert(state.dispatched[#state.dispatched].args[1]=="iigesture,trigger,overview,left")
    else
        assert(case=="defaults")
        assert(count==7, "missing personal defaults without Settings snapshot")
        assert(state.gestures["4:swipe"].action=="move")
        assert(state.gestures["4:pinch"].action=="float")
        assert(state.gestures["3:horizontal"].action=="workspace")
        for _,id in ipairs({"3:up","3:down","5:up","5:down"}) do
            assert(type(state.gestures[id].action)=="function", "personal handler lost: "..id)
        end
    end
end
-- Check immediately after config load: the QML client may only report, not reapply.
verify()
assert(ii_gestures.reload()=="ok")
verify()
print("Settings "..arg[2].." retained at config load and registry reload: passed")
