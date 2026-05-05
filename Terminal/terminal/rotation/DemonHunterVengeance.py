"""
天赋：CUkAG5bbocFKcv+yIq8fPd6ORBAMjZmZMjZmMzMMWMjZwMjZGzYmZGDzsNzYzMjxwAAAAwsNDGGLLMhhZmxGAAAAGMzMzMzSbzMzAAAAAAMA
"""

from datetime import datetime

from terminal.context import Context
from .base import BaseRotation


class DemonHunterVengeance(BaseRotation):
    name = "复仇歼灭者DHT"
    desc = "目前只适配歼灭者"

    def __init__(self) -> None:
        super().__init__()

        self.macroTable = {
            "target幽魂炸弹": "ALT-NUMPAD1",
            "target怨念咒符": "ALT-NUMPAD2",
            "target灵魂裂劈": "ALT-NUMPAD3",
            "target烈焰咒符": "ALT-NUMPAD4",
            "邪能毁灭": "ALT-NUMPAD5",
            "献祭光环": "ALT-NUMPAD6",
            "恶魔变形": "ALT-NUMPAD7",
            "target投掷利刃": "ALT-NUMPAD8",
            "target瓦解": "ALT-NUMPAD9",
            "focus瓦解": "ALT-NUMPAD0",
            "鲁莽药水": "SHIFT-NUMPAD1",
            "target破裂": "SHIFT-NUMPAD2",
            "停止施法": "SHIFT-NUMPAD3",
            "恶魔尖刺": "SHIFT-NUMPAD4",
        }

    def main_rotation(self, ctx: Context) -> tuple[str, float, str]:

        if not ctx.enable:
            return self.idle("总开关未开启")

        if ctx.delay:
            return self.idle("延迟开关开启")

        is_opener = float(ctx.combat_time) <= 10
        spell_queue_window = float(ctx.spell_queue_window or 0.3)
        player = ctx.player
        target = ctx.target
        focus = ctx.focus
        mouseover = ctx.mouseover
        latest_succeeded_cast = ctx.latest_succeeded_cast

        # ── 设置项读取 ──────────────────────────────────────────────

        # # AOE敌人数量阈值 min:2 max:10 default:4 step:1
        # aoe_enemy_count_cell = ctx.setting.cell(5)
        # aoe_enemy_count = (
        #     4 if aoe_enemy_count_cell is None else round(aoe_enemy_count_cell.mean / 10)
        # )

        # # 灵魂碎片（玩家身上）
        # soul_fragments_cell = ctx.spec.cell(0)
        # soul_fragments = (
        #     0 if soul_fragments_cell is None else int(soul_fragments_cell.mean / 5)
        # )

        # 获取恶魔之怒最大值，默认120，恶魔之怒是根据这个值来计算的。因为不同版本恶魔之怒的最大值可能不同，所以让用户自己设置这个值。
        fury_max_cell = ctx.setting.cell(0)
        fury_max = 120 if fury_max_cell is None else fury_max_cell.mean
        fury = int(ctx.player.powerPercent * fury_max / 100)

        # 斩杀血量阈值（默认10%）
        reaper_health_threshold_cell = ctx.setting.cell(4)
        reaper_health_threshold = (
            10
            if reaper_health_threshold_cell is None
            else int(reaper_health_threshold_cell.mean)
        )

        # 打断模式（blacklist / any）
        dh_interrupt_mode_cell = ctx.setting.cell(1)
        dh_interrupt_mode = (
            "blacklist"
            if dh_interrupt_mode_cell is None or dh_interrupt_mode_cell.mean >= 200
            else "any"
        )
        interrupt_blacklist = ctx.interrupt_blacklist
        spell_stop_list = ctx.spell_stop_list
        range_spell_stop_list = ctx.range_spell_stop_list

        # # 开启保命血量阈值（默认60%）
        # dh_health_threshold_cell = ctx.setting.cell(2)
        # dh_health_threshold = (
        #     60
        #     if dh_health_threshold_cell is None
        #     else int(dh_health_threshold_cell.mean)
        # )

        # # 虚空射线泄能怒气阈值（常态，默认100）
        # fury_overflow_threshold_cell = ctx.setting.cell(3)
        # fury_overflow_threshold = (
        #     100
        #     if fury_overflow_threshold_cell is None
        #     else int(fury_overflow_threshold_cell.mean)
        # )

        # ── 基础状态检查 ────────────────────────────────────────────

        if not player.alive:
            return self.idle("玩家已死亡")

        if player.isChatInputActive:
            return self.idle("正在聊天输入")

        if player.isMounted:
            return self.idle("骑乘中")

        if player.castIcon is not None:
            return self.idle("正在施法")

        if player.channelIcon is not None:
            # 引导中断：虚空射线目标丢失时停止引导
            # if player.channelIcon == "虚空射线" and enemy_count == 0:
            #     # 目标已全部死亡，停止引导虚空射线
            #     return self.cast("停止施法")  # 或使用对应的取消宏
            return self.idle("正在引导")

        if player.isEmpowering:
            return self.idle("正在蓄力")

        if player.hasBuff("食物和饮料"):
            return self.idle("正在吃喝")

        if not player.isInCombat:
            return self.idle("未进入战斗")

        # ── 敌对目标确定：存在、可攻击、在战斗──────────────────────────────────────────────

        main_enemy = None
        if focus.exists and focus.canAttack and focus.isInCombat:
            main_enemy = focus
        elif target.exists and target.canAttack and target.isInCombat:
            main_enemy = target

        # ── AOE判断 ─────────────────────────────────────────────────
        # is_aoe = player.enemyCount >= aoe_enemy_count

        # ── Buff/状态读取 ───────────────────────────────────────────

        # 无羁邪怒
        untethered_rage_buff_exists = player.hasBuff("无羁邪怒")

        # # 虚落层数
        # voidfall_count = player.buffStack("虚落")

        # # 地上的灵魂碎片（散落）
        # scattered_souls_fragments_count = player.buffStack("灵魂残片")

        # # 噬欲时刻
        # moment_of_craving_exists = player.hasBuff("噬欲时刻")
        # moment_of_craving_remaining = player.buffRemain("噬欲时刻")

        # 恶魔尖刺
        demonspikes_exists = player.hasBuff("恶魔尖刺")

        # # 灵魂献祭
        # soul_immolation_exists = player.hasBuff("灵魂献祭")

        # # ── 保命：献祭（应急，忽略常规优先级限制）──────────────────
        # # 注意：灵魂献祭在持续时间内可回复24%最大生命值，应急时可在变身内外使用
        # if (
        #     not soul_immolation_exists
        #     and player.healthPercent < dh_health_threshold
        #     and ctx.spell_cooldown_ready("灵魂献祭", spell_queue_window)
        # ):
        #     return self.cast("灵魂献祭")

        # ── 打断逻辑 ────────────────────────────────────────────────

        focus_need_interrupt = False
        target_need_interrupt = False

        if focus.exists and focus.canAttack and focus.isInRangedRange:
            if focus.anyCastIcon is not None and focus.anyCastIsInterruptible:
                if dh_interrupt_mode == "any":
                    focus_need_interrupt = True
                elif focus.anyCastIcon not in interrupt_blacklist:
                    focus_need_interrupt = True

        if target.exists and target.canAttack and target.isInRangedRange:
            if target.anyCastIcon is not None and target.anyCastIsInterruptible:
                if dh_interrupt_mode == "any":
                    target_need_interrupt = True
                elif target.anyCastIcon not in interrupt_blacklist:
                    target_need_interrupt = True

        if ctx.spell_cooldown_ready("瓦解", spell_queue_window, ignore_gcd=True):
            if focus_need_interrupt:
                return self.cast("focus瓦解")
            elif target_need_interrupt:
                return self.cast("target瓦解")

        # # ── 停止施法黑名单检查 ──────────────────────────────────────

        # trigger_spell = None
        # player_need_spell_stop = False
        # if target.exists and target.anyCastIcon in spell_stop_list:
        #     trigger_spell = target.anyCastIcon
        #     player_need_spell_stop = True
        # elif focus.exists and focus.anyCastIcon in spell_stop_list:
        #     trigger_spell = focus.anyCastIcon
        #     player_need_spell_stop = True

        # if player_need_spell_stop:
        #     return self.idle(f"检测到黑名单技能 [{trigger_spell}]，停止施法")

        # # ── 大范围技能停止施法黑名单检查 ──────────────────────────────

        # range_trigger_spell = None
        # player_need_specific_spell_stop = False
        # if target.exists and target.anyCastIcon in range_spell_stop_list:
        #     range_trigger_spell = target.anyCastIcon
        #     player_need_specific_spell_stop = True
        # elif focus.exists and focus.anyCastIcon in range_spell_stop_list:
        #     range_trigger_spell = focus.anyCastIcon
        #     player_need_specific_spell_stop = True

        # ══════════════════════════════════════════════════════════════

        if untethered_rage_buff_exists and ctx.spell_cooldown_ready(
            "恶魔变形", spell_queue_window
        ):
            return self.cast("恶魔变形")

        if (
            ctx.spell_charges_ready("恶魔尖刺", 1, spell_queue_window)
            and not demonspikes_exists
        ):
            return self.cast("恶魔尖刺")

        if main_enemy is not None:
            if ctx.assisted_combat == "幽魂炸弹":
                return self.cast(f"{main_enemy.unitToken}幽魂炸弹")
            if ctx.assisted_combat == "怨念咒符":
                return self.cast(f"{main_enemy.unitToken}怨念咒符")
            if ctx.assisted_combat == "灵魂裂劈":
                return self.cast(f"{main_enemy.unitToken}灵魂裂劈")
            if ctx.assisted_combat == "烈焰咒符":
                return self.cast(f"{main_enemy.unitToken}烈焰咒符")
            if ctx.assisted_combat == "献祭光环":
                return self.cast(f"献祭光环")
            if ctx.assisted_combat == "邪能毁灭":
                return self.cast(f"{main_enemy.unitToken}邪能毁灭")
            if ctx.assisted_combat == "投掷利刃":
                return self.cast(f"{main_enemy.unitToken}投掷利刃")
            if ctx.assisted_combat == "破裂":
                return self.cast(f"{main_enemy.unitToken}破裂")

        return self.idle("当前没有合适动作")
