#!/usr/bin/env python3
"""
Hyprland Layout Manager backend helper.
Queries and applies layouts and window arrangements in Hyprland 0.50+ via hyprctl eval (Lua) and hyprctl dispatch/keyword.
"""

import sys
import json
import subprocess

_has_lua_cached = None

def has_lua():
    global _has_lua_cached
    if _has_lua_cached is not None:
        return _has_lua_cached
    try:
        res = subprocess.run(["hyprctl", "eval", "return 1"], capture_output=True, text=True, timeout=1)
        _has_lua_cached = (res.returncode == 0)
    except Exception:
        _has_lua_cached = False
    return _has_lua_cached

def hypr_eval(code):
    try:
        res = subprocess.run(["hyprctl", "eval", code], capture_output=True, text=True, timeout=2)
        return res.returncode == 0
    except Exception as e:
        sys.stderr.write(f"hypr_eval error: {e}\n")
        return False

def hypr_dispatch(cmd):
    try:
        args = ["hyprctl", "dispatch"] + cmd.split()
        res = subprocess.run(args, capture_output=True, text=True, timeout=2)
        return res.returncode == 0
    except Exception as e:
        sys.stderr.write(f"hypr_dispatch error: {e}\n")
        return False

def hypr_keyword(key, val):
    try:
        res = subprocess.run(["hyprctl", "keyword", key, str(val)], capture_output=True, text=True, timeout=2)
        return res.returncode == 0
    except Exception as e:
        sys.stderr.write(f"hypr_keyword error: {e}\n")
        return False

def get_state(target_monitor=None):
    gl = "dwindle"
    mo = "left"
    mons = []
    aw = {}

    try:
        raw = subprocess.check_output(
            ["hyprctl", "--batch", "j/getoption general:layout ; j/getoption master:orientation ; j/monitors ; j/activewindow"],
            timeout=2
        ).decode()
        parts = [p.strip() for p in raw.split("\n\n") if p.strip()]
        if len(parts) >= 1:
            gl = json.loads(parts[0]).get("str", "dwindle")
        if len(parts) >= 2:
            mo = json.loads(parts[1]).get("str", "left")
        if len(parts) >= 3:
            mons = json.loads(parts[2])
        if len(parts) >= 4:
            aw = json.loads(parts[3])
    except Exception:
        try:
            gl = json.loads(subprocess.check_output(["hyprctl", "-j", "getoption", "general:layout"], timeout=1)).get("str", "dwindle")
        except Exception:
            pass
        try:
            mo = json.loads(subprocess.check_output(["hyprctl", "-j", "getoption", "master:orientation"], timeout=1)).get("str", "left")
        except Exception:
            pass
        try:
            mons = json.loads(subprocess.check_output(["hyprctl", "-j", "monitors"], timeout=1))
        except Exception:
            pass
        try:
            aw = json.loads(subprocess.check_output(["hyprctl", "-j", "activewindow"], timeout=1))
        except Exception:
            pass

    target_ws = None
    target_mon_info = None
    if target_monitor and mons:
        for m in mons:
            if str(m.get("name", "")).strip().lower() == str(target_monitor).strip().lower():
                target_ws = m.get("activeWorkspace", {})
                target_mon_info = m
                break

    if target_ws and target_ws.get("id"):
        ws = target_ws
        ws_id = ws.get("id")
        monitor_name = target_mon_info.get("name", target_monitor) if target_mon_info else target_monitor
        if aw.get("workspace", {}).get("id") != ws_id:
            aw = {}
    else:
        ws = aw.get("workspace", {})
        monitor_name = target_monitor or ""
        if mons:
            for m in mons:
                if m.get("focused"):
                    ws = m.get("activeWorkspace", ws)
                    monitor_name = m.get("name", monitor_name)
                    break

    # Check if workspace has a per-workspace tiledLayout override
    ws_tiled = ws.get("tiledLayout")
    if ws_tiled and ws_tiled in ("dwindle", "master"):
        gl = ws_tiled

    fs = bool(aw.get("fullscreen", 0))
    grouped = bool(aw.get("grouped", []))
    floating = bool(aw.get("floating", False))
    pinned = bool(aw.get("pinned", False))

    if fs:
        layout_id = "monocle"
    elif grouped:
        layout_id = "deck"
    elif gl == "master":
        if mo == "right":
            layout_id = "right_tile"
        elif mo == "top":
            layout_id = "vertical_tile"
        elif mo == "center":
            layout_id = "center_tile"
        elif mo == "bottom":
            layout_id = "vertical_fair"
        else:
            layout_id = "tile"
    elif gl == "dwindle":
        layout_id = "dwindle"
    else:
        layout_id = gl

    LAYOUT_METAS = {
        "tile": ("Tile", "T", "view_quilt"),
        "right_tile": ("Right Tile", "RT", "view_sidebar"),
        "vertical_tile": ("Vertical Tile", "VT", "clarify"),
        "center_tile": ("Center Tile", "CT", "view_compact"),
        "vertical_fair": ("Vertical Fair", "VF", "vertical_distribute"),
        "dwindle": ("Dwindle", "DW", "account_tree"),
        "monocle": ("Monocle", "M", "fullscreen"),
        "deck": ("Deck", "K", "layers")
    }

    meta = LAYOUT_METAS.get(layout_id, (layout_id.capitalize(), layout_id[:2].upper(), "view_quilt"))

    return {
        "currentLayout": layout_id,
        "layoutLabel": meta[0],
        "layoutCode": meta[1],
        "layoutIcon": meta[2],
        "generalLayout": gl,
        "masterOrientation": mo,
        "isFullscreen": fs,
        "isGrouped": grouped,
        "isFloating": floating,
        "isPinned": pinned,
        "activeWorkspace": ws.get("id", 1),
        "workspaceName": ws.get("name", "1"),
        "monitor": monitor_name,
        "activeTitle": aw.get("title", ""),
        "activeClass": aw.get("class", ""),
        "windowAddress": aw.get("address", "")
    }

