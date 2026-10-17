#!/usr/bin/env python3
import sys
import subprocess
import json

def get_hypr_state():
    try:
        raw = subprocess.check_output(
            ["hyprctl", "--batch", "j/activeworkspace ; j/workspaces ; j/clients ; j/activewindow"],
            stderr=subprocess.DEVNULL
        ).decode("utf-8")
        parts = [p.strip() for p in raw.strip().split("\n\n") if p.strip()]
        
        active_ws = json.loads(parts[0]) if len(parts) > 0 else {}
        workspaces_raw = json.loads(parts[1]) if len(parts) > 1 else []
        clients_raw = json.loads(parts[2]) if len(parts) > 2 else []
        active_win = json.loads(parts[3]) if len(parts) > 3 else {}
    except Exception:
        # Fallback to individual calls
        try:
            active_ws = json.loads(subprocess.check_output(["hyprctl", "activeworkspace", "-j"], stderr=subprocess.DEVNULL).decode("utf-8"))
        except Exception:
            active_ws = {}
        try:
            workspaces_raw = json.loads(subprocess.check_output(["hyprctl", "workspaces", "-j"], stderr=subprocess.DEVNULL).decode("utf-8"))
        except Exception:
            workspaces_raw = []
        try:
            clients_raw = json.loads(subprocess.check_output(["hyprctl", "clients", "-j"], stderr=subprocess.DEVNULL).decode("utf-8"))
        except Exception:
            clients_raw = []
        try:
            active_win = json.loads(subprocess.check_output(["hyprctl", "activewindow", "-j"], stderr=subprocess.DEVNULL).decode("utf-8"))
        except Exception:
            active_win = {}

    active_ws_id = active_ws.get("id", 1)
    
    # Process clients
    clients = []
    clients_by_ws = {}
    scratchpad_count = 0
    
    for c in clients_raw:
        if not isinstance(c, dict):
            continue
        ws_info = c.get("workspace", {})
        ws_id = ws_info.get("id") if isinstance(ws_info, dict) else ws_info
        ws_name = ws_info.get("name", "") if isinstance(ws_info, dict) else str(ws_info)
        
        client_item = {
            "address": c.get("address", ""),
            "title": c.get("title", ""),
            "class": c.get("class", ""),
            "initialClass": c.get("initialClass", ""),
            "workspaceId": ws_id,
            "workspaceName": ws_name,
            "floating": bool(c.get("floating", False)),
            "fullscreen": bool(c.get("fullscreen", False) or c.get("fullscreenClient", 0) > 0),
            "pinned": bool(c.get("pinned", False)),
            "pid": c.get("pid", 0)
        }
        clients.append(client_item)
        
        if "special" in str(ws_name).lower():
            scratchpad_count += 1
            
        if ws_id not in clients_by_ws:
            clients_by_ws[ws_id] = []
        clients_by_ws[ws_id].append(client_item)

    # Build workspace list for 1..10 plus existing special or >10 workspaces
    ws_dict = {w.get("id"): w for w in workspaces_raw if isinstance(w, dict) and "id" in w}
    
    all_ws_ids = set(range(1, 11))
    for wid in ws_dict.keys():
        if isinstance(wid, int) and wid > 0:
            all_ws_ids.add(wid)

    workspaces = []
    for wid in sorted(list(all_ws_ids)):
        raw_w = ws_dict.get(wid, {})
        ws_clients = clients_by_ws.get(wid, [])
        is_active = (wid == active_ws_id)
        workspaces.append({
            "id": wid,
            "name": str(raw_w.get("name", wid)),
            "monitor": raw_w.get("monitor", ""),
            "isActive": is_active,
            "windowsCount": len(ws_clients),
            "clients": ws_clients,
            "hasFullscreen": bool(raw_w.get("hasfullscreen", False))
        })

    # Add special scratchpad workspace info
    special_clients = [c for c in clients if "special" in str(c.get("workspaceName", "")).lower()]
    
    return {
        "available": bool(active_ws),
        "activeWorkspace": {
            "id": active_ws_id,
            "name": str(active_ws.get("name", active_ws_id)),
            "monitor": active_ws.get("monitor", ""),
            "windowsCount": active_ws.get("windows", len(clients_by_ws.get(active_ws_id, []))),
            "tiledLayout": active_ws.get("tiledLayout", "dwindle")
        },
        "activeWindow": {
            "address": active_win.get("address", ""),
            "title": active_win.get("title", ""),
            "class": active_win.get("class", ""),
            "workspaceId": active_win.get("workspace", {}).get("id") if isinstance(active_win.get("workspace"), dict) else 0,
            "floating": bool(active_win.get("floating", False)),
            "fullscreen": bool(active_win.get("fullscreen", False) or active_win.get("fullscreenClient", 0) > 0),
            "pinned": bool(active_win.get("pinned", False))
        },
        "workspaces": workspaces,
        "clients": clients,
        "scratchpadCount": len(special_clients),
        "scratchpadClients": special_clients
    }

def main():
    if len(sys.argv) > 1 and sys.argv[1] == "dispatch":
        args = sys.argv[2:]
        try:
            res = subprocess.check_output(["hyprctl", "dispatch"] + args, stderr=subprocess.STDOUT).decode("utf-8")
            print(res)
        except subprocess.CalledProcessError as e:
            print(e.output.decode("utf-8"), file=sys.stderr)
            sys.exit(e.returncode)
        return

    state = get_hypr_state()
    print(json.dumps(state, ensure_ascii=False))

if __name__ == "__main__":
    main()
