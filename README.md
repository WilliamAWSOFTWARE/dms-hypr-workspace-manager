# Hyprland Workspace & Window Manager for DankMaterialShell

A feature-rich workspace switcher, window manager, and tiling controller widget for **DankMaterialShell (DankLinux)** running on **Hyprland**.

Inspired by `mangoWmLayoutManager`, but purpose-built with native `hyprctl` power.

![DankMaterialShell Hyprland Plugin](https://raw.githubusercontent.com/WilliamAWSOFTWARE/dms-hypr-workspace-manager/main/screenshot.png)

---

## Features

### 1. DankBar Widget Pill
- **Rich Display**:
  - Active workspace badge (e.g. `1`).
  - Active focused application name/title with state indicator (Tiling, Floating, or Fullscreen).
  - Badge counter showing total open windows in the current workspace.
- **Mouse Shortcuts**:
  - **Left-Click**: Opens the interactive management popout dashboard.
  - **Right-Click**: Quick-toggle **Special Workspace / Scratchpad** (customizable in settings).
  - **Middle-Click**: Quick-toggle Dwindle split orientation (**Toggle Split**).
  - **Mouse Wheel Scroll**: Smoothly cycle through workspaces with kinetic throttling.

### 2. Interactive Popout Dashboard
- **Tiling Quick Toolbar**:
  - 🔄 **Toggle Split**: Toggle horizontal/vertical split in Hyprland's dwindle layout (`layoutmsg togglesplit`).
  - ⭐ **Scratchpad**: Instant toggle for your special scratchpad / notes window.
  - ⬅️ ➡️ ⬆️ ⬇️ **Directional Swap**: Swap window position left, right, up, or down (`swapwindow l/r/u/d`).
- **Workspaces Matrix (1 to 10)**:
  - Interactive grid displaying all workspaces with active space highlighting.
  - Live window chips showing applications running in each workspace.
  - **Click Card**: Instantly switches to that workspace.
  - **"Send Active Here" Button**: One-click relocation for the currently focused window.
- **Window List & Quick Relocation**:
  - Filter tabs: *In Current Workspace*, *All Windows*, and *Scratchpad*.
  - Direct 1-click workspace buttons per window: `[ 1 ] [ 2 ] [ 3 ] ... [ 10 ] [ ★ Scratchpad ]` to move any window anywhere immediately.
  - Per-window actions: Focus (🎯), Toggle Floating (🪟), Fullscreen (🔲), Pin/Sticky (📌), and Close (❌).

---

## Requirements

- **Hyprland** (>= 0.40)
- `hyprctl` (included by default with Hyprland)
- `python3` (for sub-millisecond state parsing)

---

## Installation

### Via Git Clone
```bash
cd ~/.config/DankMaterialShell/plugins
git clone https://github.com/WilliamAWSOFTWARE/dms-hypr-workspace-manager.git hyprWorkspaceManager
dms restart
```

Then enable it in **DMS Settings → Plugins → Hyprland Workspace & Window Manager**, and add `hyprWorkspaceManager` to your bar widgets layout.

---

## Configuration

Customizable directly inside DMS Settings → Plugins:
- **Right-Click Action**: Scratchpad, Toggle Floating, Toggle Split, Fullscreen, or Next Workspace.
- **Middle-Click Action**: Toggle Split, Toggle Floating, Scratchpad, etc.
- **Show Window Title**: Toggle title display in bar pill.
- **Max Title Length**: Character limit before truncation.
- **Scroll Cooldown (ms)**: Wheel sensitivity to prevent accidental multi-workspace skips.
- **Silent Move**: Keep focus on current workspace when moving windows to other spaces.

---

<details>
<summary><b>🇪🇸 Documentación en Español (Haz clic para expandir)</b></summary>

### Características
- **Pill en la barra (DankBar)** con workspace activo, ventana enfocada y conteo de ventanas.
- **Atajos en barra**:
  - Clic izquierdo: Abre el Popout Dashboard.
  - Clic derecho: Alterna el Scratchpad / Special Workspace.
  - Clic central: Alterna la división de Dwindle (Split).
  - Scroll: Cambia de espacio de trabajo rápidamente.
- **Dashboard Popout**:
  - Matriz 5x2 de espacios de trabajo con chips de aplicaciones en tiempo real.
  - Botón de enviar ventana activa a cualquier espacio con 1 clic.
  - Listado de ventanas con botones directos `[ 1 ] [ 2 ] [ 3 ] ... [ 10 ] [ Scratchpad ]`.
  - Controles de ventana: Flotante, Fullscreen, Pin y Cerrar.
  - Toolbar de Tiling: Split y Swap direccional (⬅️ ➡️ ⬆️ ⬇️).

### Instalación
```bash
cd ~/.config/DankMaterialShell/plugins
git clone https://github.com/WilliamAWSOFTWARE/dms-hypr-workspace-manager.git hyprWorkspaceManager
dms restart
```

</details>

---

## License

MIT © [WilliamAWSOFTWARE](https://github.com/WilliamAWSOFTWARE)
