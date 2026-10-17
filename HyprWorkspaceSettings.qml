import QtQuick
import qs.Common
import qs.Widgets
import qs.Modules.Plugins

PluginSettings {
    id: root
    pluginId: "hyprWorkspaceManager"

    StyledText {
        width: parent.width
        text: "Hyprland Workspace & Window Manager"
        font.pixelSize: Theme.fontSizeLarge
        font.weight: Font.Bold
        color: Theme.surfaceText
    }

    StyledText {
        width: parent.width
        text: "Configura el comportamiento del widget de barra y las acciones rápidas para Hyprland."
        font.pixelSize: Theme.fontSizeSmall
        color: Theme.surfaceVariantText
    }

    SelectionSetting {
        settingKey: "rightClickAction"
        label: "Acción de clic derecho en la barra"
        description: "Acción rápida que se ejecuta al hacer clic derecho sobre el pill de la barra."
        options: [
            { value: "scratchpad", label: "Alternar Special Workspace / Scratchpad (Por defecto)" },
            { value: "togglefloating", label: "Alternar ventana activa Flotante / Tiling" },
            { value: "togglesplit", label: "Alternar orientación de división (Dwindle Split)" },
            { value: "fullscreen", label: "Alternar pantalla completa" },
            { value: "next_workspace", label: "Cambiar al siguiente workspace" },
            { value: "none", label: "Ninguna (Desactivado)" }
        ]
        defaultValue: "scratchpad"
    }

    SelectionSetting {
        settingKey: "middleClickAction"
        label: "Acción de clic central en la barra"
        description: "Acción rápida que se ejecuta al hacer clic con la rueda del ratón sobre el pill."
        options: [
            { value: "togglesplit", label: "Alternar orientación de división (Dwindle Split)" },
            { value: "togglefloating", label: "Alternar ventana activa Flotante / Tiling" },
            { value: "scratchpad", label: "Alternar Special Workspace / Scratchpad" },
            { value: "fullscreen", label: "Alternar pantalla completa" },
            { value: "none", label: "Ninguna (Desactivado)" }
        ]
        defaultValue: "togglesplit"
    }

    ToggleSetting {
        settingKey: "showTitleInPill"
        label: "Mostrar título de ventana activa en la barra"
        description: "Muestra el nombre o clase de la aplicación actualmente enfocada junto al número de espacio."
        defaultValue: true
    }

    SliderSetting {
        settingKey: "maxTitleLength"
        label: "Longitud máxima del título de ventana"
        description: "Límite de caracteres antes de truncar el título en la barra."
        minValue: 10
        maxValue: 40
        step: 2
        defaultValue: 22
    }

    SliderSetting {
        settingKey: "scrollCooldownMs"
        label: "Intervalo de scroll para cambiar workspace (ms)"
        description: "Tiempo mínimo entre dos cambios de espacio al usar la rueda del ratón sobre la barra."
        minValue: 150
        maxValue: 800
        step: 50
        defaultValue: 300
    }

    ToggleSetting {
        settingKey: "silentMove"
        label: "Mover ventanas de forma silenciosa"
        description: "Al enviar una ventana a otro espacio desde el popout, no cambiar de espacio automáticamente."
        defaultValue: true
    }
}
