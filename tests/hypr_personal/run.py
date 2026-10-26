#!/usr/bin/env python3
"""Run offline shared-Lua regressions on an approved remote, never a live desktop."""
import argparse
import json
import os
from pathlib import Path
import shutil
import subprocess
import sys

parser=argparse.ArgumentParser(description=__doc__)
parser.add_argument("--work-root",type=Path,required=True,help="new private remote task directory")
args=parser.parse_args()
if os.getuid()==0:
    parser.error("run tests as an unprivileged user")
root=args.work_root.resolve()
root.mkdir(mode=0o700,parents=True,exist_ok=False)
suite=Path(__file__).resolve().parent
repo=suite.parents[1]

def materialize(source,destination):
    # Only the Lua source needed by the recording harness; never run chezmoi/apply.
    for src in sorted(source.rglob("*.lua")):
        parts=[part.removeprefix("exact_").removeprefix("literal_") for part in src.relative_to(source).parts]
        dst=destination.joinpath(*parts)
        dst.parent.mkdir(parents=True,exist_ok=True)
        shutil.copyfile(src,dst)

shared=root/"shared"
ii=root/"ii/hypr"
materialize(repo/"private_dot_config/exact_hypr-personal",shared)
materialize(repo/"private_dot_config/desktop-profiles/hyprland-ii/exact_hypr",ii)
snapshots={
    "off":"return {enabled=false,bindings={}}\n",
    "empty":"return {enabled=true,bindings={}}\n",
    "custom":'return {enabled=true,bindings={{fingers=2,direction="horizontal",kind="hyprland",action="resize",mods="SUPER",scale=2,disable_inhibit=true},{fingers=5,direction="left",kind="shell",action="overview"}}}\n',
    "defaults":None,
}
cases=[("clean","check_clean.lua",None),*(
    ("gestures-"+case,"check_gestures.lua",case) for case in snapshots),
    ("monitor-dpms","check_monitor_dpms.lua",None)]
results=[]
for name,file,case in cases:
    home=root/name
    env=dict(HOME=str(home),PATH="/usr/bin:/bin",LANG="C.UTF-8",HYPR_PERSONAL_DIR=str(shared),
        DESKTOP_PROFILE="hyprland-ii",GSETTINGS_BACKEND="memory",PYTHONDONTWRITEBYTECODE="1")
    for key,sub in [("XDG_CONFIG_HOME",".config"),("XDG_DATA_HOME","data"),("XDG_STATE_HOME","state"),
                    ("XDG_CACHE_HOME","cache"),("XDG_RUNTIME_DIR","runtime"),("TMPDIR","tmp"),
                    ("XDG_CONFIG_DIRS","config-dirs"),("XDG_DATA_DIRS","data-dirs")]:
        env[key]=str(home/sub)
        Path(env[key]).mkdir(mode=0o700,parents=True)
    config=Path(env["XDG_CONFIG_HOME"])
    (config/"hypr").symlink_to(ii,target_is_directory=True)
    if case and snapshots[case] is not None:
        snapshot=Path(env["XDG_STATE_HOME"])/"quickshell/user/generated/touchpad_gestures.lua"
        snapshot.parent.mkdir(parents=True)
        snapshot.write_text(snapshots[case])
    command=["dbus-run-session","--",sys.executable,str(suite/"fixtures/run_lua.py"),str(suite/file),str(config)]
    if case: command.append(case)
    proc=subprocess.run(command,env=env,text=True,capture_output=True,timeout=20)
    log=root/(name+".log")
    log.write_text(json.dumps(dict(uid=os.getuid(),command=command,environment=env),indent=2)+"\n"+proc.stdout+proc.stderr)
    results.append(dict(name=name,exit_code=proc.returncode,log=str(log)))
    print(name,"exit="+str(proc.returncode),log,flush=True)
(root/"results.json").write_text(json.dumps(results,indent=2)+"\n")
sys.exit(any(result["exit_code"] for result in results))
