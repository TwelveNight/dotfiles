-- arg[1]: normalized II config root; HYPR_PERSONAL_DIR: shared package.
local state=dofile(assert(arg[0]:match("^(.*)/")).."/fixtures/load_ii.lua")
local chord="SUPER+SHIFT+ALT+P"
for _=1,2 do
    state.binding(chord).action()
    assert(state.submap()=="clean", "original chord must enter clean")
    local exits=assert(state.binds["clean|"..state.key(chord)],
        "clean escape removed by cross-submap unbind")
    assert(#exits==1, "clean must have exactly one escape")
    assert(exits[1].options.submap_universal, "escape must remain universal")
    exits[1].action()
    assert(state.submap()=="", "same chord must exit clean to normal bindings")
end
assert(state.binding("SUPER+Return"), "normal shortcuts must remain available")
print("clean enter/exit twice: passed")
