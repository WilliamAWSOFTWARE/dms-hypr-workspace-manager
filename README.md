# Hyprland Layout Manager (DMS Plugin)

Un widget y selector visual de layouts para **Hyprland** en **DankMaterialShell (DMS)**, con la misma estética premium y funcionalidad que el Layout Manager de MangoWM.

---

## 🎯 ¿Qué hace este plugin?

Permite cambiar y alternar la disposición de tus ventanas en Hyprland en tiempo real desde la barra o mediante un popout visual con esquemas gráficos interactivos.

Soporta los 14 estilos de layouts característicos:
- **Tile (T)**: Master a la izquierda, ventanas apiladas a la derecha.
- **Right Tile (RT)**: Master a la derecha, ventanas apiladas a la izquierda.
- **Vertical Tile (VT)**: Master arriba, columnas apiladas abajo.
- **Center Tile (CT)**: Master en el centro, columnas a izquierda y derecha.
- **Dwindle (DW)**: Árbol binario en espiral clásico de Hyprland.
- **Monocle (M)**: Modo pantalla completa / maximizado (una ventana visible a la vez).
- **Deck / Group (K)**: Ventanas agrupadas en pestañas (Deck/Tabbed group).
- **Grid (G)**: Cuadrícula equilibrada (pseudotile).
- **Fair (F)**: Distribución horizontal uniforme (togglesplit).
- **Vertical Fair (VF)**: Distribución vertical uniforme (master abajo).
- **Scroller / Vertical Scroller (S / VS)**: Desplazamiento y carrusel de ventanas.
- **Vertical Grid (VG) / Vertical Deck (VK)**: Variantes verticales para monitores ultrawide o verticales.

---

## 🚀 ¿Cómo se usa?

### 1. En la Barra (DankBar)
El widget muestra el **ícono** y el **código** del layout actual (ejemplo: `DW` para Dwindle, `T` para Tile, `CT` para Center Tile, `M` para Monocle).

- **Clic Izquierdo**: Abre el **Popout Grid** con los esquemas visuales en 3 columnas para elegir directamente cualquier layout.
- **Clic Derecho**: Alterna rápidamente con el layout objetivo configurado (por defecto: `Monocle` / Fullscreen). Si ya estás en ese layout, regresa automáticamente al anterior.
- **Clic Central (Rueda del Mouse)**: Alterna con un segundo layout objetivo configurado (por defecto: `Center Tile`).
- **Scroll (Giro de la rueda o deslizamiento con 2 dedos)**: Pasa al siguiente o anterior layout activo en el ciclo de rotación.

### 2. En el Popout (Menú Desplegable)
- Muestra una cuadrícula de 3 columnas con esquemas gráficos en miniatura de cada layout.
- El layout actualmente activo se resalta con el borde y acento del tema de DankMaterialShell.
- Al hacer clic en cualquier tarjeta, Hyprland aplica instantáneamente la nueva disposición.
- **Barra de Acciones Rápidas (Quick Actions)** en la parte inferior:
  - **Float**: Alterna el modo flotante/tiling en la ventana activa.
  - **Fullscreen**: Alterna pantalla completa / monocle.
  - **Group**: Agrupa o desagrupa ventanas en pestañas (Deck).
  - **Split**: Alterna la orientación del split en Dwindle.

---

## ⚙️ Configuración (Settings)

Desde **DMS Settings → Plugins → Hyprland Layout Manager**:

1. **Right-click toggle target**: Elige qué layout se activa con el clic derecho en la barra (Monocle, Dwindle, Center Tile, etc., o None para desactivar).
2. **Middle-click toggle target**: Elige qué layout se activa con el clic central.
3. **Scroll cycle**:
   - Usa el ícono del **ojo** para ocultar o mostrar layouts en el ciclo de scroll y en la cuadrícula.
   - Usa el **manillar de arrastre** para ordenar los layouts según tu preferencia.
4. **Scroll speed**: Tiempo mínimo de enfriamiento (ms) entre giros de la rueda para evitar saltar varios layouts en trackpads.

---

## 🔧 Requisitos

- **Hyprland** (compatible con 0.50.x hasta 0.56.2+ con soporte para Lua eval y dispatchers nativos).
- **Python 3** (incluido por defecto en Linux).
- **DankMaterialShell (DMS)** v1.2.0+.

---

## 📦 Instalación y Actualización

El plugin se encuentra en:
```bash
~/.config/DankMaterialShell/plugins/hyprWorkspaceManager
```

Para recargar los cambios en DMS:
```bash
dms restart
```
