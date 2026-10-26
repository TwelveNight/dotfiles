local root=assert(os.getenv("HYPR_PERSONAL_DIR"))
package.path=root.."/custom/?.lua;"..package.path
local closed=true
io.open=function(path)
    assert(path:match("^/proc/acpi/button/lid/[^/]+/state$"), "unexpected read: "..path)
    return {read=function() return closed and "state: closed" or "state: open" end,close=function() end}
end
local external={name="HDMI-A-1",dpms_status=true}
local second={name="DP-2",dpms_status=true}
local panel={name="eDP-2",dpms_status=true,width=2560,height=1600,refresh_rate=165,
    x=-2560,y=0,scale=1.25,transform=0}
local monitors={external,panel}
local updates={}
hl={get_monitors=function() return monitors end,timer=function() return {} end,
    monitor=function(spec) updates[#updates+1]=spec end}
local policy=require("hypr_personal.monitor_policy")
local function disable()
    local before=#updates
    policy.reconcile()
    assert(#updates==before+1 and updates[#updates].disabled==true, "awake external must disable closed panel")
end
local function restore()
    local before=#updates
    policy.reconcile()
    assert(#updates==before+1 and updates[#updates].disabled==false,
        "panel not restored after last external goes DPMS-off")
    local saved=updates[#updates]
    assert(saved.output==panel.name and saved.mode=="2560x1600@165.000")
    assert(saved.position=="-2560x0" and saved.scale==1.25 and saved.transform==0,
        "restore must retain original geometry")
    policy.reconcile()
    assert(#updates==before+1, "restore must happen only once")
end
disable()
-- The disabled panel disappears from get_monitors; external is still connected.
monitors={external};external.dpms_status=false
restore()
-- Streaming/internal-only from startup must not issue a display change.
monitors={external,panel};local before=#updates
policy.reconcile();assert(#updates==before, "DPMS-off external must not disable streaming panel")
external.dpms_status=true
disable()
monitors={external,second};external.dpms_status=false
before=#updates;policy.reconcile()
assert(#updates==before, "another awake external must keep closed panel disabled")
second.dpms_status=false
restore()
monitors={external,panel};external.dpms_status=true
disable();monitors={}
restore()
monitors={external,panel}
disable();closed=false;monitors={external}
restore()
print("closed-lid awake -> DPMS-off, multi-external, disconnect and lid-open restores: passed")
