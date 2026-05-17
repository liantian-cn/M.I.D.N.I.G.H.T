local _, addonTable = ...

local baseLocale = {
    -- General
    ["OKAY"] = OKAY,
    ["CLOSE"] = CLOSE,
    ["CANCEL"] = CANCEL,
    ["RELOADUI"] = RELOADUI,
    ["RELOADUI_TEXT"] = "Einige Änderungen erfordern das Neuladen des Interfaces",

    -- Import / Export errors
    ["EXPORT"] = "Exportieren",
    ["EXPORT_BAR"] = "Diese Leiste exportieren",
    ["IMPORT"] = "Importieren",
    ["IMPORT_BAR"] = "Diese Leiste importieren",
    ["EXPORT_FAILED"] = "Exportieren fehlgeschlagen.",
    ["IMPORT_FAILED_WITH_ERROR"] = "Importieren mit dem folgenden Fehler fehlgeschlagen: ",
    ["IMPORT_STRING_NOT_SUITABLE"] = "Dieser Importstring ist nicht nutzbar für",
    ["IMPORT_STRING_OLDER_VERSION"] = "Dieser Importstring ist für eine ältere Version von",
    ["IMPORT_STRING_INVALID"] = "Ungültiger Importstring",
    ["IMPORT_DECODE_FAILED"] = "Dekodieren fehlgeschlagen",
    ["IMPORT_DECOMPRESSION_FAILED"] = "Dekomprimierung fehlgeschlagen",
    ["IMPORT_DESERIALIZATION_FAILED"] = "Deserialisierung fehlgeschlagen",

    -- Settings (Esc > Options > AddOns)
    ["SETTINGS_HEADER_POWER_COLORS"] = "Ressourcenfarben",
    ["SETTINGS_HEADER_HEALTH_COLOR"] = "Gesundheitsfarbe",
    ["SETTINGS_CATEGORY_IMPORT_EXPORT"] = "Importieren / Exportieren",
    ["SETTINGS_IMPORT_EXPORT_TEXT_1"] = "Hier generierte Exportstrings umfassen alle Leisten des aktuellen Layouts im Bearbeitungsmodus.\nWenn Du nur eine bestimmte Leiste exportieren möchtest, nutze bitte den Exportieren Button in den\nLeisteneinstellungen im Bearbeitungsmodus.",
    ["SETTINGS_IMPORT_EXPORT_TEXT_2"] = "Der untenstehende Importieren Button  unterstützt globale und individuelle Exportstrings für Leisten.\nDer Button in den jeweiligen Einstellungen der Leisten im Bearbeitungsmodus ist beschränkt auf die jeweilige Leiste.\nWenn Du beispielsweise alle Leisten exportiert hast, aber nur die primäre Ressourcenanzeige importieren möchtest,\nnutze den Importieren Button der primären Ressourcenleiste im Bearbeitungsmodus.",
    ["SETTINGS_BUTTON_EXPORT_ONLY_POWER_COLORS"] = "Nur Ressourcenfarben exportieren",
    ["SETTINGS_BUTTON_EXPORT_WITH_POWER_COLORS"] = "Mit Ressourcenfarben exportieren",
    ["SETTINGS_BUTTON_EXPORT_WITHOUT_POWER_COLORS"] = "Ohne Ressourcenfarben exportieren",
    ["SETTINGS_BUTTON_IMPORT"] = "Importieren",
    ["SETTING_OPEN_AFTER_EDIT_MODE_CLOSE"] = "Einstellungen werden nach Verlassen des Bearbeitungsmodus geöffnet",

    -- Power
    ["HEALTH"] = HEALTH,
    ["MANA"] = POWER_TYPE_MANA,
    ["RAGE"]= POWER_TYPE_RED_POWER,
    ["WHIRLWIND"] = "Wirbelwind",
    ["FOCUS"] = POWER_TYPE_FOCUS,
    ["TIP_OF_THE_SPEAR"] = "Speerspitze",
    ["ENERGY"] = POWER_TYPE_ENERGY,
    ["RUNIC_POWER"] = POWER_TYPE_RUNIC_POWER,
    ["LUNAR_POWER"] = POWER_TYPE_LUNAR_POWER,
    ["MAELSTROM"] = POWER_TYPE_MAELSTROM,
    ["MAELSTROM_WEAPON"] = "Waffe des Mahlstroms",
    ["INSANITY"] = POWER_TYPE_INSANITY,
    ["FURY"] = POWER_TYPE_FURY_DEMONHUNTER,
    ["BLOOD_RUNE"] = COMBAT_TEXT_RUNE_BLOOD,
    ["FROST_RUNE"] = COMBAT_TEXT_RUNE_FROST,
    ["UNHOLY_RUNE"] = COMBAT_TEXT_RUNE_UNHOLY,
    ["COMBO_POINTS"] = COMBO_POINTS,
    ["OVERCHARGED_COMBO_POINTS"] = "Überladene Combopunkte",
    ["SOUL_SHARDS"] = SOUL_SHARDS,
    ["HOLY_POWER"] = HOLY_POWER,
    ["CHI"] = CHI,
    ["STAGGER_LOW"] = "Niedriges Staffeln",
    ["STAGGER_MEDIUM"] ="Mittleres Staffeln",
    ["STAGGER_HIGH"] = "Hohes Staffeln",
    ["ARCANE_CHARGES"] = POWER_TYPE_ARCANE_CHARGES,
    ["ICICLES"] = "Eiszapfen",
    ["SOUL_FRAGMENTS_VENGEANCE"] = "Rachsucht Seelenfragmente",
    ["SOUL_FRAGMENTS_DDH"] = "Verschlinger Seelenfragmente",
    ["SOUL_FRAGMENTS_VOID_META"] = "Verschl. Seelenfragm. Metamorphose",
    ["ESSENCE"]= POWER_TYPE_ESSENCE,
    ["EBON_MIGHT"] = "Schwarzmacht",

    -- Bar names
    ["HEALTH_BAR_EDIT_MODE_NAME"] = "Lebensleiste",
    ["PRIMARY_POWER_BAR_EDIT_MODE_NAME"] = "Primäre Ressourcenleiste",
    ["SECONDARY_POWER_BAR_EDIT_MODE_NAME"] = "Sekundäre Ressourcenleiste",
    ["TERNARY_POWER_BAR_EDIT_MODE_NAME"] = "Tertiäre Ressourcenleiste",

    -- Bar visibility category - Edit Mode
    ["CATEGORY_BAR_VISIBILITY"] = "Sichtbarkeit der Leiste",
    ["BAR_VISIBLE"] = "Leiste sichtbar",
    ["BAR_STRATA"] = "Layer der Leiste",
    ["BAR_STRATA_TOOLTIP"] = "Der Layer auf dem die Leiste dargestellt wird",
    ["HIDE_WHILE_MOUNTED_OR_VEHICULE"] = "Verstecken während auf Reittier oder in Fahrzeug",
    ["HIDE_WHILE_MOUNTED_OR_VEHICULE_TOOLTIP"] = "Beinhaltet Reiseform des Druiden",
    ["HIDE_MANA_ON_ROLE"] = "Mana bei Rolle verstecken",
    ["HIDE_MANA_ON_ROLE_PRIMARY_BAR_TOOLTIP"] = "Funktioniert nicht bei Arkan-Magier",
    ["HIDE_CUSTOM_RESOURCES"] = "Bestimmte Ressourcen verstecken",
    ["HIDE_HEALTH_ON_ROLE"] = "Bei Rolle verstecken",
    ["HIDE_BLIZZARD_UI"] = "Blizzard UI verstecken",
    ["HIDE_BLIZZARD_UI_HEALTH_BAR_TOOLTIP"] = "Versteckt das standardmäßige Blizzard Spielerfenster UI",
    ["HIDE_BLIZZARD_UI_SECONDARY_POWER_BAR_TOOLTIP"] = "Versteckt die standardmäßige sekundäre Ressourcenanzeige des Blizzard UI (z.B. Runen eines Todesritters)",
    ["ENABLE_HP_BAR_MOUSE_INTERACTION"] = "Klickbare Lebensleiste",
    ["ENABLE_HP_BAR_MOUSE_INTERACTION_TOOLTIP"] = "Aktiviert das Auswählen des Spielerfensters beim Klick auf die Lebensleiste.",

    -- Position & Size category - Edit Mode
    ["CATEGORY_POSITION_AND_SIZE"] = "Position & Größe",
    ["POSITION"] = "Position",
    ["X_POSITION"] = "X Position",
    ["Y_POSITION"] = "Y Position",
    ["RELATIVE_FRAME"] = "Relatives Fenster",
    ["RELATIVE_FRAME_TOOLTIP"] = "Durch Einschränkungen kann das Fenster nicht verschoben werden, während es an einem anderen Fenster als UIParent ausgerichtet ist. Nutze die X/Y Schieberegler",
    ["RELATIVE_FRAME_CYCLIC_WARNING"] = "Kann relatives Fenster nicht ändern, da das gewählte Fenster bereits relativ zu diesem Fenster ist.",
    ["ANCHOR_POINT"] = "Ankerpunkt",
    ["RELATIVE_POINT"] = "Relativer Punkt",
    ["BAR_SIZE"] = "Leistengröße",
    ["WIDTH_MODE"] = "Breitenmodus",
    ["WIDTH"] = "Breite",
    ["MINIMUM_WIDTH"] = "Minimale Breite",
    ["MINIMUM_WIDTH_TOOLTIP"] = "0 zum Deaktivieren. Nur aktiv wenn synchronisiert mit Abklingzeitenmanager",
    ["HEIGHT"] = "Höhe",

    -- Bar settings category - Edit Mode
    ["CATEGORY_BAR_SETTINGS"] = "Leisteneinstellungen",
    ["FILL_DIRECTION"] = "Füllrichtung",
    ["FASTER_UPDATES"] = "Schnellere Updates (Höhere CPU Last)",
    ["SMOOTH_PROGRESS"] = "Sanfter Verlauf",
    ["SHOW_TICKS_WHEN_AVAILABLE"] = "Wenn verfügbar Ticks anzeigen",
    ["TICK_THICKNESS"] = "Tick Dicke",

    -- Bar style category - Edit Mode
    ["CATEGORY_BAR_STYLE"] = "Stil der Leiste",
    ["USE_CLASS_COLOR"] = "Klassenfarbe nutzen",
    ["USE_RESOURCE_TEXTURE_AND_COLOR"] = "Ressourcentextur und -farbe verwenden",
    ["BAR_TEXTURE"] = "Leistentextur",
    ["BAR_BACKGROUND"] = "Hintergrund",
    ["USE_BAR_COLOR_FOR_BACKGROUND_COLOR"] = "Leistenfarbe als Hintergrundfarbe nutzen",
    ["BAR_BORDER"] = "Rahmen",

    --  (Heal) Absorb bar style category - Edit Mode
    ["CATEGORY_ABSORB_BAR_STYLE"] = "Stil der Absorbtionsleiste",
    ["CATEGORY_HEAL_ABSORB_BAR_STYLE"] = "Stil der Heilabsorbtionsleiste",
    ["ENABLE"] = "Aktivieren",
    ["ABSORB_BAR_POSITION"] = "Stil",
    ["HEAL_ABSORB_BAR_POSITION"] = "Stil",

    -- Text settings category - Edit Mode
    ["CATEGORY_TEXT_SETTINGS"] = "Texteinstellungen",
    ["SHOW_RESOURCE_NUMBER"] = "Ressourcenzahl anzeigen",
    ["RESOURCE_NUMBER_FORMAT"] = "Format",
    ["RESOURCE_NUMBER_FORMAT_TOOLTIP"] = "Einige Ressourcen unterstützen das Prozenformat nicht",
    ["RESOURCE_NUMBER_PRECISION"] = "Präzision",
    ["RESOURCE_NUMBER_ALIGNMENT"] = "Ausrichtung",
    ["SHOW_MANA_AS_PERCENT"] = "Mana als Prozent anzeigen",
    ["SHOW_MANA_AS_PERCENT_TOOLTIP"] = "Prozentformat für Mana erzwingen",
    ["SHOW_RESOURCE_CHARGE_TIMER"] = "Ressourcen Aufladezeit anzeigen (z.B. Runen)",
    ["CHARGE_TIMER_PRECISION"] = "Präzision der Aufladezeit",

    -- Font category - Edit Mode
    ["CATEGORY_FONT"] = "Schriftart",
    ["FONT"] = "Schriftart",
    ["FONT_SIZE"] = "Größe",
    ["FONT_OUTLINE"] = "Umrandung",

    -- Other
    ["POWER_COLOR_SETTINGS"] = "Einstellungen der Ressourcenfarben",

    -- Edit Mode Settings dropdown --

    -- Visibility Options
    ["ALWAYS_VISIBLE"] = "Immer sichtbar",
    ["IN_COMBAT"] = "Im Kampf",
    ["HAS_TARGET_SELECTED"] = "Ziel gewählt",
    ["HAS_TARGET_SELECTED_OR_IN_COMBAT"] = "Ziel gewählt ODER im Kampf",
    ["HIDDEN"] = "Versteckt",

    -- Strata Options -- Maybe keep it the same in all language ?
    ["TOOLTIP"] = "Tooltip",
    ["DIALOG"] = "Dialog",
    ["HIGH"] = "Hoch",
    ["MEDIUM"] = "Mittel",
    ["LOW"] = "Niedrig",
    ["BACKGROUND"] = "Hintergrund",

    -- Role Options
    ["TANK"] = TANK,
    ["HEALER"] = HEALER,
    ["DPS"] = "DPS",

    -- Position Options
    ["POSITION_SELF"] = "Eigen",
    ["USE_HEALTH_BAR_POSITION_IF_HIDDEN"] = "Wenn versteckt, Position der Lebensleiste nutzen",
    ["USE_PRIMARY_RESOURCE_BAR_POSITION_IF_HIDDEN"] = "Wenn versteckt, Position der primären Ressourcenleiste nutzen",
    ["USE_SECONDARY_RESOURCE_BAR_POSITION_IF_HIDDEN"] = "Wenn versteckt, Position der sekundären Ressourcenleiste nutzen",

    -- Frame Names
    ["UI_PARENT"] = "UIParent",
    ["HEALTH_BAR"] = "Lebensleiste",
    ["PRIMARY_RESOURCE_BAR"] = "Primäre Ressourcenleiste",
    ["SECONDARY_RESOURCE_BAR"] = "Sekundäre Ressourcenleiste",
    ["PLAYER_FRAME"] = "Spielerfenster",
    ["TARGET_FRAME"] = "Zielfenster",
    ["ESSENTIAL_COOLDOWNS"] = "Essenzielle Abklingzeiten",
    ["UTILITY_COOLDOWNS"] = "Strategische Abklingzeiten",
    ["TRACKED_BUFFS"] = "Verfolgte Stärkungseffekte",
    ["ACTION_BAR"] = "Aktionsleiste",
    ["ACTION_BAR_X"] = "Aktionsleiste %d",

    -- Anchor & Relative Points -- Maybe keep it the same in all language ?
    ["TOPLEFT"] = "Oben links",
    ["TOP"] = "Oben",
    ["TOPRIGHT"] = "Oben rechts",
    ["LEFT"] = "Links",
    ["CENTER"] = "Mitte",
    ["RIGHT"] = "Rechts",
    ["BOTTOMLEFT"] = "Unten links",
    ["BOTTOM"] = "Unten",
    ["BOTTOMRIGHT"] = "Unten rechts",

    -- Width Modes
    ["MANUAL"] = "Manuell",
    ["SYNC_WITH_ESSENTIAL_COOLDOWNS"] = "Synchronisiert mit essenziellen Abklingzeiten",
    ["SYNC_WITH_UTILITY_COOLDOWNS"] = "Synchronisiert mit strategischen Abklingzeiten",
    ["SYNC_WITH_TRACKED_BUFFS"] = "Synchronisiert mit verfolgten Stärkungseffekten",

    -- Fill Directions
    ["LEFT_TO_RIGHT"] = "Links nach Rechts",
    ["RIGHT_TO_LEFT"] = "Rechts nach Links",
    ["TOP_TO_BOTTOM"] = "Oben nach Unten",
    ["BOTTOM_TO_TOP"] = "Unten nach Oben",

    -- (Heal) Absorb Bar Styles
    ["BAR_POSITION_FIXED"] = "Fixiert",
    ["BAR_POSITION_REVERSED"] = "Umgekehrt",
    ["BAR_POSITION_ATTACH_HEALTH"] = "An Gesundheit anhängen",

    -- Outline Styles -- Maybe keep it the same in all language ?
    ["NONE"] = "Keine",
    ["OUTLINE"] = "Umrandung",
    ["THICKOUTLINE"] = "Dicke Umrandung",

    -- Text Formats
    ["CURRENT"] = "Aktuell",
    ["CURRENT_MAXIMUM"] = "Aktuell / Maximum",
    ["PERCENT"] = "Prozent",
    ["PERCENT_SYMBOL"] = "Prozent%",
    ["CURRENT_PERCENT"] = "Aktuell - Prozent",
    ["CURRENT_PERCENT_SYMBOL"] = "Aktuell - Prozent%",
}

addonTable:RegisterLocale("deDE", baseLocale)
