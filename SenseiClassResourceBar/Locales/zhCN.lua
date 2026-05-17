local _, addonTable = ...

local baseLocale = {
    -- General
    ["OKAY"] = OKAY,
    ["CLOSE"] = CLOSE,
    ["CANCEL"] = CANCEL,
    ["RELOADUI"] = RELOADUI,
    ["RELOADUI_TEXT"] = "一些更改需要重新加载你的UI",

    -- Import / Export errors
    ["EXPORT"] = "导出",
    ["EXPORT_BAR"] = "导出此条形",
    ["IMPORT"] = "导入",
    ["IMPORT_BAR"] = "导入此条形",
    ["EXPORT_FAILED"] = "导出失败。",
    ["IMPORT_FAILED_WITH_ERROR"] = "导入失败，错误如下：",
    ["IMPORT_STRING_NOT_SUITABLE"] = "此导入字符串不适用于",
    ["IMPORT_STRING_OLDER_VERSION"] = "此导入字符串适用于旧版本的",
    ["IMPORT_STRING_INVALID"] = "无效的导入字符串",
    ["IMPORT_DECODE_FAILED"] = "解码失败",
    ["IMPORT_DECOMPRESSION_FAILED"] = "解压失败",
    ["IMPORT_DESERIALIZATION_FAILED"] = "反序列化失败",

    -- Settings (Esc > Options > AddOns)
    ["SETTINGS_HEADER_POWER_COLORS"] = "能量颜色",
    ["SETTINGS_HEADER_HEALTH_COLOR"] = "生命值颜色",
    ["SETTINGS_CATEGORY_IMPORT_EXPORT"] = "导入 / 导出",
    ["SETTINGS_IMPORT_EXPORT_TEXT_1"] = "此处生成的导出字符串包含当前编辑模式布局的所有条形。\n如果您只想导出某个特定条形，请检查编辑模式中该条形设置面板中的导出按钮。",
    ["SETTINGS_IMPORT_EXPORT_TEXT_2"] = "下方的导入按钮支持全局和单个条形导出字符串。编辑模式中每个条形设置中的导入按钮仅限于该特定条形。\n例如，如果您导出了所有条形，但只想导入主要资源条，请使用编辑模式中主要资源条的导入按钮。",
    ["SETTINGS_BUTTON_EXPORT_ONLY_POWER_COLORS"] = "仅导出能量颜色",
    ["SETTINGS_BUTTON_EXPORT_WITH_POWER_COLORS"] = "导出（包含能量颜色）",
    ["SETTINGS_BUTTON_EXPORT_WITHOUT_POWER_COLORS"] = "导出（不含能量颜色）",
    ["SETTINGS_BUTTON_IMPORT"] = "导入",
    ["SETTING_OPEN_AFTER_EDIT_MODE_CLOSE"] = "退出编辑模式后将打开设置",

    -- Power
    ["HEALTH"] = HEALTH,
    ["MANA"] = POWER_TYPE_MANA,
    ["RAGE"]= POWER_TYPE_RED_POWER,
    ["WHIRLWIND"] = "旋风斩",
    ["FOCUS"] = POWER_TYPE_FOCUS,
    ["TIP_OF_THE_SPEAR"] = "利矛之刃",
    ["ENERGY"] = POWER_TYPE_ENERGY,
    ["RUNIC_POWER"] = POWER_TYPE_RUNIC_POWER,
    ["LUNAR_POWER"] = POWER_TYPE_LUNAR_POWER,
    ["MAELSTROM"] = POWER_TYPE_MAELSTROM,
    ["MAELSTROM_WEAPON"] = "漩涡武器",
    ["INSANITY"] = POWER_TYPE_INSANITY,
    ["FURY"] = POWER_TYPE_FURY_DEMONHUNTER,
    ["BLOOD_RUNE"] = COMBAT_TEXT_RUNE_BLOOD,
    ["FROST_RUNE"] = COMBAT_TEXT_RUNE_FROST,
    ["UNHOLY_RUNE"] = COMBAT_TEXT_RUNE_UNHOLY,
    ["COMBO_POINTS"] = COMBO_POINTS,
    ["OVERCHARGED_COMBO_POINTS"] = "超荷充能连击点数",
    ["SOUL_SHARDS"] = SOUL_SHARDS,
    ["HOLY_POWER"] = HOLY_POWER,
    ["CHI"] = CHI,
    ["STAGGER_LOW"] = "轻度醉拳",
    ["STAGGER_MEDIUM"] ="中度醉拳",
    ["STAGGER_HIGH"] = "重度醉拳",
    ["ARCANE_CHARGES"] = POWER_TYPE_ARCANE_CHARGES,
    ["ICICLES"] = "冰刺",
    ["SOUL_FRAGMENTS_VENGEANCE"] = "复仇灵魂残片",
    ["SOUL_FRAGMENTS_DDH"] = "噬灭灵魂残片",
    ["SOUL_FRAGMENTS_VOID_META"] = "噬灭灵魂残片（虚空变形）",
    ["ESSENCE"]= POWER_TYPE_ESSENCE,
    ["EBON_MIGHT"] = "黑檀之力",
    ["FREEZE"] = "冻结",

    -- Bar names
    ["HEALTH_BAR_EDIT_MODE_NAME"] = "生命条",
    ["PRIMARY_POWER_BAR_EDIT_MODE_NAME"] = "主要资源条",
    ["SECONDARY_POWER_BAR_EDIT_MODE_NAME"] = "次要资源条",
    ["TERNARY_POWER_BAR_EDIT_MODE_NAME"] = "第三资源条",

    -- Bar visibility category - Edit Mode
    ["CATEGORY_BAR_VISIBILITY"] = "条形可见性",
    ["BAR_VISIBLE"] = "显示条形",
    ["BAR_STRATA"] = "条形层级",
    ["BAR_STRATA_TOOLTIP"] = "条形渲染的层级",
    ["HIDE_WHILE_MOUNTED_OR_VEHICULE"] = "在坐骑或载具中隐藏",
    ["HIDE_WHILE_MOUNTED_OR_VEHICULE_TOOLTIP"] = "包括德鲁伊旅行形态",
    ["HIDE_MANA_ON_ROLE"] = "在特定职责下隐藏法力值",
    ["HIDE_MANA_ON_ROLE_PRIMARY_BAR_TOOLTIP"] = "对奥术法师无效",
    ["HIDE_CUSTOM_RESOURCES"] = "隐藏自定义资源",
    ["HIDE_HEALTH_ON_ROLE"] = "在特定职责下隐藏",
    ["HIDE_BLIZZARD_UI"] = "隐藏暴雪自带界面",
    ["HIDE_BLIZZARD_UI_HEALTH_BAR_TOOLTIP"] = "隐藏暴雪自带的玩家框架界面",
    ["HIDE_BLIZZARD_UI_SECONDARY_POWER_BAR_TOOLTIP"] = "隐藏暴雪自带的次要资源界面（例如死亡骑士的符文条）",
    ["ENABLE_HP_BAR_MOUSE_INTERACTION"] = "可点击生命条",
    ["ENABLE_HP_BAR_MOUSE_INTERACTION_TOOLTIP"] = "在生命条上启用玩家框体的默认点击行为。",

    -- Position & Size category - Edit Mode
    ["CATEGORY_POSITION_AND_SIZE"] = "位置与大小",
    ["POSITION"] = "位置",
    ["X_POSITION"] = "X 坐标",
    ["Y_POSITION"] = "Y 坐标",
    ["RELATIVE_FRAME"] = "相对框架",
    ["RELATIVE_FRAME_TOOLTIP"] = "由于限制，如果锚定到 UIParent 以外的框架，您可能无法拖动该框架。请使用 X/Y 滑块",
    ["RELATIVE_FRAME_CYCLIC_WARNING"] = "无法更改相对框架，因为所选框架已经相对于此框架。",
    ["ANCHOR_POINT"] = "锚点",
    ["RELATIVE_POINT"] = "相对点",
    ["BAR_SIZE"] = "条形大小",
    ["WIDTH_MODE"] = "宽度模式",
    ["WIDTH"] = "宽度",
    ["MINIMUM_WIDTH"] = "最小宽度",
    ["MINIMUM_WIDTH_TOOLTIP"] = "设为0禁用。仅在同步到冷却管理器时有效",
    ["HEIGHT"] = "高度",

    -- Bar settings category - Edit Mode
    ["CATEGORY_BAR_SETTINGS"] = "条形设置",
    ["FILL_DIRECTION"] = "填充方向",
    ["FASTER_UPDATES"] = "快速更新 (较高CPU占用)",
    ["SMOOTH_PROGRESS"] = "平滑进度",
    ["SHOW_TICKS_WHEN_AVAILABLE"] = "显示刻度（如果可用）",
    ["TICK_THICKNESS"] = "刻度粗细",

    -- Bar style category - Edit Mode
    ["CATEGORY_BAR_STYLE"] = "条形样式",
    ["USE_CLASS_COLOR"] = "使用职业颜色",
    ["USE_RESOURCE_TEXTURE_AND_COLOR"] = "使用资源纹理和颜色",
    ["BAR_TEXTURE"] = "条形纹理",
    ["BAR_BACKGROUND"] = "背景",
    ["USE_BAR_COLOR_FOR_BACKGROUND_COLOR"] = "使用条形颜色作为背景颜色",
    ["BAR_BORDER"] = "边框",

    --  (Heal) Absorb bar style category - Edit Mode
    ["CATEGORY_ABSORB_BAR_STYLE"] = "吸收条样式",
    ["CATEGORY_HEAL_ABSORB_BAR_STYLE"] = "治疗吸收条样式",
    ["ENABLE"] = "启用",
    ["ABSORB_BAR_POSITION"] = "样式",
    ["HEAL_ABSORB_BAR_POSITION"] = "样式",

    -- Text settings category - Edit Mode
    ["CATEGORY_TEXT_SETTINGS"] = "文本设置",
    ["SHOW_RESOURCE_NUMBER"] = "显示资源数值",
    ["RESOURCE_NUMBER_FORMAT"] = "格式",
    ["RESOURCE_NUMBER_FORMAT_TOOLTIP"] = "某些资源不支持百分比格式",
    ["RESOURCE_NUMBER_PRECISION"] = "精度",
    ["RESOURCE_NUMBER_ALIGNMENT"] = "对齐",
    ["SHOW_MANA_AS_PERCENT"] = "以百分比显示法力值",
    ["SHOW_MANA_AS_PERCENT_TOOLTIP"] = "强制法力值使用百分比格式",
    ["SHOW_RESOURCE_CHARGE_TIMER"] = "显示资源充能计时器（例如符文）",
    ["CHARGE_TIMER_PRECISION"] = "充能计时器精度",

    -- Font category - Edit Mode
    ["CATEGORY_FONT"] = "字体",
    ["FONT"] = "字体",
    ["FONT_SIZE"] = "大小",
    ["FONT_OUTLINE"] = "描边",

    -- Other
    ["POWER_COLOR_SETTINGS"] = "能量颜色设置",

    -- Edit Mode Settings dropdown --

    -- Visibility Options
    ["ALWAYS_VISIBLE"] = "始终可见",
    ["IN_COMBAT"] = "战斗中",
    ["HAS_TARGET_SELECTED"] = "目标已选择",
    ["HAS_TARGET_SELECTED_OR_IN_COMBAT"] = "目标已选择或战斗中",
    ["HIDDEN"] = "隐藏",

    -- Strata Options -- Maybe keep it the same in all language ?
    ["TOOLTIP"] = "提示层",
    ["DIALOG"] = "对话层",
    ["HIGH"] = "高层",
    ["MEDIUM"] = "中层",
    ["LOW"] = "低层",
    ["BACKGROUND"] = "背景层",

    -- Role Options
    ["TANK"] = TANK,
    ["HEALER"] = HEALER,
    ["DPS"] = "DPS",

    -- Position Options
    ["POSITION_SELF"] = "自己",
    ["USE_HEALTH_BAR_POSITION_IF_HIDDEN"] = "如果隐藏则使用生命条位置",
    ["USE_PRIMARY_RESOURCE_BAR_POSITION_IF_HIDDEN"] = "如果隐藏则使用主要资源条位置",
    ["USE_SECONDARY_RESOURCE_BAR_POSITION_IF_HIDDEN"] = "如果隐藏则使用次要资源条位置",

    -- Frame Names
    ["UI_PARENT"] = "UI父框架(屏幕)",
    ["HEALTH_BAR"] = "生命条",
    ["PRIMARY_RESOURCE_BAR"] = "主要资源条",
    ["SECONDARY_RESOURCE_BAR"] = "次要资源条",
    ["PLAYER_FRAME"] = "玩家框架",
    ["TARGET_FRAME"] = "目标框架",
    ["ESSENTIAL_COOLDOWNS"] = "重要技能冷却",
    ["UTILITY_COOLDOWNS"] = "效能技能冷却",
    ["TRACKED_BUFFS"] = "追踪增益",
    ["ACTION_BAR"] = "动作条",
    ["ACTION_BAR_X"] = "动作条%d",

    -- Anchor & Relative Points -- Maybe keep it the same in all language ?
    ["TOPLEFT"] = "左上角",
    ["TOP"] = "顶部",
    ["TOPRIGHT"] = "右上角",
    ["LEFT"] = "左侧",
    ["CENTER"] = "中心",
    ["RIGHT"] = "右侧",
    ["BOTTOMLEFT"] = "左下角",
    ["BOTTOM"] = "底部",
    ["BOTTOMRIGHT"] = "右下角",

    -- Width Modes
    ["MANUAL"] = "手动",
    ["SYNC_WITH_ESSENTIAL_COOLDOWNS"] = "同步重要技能冷却",
    ["SYNC_WITH_UTILITY_COOLDOWNS"] = "同步效能技能冷却",
    ["SYNC_WITH_TRACKED_BUFFS"] = "同步追踪增益",

    -- Fill Directions
    ["LEFT_TO_RIGHT"] = "从左到右",
    ["RIGHT_TO_LEFT"] = "从右到左",
    ["TOP_TO_BOTTOM"] = "从顶部到底部",
    ["BOTTOM_TO_TOP"] = "从底部到顶部",

    -- (Heal) Absorb Bar Styles
    ["BAR_POSITION_FIXED"] = "固定位置",
    ["BAR_POSITION_REVERSED"] = "反转位置",
    ["BAR_POSITION_ATTACH_HEALTH"] = "绑定到生命条",

    -- Outline Styles -- Maybe keep it the same in all language ?
    ["NONE"] = "无",
    ["OUTLINE"] = "描边",
    ["THICKOUTLINE"] = "粗描边",

    -- Text Formats
    ["CURRENT"] = "当前",
    ["CURRENT_MAXIMUM"] = "当前 / 最大值",
    ["PERCENT"] = "百分比",
    ["PERCENT_SYMBOL"] = "百分比%",
    ["CURRENT_PERCENT"] = "当前 - 百分比",
    ["CURRENT_PERCENT_SYMBOL"] = "当前 - 百分比%",
}

addonTable:RegisterLocale("zhCN", baseLocale)
