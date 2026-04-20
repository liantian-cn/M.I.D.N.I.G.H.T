from __future__ import annotations
from typing import cast
from .base import BaseRotation
from terminal.context import Context, Unit
from datetime import datetime


__all__ = ["PriestDiscipline",]


class DisciplinePartyMember(Unit):
    # 只在当前 rotation 内补充类型信息，不改 Unit 本体。
    rejuvenation_remaining: float
    germination_remaining: float
    regrowth_remaining: float
    wild_growth_remaining: float
    lifebloom_remaining: float
    health_score: float
    health_deficit: float
    health_base: float
    rejuvenation_count: int
    hot_count: int
    dispel_list: list[str]
    debuff_list: list[str]
    buff_list: list[str]
    can_dispel: bool


class PriestDiscipline(BaseRotation):
    name = "戒律"
    desc = "戒律牧师的循环逻辑。"

    def __init__(self) -> None:
        super().__init__()

        self.dispel_types = {"MAGIC", "CURSE", "POISON"}  # 可驱散的 debuff 类型
        self.dispel_blacklist: list[str] = []

        self.macroTable = {
            "player苦修": "ALT-NUMPAD1",
            "party1苦修": "ALT-NUMPAD2",
            "party2苦修": "ALT-NUMPAD3",
            "party3苦修": "ALT-NUMPAD4",
            "party4苦修": "ALT-NUMPAD5",
            "player快速治疗": "ALT-NUMPAD6",
            "party1快速治疗": "ALT-NUMPAD7",
            "party2快速治疗": "ALT-NUMPAD8",
            "party3快速治疗": "ALT-NUMPAD9",
            "party4快速治疗": "ALT-NUMPAD0",
            "player真言术盾": "ALT-F1",
            "party1真言术盾": "ALT-F2",
            "party2真言术盾": "ALT-F3",
            "party3真言术盾": "ALT-F5",
            "party4真言术盾": "ALT-F6",
            "player纯净术": "ALT-F7",
            "party1纯净术": "ALT-F8",
            "party2纯净术": "ALT-F9",
            "party3纯净术": "ALT-F10",
            "party4纯净术": "ALT-F11",
            "player耀": "ALT-F12",
            # "party1耀": "ALT-,",
            # "party2耀": "ALT-.",
            # "party3耀": "ALT-/",
            # "party4耀": "ALT-;",
            "player灌注": "ALT-'",
            "party1灌注": "ALT-[",
            "party2灌注": "ALT-]",
            "party3灌注": "ALT-=",
            "party4灌注": "ALT-`",
            # "player占位1": "SHIFT-NUMPAD1",
            # "party1占位1": "SHIFT-NUMPAD2",
            # "party2占位1": "SHIFT-NUMPAD3",
            # "party3占位1": "SHIFT-NUMPAD4",
            # "party4占位1": "SHIFT-NUMPAD5",
            "绝望祷言": "SHIFT-NUMPAD6",
            "终极苦修": "SHIFT-NUMPAD7",
            "福音": "SHIFT-NUMPAD8",
            # "自然迅捷": "SHIFT-NUMPAD9",
            # "迅捷治愈": "SHIFT-NUMPAD0",
            "target灭": "SHIFT-F1",
            "target惩击": "SHIFT-F2",
            "target心灵震爆": "SHIFT-F3",
            "target痛": "SHIFT-F5",
            "target暗影魔": "SHIFT-F6",
            # "target愤怒": "SHIFT-F7",
            # "激活": "SHIFT-F8",
            # "mouseover复生": "SHIFT-F9",
        }

    def calculate_party_health_score(self, ctx: Context) -> list[DisciplinePartyMember]:
        spell_queue_window = float(ctx.spell_queue_window or 0.3)
        party_members: list[DisciplinePartyMember] = []
        for unit in ctx.parties:
            if unit.exists and unit.isInRangedRange and unit.alive:
                # if unit.exists and unit.alive:
                party_members.append(cast(DisciplinePartyMember, unit))
        party_members.append(cast(DisciplinePartyMember, ctx.player))
        # print(f"{ctx.player.castIcon=}")

        for member in party_members:
            unit_role = member.unitRole
            health_percent = member.healthPercent
            damage_absorbs = member.damageAbsorbs
            heal_absorbs = member.healAbsorbs
            rejuvenation_remaining = member.buffRemain("占位1")
            germination_remaining = member.buffRemain("萌芽")
            regrowth_remaining = member.buffRemain("灌注")
            wild_growth_remaining = member.buffRemain("耀")
            lifebloom_remaining = member.buffRemain("纯净术")

            # 血量基线使用“当前血量 - 治疗吸收”，数值越低说明越危险。
            health_base = health_percent - heal_absorbs

            # 计算hot数量，并且每个hot，增加大约点血量。
            rejuvenation_count = 0      # 回春数量，萌芽算回春（游戏机制）
            hot_count = 0               # hot机制下的总层数，回春、萌芽、灌注、耀、纯净术都算
            if rejuvenation_remaining > spell_queue_window:
                rejuvenation_count += 1
                hot_count += 1
            if germination_remaining > spell_queue_window:
                rejuvenation_count += 1
                hot_count += 1
            if regrowth_remaining > spell_queue_window:
                hot_count += 1
            if wild_growth_remaining > spell_queue_window:
                hot_count += 1
            if lifebloom_remaining > spell_queue_window:
                hot_count += 1

            if member.isPlayerCastingTarget:
                if ctx.player.castIcon == "灌注":
                    # print(f"{member.unitToken}正在被施法选中{health_base}")
                    health_base = health_base + 15  # 假设玩家正在施放的灌注会被打断，那么就把这个灌注提供的血量加回基线里，数值越低说明越危险。

            # 先找出单位身上可驱散的 debuff，再按黑名单过滤。
            dispel_list = [debuff.title for debuff in member.debuff if (debuff.type in self.dispel_types)]
            can_dispel = len(dispel_list) > 0
            for dispel in dispel_list:
                if dispel in self.dispel_blacklist:
                    can_dispel = False
                    break

            # 记录完整 debuff 列表，方便调试和后续扩展判断。
            debuff_list = [debuff.title for debuff in member.debuff if (debuff.title not in ["嗜血", "英勇", "赛季词缀", "良性Debuff"])]
            # print(f"{member.unitToken}的debuff列表: {debuff_list}")

            # 记录完整 buff 列表，方便调试和后续扩展判断。
            buff_list = [buff.title for buff in member.buff]

            # 血量缺口表示补满到 100% 还需要多少治疗量。
            health_deficit = 100 - health_base
            # 积分计算过程
            # 积分是基于血量基线的，血量基线越低说明越危险，优先级越高。
            # 积分是后续所有判断的标准。
            health_score = health_base + damage_absorbs  # 基础健康分数，治疗吸收越多越安全

            # 角色修正
            # 坦克的积分视为身上有3个hot。
            # 治疗的积分视为身上少1个hot
            if unit_role == "TANK":
                health_score += 0
            elif unit_role == "HEALER":
                health_score -= 0

            # debuff修正，每个debuff，积分-10分
            health_score += len(debuff_list) * (-10)

            # 积分最大100分
            health_score = min(health_score, 100)

            member.rejuvenation_remaining = rejuvenation_remaining  # 占位1剩余时间
            member.germination_remaining = germination_remaining  # 萌芽剩余时间，等价于第二个回春
            member.regrowth_remaining = regrowth_remaining  # 灌注剩余时间
            member.wild_growth_remaining = wild_growth_remaining  # 耀剩余时间
            member.lifebloom_remaining = lifebloom_remaining  # 纯净术剩余时间
            member.health_score = health_score  # 综合健康分数，数值越低越优先处理
            member.health_deficit = health_deficit  # 血量缺口，数值越高说明越缺治疗
            member.health_base = health_base  # 当前血量减治疗吸收后的基线，数值越低越危险
            member.dispel_list = dispel_list  # 可驱散debuff列表
            member.debuff_list = debuff_list  # debuff列表
            member.buff_list = buff_list  # buff列表
            member.rejuvenation_count = rejuvenation_count  # 回春层数，可能是 0 层、1 层、2 层
            member.can_dispel = can_dispel  # 是否有可驱散的debuff
            member.hot_count = hot_count  # 身上剩余的 HoT 数量（回春、萌芽、灌注、耀、纯净术）
        #     print(f"{member.unitToken}的状态: 血量基线={health_base:.2f}%", end="; ")
        # print(f"{datetime.now().strftime('%H:%M:%S')}")
        return party_members

    def read_config(self, ctx: Context):
        pass
        # 驱散黑名单
        self.dispel_blacklist = ctx.dispel_blacklist

    def main_rotation(self, ctx: Context) -> tuple[str, float, str]:
        self.read_config(ctx)
        party_members = self.calculate_party_health_score(ctx)
        spell_queue_window = float(ctx.spell_queue_window or 0.3)

        if not ctx.enable:
            # print("总开关未开启")
            return self.idle("总开关未开启")

        if ctx.delay:
            # print("延迟开关开启")
            return self.idle("延迟开关开启")

        player = [member for member in party_members if member.unitToken == "player"][0]

        if not player.alive:
            return self.idle("玩家已死亡")

        if player.isChatInputActive:
            return self.idle("正在聊天输入")

        if player.isMounted:
            return self.idle("骑乘中")

        if player.castIcon is not None:
            return self.idle("正在施法")

        if player.channelIcon is not None:
            return self.idle("正在引导")

        if player.isEmpowering:
            return self.idle("正在蓄力")

        if player.hasBuff("食物和饮料"):
            return self.idle("正在吃喝")

        # print(f"当前时间: {datetime.now().strftime('%H:%M:%S')}")
        return self.idle("当前没有合适动作")
