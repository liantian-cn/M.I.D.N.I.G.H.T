from __future__ import annotations
from typing import cast
from .base import BaseRotation
from terminal.context import Context, Unit
from datetime import datetime


__all__ = ["PriestDiscipline",]

# 技能       | 英文                 | 定义
# --------------------------------------------------------------
# 快速治疗   |  Flash Heal          |
# 真言术：盾 |  Power Word: Shield  | 又叫盾
# 暗影愈合   |  Shadow Mend         | 施法技能是 快速治疗 的热键，实际施放的可能是暗影愈合
# 虚空之盾   |  Void Shield         | 又叫黑盾，和真言术：盾是同一个技能，再存在buff 虚空之盾 时，技能变为 虚空之盾
# 救赎       |  Atonement
# 纯净术     |  Purify
# 灌注       |  Infusion
# 耀         |  Radiance
# 绝望祷言   |  Desperate Prayer
# 终极苦修   |  Ultimate Penitence
# 福音       |  Evangelism
# 灭         |  Smite
# 惩击       |  Penance
# 心灵震爆   |  Mind Blast
# 痛         |  Pain
# 圣光涌动   |  Surge of Light


class DisciplinePartyMember(Unit):
    # 只在当前 rotation 内补充类型信息，不改 Unit 本体。
    atonement_remaining: float
    has_shadow_shield: bool
    has_shield: bool
    shield_remaining: float
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

        self.dispel_types = ["MAGIC", ]  # 可驱散的 debuff 类型  本赛季好像没有疾病
        self.dispel_blacklist: list[str] = []

        self.macroTable = {
            "player苦修": "ALT-NUMPAD1",
            "party1苦修": "ALT-NUMPAD2",
            "party2苦修": "ALT-NUMPAD3",
            "party3苦修": "ALT-NUMPAD4",
            "party4苦修": "ALT-NUMPAD5",
            #
            "player快速治疗": "ALT-NUMPAD6",
            "party1快速治疗": "ALT-NUMPAD7",
            "party2快速治疗": "ALT-NUMPAD8",
            "party3快速治疗": "ALT-NUMPAD9",
            "party4快速治疗": "ALT-NUMPAD0",
            #
            "player真言术盾": "ALT-F2",
            "party1真言术盾": "ALT-F3",
            "party2真言术盾": "ALT-F5",
            "party3真言术盾": "ALT-F6",
            "party4真言术盾": "ALT-F7",
            #
            "player纯净术": "ALT-F8",
            "party1纯净术": "ALT-F9",
            "party2纯净术": "ALT-F10",
            "party3纯净术": "ALT-F11",
            "party4纯净术": "ALT-F12",
            #
            "player耀": "SHIFT-NUMPAD1",
            "party1耀": "SHIFT-NUMPAD2",
            "party2耀": "SHIFT-NUMPAD3",
            "party3耀": "SHIFT-NUMPAD4",
            "party4耀": "SHIFT-NUMPAD5",
            #
            "player灌注": "SHIFT-NUMPAD6",
            "party1灌注": "SHIFT-NUMPAD7",
            "party2灌注": "SHIFT-NUMPAD8",
            "party3灌注": "SHIFT-NUMPAD9",
            "party4灌注": "SHIFT-NUMPAD0",
            # 暗言术：痛
            "target痛": "未分配",
            "focus痛": "未分配",
            # 暗言术：灭
            "target灭": "未分配",
            "focus灭": "未分配",
            # 心灵震爆
            "target心灵震爆": "未分配",
            "focus心灵震爆": "未分配",
            # 苦修
            "target苦修": "未分配",
            "focus苦修": "未分配",
            # 惩击
            "target惩击": "未分配",
            "focus惩击": "未分配",

        }

    def calculate_party_health_score(self, ctx: Context) -> list[DisciplinePartyMember]:
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
            atonement_remaining = member.buffRemain("救赎")
            has_shadow_shield = member.hasBuff("虚空之盾")
            has_shield = has_shadow_shield or member.hasBuff("真言术：盾")
            if member.hasBuff("虚空之盾"):
                shield_remaining = member.buffRemain("虚空之盾")
            else:
                shield_remaining = member.buffRemain("真言术：盾")

            # 血量基线使用“当前血量 - 治疗吸收”，数值越低说明越危险。
            health_base = health_percent - heal_absorbs

            if member.isPlayerCastingTarget:
                if ctx.player.castIcon == "快速治疗":
                    health_base = health_base + 15
                elif ctx.player.castIcon == "暗影愈合":
                    health_base = health_base + 30

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
                health_score += 10
            elif unit_role == "HEALER":
                health_score -= 3

            # debuff修正，每个debuff，积分-15分
            health_score += -10 * len(debuff_list)

            # 积分最大100分
            health_score = min(health_score, 100)

            member.atonement_remaining = atonement_remaining  # 救赎剩余事件
            member.has_shadow_shield = has_shadow_shield  # 有没有黑盾，又叫虚空盾
            member.has_shield = has_shield  # 有没有护盾：包含黑盾
            member.shield_remaining = shield_remaining  # 盾剩余时间
            member.health_score = health_score  # 综合健康分数，数值越低越优先处理
            member.health_deficit = health_deficit  # 血量缺口，数值越高说明越缺治疗
            member.health_base = health_base  # 当前血量减治疗吸收后的基线，数值越低越危险
            member.dispel_list = dispel_list  # 可驱散debuff列表
            member.debuff_list = debuff_list  # debuff列表
            member.buff_list = buff_list  # buff列表
            member.can_dispel = can_dispel  # 是否有可驱散的debuff
        #     print(f"{member.unitToken}的状态: 血量基线={health_base:.2f}%", end="; ")
        # print(f"{datetime.now().strftime('%H:%M:%S')}")
        return party_members

    def read_config(self, ctx: Context):
        self.dispel_blacklist = ctx.dispel_blacklist

        use_mana_balance = ctx.setting.cell(0)
        if use_mana_balance is None:
            use_mana_balance = "no"
        else:
            use_mana_balance = "yes" if use_mana_balance.mean >= 200 else "no"

        self.use_mana_balance = use_mana_balance

    def main_rotation(self, ctx: Context) -> tuple[str, float, str]:
        self.read_config(ctx)
        party_members = self.calculate_party_health_score(ctx)
        spell_queue_window = float(ctx.spell_queue_window or 0.3)

        if not ctx.enable:
            return self.idle("总开关未开启")

        if ctx.delay:
            return self.idle("延迟开关开启")

        player = [member for member in party_members if member.unitToken == "player"][0]
        target = ctx.target
        focus = ctx.focus
        mouseover = ctx.mouseover

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

        # print(f"当前时间: {datetime.now().strftime('%H:%M:%S')}", end="; ")

        # 循环前会先算的目标与阈值
        # 最低单位/最低生命值：全队血量最低者，来自 /E:/Desktop/Fuyutsui/Fuyutsui/utils.py:138。
        # 无救赎最低：没有“救赎”且血量最低者，来自 /E:/Desktop/Fuyutsui/Fuyutsui/utils.py:334。
        # 无盾最低：没有“真言术：盾”且血量最低者，也是同一个函数。
        # 无盾坦克：第一个没有盾的坦克，来自 /E:/Desktop/Fuyutsui/Fuyutsui/utils.py:221。
        # 无救赎90数量：没有“救赎”且血量低于 90% 的人数，来自 /E:/Desktop/Fuyutsui/Fuyutsui/utils.py:476。
        # 有救赎数量：当前有“救赎”的人数，来自 /E:/Desktop/Fuyutsui/Fuyutsui/utils.py:513。
        # 驱散单位选择顺序：先看魔法驱散目标；在五人本里只要 首领战 != 64 就允许优先驱魔法；如果没有合适魔法目标，再退回疾病目标，逻辑在 /E:/Desktop/Fuyutsui/Fuyutsui/class/priest_logic.py:108。
        # 阈值：
        # 暗影愈合阈值 = 70 - 暗影愈合*2 + 暗影层数*15
        # 涌动阈值 = 80 - 圣光涌动 + 涌动层数*10

        # 五人本神谕者戒律实际优先级

        # 2. 绝望祷言 冷却好且自己血量 < 50，放 绝望祷言。

        if player.healthPercent < 50 and ctx.spell_cooldown_ready("绝望祷言", spell_queue_window, ignore_gcd=True):
            return self.cast("绝望祷言")

        # 6. 纯净术 冷却好且存在 驱散单位，对该单位放 纯净术。

        if ctx.spell_charges_ready("纯净术", 1, spell_queue_window):
            for member in party_members:
                if member.can_dispel:
                    return self.cast(f"{member.unitToken}纯净术")

        # 敌对目标，必须：存在、可攻击、在战斗
        main_enemy = None
        if focus.exists and focus.canAttack and focus.isInCombat:
            main_enemy = focus
        elif target.exists and target.canAttack and target.isInCombat:
            main_enemy = target

        # 7. 当前有敌对目标、处于战斗、且 一键辅助 == 14，先补 暗言术：痛。
        # 如果没有主目标，当前目标也不再远程范围，也不可以攻击，那么就什么都做不了。
        if main_enemy is not None:
            if ctx.assisted_combat == "暗言术：痛":
                return self.cast(f"{main_enemy.unitToken}痛")

        # 救赎且血量低于90的队友，按照健康分数从低到高排序，优先级越高越先处理
        without_atonement_and_below_90 = [member for member in party_members if (member.atonement_remaining <= 0 and member.healthPercent < 90)]
        without_atonement_and_below_90.sort(key=lambda m: m.health_score)  # 按健康分数排序，数值越低优先级越高
        # 无救赎的队友
        without_atonement = [member for member in party_members if member.atonement_remaining <= 0]
        without_atonement.sort(key=lambda m: m.health_score)  # 按健康分数排序，数值越低优先级越高
        # 最低健康分的队友
        lowest_health_score = sorted(party_members, key=lambda m: m.health_score)[0]
        # 最低血量的队友
        lowest_health_percent = sorted(party_members, key=lambda m: m.healthPercent)[0]
        # 没有盾的队友
        without_shield = [member for member in party_members if not member.has_shield]

        # 8. 无救赎90数量 >= 2、真言术：耀 可用、且 福音层数 > 0，放 真言术：耀。
        if len(without_atonement_and_below_90) >= 2:
            if player.buffStack("福音") > 0:
                if ctx.spell_charges_ready("真言术：耀", 1, spell_queue_window):
                    return self.cast(f"{without_atonement_and_below_90[0].unitToken}耀")

        # 9. 无救赎90数量 >= 2、福音 可用，放 福音。
        if len(without_atonement_and_below_90) >= 2:
            if player.buffStack("福音") == 0:
                if ctx.spell_cooldown_ready("福音", spell_queue_window):
                    return self.cast(f"福音")

        # 10. 暗言术：灭 可用、当前有敌对目标、在战斗中、且目标血量 < 20，放 暗言术：灭。
        if main_enemy is not None:
            if main_enemy.healthPercent < 20:
                if ctx.spell_charges_ready("暗言术：灭", 1, spell_queue_window):
                    return self.cast(f"{main_enemy.unitToken}灭")

        # 涌动阈值 = 80 - 圣光涌动CD + 涌动层数*10
        if player.hasBuff("圣光涌动"):
            surge_threshold = 80 - player.buffRemain("圣光涌动") + player.buffStack("圣光涌动层数") * 10

            # 11. 圣光涌动 > 0 且 涌动层数 > 0，如果“无救赎最低”血量 < 90，对它放 快速治疗。
            if len(without_atonement_and_below_90) > 0:
                if ctx.spell_cooldown_ready("快速治疗", spell_queue_window):
                    return self.cast(f"{without_atonement_and_below_90[0].unitToken}快速治疗")
            # 12. 同样要求 圣光涌动 > 0 且 涌动层数 > 0，如果全队最低血量 < 涌动阈值，对最低单位放 快速治疗。
            if lowest_health_percent.healthPercent < surge_threshold:
                if ctx.spell_cooldown_ready("快速治疗", spell_queue_window):
                    return self.cast(f"{lowest_health_percent.unitToken}快速治疗")

        # 13. 暗影愈合 > 0、暗影层数 > 0、施法技能 != 34、且最低单位血量 < 暗影愈合阈值，代码标记为“放暗影愈合”。
        if ctx.spell_cooldown_ready("暗影愈合", spell_queue_window):
            # 暗影愈合阈值 = 70 - 暗影愈合*2 + 暗影层数*15
            shadow_mend_threshold = 70 - player.buffRemain("暗影愈合") * 2 + player.buffStack("暗影愈合层数") * 15
            if lowest_health_percent.healthPercent < shadow_mend_threshold:
                return self.cast(f"{lowest_health_percent.unitToken}快速治疗")

        # 15. 真言术：盾 逻辑
        # 优先给无救赎且血量 < 90 的队友上盾。
        # 其次自己没盾就上盾
        # 最后给无盾最低健康分的队友上盾。
        if ctx.spell_cooldown_ready("真言术：盾", spell_queue_window):
            if len(without_atonement_and_below_90) > 0:
                if without_atonement_and_below_90[0].healthPercent < 90 or player.hasBuff("虚空之盾"):
                    return self.cast(f"{without_atonement_and_below_90[0].unitToken}真言术盾")

            if not player.has_shield:
                return self.cast(f"player真言术盾")

            if len(without_shield) > 0:
                without_shield.sort(key=lambda m: m.health_score)  # 按健康分数排序，数值越低优先级越高
                return self.cast(f"{without_shield[0].unitToken}真言术盾")

        # 18. 无救赎90数量 >= 3、真言术：耀 可用、且 施法技能 != 30，放 真言术：耀。
        if ctx.spell_charges_ready("真言术：耀", 1, spell_queue_window):
            if player.castIcon != "真言术：耀":
                if len(without_atonement_and_below_90) >= 3:
                    return self.cast(f"{without_atonement_and_below_90[0].unitToken}耀")

        # 19. 苦修 可用，且最低单位血量 < 75，对最低单位放 苦修。
        if ctx.spell_charges_ready("苦修", 1, spell_queue_window):
            if lowest_health_percent.healthPercent < 80:
                return self.cast(f"{lowest_health_percent.unitToken}苦修")

        # 20. 如果当前有敌对目标且在战斗中，进入 Atonement 输出补伤阶段：
        if main_enemy is not None:

            # 21. 暗言术：灭 可用且 有救赎数量 > 0，放 暗言术：灭。
            # 有救赎的队友数量
            with_atonement_count = len(party_members) - len(without_atonement)
            if ctx.spell_charges_ready("暗言术：灭", 1, spell_queue_window):
                if with_atonement_count > 0:
                    return self.cast(f"{main_enemy.unitToken}灭")
            # 22. 不在移动、心灵震爆 可用、且 有救赎数量 > 0，放 心灵震爆。
            if ctx.spell_charges_ready("心灵震爆", 1, spell_queue_window):
                if with_atonement_count > 0:
                    if not player.isMoving:
                        return self.cast(f"{main_enemy.unitToken}心灵震爆")
            # 23. 否则，苦修 可用、且 有救赎数量 > 0，放 苦修。
            if ctx.spell_charges_ready("苦修", 1, spell_queue_window):
                if with_atonement_count > 0:
                    return self.cast(f"{main_enemy.unitToken}苦修")

            # 24. 否则，只要不在移动，就放 惩击。
            if not player.isMoving:
                if ctx.spell_cooldown_ready("惩击", spell_queue_window):
                    return self.cast(f"{main_enemy.unitToken}惩击")

        # print("END")
        return self.idle("当前没有合适动作")
