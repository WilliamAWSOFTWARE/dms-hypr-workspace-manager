.pragma library

var OPTION_DATA = [
    {
        id: "tile",
        label: "Tile",
        code: "T",
        icon: "view_quilt",
        aliases: ["tile", "T"]
    },
    {
        id: "right_tile",
        label: "Right Tile",
        code: "RT",
        icon: "view_sidebar",
        aliases: ["right_tile", "RT"]
    },
    {
        id: "vertical_tile",
        label: "Vertical Tile",
        code: "VT",
        icon: "clarify",
        aliases: ["vertical_tile", "VT"]
    },
    {
        id: "center_tile",
        label: "Center Tile",
        code: "CT",
        icon: "view_compact",
        aliases: ["center_tile", "CT"]
    },
    {
        id: "vertical_fair",
        label: "Vertical Fair",
        code: "VF",
        icon: "vertical_distribute",
        aliases: ["vertical_fair", "VF"]
    },
    {
        id: "dwindle",
        label: "Dwindle",
        code: "DW",
        icon: "account_tree",
        aliases: ["dwindle", "DW"]
    },
    {
        id: "monocle",
        label: "Monocle",
        code: "M",
        icon: "fullscreen",
        aliases: ["monocle", "M"]
    },
    {
        id: "deck",
        label: "Deck",
        code: "K",
        icon: "layers",
        aliases: ["deck", "K"]
    }
];

function options() {
    return OPTION_DATA;
}

function findOption(value) {
    var lower = String(value === undefined || value === null ? "" : value).toLowerCase();
    if (!lower) {
        return null;
    }

    for (var i = 0; i < OPTION_DATA.length; i += 1) {
        var option = OPTION_DATA[i];
        for (var j = 0; j < option.aliases.length; j += 1) {
            if (lower === String(option.aliases[j]).toLowerCase()) {
                return option;
            }
        }
    }

    return null;
}

function mirrorWindowSpecs(specs) {
    var mirrored = [];

    for (var i = 0; i < specs.length; i += 1) {
        var spec = specs[i];
        mirrored.push({
            x: 1 - spec.x - spec.w,
            y: spec.y,
            w: spec.w,
            h: spec.h,
            accent: !!spec.accent,
            z: spec.z || 0,
            opacity: spec.opacity === undefined ? 1 : spec.opacity
        });
    }

    return mirrored;
}

function windowSpecs(layoutId) {
    switch (layoutId) {
    case "tile":
        return [
            { x: 0.0, y: 0.0, w: 0.58, h: 1.0, accent: true },
            { x: 0.62, y: 0.0, w: 0.38, h: 0.48 },
            { x: 0.62, y: 0.52, w: 0.38, h: 0.48 }
        ];
    case "right_tile":
        return mirrorWindowSpecs(windowSpecs("tile"));
    case "vertical_tile":
        return [
            { x: 0.0, y: 0.0, w: 1.0, h: 0.54, accent: true },
            { x: 0.0, y: 0.60, w: 0.31, h: 0.40 },
            { x: 0.345, y: 0.60, w: 0.31, h: 0.40 },
            { x: 0.69, y: 0.60, w: 0.31, h: 0.40 }
        ];
    case "center_tile":
        return [
            { x: 0.0, y: 0.0, w: 0.20, h: 0.48 },
            { x: 0.0, y: 0.52, w: 0.20, h: 0.48 },
            { x: 0.24, y: 0.0, w: 0.52, h: 1.0, accent: true },
            { x: 0.80, y: 0.0, w: 0.20, h: 0.48 },
            { x: 0.80, y: 0.52, w: 0.20, h: 0.48 }
        ];
    case "vertical_fair":
        return [
            { x: 0.0, y: 0.0, w: 0.48, h: 0.32, accent: true },
            { x: 0.0, y: 0.34, w: 0.48, h: 0.32 },
            { x: 0.0, y: 0.68, w: 0.48, h: 0.32 },
            { x: 0.52, y: 0.0, w: 0.48, h: 0.49 },
            { x: 0.52, y: 0.51, w: 0.48, h: 0.49 }
        ];
    case "dwindle":
        return [
            { x: 0.0, y: 0.0, w: 0.60, h: 1.0, accent: true },
            { x: 0.62, y: 0.0, w: 0.38, h: 0.58 },
            { x: 0.62, y: 0.60, w: 0.20, h: 0.40 },
            { x: 0.84, y: 0.60, w: 0.16, h: 0.40 }
        ];
    case "monocle":
        return [
            { x: 0.0, y: 0.0, w: 1.0, h: 1.0, accent: true }
        ];
    case "deck":
        return [
            { x: 0.0, y: 0.0, w: 0.56, h: 1.0, accent: true, z: 3 },
            { x: 0.62, y: 0.06, w: 0.26, h: 0.78, opacity: 0.72, z: 1 },
            { x: 0.68, y: 0.16, w: 0.24, h: 0.58, opacity: 0.82, z: 2 },
            { x: 0.74, y: 0.26, w: 0.22, h: 0.38, opacity: 0.92, z: 4 }
        ];
    default:
        return [
            { x: 0.0, y: 0.0, w: 0.60, h: 1.0, accent: true },
            { x: 0.62, y: 0.0, w: 0.38, h: 0.58 },
            { x: 0.62, y: 0.60, w: 0.20, h: 0.40 },
            { x: 0.84, y: 0.60, w: 0.16, h: 0.40 }
        ];
    }
}
