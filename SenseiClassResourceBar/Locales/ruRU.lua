local _, addonTable = ...
-- Translator ZamestoTV
local baseLocale = {
    -- General
    ["OKAY"] = OKAY,
    ["CLOSE"] = CLOSE,
    ["CANCEL"] = CANCEL,
    ["RELOADUI"] = RELOADUI,
    ["RELOADUI_TEXT"] = "Для вступления изменений в силу необходима перезагрузка интерфейса",

    -- Import / Export errors
    ["EXPORT"] = "Экспорт",
    ["EXPORT_BAR"] = "Экспортировать эту панель",
    ["IMPORT"] = "Импорт",
    ["IMPORT_BAR"] = "Импортировать эту панель",
    ["EXPORT_FAILED"] = "Ошибка экспорта.",
    ["IMPORT_FAILED_WITH_ERROR"] = "Ошибка импорта: ",
    ["IMPORT_STRING_NOT_SUITABLE"] = "Эта строка импорта не подходит для",
    ["IMPORT_STRING_OLDER_VERSION"] = "Эта строка импорта предназначена для более старой версии",
    ["IMPORT_STRING_INVALID"] = "Неверная строка импорта",
    ["IMPORT_DECODE_FAILED"] = "Ошибка декодирования",
    ["IMPORT_DECOMPRESSION_FAILED"] = "Ошибка декомпрессии",
    ["IMPORT_DESERIALIZATION_FAILED"] = "Ошибка десериализации",

    -- Settings (Esc > Options > AddOns)
    ["SETTINGS_HEADER_POWER_COLORS"] = "Цвета ресурсов",
    ["SETTINGS_HEADER_HEALTH_COLOR"] = "Цвет здоровья",
    ["SETTINGS_CATEGORY_IMPORT_EXPORT"] = "Импорт / Экспорт",
    ["SETTINGS_IMPORT_EXPORT_TEXT_1"] = "Созданные здесь строки экспорта включают в себя все панели вашего текущего макета Режима редактирования.\nЕсли вы хотите экспортировать только одну конкретную панель, используйте кнопку «Экспорт» в настройках этой панели в Режиме редактирования.",
    ["SETTINGS_IMPORT_EXPORT_TEXT_2"] = "Кнопка «Импорт» ниже поддерживает строки экспорта как для всех панелей сразу, так и для отдельных. Кнопка импорта в настройках конкретной панели в Режиме редактирования ограничена только этой панелью.\nНапример, если вы экспортировали все панели, но хотите импортировать только панель основного ресурса, используйте кнопку импорта в настройках панели основного ресурса в Режиме редактирования.",
    ["SETTINGS_BUTTON_EXPORT_ONLY_POWER_COLORS"] = "Экспорт. только цвета ресурсов",
    ["SETTINGS_BUTTON_EXPORT_WITH_POWER_COLORS"] = "Экспорт. с цветами ресурсов",
    ["SETTINGS_BUTTON_EXPORT_WITHOUT_POWER_COLORS"] = "Экспорт. без цветов ресурсов",
    ["SETTINGS_BUTTON_IMPORT"] = "Импорт",
    ["SETTING_OPEN_AFTER_EDIT_MODE_CLOSE"] = "Настройки откроются после выхода из Режима редактирования",

    -- Power
    ["HEALTH"] = HEALTH,
    ["MANA"] = POWER_TYPE_MANA,
    ["RAGE"] = POWER_TYPE_RED_POWER,
    ["WHIRLWIND"] = "Вихрь",
    ["FOCUS"] = POWER_TYPE_FOCUS,
    ["TIP_OF_THE_SPEAR"] = "Наконечник копья",
    ["ENERGY"]= POWER_TYPE_ENERGY,
    ["RUNIC_POWER"] = POWER_TYPE_RUNIC_POWER,
    ["LUNAR_POWER"] = POWER_TYPE_LUNAR_POWER,
    ["MAELSTROM"] = POWER_TYPE_MAELSTROM,
    ["MAELSTROM_WEAPON"] = "Оружие Водоворота",
    ["INSANITY"]= POWER_TYPE_INSANITY,
    ["FURY"]= POWER_TYPE_FURY_DEMONHUNTER,
    ["BLOOD_RUNE"] = COMBAT_TEXT_RUNE_BLOOD,
    ["FROST_RUNE"] = COMBAT_TEXT_RUNE_FROST,
    ["UNHOLY_RUNE"] = COMBAT_TEXT_RUNE_UNHOLY,
    ["COMBO_POINTS"] = COMBO_POINTS,
    ["OVERCHARGED_COMBO_POINTS"] = "Перегруженные комбо очки",
    ["SOUL_SHARDS"] = SOUL_SHARDS,
    ["HOLY_POWER"] = HOLY_POWER,
    ["CHI"] = CHI,
    ["STAGGER_LOW"] = "Слабое пошатывание",
    ["STAGGER_MEDIUM"] = "Среднее пошатывание",
    ["STAGGER_HIGH"] = "Сильное пошатывание",
    ["ARCANE_CHARGES"] = POWER_TYPE_ARCANE_CHARGES,
    ["ICICLES"] = "кристаллы льда",
    ["SOUL_FRAGMENTS_VENGEANCE"] = "Фрагменты души (Месть)",
    ["SOUL_FRAGMENTS_DDH"] = "Фрагменты души (Пожиратель)",
    ["SOUL_FRAGMENTS_VOID_META"] = "Фрагменты души (Пожиратель - Метаморфоза Бездны)",
    ["ESSENCE"] = POWER_TYPE_ESSENCE,
    ["EBON_MIGHT"] = "Черная мощь",

    -- Bar names
    ["HEALTH_BAR_EDIT_MODE_NAME"] = "Панель здоровья",
    ["PRIMARY_POWER_BAR_EDIT_MODE_NAME"] = "Панель основного ресурса",
    ["SECONDARY_POWER_BAR_EDIT_MODE_NAME"] = "Панель вторичного ресурса",
    ["TERNARY_POWER_BAR_EDIT_MODE_NAME"] = "Панель третичного ресурса",

    -- Bar visibility category - Edit Mode
    ["CATEGORY_BAR_VISIBILITY"] = "Видимость панели",
    ["BAR_VISIBLE"] = "Панель видима",
    ["BAR_STRATA"] = "Слой панели (Strata)",
    ["BAR_STRATA_TOOLTIP"] = "Уровень слоя, на котором отрисовывается панель",
    ["HIDE_WHILE_MOUNTED_OR_VEHICULE"] = "Скрывать верхом или в транспорте",
    ["HIDE_WHILE_MOUNTED_OR_VEHICULE_TOOLTIP"] = "Включая походный облик друида",
    ["HIDE_MANA_ON_ROLE"] = "Скрывать ману по роли",
    ["HIDE_HEALTH_ON_ROLE"] = "Скрывать здоровье по роли",
    ["HIDE_MANA_ON_ROLE_PRIMARY_BAR_TOOLTIP"] = "Не работает для магов «Тайной магии»",
    ["HIDE_BLIZZARD_UI"] = "Скрыть интерфейс Blizzard",
    ["HIDE_BLIZZARD_UI_HEALTH_BAR_TOOLTIP"] = "Скрывает стандартный фрейм игрока Blizzard",
    ["HIDE_BLIZZARD_UI_SECONDARY_POWER_BAR_TOOLTIP"] = "Скрывает стандартный интерфейс вторичных ресурсов (напр. руны ДК)",
    ["ENABLE_HP_BAR_MOUSE_INTERACTION"] = "Кликабельная панель здоровья",
    ["ENABLE_HP_BAR_MOUSE_INTERACTION_TOOLTIP"] = "Включает стандартное взаимодействие с рамкой персонажа при нажатии на панель здоровья.",

    -- Position & Size category - Edit Mode
    ["CATEGORY_POSITION_AND_SIZE"] = "Положение и размер",
    ["POSITION"] = "Положение",
    ["X_POSITION"] = "Положение по X",
    ["Y_POSITION"] = "Положение по Y",
    ["RELATIVE_FRAME"] = "Привязка к фрейму",
    ["RELATIVE_FRAME_TOOLTIP"] = "Из-за ограничений нельзя перетаскивать фрейм, если он привязан не к UIParent. Используйте ползунки.",
    ["RELATIVE_FRAME_CYCLIC_WARNING"] = "Нельзя изменить привязку: выбранный фрейм уже привязан к этому.",
    ["ANCHOR_POINT"] = "Точка привязки",
    ["RELATIVE_POINT"] = "Точка относительно",
    ["BAR_SIZE"] = "Размер панели",
    ["WIDTH_MODE"] = "Режим ширины",
    ["WIDTH"] = "Ширина",
    ["MINIMUM_WIDTH"] = "Мин. ширина",
    ["MINIMUM_WIDTH_TOOLTIP"] = "0 — отключить. Работает при синхронизации с менеджером перезарядки",
    ["HEIGHT"] = "Высота",

    -- Bar settings category - Edit Mode
    ["CATEGORY_BAR_SETTINGS"] = "Настройки панели",
    ["FILL_DIRECTION"] = "Направление заполнения",
    ["FASTER_UPDATES"] = "Частое обновление (выше нагрузка на ЦПУ)",
    ["SMOOTH_PROGRESS"] = "Плавное заполнение",
    ["SHOW_TICKS_WHEN_AVAILABLE"] = "Показывать деления (тиков)",
    ["TICK_THICKNESS"] = "Толщина делений",

    -- Bar style category - Edit Mode
    ["CATEGORY_BAR_STYLE"] = "Стиль панели",
    ["USE_CLASS_COLOR"] = "Цвет класса",
    ["USE_RESOURCE_TEXTURE_AND_COLOR"] = "Текстура и цвет ресурса",
    ["BAR_TEXTURE"] = "Текстура панели",
    ["BAR_BACKGROUND"] = "Фон",
    ["USE_BAR_COLOR_FOR_BACKGROUND_COLOR"] = "Цвет панели для фона",
    ["BAR_BORDER"] = "Граница",

    -- Text settings category - Edit Mode
    ["CATEGORY_TEXT_SETTINGS"] = "Настройки текста",
    ["SHOW_RESOURCE_NUMBER"] = "Числовое значение ресурса",
    ["RESOURCE_NUMBER_FORMAT"] = "Формат",
    ["RESOURCE_NUMBER_FORMAT_TOOLTIP"] = "Некоторые ресурсы не поддерживают проценты",
    ["RESOURCE_NUMBER_PRECISION"] = "Точность",
    ["RESOURCE_NUMBER_ALIGNMENT"] = "Выравнивание",
    ["SHOW_MANA_AS_PERCENT"] = "Мана в процентах",
    ["SHOW_MANA_AS_PERCENT_TOOLTIP"] = "Принудительно отображать ману в процентах",
    ["SHOW_RESOURCE_CHARGE_TIMER"] = "Таймер зарядов (напр. руны)",
    ["CHARGE_TIMER_PRECISION"] = "Точность таймера",

    -- Font category - Edit Mode
    ["CATEGORY_FONT"] = "Шрифт",
    ["FONT"] = "Шрифт",
    ["FONT_SIZE"] = "Размер",
    ["FONT_OUTLINE"] = "Контур",

    -- Other
    ["POWER_COLOR_SETTINGS"] = "Настройки цветов ресурса",
   
    -- Edit Mode Settings dropdown --

    -- Visibility Options
    ["ALWAYS_VISIBLE"] = "Всегда отображать",
    ["IN_COMBAT"] = "В бою",
    ["HAS_TARGET_SELECTED"] = "Цель выбрана",
    ["HAS_TARGET_SELECTED_OR_IN_COMBAT"] = "Цель выбрана или в бою",
    ["HIDDEN"] = "Скрыто",
    
    -- Role Options
    ["TANK"] = TANK,
    ["HEALER"] = HEALER,
    ["DPS"] = "Урон",
    
    -- Position Options
    ["POSITION_SELF"] = "Персонаж",
    ["USE_HEALTH_BAR_POSITION_IF_HIDDEN"] = "Позиция панели здоровья (если скрыто)",
    ["USE_PRIMARY_RESOURCE_BAR_POSITION_IF_HIDDEN"] = "Позиция осн. панели ресурса (если скрыто)",
    ["USE_SECONDARY_RESOURCE_BAR_POSITION_IF_HIDDEN"] = "Позиция доп. панели ресурса (если скрыто)",
    
    -- Frame Names
    ["UI_PARENT"] = "UIParent",
    ["HEALTH_BAR"] = "Панель здоровья",
    ["PRIMARY_RESOURCE_BAR"] = "Основной ресурс",
    ["SECONDARY_RESOURCE_BAR"] = "Дополнительный ресурс",
    ["PLAYER_FRAME"] = "Фрейм игрока",
    ["TARGET_FRAME"] = "Фрейм цели",
    ["ESSENTIAL_COOLDOWNS"] = "Важные кулдауны",
    ["UTILITY_COOLDOWNS"] = "Вспомогат. кулдауны",
    ["TRACKED_BUFFS"] = "Отслеживаемые баффы",
    ["ACTION_BAR"] = "Панель команд",
    ["ACTION_BAR_X"] = "Панель команд %d",
    
    -- Anchor & Relative Points -- Maybe keep it the same in all language ?
    ["TOPLEFT"] = "Сверху слева",
    ["TOP"] = "Сверху",
    ["TOPRIGHT"] = "Сверху справа",
    ["LEFT"] = "Слева",
    ["CENTER"] = "По центру",
    ["RIGHT"] = "Справа",
    ["BOTTOMLEFT"] = "Снизу слева",
    ["BOTTOM"] = "Снизу",
    ["BOTTOMRIGHT"] = "Снизу справа",
    
    -- Width Modes
    ["MANUAL"] = "Вручную",
    ["SYNC_WITH_ESSENTIAL_COOLDOWNS"] = "Синхрон. с важными КД",
    ["SYNC_WITH_UTILITY_COOLDOWNS"] = "Синхрон. со вспомогат. КД",
    ["SYNC_WITH_TRACKED_BUFFS"] = "Синхрон. с баффами",
    
    -- Fill Directions
    ["LEFT_TO_RIGHT"] = "Слева направо",
    ["RIGHT_TO_LEFT"] = "Справа налево",
    ["TOP_TO_BOTTOM"] = "Сверху вниз",
    ["BOTTOM_TO_TOP"] = "Снизу вверх",
    
    -- Outline Styles -- Maybe keep it the same in all language ?
    ["NONE"] = "Нет",
    ["OUTLINE"] = "Контур",
    ["THICKOUTLINE"] = "Толстый контур",
    
    -- Text Formats
    ["CURRENT"] = "Текущее",
    ["CURRENT_MAXIMUM"] = "Текущее / Максимум",
    ["PERCENT"] = "Процент",
    ["PERCENT_SYMBOL"] = "Процент%",
    ["CURRENT_PERCENT"] = "Текущее - Процент",
    ["CURRENT_PERCENT_SYMBOL"] = "Текущее - Процент%",
}

addonTable:RegisterLocale("ruRU", baseLocale)
