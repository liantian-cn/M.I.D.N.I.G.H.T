# 摘要：专精模板基类，定义所有专精共用的技能、充能、Aura、小队增益与无用字段的容器约定及统一 helper。

# 描述：
# 本文件是 Copilot 本地专精模块族的基类。各专精子类继承 SpecTemplate，并在 __init__ 中先调用
# super().__init__() 初始化所有字段为本模板默认值，再按上游 PhantomProject 对于专精 lua 中
# 实际存在定义的字段覆盖之。所有表（spell_list、charge_list、player_buff、target_debuff、party_hots）
# 统一使用整数 1..n 键，与上游 1-based 索引语义一一对应；party_buff 为单对象 dict，不套用整数键。
# "计划中在 Copilot 中无用"的字段（party_buff、dispel_types、party_range_spell_ids、ranged_spell、
# melee_spell）仍按上游是否定义迁移，迁移时容器表达为 set/list/int，模板默认 party_buff=None、
# dispel_types=set()、party_range_spell_ids=None、ranged_spell=None、melee_spell=None。
# helper 仅对同构表（spell_list、charge_list、player_buff、target_debuff、party_hots）补齐
# *_by_index 与 *_name_by_index，index 为 1-based 整数。

# 主要变量信息：
# SPEC_LUA：上游对应 lua 路径，用于审计回溯；template 自身为 class_specialization_template.lua。
# SPEC_GIT_COMMIT_HASH：上游对应 git commit hash；template 与本轮同步上游 HEAD 一致。
# spell_list：技能冷却表，整数键 -> {spellId, description, 可选 charge/isGCD}。
# charge_list：充能技能表，整数键 -> {spellId, description, minValue, maxValue}。
# player_buff：玩家增益监控表，整数键 -> {description, spellIDs, 可选 maxApplications}。
# target_debuff：目标减益监控表，整数键 -> {description, spellIDs, 可选 maxApplications}。
# party_hots：小队 HOT 监控表，整数键 -> {description, spellIDs}。
# party_buff：职业小队增益单对象 {description, spellIDs} 或 None。
# dispel_types：驱散类型集合 set[str]；默认 set()。
# party_range_spell_ids：小队距离候选技能 list[int] 或 None。
# ranged_spell：远程通用 spellId int 或 None。
# melee_spell：近战通用 spellId int 或 None。

# 修改记录：
# 2026-08-01：按冻结 plan 修复 key 风格为整数、修正 spell_by_index 的 off-by 实现、补齐 charge/
#   player_buff/target_debuff/party_hots 的 *_by_index 与 *_name_by_index、补齐文件头与无用字段占位。


from __future__ import annotations
from typing import Any, Optional, Set, List, Dict


# 该文件对应的lua文件路径，属于PhantomProject项目
SPEC_LUA = "src/class/class_specialization_template.lua"
# 对应文件的git commit hash
SPEC_GIT_COMMIT_HASH = "4b695a44cd7faa991d005cc3f99d4396d58a9f7b"


class SpecTemplate(object):
    spec_name = "模板文件"
    spec_base = "WowAPI UnitClassBase()的值"
    spec_id = "WowAPI GetSpecialization()的值"

    def __init__(self) -> None:
        # spell_list、charge_list、player_buff、target_debuff：为了美观禁止换行。
        self.spell_list: Dict[int, Any] = {  # 等效lua的addonTable.SPEC.SpellList

        }
        self.charge_list: Dict[int, Any] = {  # 等效lua的addonTable.SPEC.ChargeList

        }
        self.player_buff: Dict[int, Any] = {  # 等效lua的addonTable.SPEC.PlayerBuff

        }
        self.target_debuff: Dict[int, Any] = {  # 等效lua的addonTable.SPEC.TargetDebuff

        }
        self.party_hots: Dict[int, Any] = {  # 等效lua的addonTable.SPEC.PartyHots

        }
        self.party_buff: Optional[Dict[str, Any]] = None  # 等效lua的addonTable.SPEC.PartyBuff ,计划中在Copilot中无用.
        self.dispel_types: Set[str] = set()  # 等效lua的addonTable.SPEC.DISPEL_TYPES  ,计划中在Copilot中无用.
        self.party_range_spell_ids: Optional[List[int]] = None  # 等效lua的addonTable.SPEC.PartyRangeSpellIDs ,计划中在Copilot中无用.
        self.ranged_spell: Optional[int] = None  # 等效lua的addonTable.SPEC.RANGED_SEPLL,计划中在Copilot中无用.
        self.melee_spell: Optional[int] = None  # 等效lua的addonTable.SPEC.MELEE_SEPLL,计划中在Copilot中无用.

    def spell_by_index(self, index: int):
        return self.spell_list[index]

    def spell_name_by_index(self, index: int):
        return self.spell_by_index(index)["description"]

    def charge_by_index(self, index: int):
        return self.charge_list[index]

    def charge_name_by_index(self, index: int):
        return self.charge_by_index(index)["description"]

    def player_buff_by_index(self, index: int):
        return self.player_buff[index]

    def player_buff_name_by_index(self, index: int):
        return self.player_buff_by_index(index)["description"]

    def target_debuff_by_index(self, index: int):
        return self.target_debuff[index]

    def target_debuff_name_by_index(self, index: int):
        return self.target_debuff_by_index(index)["description"]

    def party_hots_by_index(self, index: int):
        return self.party_hots[index]

    def party_hots_name_by_index(self, index: int):
        return self.party_hots_by_index(index)["description"]