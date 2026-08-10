在当前项目中，为我实现几个功能

## 一件辅助

DejaVu原版文件：DejaVu*Common\AssistedCombat.lua
新版本的文件：0631*\*.lua
要求：

- 使用IconCell，IconCell的BORDER的颜色总是addonTable.COLOR.SPELL.PLAYER
- 逻辑和DejaVu相似
- 坐标在x=31,y=5，占据到x=32,y=6，共4个cell的区域。

## 打断技能黑名单

DejaVu原版文件：DejaVu*Common\InterruptBlacklist.lua
新版本的文件：0632*\*.lua

要求：

- 使用IconCell，IconCell的BORDER的颜色总是addonTable.COLOR.SPELL.INTERRUPTIBLE
- 逻辑和DejaVu相似
- 左上角坐标在x=1,y=16，共计10个，占据到x=20,y=17，长条区域。
- 默认值和DejaVu一样
- 和DejaVu一样，注册到设置菜单。

## UTF输出

DejaVu源文件：DejaVu*Common\BadgeUTF.lua
新版本的文件：0633*\*.lua

要求：

- 使用IconCell
- 旧版使用DejaVu.BadgeTitleTable，新版不采用了，也没必要对iconcell信息储存，因为都是秘密值
- BadgeUTF使用的技能/图标范围，暂时仅来自2个地方。

1. 玩家所有的技能：使用 GetCooldownViewerCategorySet(Enum.CooldownViewerCategory.Essential, true)和GetCooldownViewerCategorySet(Enum.CooldownViewerCategory.Utility, true)可以获得玩家的所有技能。他们统一搭配 addonTable.COLOR.SPELL.PLAYER作为BORDER的颜色。
2. 打断技能黑名单添加的所有技能id，搭配addonTable.COLOR.SPELL.INTERRUPTIBLE作为BORDER的颜色。

- 左上角坐标在x=41,y=16，共计9个，占据到x=58,y=17，长条区域。

## 其他要求

完成后更新.context\project_rules\layout.md

下面进行一项整改要求
修改`src\0004_color.lua`

把
addonTable.COLOR = {
SPELL = {
PLAYER = CreateColor(64 / 255, 158 / 255, 210 / 255, 1), -- 玩家施法
INTERRUPTIBLE = CreateColor(255 / 255, 255 / 255, 60 / 255, 1), -- 可打断
NOT_INTERRUPTIBLE = CreateColor(200 / 255, 0, 0, 1), -- 不可打断
},
AURA_TYPE = { -- 技能类型颜色表
MAGIC = CreateColor(60 / 255, 100 / 255, 220 / 255, 1), -- 魔法
CURSE = CreateColor(100 / 255, 0, 120 / 255, 1), -- 诅咒
DISEASE = CreateColor(160 / 255, 120 / 255, 60 / 255, 1), -- 疾病
POISON = CreateColor(154 / 255, 205 / 255, 50 / 255, 1), -- 中毒
ENRAGE = CreateColor(230 / 255, 120 / 255, 20 / 255, 1), -- 激怒
BLEED = CreateColor(80 / 255, 0, 20 / 255, 1), -- 流血
DEBUFF_ON_FRIENDLY = CreateColor(255 / 255, 60 / 255, 60 / 255, 1), -- 在友方身上的减益
BUFF_ON_FRIENDLY = CreateColor(80 / 255, 220 / 255, 120 / 255, 1), -- 在友方身上的增益
PLAYER_SPELL = CreateColor(64 / 255, 158 / 255, 210 / 255, 1), -- 友方施法
ENEMY_SPELL_INTERRUPTIBLE = CreateColor(255 / 255, 255 / 255, 60 / 255, 1), -- 可打断
ENEMY_SPELL_NOT_INTERRUPTIBLE = CreateColor(200 / 255, 0, 0, 1), -- 不可打断
DEBUFF_ON_ENEMY = CreateColor(105 / 255, 105 / 255, 210 / 255, 1), -- 在敌方身上的减益
NONE = CreateColor(0, 0, 0, 0), -- 无
},

}
改成
addonTable.COLOR = { -- 技能类型颜色表
MAGIC = CreateColor(60 / 255, 100 / 255, 220 / 255, 1), -- 魔法
CURSE = CreateColor(100 / 255, 0, 120 / 255, 1), -- 诅咒
DISEASE = CreateColor(160 / 255, 120 / 255, 60 / 255, 1), -- 疾病
POISON = CreateColor(154 / 255, 205 / 255, 50 / 255, 1), -- 中毒
ENRAGE = CreateColor(230 / 255, 120 / 255, 20 / 255, 1), -- 激怒
BLEED = CreateColor(80 / 255, 0, 20 / 255, 1), -- 流血
DEBUFF_ON_FRIENDLY = CreateColor(255 / 255, 60 / 255, 60 / 255, 1), -- 在友方身上的减益
BUFF_ON_FRIENDLY = CreateColor(80 / 255, 220 / 255, 120 / 255, 1), -- 在友方身上的增益
PLAYER_SPELL = CreateColor(64 / 255, 158 / 255, 210 / 255, 1), -- 友方施法
ENEMY_SPELL_INTERRUPTIBLE = CreateColor(255 / 255, 255 / 255, 60 / 255, 1), -- 可打断
ENEMY_SPELL_NOT_INTERRUPTIBLE = CreateColor(200 / 255, 0, 0, 1), -- 不可打断
DEBUFF_ON_ENEMY = CreateColor(105 / 255, 105 / 255, 210 / 255, 1), -- 在敌方身上的减益
NONE = CreateColor(0, 0, 0, 0), -- 无

}

1. 搜索 SetBorderColor、搜索addonTable.COLOR，对所有使用addonTable.COLOR的地方修改。

2. 另外：
   SPELL.PLAYER改成 PLAYER_SPELL
   SPELL.INTERRUPTIBLE改成ENEMY_SPELL_INTERRUPTIBLE
   SPELL.NOT_INTERRUPTIBLE改成ENEMY_SPELL_NOT_INTERRUPTIBLE

3. 部分之前没引用addonTable.COLOR的，比如src\0119_player_cast_info.lua也改成使用addonTable.COLOR

以上是为了便于未来统一调整。
