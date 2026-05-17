local _, addonTable = ...

local baseLocale = {
    -- General
    ["OKAY"] = "확인",
    ["CLOSE"] = "닫기",
    ["CANCEL"] = "취소",

    -- Import / Export errors
    ["EXPORT"] = "내보내기",
    ["EXPORT_BAR"] = "이 바 내보내기",
    ["IMPORT"] = "가져오기",
    ["IMPORT_BAR"] = "이 바 가져오기",
    ["EXPORT_FAILED"] = "내보내기에 실패했습니다.",
    ["IMPORT_FAILED_WITH_ERROR"] = "다음 오류로 인해 가져오기에 실패했습니다:",
    ["IMPORT_STRING_NOT_SUITABLE"] = "이 가져오기 문자열은 다음에 적합하지 않습니다:",
    ["IMPORT_STRING_OLDER_VERSION"] = "이 가져오기 문자열은 이전 버전용입니다:",
    ["IMPORT_STRING_INVALID"] = "잘못된 가져오기 문자열",
    ["IMPORT_DECODE_FAILED"] = "디코딩 실패",
    ["IMPORT_DECOMPRESSION_FAILED"] = "압축 해제 실패",
    ["IMPORT_DESERIALIZATION_FAILED"] = "역직렬화 실패",

    -- Settings (Esc > Options > AddOns)
    ["SETTINGS_HEADER_POWER_COLORS"] = "자원 색상",
    ["SETTINGS_HEADER_HEALTH_COLOR"] = "생명력 색상",
    ["SETTINGS_CATEGORY_IMPORT_EXPORT"] = "가져오기 / 내보내기",
    ["SETTINGS_IMPORT_EXPORT_TEXT_1"] = "여기서 생성된 내보내기 문자열에는 현재 편집 모드 레이아웃의 모든 바가 포함됩니다.\n특정 바만 내보내려면 편집 모드에서 해당 바 설정 패널의 내보내기 버튼을 사용하세요.",
    ["SETTINGS_IMPORT_EXPORT_TEXT_2"] = "아래의 가져오기 버튼은 전체 및 개별 바 내보내기 문자열을 모두 지원합니다.\n편집 모드의 각 바 설정에 있는 가져오기 버튼은 해당 바에만 적용됩니다.\n예를 들어 모든 바를 내보냈지만 기본 자원 바만 가져오고 싶다면,\n편집 모드에서 기본 자원 바의 가져오기 버튼을 사용하세요.",
    ["SETTINGS_BUTTON_EXPORT_ONLY_POWER_COLORS"] = "자원 색상만 내보내기",
    ["SETTINGS_BUTTON_EXPORT_WITH_POWER_COLORS"] = "자원 색상 포함 내보내기",
    ["SETTINGS_BUTTON_EXPORT_WITHOUT_POWER_COLORS"] = "자원 색상 제외 내보내기",
    ["SETTINGS_BUTTON_IMPORT"] = "가져오기",
    ["SETTING_OPEN_AFTER_EDIT_MODE_CLOSE"] = "편집 모드를 종료하면 설정을 엽니다",

    -- Power
    ["HEALTH"] = "생명력",
    ["MANA"] = "마나",
    ["RAGE"] = "분노",
    ["FOCUS"] = "집중",
    ["TIP_OF_THE_SPEAR"] = "창끝",
    ["ENERGY"] = "기력",
    ["RUNIC_POWER"] = "룬 마력",
    ["LUNAR_POWER"] = "달의 힘",
    ["MAELSTROM"] = "소용돌이",
    ["MAELSTROM_WEAPON"] = "소용돌이치는 무기",
    ["INSANITY"] = "광기",
    ["FURY"] = "분노",
    ["BLOOD_RUNE"] = "혈기 룬",
    ["FROST_RUNE"] = "냉기 룬",
    ["UNHOLY_RUNE"] = "부정 룬",
    ["COMBO_POINTS"] = "연계 점수",
    ["OVERCHARGED_COMBO_POINTS"] = "과충전 연계 점수",
    ["SOUL_SHARDS"] = "영혼의 조각",
    ["HOLY_POWER"] = "신성한 힘",
    ["CHI"] = "기",
    ["STAGGER_LOW"] = "낮은 시간차",
    ["STAGGER_MEDIUM"] = "중간 시간차",
    ["STAGGER_HIGH"] = "높은 시간차",
    ["ARCANE_CHARGES"] = "비전 충전",
    ["ICICLES"] = "고드름",
    ["SOUL_FRAGMENTS_VENGEANCE"] = "복수 영혼 파편",
    ["SOUL_FRAGMENTS_DDH"] = "영혼 포식자 파편",
    ["SOUL_FRAGMENTS_VOID_META"] = "영혼 포식자 파편 (공허 변신)",
    ["ESSENCE"] = "정수",
    ["EBON_MIGHT"] = "칠흑의 힘",

    -- Bar names
    ["HEALTH_BAR_EDIT_MODE_NAME"] = "생명력 바",
    ["PRIMARY_POWER_BAR_EDIT_MODE_NAME"] = "기본 자원 바",
    ["SECONDARY_POWER_BAR_EDIT_MODE_NAME"] = "보조 자원 바",
    ["TERNARY_POWER_BAR_EDIT_MODE_NAME"] = "3차 자원 바",

    -- Bar visibility category - Edit Mode
    ["CATEGORY_BAR_VISIBILITY"] = "바 표시",
    ["BAR_VISIBLE"] = "바 표시 여부",
    ["BAR_STRATA"] = "바 표시 우선순위",
    ["BAR_STRATA_TOOLTIP"] = "바가 표시되는 레이어를 설정합니다",
    ["HIDE_WHILE_MOUNTED_OR_VEHICULE"] = "탈것 또는 차량 탑승 시 숨기기",
    ["HIDE_WHILE_MOUNTED_OR_VEHICULE_TOOLTIP"] = "드루이드 이동 형태 포함",
    ["HIDE_MANA_ON_ROLE"] = "역할에 따라 마나 숨기기",
    ["HIDE_HEALTH_ON_ROLE"] = "역할에 따라 숨기기",
    ["HIDE_MANA_ON_ROLE_PRIMARY_BAR_TOOLTIP"] = "비전 마법사에게는 적용되지 않습니다",
    ["HIDE_BLIZZARD_UI"] = "블리자드 기본 UI 숨기기",
    ["HIDE_BLIZZARD_UI_HEALTH_BAR_TOOLTIP"] = "블리자드 기본 플레이어 프레임을 숨깁니다",
    ["HIDE_BLIZZARD_UI_SECONDARY_POWER_BAR_TOOLTIP"] = "블리자드 기본 보조 자원 UI를 숨깁니다 (예: 죽음의 기사 룬 프레임)",
    ["ENABLE_HP_BAR_MOUSE_INTERACTION"] = "생명력 바 마우스 상호작용",
    ["ENABLE_HP_BAR_MOUSE_INTERACTION_TOOLTIP"] = "생명력 바에서 기본 플레이어 프레임 클릭 동작을 활성화합니다.",

    -- Position & Size category - Edit Mode
    ["CATEGORY_POSITION_AND_SIZE"] = "위치 및 크기",
    ["POSITION"] = "위치",
    ["X_POSITION"] = "가로 위치",
    ["Y_POSITION"] = "세로 위치",
    ["RELATIVE_FRAME"] = "기준 프레임",
    ["RELATIVE_FRAME_TOOLTIP"] = "제한으로 인해 UIParent 외의 프레임에 고정된 경우 드래그할 수 없습니다.\n가로/세로 슬라이더를 사용하세요.",
    ["RELATIVE_FRAME_CYCLIC_WARNING"] = "선택한 프레임이 이미 이 프레임을 기준으로 하고 있어 변경할 수 없습니다.",
    ["ANCHOR_POINT"] = "고정 지점",
    ["RELATIVE_POINT"] = "상대 지점",
    ["BAR_SIZE"] = "바 크기",
    ["WIDTH_MODE"] = "너비 모드",
    ["WIDTH"] = "너비",
    ["MINIMUM_WIDTH"] = "최소 너비",
    ["MINIMUM_WIDTH_TOOLTIP"] = "0으로 설정 시 비활성화됩니다. 쿨다운 매니저와 동기화된 경우에만 적용됩니다.",
    ["HEIGHT"] = "높이",

    -- Bar settings category - Edit Mode
    ["CATEGORY_BAR_SETTINGS"] = "바 설정",
    ["FILL_DIRECTION"] = "채우기 방향",
    ["FASTER_UPDATES"] = "빠른 업데이트 (CPU 사용량 증가)",
    ["SMOOTH_PROGRESS"] = "부드러운 진행",
    ["SHOW_TICKS_WHEN_AVAILABLE"] = "가능한 경우 눈금 표시",
    ["TICK_THICKNESS"] = "눈금 두께",

    -- Bar style category - Edit Mode
    ["CATEGORY_BAR_STYLE"] = "바 스타일",
    ["USE_CLASS_COLOR"] = "직업 색상 사용",
    ["USE_RESOURCE_TEXTURE_AND_COLOR"] = "자원 텍스처 및 색상 사용",
    ["BAR_TEXTURE"] = "바 텍스처",
    ["BAR_BACKGROUND"] = "배경",
    ["USE_BAR_COLOR_FOR_BACKGROUND_COLOR"] = "바 색상을 배경 색상으로 사용",
    ["BAR_BORDER"] = "테두리",

    -- Text settings category - Edit Mode
    ["CATEGORY_TEXT_SETTINGS"] = "텍스트 설정",
    ["SHOW_RESOURCE_NUMBER"] = "자원 수치 표시",
    ["RESOURCE_NUMBER_FORMAT"] = "형식",
    ["RESOURCE_NUMBER_FORMAT_TOOLTIP"] = "일부 자원은 백분율 형식을 지원하지 않습니다",
    ["RESOURCE_NUMBER_PRECISION"] = "정밀도",
    ["RESOURCE_NUMBER_ALIGNMENT"] = "정렬",
    ["SHOW_MANA_AS_PERCENT"] = "마나를 백분율로 표시",
    ["SHOW_MANA_AS_PERCENT_TOOLTIP"] = "마나에 백분율 형식을 강제로 적용합니다",
    ["SHOW_RESOURCE_CHARGE_TIMER"] = "자원 충전 타이머 표시 (예: 룬)",
    ["CHARGE_TIMER_PRECISION"] = "충전 타이머 정밀도",

    -- Font category - Edit Mode
    ["CATEGORY_FONT"] = "글꼴",
    ["FONT"] = "글꼴",
    ["FONT_SIZE"] = "크기",
    ["FONT_OUTLINE"] = "외곽선",

    -- Other
    ["POWER_COLOR_SETTINGS"] = "자원 색상 설정",
}

addonTable:RegisterLocale("koKR", baseLocale)
