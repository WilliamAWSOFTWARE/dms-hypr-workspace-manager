#!/usr/bin/env python3
"""
Hyprland Layout Manager backend helper.
Queries and applies layouts and window arrangements in Hyprland 0.56.2+ via hyprctl eval and JSON queries.
"""

import sys
import json
import subprocess

def hypr_eval(code):
    try:
        res = subprocess.run(["hyprctl", "eval", code], capture_output=True, text=True, check=True)
        return True
    except Exception as e:
        sys.stderr.write(f"hypr_eval error: {e}\n")
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
                    hypr_eval(f"hl.dispatch(hl.dsp.workspace.change_id({ws_id}))")
                break
    except Exception:
        pass

def set_layout(layout_id, target_monitor=None):
    if target_monitor:
        ensure_monitor_focus(target_monitor)

    current = get_state(target_monitor)
    is_fs = current.get("isFullscreen", False)

    if layout_id == "monocle":
        hypr_eval("hl.dispatch(hl.dsp.window.fullscreen())")
    else:
        # If currently in fullscreen/monocle, un-fullscreen first
        if is_fs:
            hypr_eval("hl.dispatch(hl.dsp.window.fullscreen())")

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
            hypr_eval("hl.config({ general = { layout = 'dwindle' } }) hl.dispatch(hl.dsp.window.pseudo())")
        elif layout_id == "fair":
            hypr_eval("hl.config({ general = { layout = 'dwindle' } }) hl.dispatch(hl.dsp.layout('togglesplit'))")
        elif layout_id == "vertical_grid":
            hypr_eval("hl.config({ general = { layout = 'master' }, master = { orientation = 'top' } }) hl.dispatch(hl.dsp.layout('rollnext'))")
        elif layout_id == "vertical_deck":
            hypr_eval("hl.config({ general = { layout = 'master' }, master = { orientation = 'top' } }) hl.dispatch(hl.dsp.group.toggle())")
        elif layout_id in ("scroller", "vertical_scroller"):
            hypr_eval("pcall(function() hl.config({ general = { layout = 'scroller' } }) end) hl.dispatch(hl.dsp.layout('rollnext'))")
        else:
            hypr_eval(f"hl.config({{ general = {{ layout = '{layout_id}' }} }})")

    return get_state(target_monitor)

def quick_action(action, target_monitor=None):
    if target_monitor:
        ensure_monitor_focus(target_monitor)

    if action == "toggle_floating":
        hypr_eval("hl.dispatch(hl.dsp.window.float({ action = 'toggle' }))")
    elif action == "toggle_fullscreen":
        hypr_eval("hl.dispatch(hl.dsp.window.fullscreen())")
    elif action == "toggle_pin":
        hypr_eval("hl.dispatch(hl.dsp.window.pin())")
    elif action == "toggle_group":
        hypr_eval("hl.dispatch(hl.dsp.group.toggle())")
    elif action == "toggle_split":
        hypr_eval("hl.dispatch(hl.dsp.layout('togglesplit'))")
    elif action == "swap_master":
        hypr_eval("hl.dispatch(hl.dsp.layout('swapwithmaster'))")
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