def ensure_monitor_focus(target_monitor):
    if not target_monitor:
        return
    try:
        mons = json.loads(subprocess.check_output(["hyprctl", "-j", "monitors"], timeout=1))
        for m in mons:
            if str(m.get("name", "")).strip().lower() == str(target_monitor).strip().lower():
                ws_id = m.get("activeWorkspace", {}).get("id")
                if ws_id is not None:
                    if has_lua():
                        hypr_eval(f"hl.dispatch(hl.dsp.workspace.change_id({ws_id}))")
                    else:
                        hypr_dispatch(f"workspace {ws_id}")
                break
    except Exception:
        pass

def set_layout(layout_id, target_monitor=None):
    if target_monitor:
        ensure_monitor_focus(target_monitor)

    current = get_state(target_monitor)
    is_fs = current.get("isFullscreen", False)
    is_grp = current.get("isGrouped", False)
    use_lua = has_lua()

    if layout_id == "monocle":
        if not is_fs:
            if use_lua:
                hypr_eval("hl.dispatch(hl.dsp.window.fullscreen())")
            else:
                hypr_dispatch("fullscreen 1")
    elif layout_id == "deck":
        if is_fs:
            if use_lua:
                hypr_eval("hl.dispatch(hl.dsp.window.fullscreen())")
            else:
                hypr_dispatch("fullscreen 1")
        if not is_grp:
            if use_lua:
                hypr_eval("hl.dispatch(hl.dsp.group.toggle())")
            else:
                hypr_dispatch("togglegroup")
    else:
        # If currently in fullscreen/monocle, un-fullscreen first
        if is_fs:
            if use_lua:
                hypr_eval("hl.dispatch(hl.dsp.window.fullscreen())")
            else:
                hypr_dispatch("fullscreen 1")

        if use_lua:
            if layout_id == "dwindle":
                hypr_eval("hl.config({ general = { layout = 'dwindle' } })")
            elif layout_id == "tile":
                hypr_eval("hl.config({ general = { layout = 'master' }, master = { orientation = 'left' } })")
            elif layout_id == "right_tile":
                hypr_eval("hl.config({ general = { layout = 'master' }, master = { orientation = 'right' } })")
            elif layout_id == "vertical_tile":
                hypr_eval("hl.config({ general = { layout = 'master' }, master = { orientation = 'top' } })")
            elif layout_id == "center_tile":
                hypr_eval("hl.config({ general = { layout = 'master' }, master = { orientation = 'center' } })")
            elif layout_id == "vertical_fair":
                hypr_eval("hl.config({ general = { layout = 'master' }, master = { orientation = 'bottom' } })")
            else:
                hypr_eval(f"hl.config({{ general = {{ layout = '{layout_id}' }} }})")
        else:
            if layout_id == "dwindle":
                hypr_keyword("general:layout", "dwindle")
            elif layout_id == "tile":
                hypr_keyword("general:layout", "master")
                hypr_keyword("master:orientation", "left")
            elif layout_id == "right_tile":
                hypr_keyword("general:layout", "master")
                hypr_keyword("master:orientation", "right")
            elif layout_id == "vertical_tile":
                hypr_keyword("general:layout", "master")
                hypr_keyword("master:orientation", "top")
            elif layout_id == "center_tile":
                hypr_keyword("general:layout", "master")
                hypr_keyword("master:orientation", "center")
            elif layout_id == "vertical_fair":
                hypr_keyword("general:layout", "master")
                hypr_keyword("master:orientation", "bottom")
            else:
                hypr_keyword("general:layout", layout_id)

    return get_state(target_monitor)

