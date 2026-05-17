local _, addonTable = ...

local baseLocale = {
    -- General
    ["OKAY"] = OKAY,
    ["CLOSE"] = CLOSE,
    ["CANCEL"] = CANCEL,
    ["RELOADUI"] = RELOADUI,
    ["RELOADUI_TEXT"] = "Algumas alterações exigem que você recarregue sua interface",

    -- Import / Export errors
    ["EXPORT"] = "Exportar",
    ["EXPORT_BAR"] = "Exportar Esta Barra",
    ["IMPORT"] = "Importar",
    ["IMPORT_BAR"] = "Importar Esta Barra",
    ["EXPORT_FAILED"] = "A exportação falhou.",
    ["IMPORT_FAILED_WITH_ERROR"] = "A importação falhou com o seguinte erro: ",
    ["IMPORT_STRING_NOT_SUITABLE"] = "Esta string de importação não é adequada para",
    ["IMPORT_STRING_OLDER_VERSION"] = "Esta string de importação é destinada a uma versão mais antiga do",
    ["IMPORT_STRING_INVALID"] = "String de importação inválida",
    ["IMPORT_DECODE_FAILED"] = "A decodificação falhou",
    ["IMPORT_DECOMPRESSION_FAILED"] = "A descompressão falhou",
    ["IMPORT_DESERIALIZATION_FAILED"] = "A desserialização falhou",

    -- Settings (Esc > Options > AddOns)
    ["SETTINGS_HEADER_POWER_COLORS"] = "Cores de Poder",
    ["SETTINGS_HEADER_HEALTH_COLOR"] = "Cor da Vida",
    ["SETTINGS_CATEGORY_IMPORT_EXPORT"] = "Importar / Exportar",
    ["SETTINGS_IMPORT_EXPORT_TEXT_1"] = "As strings de exportação geradas aqui englobam todas as barras do seu Layout atual do Modo de Edição.\nSe você deseja exportar apenas uma barra em particular, marque o botão Exportar no painel de Configurações da Barra no\nModo de Edição.",
    ["SETTINGS_IMPORT_EXPORT_TEXT_2"] = "O botão Importar abaixo suporta strings de exportação globais e de barras individuais. O de cada Configuração de Barra no\nModo de Edição é restrito a esta barra em particular.\nPor exemplo, se você exportou todas as suas barras, mas deseja importar apenas a Barra de Recurso Primário, use o\nbotão Importar da Barra de Recurso Primário no Modo de Edição.",
    ["SETTINGS_BUTTON_EXPORT_ONLY_POWER_COLORS"] = "Exportar Apenas Cores de Poder",
    ["SETTINGS_BUTTON_EXPORT_WITH_POWER_COLORS"] = "Exportar Com Cores de Poder",
    ["SETTINGS_BUTTON_EXPORT_WITHOUT_POWER_COLORS"] = "Exportar Sem Cores de Poder",
    ["SETTINGS_BUTTON_IMPORT"] = "Importar",
    ["SETTING_OPEN_AFTER_EDIT_MODE_CLOSE"] = "As configurações abrirão após sair do Modo de Edição",

    -- Power
    ["HEALTH"] = HEALTH,
    ["MANA"] = POWER_TYPE_MANA,
    ["RAGE"]= POWER_TYPE_RED_POWER,
    ["WHIRLWIND"] = "Redemoinho",
    ["FOCUS"] = POWER_TYPE_FOCUS,
    ["TIP_OF_THE_SPEAR"] = "Ponta da Lança",
    ["ENERGY"] = POWER_TYPE_ENERGY,
    ["RUNIC_POWER"] = POWER_TYPE_RUNIC_POWER,
    ["LUNAR_POWER"] = POWER_TYPE_LUNAR_POWER,
    ["MAELSTROM"] = POWER_TYPE_MAELSTROM,
    ["MAELSTROM_WEAPON"] = "Arma da Voragem",
    ["INSANITY"] = POWER_TYPE_INSANITY,
    ["FURY"] = POWER_TYPE_FURY_DEMONHUNTER,
    ["BLOOD_RUNE"] = COMBAT_TEXT_RUNE_BLOOD,
    ["FROST_RUNE"] = COMBAT_TEXT_RUNE_FROST,
    ["UNHOLY_RUNE"] = COMBAT_TEXT_RUNE_UNHOLY,
    ["COMBO_POINTS"] = COMBO_POINTS,
    ["OVERCHARGED_COMBO_POINTS"] = "Pontos de Combo Sobrecarregados",
    ["SOUL_SHARDS"] = SOUL_SHARDS,
    ["HOLY_POWER"] = HOLY_POWER,
    ["CHI"] = CHI,
    ["STAGGER_LOW"] = "Cambalear Baixo",
    ["STAGGER_MEDIUM"] ="Cambalear Médio",
    ["STAGGER_HIGH"] = "Cambalear Alto",
    ["ARCANE_CHARGES"] = POWER_TYPE_ARCANE_CHARGES,
    ["ICICLES"] = "Sincelos",
    ["SOUL_FRAGMENTS_VENGEANCE"] = "Fragmentos de Alma Vingança",
    ["SOUL_FRAGMENTS_DDH"] = "Fragmentos de Alma Devorador",
    ["SOUL_FRAGMENTS_VOID_META"] = "Fragmentos de Alma Mt. Devorador",
    ["ESSENCE"]= POWER_TYPE_ESSENCE,
    ["EBON_MIGHT"] = "Poder de Ébano",

    -- Bar names
    ["HEALTH_BAR_EDIT_MODE_NAME"] = "Barra de Vida",
    ["PRIMARY_POWER_BAR_EDIT_MODE_NAME"] = "Barra de Recurso Primário",
    ["SECONDARY_POWER_BAR_EDIT_MODE_NAME"] = "Barra de Recurso Secundário",
    ["TERNARY_POWER_BAR_EDIT_MODE_NAME"] = "Barra de Recurso Terciário",

    -- Bar visibility category - Edit Mode
    ["CATEGORY_BAR_VISIBILITY"] = "Visibilidade da Barra",
    ["BAR_VISIBLE"] = "Barra Visível",
    ["BAR_STRATA"] = "Camada da Barra",
    ["BAR_STRATA_TOOLTIP"] = "A camada na qual a barra é renderizada",
    ["HIDE_WHILE_MOUNTED_OR_VEHICULE"] = "Ocultar Enquanto Montado ou em Veículo",
    ["HIDE_WHILE_MOUNTED_OR_VEHICULE_TOOLTIP"] = "Incluir a Forma de Viagem do Druida",
    ["HIDE_MANA_ON_ROLE"] = "Ocultar Mana por Função",
    ["HIDE_HEALTH_ON_ROLE"] = "Ocultar Vida por Função",
    ["HIDE_MANA_ON_ROLE_PRIMARY_BAR_TOOLTIP"] = "Não tem efeito em Mago Arcano",
    ["HIDE_BLIZZARD_UI"] = "Ocultar Interface da Blizzard",
    ["HIDE_BLIZZARD_UI_HEALTH_BAR_TOOLTIP"] = "Oculta a interface padrão do Quadro do Jogador da Blizzard",
    ["HIDE_BLIZZARD_UI_SECONDARY_POWER_BAR_TOOLTIP"] = "Oculta a interface padrão de recursos secundários da Blizzard (ex: Quadro de Runas para Cavaleiros da Morte)",
    ["ENABLE_HP_BAR_MOUSE_INTERACTION"] = "Barra de Vida Clicável",
    ["ENABLE_HP_BAR_MOUSE_INTERACTION_TOOLTIP"] = "Habilita o comportamento padrão de clique do Quadro do Jogador na Barra de Vida.",

    -- Position & Size category - Edit Mode
    ["CATEGORY_POSITION_AND_SIZE"] = "Posição e Tamanho",
    ["POSITION"] = "Posição",
    ["X_POSITION"] = "Posição X",
    ["Y_POSITION"] = "Posição Y",
    ["RELATIVE_FRAME"] = "Quadro Relativo",
    ["RELATIVE_FRAME_TOOLTIP"] = "Devido a limitações, você não pode arrastar o quadro se ele estiver ancorado a outro quadro além do UIParent. Use os controles deslizantes X/Y",
    ["RELATIVE_FRAME_CYCLIC_WARNING"] = "Não é possível alterar o Quadro Relativo, pois o Quadro selecionado já é relativo a este Quadro.",
    ["ANCHOR_POINT"] = "Ponto de Ancoragem",
    ["RELATIVE_POINT"] = "Ponto Relativo",
    ["BAR_SIZE"] = "Tamanho da Barra",
    ["WIDTH_MODE"] = "Modo de Largura",
    ["WIDTH"] = "Largura",
    ["MINIMUM_WIDTH"] = "Largura Mínima",
    ["MINIMUM_WIDTH_TOOLTIP"] = "0 para desativar. Ativo apenas se sincronizado com o Gerenciador de Recargas",
    ["HEIGHT"] = "Altura",

    -- Bar settings category - Edit Mode
    ["CATEGORY_BAR_SETTINGS"] = "Configurações da Barra",
    ["FILL_DIRECTION"] = "Direção de Preenchimento",
    ["FASTER_UPDATES"] = "Atualizações Mais Rápidas (Maior Uso de CPU)",
    ["SMOOTH_PROGRESS"] = "Progresso Suave",
    ["SHOW_TICKS_WHEN_AVAILABLE"] = "Mostrar Marcações Quando Disponíveis",
    ["TICK_THICKNESS"] = "Espessura da Marcação",

    -- Bar style category - Edit Mode
    ["CATEGORY_BAR_STYLE"] = "Estilo da Barra",
    ["USE_CLASS_COLOR"] = "Usar Cor da Classe",
    ["USE_RESOURCE_TEXTURE_AND_COLOR"] = "Usar Textura e Cor do Recurso",
    ["BAR_TEXTURE"] = "Textura da Barra",
    ["BAR_BACKGROUND"] = "Fundo",
    ["USE_BAR_COLOR_FOR_BACKGROUND_COLOR"] = "Usar Cor da Barra para a Cor de Fundo",
    ["BAR_BORDER"] = "Borda",

    --  (Heal) Absorb bar style category - Edit Mode
    ["CATEGORY_ABSORB_BAR_STYLE"] = "Estilo da Barra de Absorção",
    ["CATEGORY_HEAL_ABSORB_BAR_STYLE"] = "Estilo da Barra de Absorção de Cura",
    ["ENABLE"] = "Habilitar",
    ["ABSORB_BAR_POSITION"] = "Estilo",
    ["HEAL_ABSORB_BAR_POSITION"] = "Estilo",

    -- Text settings category - Edit Mode
    ["CATEGORY_TEXT_SETTINGS"] = "Configurações de Texto",
    ["SHOW_RESOURCE_NUMBER"] = "Mostrar Número do Recurso",
    ["RESOURCE_NUMBER_FORMAT"] = "Formato",
    ["RESOURCE_NUMBER_FORMAT_TOOLTIP"] = "Alguns recursos não suportam o formato de porcentagem",
    ["RESOURCE_NUMBER_PRECISION"] = "Precisão",
    ["RESOURCE_NUMBER_ALIGNMENT"] = "Alinhamento",
    ["SHOW_MANA_AS_PERCENT"] = "Mostrar Mana como Porcentagem",
    ["SHOW_MANA_AS_PERCENT_TOOLTIP"] = "Força o formato de Porcentagem na Mana",
    ["SHOW_RESOURCE_CHARGE_TIMER"] = "Mostrar Temporizador de Carga (ex: Runas)",
    ["CHARGE_TIMER_PRECISION"] = "Precisão do Temporizador de Carga",

    -- Font category - Edit Mode
    ["CATEGORY_FONT"] = "Fonte",
    ["FONT"] = "Fonte",
    ["FONT_SIZE"] = "Tamanho",
    ["FONT_OUTLINE"] = "Contorno",

    -- Other
    ["POWER_COLOR_SETTINGS"] = "Configurações de Cores de Poder",

    -- Edit Mode Settings dropdown --

    -- Visibility Options
    ["ALWAYS_VISIBLE"] = "Sempre Visível",
    ["IN_COMBAT"] = "Em Combate",
    ["HAS_TARGET_SELECTED"] = "Tem Alvo Selecionado",
    ["HAS_TARGET_SELECTED_OR_IN_COMBAT"] = "Tem Alvo Selecionado OU Em Combate",
    ["HIDDEN"] = "Oculto",

    -- Strata Options -- Maybe keep it the same in all language ?
    ["TOOLTIP"] = "Dica de Interface",
    ["DIALOG"] = "Diálogo",
    ["HIGH"] = "Alta",
    ["MEDIUM"] = "Média",
    ["LOW"] = "Baixa",
    ["BACKGROUND"] = "Fundo",

    -- Role Options
    ["TANK"] = TANK,
    ["HEALER"] = HEALER,
    ["DPS"] = "DPS",

    -- Position Options
    ["POSITION_SELF"] = "Próprio",
    ["USE_HEALTH_BAR_POSITION_IF_HIDDEN"] = "Usar Posição da Barra de Vida se Oculta",
    ["USE_PRIMARY_RESOURCE_BAR_POSITION_IF_HIDDEN"] = "Usar Posição do Recurso Primário se Oculta",
    ["USE_SECONDARY_RESOURCE_BAR_POSITION_IF_HIDDEN"] = "Usar Posição do Recurso Secundário se Oculta",

    -- Frame Names
    ["UI_PARENT"] = "UIParent",
    ["HEALTH_BAR"] = "Barra de Vida",
    ["PRIMARY_RESOURCE_BAR"] = "Barra de Recurso Primário",
    ["SECONDARY_RESOURCE_BAR"] = "Barra de Recurso Secundário",
    ["PLAYER_FRAME"] = "Quadro do Jogador",
    ["TARGET_FRAME"] = "Quadro do Alvo",
    ["ESSENTIAL_COOLDOWNS"] = "Recargas Essenciais",
    ["UTILITY_COOLDOWNS"] = "Recargas de Utilidade",
    ["TRACKED_BUFFS"] = "Bônus Rastreados",
    ["ACTION_BAR"] = "Barra de Ação",
    ["ACTION_BAR_X"] = "Barra de Ação %d",

    -- Anchor & Relative Points -- Maybe keep it the same in all language ?
    ["TOPLEFT"] = "Superior Esquerdo",
    ["TOP"] = "Superior",
    ["TOPRIGHT"] = "Superior Direito",
    ["LEFT"] = "Esquerda",
    ["CENTER"] = "Centro",
    ["RIGHT"] = "Direita",
    ["BOTTOMLEFT"] = "Inferior Esquerdo",
    ["BOTTOM"] = "Inferior",
    ["BOTTOMRIGHT"] = "Inferior Direito",

    -- Width Modes
    ["MANUAL"] = "Manual",
    ["SYNC_WITH_ESSENTIAL_COOLDOWNS"] = "Sincronizar com Recargas Essenciais",
    ["SYNC_WITH_UTILITY_COOLDOWNS"] = "Sincronizar com Recargas de Utilidade",
    ["SYNC_WITH_TRACKED_BUFFS"] = "Sincronizar com Bônus Rastreados",

    -- Fill Directions
    ["LEFT_TO_RIGHT"] = "Da Esquerda para a Direita",
    ["RIGHT_TO_LEFT"] = "Da Direita para a Esquerda",
    ["TOP_TO_BOTTOM"] = "De Cima para Baixo",
    ["BOTTOM_TO_TOP"] = "De Baixo para Cima",

    -- (Heal) Absorb Bar Styles
    ["BAR_POSITION_FIXED"] = "Fixo",
    ["BAR_POSITION_REVERSED"] = "Revertido",
    ["BAR_POSITION_ATTACH_HEALTH"] = "Anexar à Vida",

    -- Outline Styles -- Maybe keep it the same in all language ?
    ["NONE"] = "Nenhum",
    ["OUTLINE"] = "Contorno",
    ["THICKOUTLINE"] = "Contorno Espesso",

    -- Text Formats
    ["CURRENT"] = "Atual",
    ["CURRENT_MAXIMUM"] = "Atual / Máximo",
    ["PERCENT"] = "Porcentagem",
    ["PERCENT_SYMBOL"] = "Porcentagem%",
    ["CURRENT_PERCENT"] = "Atual - Porcentagem",
    ["CURRENT_PERCENT_SYMBOL"] = "Atual - Porcentagem%",
}

addonTable:RegisterLocale("ptBR", baseLocale)
