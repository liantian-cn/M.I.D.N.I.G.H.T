"""
本循环适用于噬灭35魂虚痕
天赋代码如下：
CgcBG5bbocFKcv+yIq8fPd6ORBA2mxMzMzMzMGmBAAAAAAgxsNYGAAAAAAAAmxMMzMzMzMzMDzsNzYsJLMzYGtMzYAMMzMLzMTzyMLGzwYGA
"""

# from __future__ import annotations
from datetime import datetime

from terminal.context import Context
from .base import BaseRotation


class DemonHunterDevourer_1(BaseRotation):
    name = "噬灭虚痕DH"
    desc = "目前正在施工适配虚痕"

    def __init__(self) -> None:
        super().__init__()

        self.macroTable = {
            "target吞噬": "ALT-NUMPAD1",
            "focus吞噬": "ALT-NUMPAD2",
            "就近吞噬": "ALT-NUMPAD3",
            "target收割": "ALT-NUMPAD4",
            "虚空射线": "ALT-NUMPAD5",
            "target根除": "ALT-NUMPAD6",
            "虚空变形": "ALT-NUMPAD7",
            "target坍缩之星": "ALT-NUMPAD8",
            "target瓦解": "ALT-NUMPAD9",
            "focus瓦解": "ALT-NUMPAD0",
            "疾影": "SHIFT-NUMPAD1",
            "灵魂献祭": "SHIFT-NUMPAD2",
            "圣光潜力": "SHIFT-NUMPAD3",
            "target虚空之刃": "SHIFT-NUMPAD4",
            "target饥渴斩击": "SHIFT-NUMPAD5",
            "复仇回避": "SHIFT-NUMPAD6",
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

        # ── 设置项读取 ──────────────────────────────────────────────

        # AOE敌人数量阈值 min:2 max:10 default:4 step:1
        # print(f"敌人数量格子{aoe_enemy_count_cell.mean}")
        aoe_enemy_count_cell = ctx.setting.cell(5)
        aoe_enemy_count = (
            4 if aoe_enemy_count_cell is None else round(aoe_enemy_count_cell.mean / 10)
        )

        # 灵魂碎片（玩家身上）
        soul_fragments_cell = ctx.spec.cell(0)
        soul_fragments = (
            0 if soul_fragments_cell is None else int(soul_fragments_cell.mean / 5)
        )

        # 恶魔之怒
        fury_max_cell = ctx.setting.cell(0)
        fury_max = 120 if fury_max_cell is None else fury_max_cell.mean
        fury = int(ctx.player.powerPercent * fury_max / 100)

        # 收割/根除 血量阈值（默认15%）
        reaper_health_threshold_cell = ctx.setting.cell(4)
        reaper_health_threshold = (
            15
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

        # 疾影保命血量阈值（默认60%）
        dh_health_threshold_cell = ctx.setting.cell(2)
        dh_health_threshold = (
            60
            if dh_health_threshold_cell is None
            else int(dh_health_threshold_cell.mean)
        )

        # 虚空射线泄能怒气阈值（常态，默认100）
        fury_overflow_threshold_cell = ctx.setting.cell(3)
        fury_overflow_threshold = (
            90
            if fury_overflow_threshold_cell is None
            else int(fury_overflow_threshold_cell.mean)
        )

        # 虚空变形血量阈值（默认30%）
        void_metamorphosis_health_threshold_cell = ctx.setting.cell(4)
        void_metamorphosis_health_threshold = (
            30
            if void_metamorphosis_health_threshold_cell is None
            else int(void_metamorphosis_health_threshold_cell.mean)
        )

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
            return self.idle("正在引导")
        if player.isEmpowering:
            return self.idle("正在蓄力")
        if player.hasBuff("食物和饮料"):
            return self.idle("正在吃喝")
        if not player.isInCombat:
            return self.idle("未进入战斗")

        # ── 主目标确定 ──────────────────────────────────────────────

        main_target = None
        if focus.exists and focus.canAttack and focus.isInRangedRange:
            main_target = focus
        elif target.exists and target.canAttack and target.isInRangedRange:
            main_target = target

        if main_target is None:
            return self.idle("没有合适的目标")

        # ── AOE判断 ─────────────────────────────────────────────────
        is_aoe = player.enemyCount >= aoe_enemy_count
        # print(
        #     f"当前敌人数量:{player.enemyCount}；设定aoe阈值：{aoe_enemy_count}；判断是否为aoe:{is_aoe}"
        # )

        # ── Buff/状态读取 ───────────────────────────────────────────

        # 疾影
        phase_shift_buff_exists = player.hasBuff("疾影")

        # 地上的灵魂碎片（散落）
        scattered_souls_fragments_count = player.buffStack("灵魂残片")

        # 噬欲时刻
        moment_of_craving_exists = player.hasBuff("噬欲时刻")
        moment_of_craving_remaining = player.buffRemain("噬欲时刻")

        # 坍缩之星（爆发变身标志）
        collapsing_star_exists = player.hasBuff("坍缩之星")

        # 灵魂献祭
        soul_immolation_exists = player.hasBuff("灵魂献祭")

        # 饥渴斩击
        hungering_slash_exists = player.hasBuff("饥渴斩击")

        # 虚空瞬步
        voidstep_exists = player.hasBuff("虚空瞬步")

        # ── 保命：疾影 ──────────────────────────────────────────────

        if (
            not phase_shift_buff_exists
            and player.healthPercent < dh_health_threshold
            and ctx.spell_cooldown_ready("疾影", spell_queue_window)
        ):
            return self.cast("疾影")

        # ── 打断逻辑 ────────────────────────────────────────────────
        # print(f"打断黑名单：{interrupt_blacklist}")

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

        # ── 停止施法黑名单检查 ──────────────────────────────────────

        trigger_spell = None
        player_need_spell_stop = False
        if target.exists and target.anyCastIcon in spell_stop_list:
            trigger_spell = target.anyCastIcon
            player_need_spell_stop = True
        elif focus.exists and focus.anyCastIcon in spell_stop_list:
            trigger_spell = focus.anyCastIcon
            player_need_spell_stop = True

        if player_need_spell_stop:
            return self.idle(f"检测到黑名单技能 [{trigger_spell}]，停止施法")

        # ── 大范围技能停止施法黑名单检查 ──────────────────────────────────────

        # print(f"目标施放法术：{target.anyCastIcon}")
        # print(f"停止施法的大范围技能黑名单列表：{range_spell_stop_list}")

        range_trigger_spell = None
        player_need_specific_spell_stop = False
        if target.exists and target.anyCastIcon in range_spell_stop_list:
            range_trigger_spell = target.anyCastIcon
            player_need_specific_spell_stop = True
        elif focus.exists and focus.anyCastIcon in range_spell_stop_list:
            range_trigger_spell = focus.anyCastIcon
            player_need_specific_spell_stop = True

        # ── 爆发触发：虚空变形 ──────────────────────────────────────
        # 条件：不在移动 + 身上魂 >= 48 + 有噬欲时刻
        # print(
        #     f"圣光潜力是否已冷却：{}"
        # )
        if (
            not player.isMoving
            and soul_fragments >= 33
            and moment_of_craving_exists
            and ctx.spell_cooldown_ready("虚空变形", spell_queue_window)
        ):
            # 当敌人数量 >= 8 时，先额外使用“圣光潜力”
            # 注意：这里不直接 return，除非你的框架要求必须 return 才能施法
            if player.enemyCount >= 8:
                self.cast("圣光潜力")

            # 无论敌人多少，只要满足外层 if，最终都执行变身
            return self.cast("虚空变形")

        # ══════════════════════════════════════════════════════════════
        # 爆发段逻辑（collapsing_star_exists == True）
        # 坍缩之星（硬性要求：身上 >= 30 魂）和虚空射线（硬性要求：怒气 >= 100）
        # 两个技能都要使用，优先级区别：
        #   AOE：坍缩之星 > 虚空射线
        #   单体：虚空射线 > 坍缩之星
        # ══════════════════════════════════════════════════════════════
        if collapsing_star_exists:

            # ── 爆发段：根除强制插入（最高优先级）────────────────────
            # 噬欲时刻即将消失（<= 1s），无论如何先打根除
            if (
                moment_of_craving_exists
                and 0 < moment_of_craving_remaining <= 1
                and ctx.spell_cooldown_ready("根除", spell_queue_window)
            ):
                return self.cast("target根除")

            # 预先计算两个核心技能是否满足硬性条件
            star_ready = (
                not player_need_specific_spell_stop
                and soul_fragments >= 30
                and ctx.spell_cooldown_ready("坍缩之星", spell_queue_window)
            )
            void_ray_ready = (
                not player_need_specific_spell_stop
                and not player.isMoving
                and target.isInRangedRange
                and ctx.spell_cooldown_ready("虚空射线", spell_queue_window)
            )

            def try_cast_void_ray():
                """
                打虚空射线前先检查根除：
                射线会刷新噬欲时刻，所以如果根除CD好了且满足打根除条件，先打根除。
                """
                if ctx.spell_cooldown_ready("根除", spell_queue_window):
                    if scattered_souls_fragments_count >= 8 or moment_of_craving_exists:
                        return self.cast("target根除")
                return self.cast("虚空射线")

            def try_cast_star():
                """
                打坍缩之星前先检查根除（地上 >= 8 魂时）。
                """
                if scattered_souls_fragments_count >= 8 and ctx.spell_cooldown_ready(
                    "根除", spell_queue_window
                ):
                    return self.cast("target根除")
                return self.cast("target坍缩之星")

            # ── AOE：坍缩之星 > 虚空射线 ────────────────────────────
            if is_aoe:
                if star_ready:
                    return try_cast_star()
                if void_ray_ready:
                    return try_cast_void_ray()

            # ── 单体：虚空射线 > 坍缩之星 ───────────────────────────
            else:
                if void_ray_ready:
                    return try_cast_void_ray()
                if star_ready:
                    return try_cast_star()

            # ── 爆发段填充：两个核心技能都没好 ──────────────────────
            # 根除：地上 >= 8 魂 或 目标低血
            if ctx.spell_cooldown_ready("根除", spell_queue_window):
                if (
                    scattered_souls_fragments_count >= 8
                    or main_target.healthPercent < reaper_health_threshold
                ):
                    return self.cast("target根除")

            # 灵魂献祭
            if ctx.spell_cooldown_ready("灵魂献祭", spell_queue_window):
                if (
                    not soul_immolation_exists
                    and soul_fragments <= 32
                    and fury <= 78
                    and ctx.spell_charges_ready("灵魂献祭", 1, spell_queue_window)
                ):
                    return self.cast("灵魂献祭")

            # # 收割：有噬欲时刻时
            # if (
            #     fury >= 70
            #     and scattered_souls_fragments_count >= 4
            #     and moment_of_craving_exists
            #     and ctx.spell_cooldown_ready("收割", spell_queue_window)
            # ):
            #     return self.cast("target收割")

            # 吞噬：产魂 + 堆怒气
            if ctx.spell_cooldown_ready("吞噬", spell_queue_window):
                if main_target is focus:
                    return self.cast("focus吞噬")
                elif main_target is target:
                    return self.cast("target吞噬")
                elif player.enemyCount >= 1:
                    return self.cast("就近吞噬")

            return self.idle("爆发中：等待CD")

        # ══════════════════════════════════════════════════════════════
        # 常态段逻辑（collapsing_star_exists == False）
        # ══════════════════════════════════════════════════════════════

        # ── 常态：聚能打虚空之刃+复仇回避──────────────────────
        # 注意：饥渴斩击(Hungering Slash)是虚空之刃的触发效果(buff/debuff)，
        # 不是独立可施放的技能，无需单独判断施放
        if ctx.spell_cooldown_ready("虚空之刃", spell_queue_window):
            return self.cast("target虚空之刃")

        print(
            f"饥渴斩击是否可用：{hungering_slash_exists}，是否已冷却{ctx.spell_cooldown_ready("饥渴斩击", spell_queue_window)}"
        )
        #  and ctx.spell_cooldown_ready("饥渴斩击", spell_queue_window)
        if hungering_slash_exists:
            # print("施放饥渴斩击")
            return self.cast("target饥渴斩击")

        if voidstep_exists and ctx.spell_cooldown_ready("复仇回避", spell_queue_window):
            return self.cast("复仇回避")

        # ── 常态：泄能打虚空射线（怒气溢出保护）──────────────────────
        if (
            not player_need_specific_spell_stop
            and fury >= fury_overflow_threshold
            and not player.isMoving
            and target.isInRangedRange
            and ctx.spell_cooldown_ready("虚空射线", spell_queue_window)
        ):
            # 射线前同样先检查是否需要打根除
            if ctx.spell_cooldown_ready("根除", spell_queue_window):
                if scattered_souls_fragments_count >= 8 or moment_of_craving_exists:
                    return self.cast("target根除")
            return self.cast("虚空射线")

        # ── 常态：高怒气 + 足够地面魂 → 收割/根除 ───────────────────
        if fury >= 68 and scattered_souls_fragments_count >= 4:
            # 优先根除（有噬欲时刻时）
            if (
                moment_of_craving_exists
                and ctx.spell_cooldown_ready("根除", spell_queue_window)
                and scattered_souls_fragments_count >= 8
            ):
                return self.cast("target根除")
            # 没有噬欲时刻时考虑根除
            if not moment_of_craving_exists and ctx.spell_cooldown_ready(
                "收割", spell_queue_window
            ):
                return self.cast("target收割")

        # ── 常态：献祭强制条件 ────────────────────────────────────────
        if ctx.spell_cooldown_ready("灵魂献祭", spell_queue_window):
            if (
                soul_fragments <= 32
                and fury <= 75
                and ctx.spell_charges_ready("灵魂献祭", 2, spell_queue_window)
                # and scattered_souls_fragments_count <= 6
            ):
                return self.cast("灵魂献祭")

        # ── 常态：根除强制条件 ────────────────────────────────────────
        # 地上 >= 8 魂，或噬欲时刻快消失，或目标低血量执行
        if ctx.spell_cooldown_ready("根除", spell_queue_window):
            if (
                (scattered_souls_fragments_count >= 8 and fury >= 48)
                or (moment_of_craving_exists and 0 < moment_of_craving_remaining <= 1)
                or main_target.healthPercent < reaper_health_threshold
            ):
                return self.cast("target根除")

        # ── 常态：吞噬作为填充技能 ────────────────────────────────────
        if ctx.spell_cooldown_ready("吞噬", spell_queue_window):
            if main_target is focus:
                return self.cast("focus吞噬")
            elif main_target is target:
                return self.cast("target吞噬")
            elif player.enemyCount >= 1:
                return self.cast("就近吞噬")

        return self.idle("当前没有合适动作")
