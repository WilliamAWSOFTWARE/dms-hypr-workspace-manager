#!/usr/bin/env python3
"""
Hyprland Layout Manager backend helper.
Queries and applies layouts and window arrangements in Hyprland 0.56.2+ via hyprctl eval and JSON queries.
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
        res = subprocess.run(["hyprctl", "eval", "return 1"], capture_output=True, text=True)
        _has_lua_cached = (res.returncode == 0)
    except Exception:
        _has_lua_cached = False
    return _has_lua_cached

def hypr_eval(code):
    try:
        res = subprocess.run(["hyprctl", "eval", code], capture_output=True, text=True)
        return res.returncode == 0
    except Exception as e:
        sys.stderr.write(f"hypr_eval error: {e}\n")
        return False

def hypr_dispatch(cmd):
    try:
        args = ["hyprctl", "dispatch"] + cmd.split()
        res = subprocess.run(args, capture_output=True, text=True)
        return res.returncode == 0
    except Exception as e:
        sys.stderr.write(f"hypr_dispatch error: {e}\n")
        return False

def hypr_keyword(key, val):
    try:
        res = subprocess.run(["hyprctl", "keyword", key, str(val)], capture_output=True, text=True)
        return res.returncode == 0
    except Exception as e:
        sys.stderr.write(f"hypr_keyword error: {e}\n")
        return False

def get_state(target_monitor=None):
    try:
        gl_out = subprocess.check_output(["hyprctl", "-j", "getoption", "general:layout"])
        gl = json.loads(gl_out).get("str", "dwindle")
    except Exception:
        gl = "dwindle"

    try:
        mo_out = subprocess.check_output(["hyprctl", "-j", "getoption", "master:orientation"])
        mo = json.loads(mo_out).get("str", "left")
    except Exception:
        mo = "left"

    target_ws = None
    target_mon_info = None
    if target_monitor:
        try:
            mons = json.loads(subprocess.check_output(["hyprctl", "-j", "monitors"]))
            for m in mons:
                if str(m.get("name", "")).strip().lower() == str(target_monitor).strip().lower():
                    target_ws = m.get("activeWorkspace", {})
                    target_mon_info = m
                    break
        except Exception:
            pass

    if target_ws and target_ws.get("id"):
        ws = target_ws
        ws_id = ws.get("id")
        monitor_name = target_mon_info.get("name", target_monitor) if target_mon_info else target_monitor
        aw = {}
        try:
            curr_aw = json.loads(subprocess.check_output(["hyprctl", "-j", "activewindow"]))
            if curr_aw.get("workspace", {}).get("id") == ws_id:
                aw = curr_aw
        except Exception:
            pass

        if not aw:
            try:
                clients = json.loads(subprocess.check_output(["hyprctl", "-j", "clients"]))
                for c in clients:
                    if c.get("workspace", {}).get("id") == ws_id:
                        aw = c
                        break
            except Exception:
                pass
    else:
        try:
            ws = json.loads(subprocess.check_output(["hyprctl", "-j", "activeworkspace"]))
        except Exception:
            ws = {}
        try:
            aw = json.loads(subprocess.check_output(["hyprctl", "-j", "activewindow"]))
        except Exception:
            aw = {}
        monitor_name = ws.get("monitor", target_monitor or "")

    # Check if workspace has a per-workspace tiledLayout override
    ws_tiled = ws.get("tiledLayout")
    if ws_tiled and ws_tiled in ("dwindle", "master", "scroller"):
        gl = ws_tiled

    fs = aw.get("fullscreen", 0) > 0
    grouped = bool(aw.get("grouped", []))
    floating = bool(aw.get("floating", False))
    pseudo = bool(aw.get("pseudo", False))
    pinned = bool(aw.get("pinned", False))

    if fs:
        layout_id = "monocle"
    elif grouped:
        layout_id = "deck"
    elif gl == "master":
        if mo == "left":
            layout_id = "tile"
        elif mo == "right":
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
        if pseudo:
            layout_id = "grid"
        else:
            layout_id = "dwindle"
    else:
        layout_id = gl

    # Layout human readable name and code
    LAYOUT_METAS = {
        "tile": ("Tile", "T", "view_quilt"),
        "scroller": ("Scroller", "S", "view_carousel"),
        "monocle": ("Monocle", "M", "fullscreen"),
        "grid": ("Grid", "G", "grid_view"),
        "deck": ("Deck", "K", "layers"),
        "center_tile": ("Center Tile", "CT", "view_compact"),
        "vertical_tile": ("Vertical Tile", "VT", "clarify"),
        "right_tile": ("Right Tile", "RT", "view_sidebar"),
        "vertical_scroller": ("Vertical Scroller", "VS", "scrollable_header"),
        "vertical_grid": ("Vertical Grid", "VG", "grid_on"),
        "vertical_deck": ("Vertical Deck", "VK", "view_day"),
        "dwindle": ("Dwindle", "DW", "account_tree"),
        "fair": ("Fair", "F", "horizontal_distribute"),
        "vertical_fair": ("Vertical Fair", "VF", "vertical_distribute")
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
        mons = json.loads(subprocess.check_output(["hyprctl", "-j", "monitors"]))
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
    use_lua = has_lua()

    if layout_id == "monocle":
        if use_lua:
            hypr_eval("hl.dispatch(hl.dsp.window.fullscreen())")
        else:
            hypr_dispatch("fullscreen 1")
    else:
        # If currently in fullscreen/monocle, un-fullscreen first
        if is_fs:
            if use_lua:
                hypr_eval("hl.dispatch(hl.dsp.window.fullscreen())")
            else:
                hypr_dispatch("fullscreen 1")

        # Ensure pseudo-tiling is cleared so windows don't get trapped with fixed aspect ratio
        if layout_id != "grid":
            if use_lua:
                hypr_eval("pcall(function() hl.dispatch(hl.dsp.window.pseudo({ action = 'off' })) end)")
            else:
                if current.get("pseudo", False):
                    hypr_dispatch("pseudo")

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
            elif layout_id == "deck":
                hypr_eval("hl.dispatch(hl.dsp.group.toggle())")
            elif layout_id == "grid":
                hypr_eval("hl.config({ general = { layout = 'dwindle' } }) hl.dispatch(hl.dsp.layout('togglesplit'))")
            elif layout_id == "fair":
                hypr_eval("hl.config({ general = { layout = 'dwindle' } }) hl.dispatch(hl.dsp.layout('togglesplit'))")
            elif layout_id == "vertical_grid":
                hypr_eval("hl.config({ general = { layout = 'master' }, master = { orientation = 'top' } }) hl.dispatch(hl.dsp.layout('rollnext'))")
            elif layout_id == "vertical_deck":
                hypr_eval("hl.config({ general = { layout = 'master' }, master = { orientation = 'top' } }) hl.dispatch(hl.dsp.group.toggle())")
            elif layout_id in ("scroller", "vertical_scroller"):
                hypr_eval("pcall(function() hl.config({ general = { layout = 'scrolling' } }) end) hl.dispatch(hl.dsp.layout('rollnext'))")
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
            elif layout_id == "deck":
                hypr_dispatch("togglegroup")
            elif layout_id == "grid":
                hypr_keyword("general:layout", "dwindle")
                hypr_dispatch("layoutmsg togglesplit")
            elif layout_id == "fair":
                hypr_keyword("general:layout", "dwindle")
                hypr_dispatch("layoutmsg togglesplit")
            elif layout_id == "vertical_grid":
                hypr_keyword("general:layout", "master")
                hypr_keyword("master:orientation", "top")
                hypr_dispatch("layoutmsg rollnext")
            elif layout_id == "vertical_deck":
                hypr_keyword("general:layout", "master")
                hypr_keyword("master:orientation", "top")
                hypr_dispatch("togglegroup")
            elif layout_id in ("scroller", "vertical_scroller"):
                hypr_keyword("general:layout", "scroller")
                hypr_dispatch("layoutmsg rollnext")
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
