#!/usr/bin/env python3
"""Personal NyxMellow rendering and upstream palette contract checks."""
import argparse
import json
import os
from pathlib import Path
import re
import subprocess
import tempfile
import tomllib

HERE = Path(__file__).resolve().parent
FILES = ("theme.conf", "panel.svg", "highlight.svg")
ROLES = {"on_surface", "on_primary", "primary", "surface_container_lowest", "outline", "outline_variant"}
DEFAULT = dict(on_surface="#e4e2e2", on_primary="#273238", primary="#b0c8ec",
               surface_container_lowest="#101418", outline="#8d9196", outline_variant="#43474a")
RELOAD = ["busctl", "--user", "--auto-start=no", "call", "org.fcitx.Fcitx5", "/controller",
          "org.fcitx.Fcitx.Controller1", "ReloadAddonConfig", "s", "classicui"]


def render(directory, colors):
    """Validate every value and render all assets before replacing any file."""
    if directory.absolute() != directory.resolve():
        raise ValueError(f"Fcitx storage must not be redirected: {directory}")
    if any(not isinstance(colors.get(key), str) or not re.fullmatch(r"#[0-9a-fA-F]{6}", colors[key]) for key in ROLES):
        raise ValueError("Incomplete Fcitx palette; keeping the previous theme")
    contents = {}
    for name in FILES:
        template = (HERE / "fcitx5" / name).read_text()
        contents[name] = re.sub(r"{{\s*colors\.(\w+)\.default\.hex\s*}}",
                                lambda m: colors[m[1]], template)
        if "{{" in contents[name]:
            raise ValueError(f"Unrecognized Fcitx template expression: {name}")
    directory.mkdir(parents=True, exist_ok=True)
    for name, text in contents.items():
        path = directory / name
        if path.exists() and path.read_text() == text:
            continue
        fd, temporary = tempfile.mkstemp(prefix=".palette-", dir=directory)
        try:
            with os.fdopen(fd, "w") as stream:
                stream.write(text)
            os.replace(temporary, path)
        finally:
            Path(temporary).unlink(missing_ok=True)


def select_theme(text):
    """Keep classicui preferences; select the session's generated palette."""
    for key, value in (("Theme", "nyxmellow"), ("DarkTheme", "nyxmellow"), ("UseDarkTheme", "False")):
        pattern = rf"^{key}=.*$"
        if re.search(pattern, text, re.M):
            text = re.sub(pattern, f"{key}={value}", text, flags=re.M)
        else:
            text = text.rstrip() + f"\n{key}={value}\n"
    return text


def reload_classicui():
    # No daemon activation or restart: an input sequence must survive recoloring.
    try:
        subprocess.run(RELOAD, check=False, stdout=subprocess.DEVNULL,
                       stderr=subprocess.DEVNULL, timeout=5)
    except (OSError, subprocess.TimeoutExpired):
        pass


def verify_contract(profile, source):
    """Reject upstream layout/output changes before installing into a profile."""
    source = Path(source)
    if profile == "dms-niri":
        # Initial DMS adoption keeps all global palette writers explicitly off.
        policy = source / "dms/config.d/00-isolation.json"
        values = json.loads(policy.read_text())
        keys = ("generateThemeAtStartup", "runDmsMatugenTemplates", "runUserMatugenTemplates")
        if not isinstance(values, dict) or any(values.get(key) is not False for key in keys):
            raise ValueError("DMS theme writers require a reviewed profile output contract")
        return
    if profile == "inir":
        base = source / "defaults/matugen"
        entries = json.loads((base / "templates.json").read_text())["templates"]
        outputs = {Path(e["input"]).name: e["output"] for e in entries if e["input"].startswith("fcitx5/")}
        hook = source / "scripts/colors/modules/25-fcitx5.sh"
        templates = base / "templates/fcitx5"
        if 'theme-path' not in (source / 'sdata/lib/functions.sh').read_text():
            raise ValueError("iNiR installer lost managed theme directory routing; review before deployment")
    elif profile == "hyprland-ii":
        base = source / "dots/.config/matugen"
        entries = tomllib.loads((base / "config.toml").read_text())["templates"].values()
        outputs = {Path(e["input_path"]).name: e["output_path"] for e in entries if "/fcitx5/" in e["input_path"]}
        hook = source / "dots/.config/quickshell/ii/scripts/colors/applycolor.sh"
        templates = base / "templates/fcitx5"
    elif profile == "nyxuri":
        templates = source / "units/fcitx5-rime/hooks/skin/templates"
        hook = source / "personal/install.py"
        policy = hook.read_text()
        required = ('noctalia/templates/fcitx5', '.local/share/fcitx5/themes/nyxmellow/',
                    'nyxmellow_{suffix}', 'FCITX_CLASSICUI_RELOAD_HOOK')
        if any(item not in policy for item in required):
            raise ValueError("Nyxuri personal Fcitx template policy changed; review before deployment")
        outputs = {name: f"~/.local/share/fcitx5/themes/nyxmellow/{name}" for name in FILES}
    elif profile in ("vitreus", "vitreus-wm", "vitreus-niri"):
        # Iris is consumed as JSON by this shell; it has no global Fcitx writer.
        shell = (source / "vitreus.luau").read_text()
        if '"--json-only"' not in shell or 'run("iris"' not in shell:
            raise ValueError("Vitreus Iris contract changed; review theme outputs before updating")
        return
    elif profile == "sekaipop":
        shell = (source / "sekaipop/shell.qml").read_text()
        if shell.count("    id: shellRoot") != 1 or not (source / "personal/FcitxTheme.qml").is_file():
            raise ValueError("SekaiPop shell entry changed; review the personal Fcitx adapter")
        return
    else:
        raise ValueError(f"Unknown Fcitx profile: {profile}")
    expected = {name: f"~/.local/share/fcitx5/themes/nyxmellow/{name}" for name in FILES}
    if {name: value.replace("/home/user", "~") for name, value in outputs.items()} != expected:
        raise ValueError(f"{profile}: Fcitx outputs changed; review desktop isolation before deployment")
    used = set()
    for name in FILES:
        used.update(re.findall(r"colors\.(\w+)\.default\.hex", (templates / name).read_text()))
    if not ROLES <= used or any(item not in hook.read_text() for item in ("--auto-start=no", "ReloadAddonConfig")):
        raise ValueError(f"{profile}: Fcitx palette/reload contract changed; review before deployment")


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--colors", required=True)
    args = parser.parse_args()
    home = Path.home()
    root = home / ".config/desktop-profiles/sekaipop/theme"
    journal = home / ".local/state/desktop-profiles/theme-session/journal.json"
    # Existing shell units only received SekaiPop's own config variable.
    # Accept that exact route until the next login, keeping all identity and
    # journal checks; an explicitly wrong common route must still be refused.
    theme_root = os.environ.get("DESKTOP_THEME_ROOT", os.environ.get("SEKAIPOP_THEME_CONFIG"))
    if (os.environ.get("DESKTOP_PROFILE") != "sekaipop"
            or theme_root != str(root)
            or root.resolve() != root or json.loads(journal.read_text()).get("profile") != "sekaipop"):
        raise ValueError("Fcitx rendering requires the active SekaiPop theme session")
    render(root / "data/fcitx5/nyxmellow", json.loads(args.colors))
    reload_classicui()


if __name__ == "__main__":
    try:
        main()
    except (OSError, ValueError, KeyError) as error:
        raise SystemExit(f"desktop-profile Fcitx: {error}")