def quick_action(action, target_monitor=None):
    if target_monitor:
        ensure_monitor_focus(target_monitor)

    use_lua = has_lua()
    if action == "toggle_floating":
        if use_lua:
            hypr_eval("hl.dispatch(hl.dsp.window.float({ action = 'toggle' }))")
        else:
            hypr_dispatch("togglefloating")
    elif action == "toggle_fullscreen":
        if use_lua:
            hypr_eval("hl.dispatch(hl.dsp.window.fullscreen())")
        else:
            hypr_dispatch("fullscreen")
    elif action == "toggle_pin":
        if use_lua:
            hypr_eval("hl.dispatch(hl.dsp.window.pin())")
        else:
            hypr_dispatch("pin")
    elif action == "toggle_group":
        if use_lua:
            hypr_eval("hl.dispatch(hl.dsp.group.toggle())")
        else:
            hypr_dispatch("togglegroup")
    elif action == "toggle_split":
        if use_lua:
            hypr_eval("hl.dispatch(hl.dsp.layout('togglesplit'))")
        else:
            hypr_dispatch("layoutmsg togglesplit")
    elif action == "swap_master":
        if use_lua:
            hypr_eval("hl.dispatch(hl.dsp.layout('swapwithmaster'))")
        else:
            hypr_dispatch("layoutmsg swapwithmaster")

    return get_state(target_monitor)

def main():
    cmd = sys.argv[1] if len(sys.argv) > 1 else "get"
    if cmd == "get":
        target_mon = sys.argv[2] if len(sys.argv) > 2 else None
        print(json.dumps(get_state(target_mon)))
    elif cmd == "set" and len(sys.argv) >= 3:
        target_mon = sys.argv[3] if len(sys.argv) > 3 else None
        print(json.dumps(set_layout(sys.argv[2], target_mon)))
    elif cmd == "action" and len(sys.argv) >= 3:
        target_mon = sys.argv[3] if len(sys.argv) > 3 else None
        print(json.dumps(quick_action(sys.argv[2], target_mon)))
    else:
        print(json.dumps(get_state()))

if __name__ == "__main__":
    main()
