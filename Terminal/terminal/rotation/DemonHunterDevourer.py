"""
35魂
天赋：CgcBG5bbocFKcv+yIq8fPd6ORBA2mxMzMzMzMGzMAAAAAAAMmtBDAAAAAAAAmxMMzMzMzMzMzYmNzYsolFmZmZ2abmZGADDABMGMmB
"""

from datetime import datetime

from terminal.context import Context
from .base import BaseRotation


class DemonHunterDevourer(BaseRotation):
    name = "35魂噬灭歼灭者DH"
    desc = "目前只适配歼灭者"

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
            "鲁莽药水": "SHIFT-NUMPAD3",
            "停止施法": "SHIFT-NUMPAD4",
            "治疗石": "SHIFT-NUMPAD5",
            "强效治疗药水": "SHIFT-NUMPAD6",
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

        # AOE敌人数量阈值 min:2 max:10 default:4 step:1
        aoe_enemy_count_cell = ctx.setting.cell(5)
        aoe_enemy_count = (
            4 if aoe_enemy_count_cell is None else round(aoe_enemy_count_cell.mean / 10)
        )

        # 灵魂碎片（玩家身上）
        soul_fragments_cell = ctx.spec.cell(0)
        soul_fragments = (
            0 if soul_fragments_cell is None else int(soul_fragments_cell.mean / 5)
        )

        # 获取恶魔之怒最大值，默认120，恶魔之怒是根据这个值来计算的。因为不同版本恶魔之怒的最大值可能不同，所以让用户自己设置这个值。
        fury_max_cell = ctx.setting.cell(0)
        fury_max = 120
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

        # 躺平模式（turn_on / turn_off）
        lying_flat_mode_cell = ctx.setting.cell(0)
        lying_flat_mode = (
            "turn_off"
            if lying_flat_mode_cell is None or lying_flat_mode_cell.mean >= 200
            else "turn_on"
        )

        # 开启保命血量阈值（默认60%）
        dh_health_threshold_cell = ctx.setting.cell(2)
        dh_health_threshold = (
            60
            if dh_health_threshold_cell is None
            else int(dh_health_threshold_cell.mean)
        )

        # 虚空变形阈值（常态，默认35）
        void_metamorphosis_threshold_cell = ctx.setting.cell(3)
        void_metamorphosis_threshold = (
            35
            if void_metamorphosis_threshold_cell is None
            else int(void_metamorphosis_threshold_cell.mean)
        )

        # 技能队列窗口，施法中剩余时间小于这个值就算技能快要好了，可以提前衔接施放下一个技能，单位是秒
        # 施法保护阈值，剩余施法时间低于此值时不打断当前施法，单位百分比。设为 90 意味着始终等待施法完成（任何技能施法时间都远小于此值）
        cast_queue_window_threshold = 90
        # 引导保护阈值，剩余引导时间低于此值时不打断当前引导，单位是百分比。设为 90 意味着始终等待引导完成
        channel_queue_window_threshold = 90

        # ── 基础状态检查 ────────────────────────────────────────────

        if not player.alive:
            return self.idle("玩家已死亡")

        if player.isChatInputActive:
            return self.idle("正在聊天输入")

        if player.isMounted:
            return self.idle("骑乘中")

        if player.castIcon is not None:
            if (
                player.castDuration is None
                or player.castDuration < cast_queue_window_threshold
            ):
                return self.idle("正在施法")

        if player.channelIcon is not None:
            if (
                player.channelDuration is None
                or player.channelDuration < channel_queue_window_threshold
            ):
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

        # if main_target is None:
        #     return self.idle("没有合适的目标")

        # ── AOE判断 ─────────────────────────────────────────────────
        is_aoe = player.enemyCount >= aoe_enemy_count

        # ── Buff/状态读取 ───────────────────────────────────────────

        # 疾影
        phase_shift_buff_exists = player.hasBuff("疾影")

        # 虚落层数
        voidfall_count = player.buffStack("虚落")

        # 地上的灵魂碎片（散落）
        scattered_souls_fragments_count = player.buffStack("灵魂残片")

        # 噬欲时刻
        moment_of_craving_exists = player.hasBuff("噬欲时刻")
        moment_of_craving_remaining = player.buffRemain("噬欲时刻")

        # 坍缩之星（爆发变身标志）
        collapsing_star_exists = player.hasBuff("坍缩之星")

        # 灵魂献祭
        soul_immolation_exists = player.hasBuff("灵魂献祭")

        # ── 保命：献祭 > 治疗石 > 强效治疗药水 ──────────────────────────
        # 优先级：灵魂献祭 > 治疗石 > 强效治疗药水
        # 任意一个可用则使用并跳过后续检查
        if player.healthPercent < dh_health_threshold:
            # 1. 灵魂献祭（应急，忽略常规优先级限制）
            # 灵魂献祭在持续时间内可回复24%最大生命值
            if not soul_immolation_exists and ctx.spell_cooldown_ready(
                "灵魂献祭", spell_queue_window
            ):
                return self.cast("灵魂献祭")

            # 2. 治疗石
            if player.healthstoneCooldownUsable:
                return self.cast("治疗石")

            # 3. 强效治疗药水
            if player.healingPotionCooldownUsable:
                return self.cast("强效治疗药水")

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

        # ── 大范围技能停止施法黑名单检查 ──────────────────────────────

        range_trigger_spell = None
        player_need_specific_spell_stop = False
        if target.exists and target.anyCastIcon in range_spell_stop_list:
            range_trigger_spell = target.anyCastIcon
            player_need_specific_spell_stop = True
        elif focus.exists and focus.anyCastIcon in range_spell_stop_list:
            range_trigger_spell = focus.anyCastIcon
            player_need_specific_spell_stop = True

        # ══════════════════════════════════════════════════════════════
        # 爆发段逻辑（虚空变形内，collapsing_star_exists == True）
        #
        # 变身前30秒（burst_time < 30）：
        #   AOE优先级：坍缩之星 > 根除（噬欲时刻激活 且 地上>=10魂）> 虚空射线 > 吞噬
        #   单体优先级：虚空射线（最高）> 坍缩之星 > 根除（噬欲时刻激活 且 地上>=10魂）> 吞噬
        #
        # 变身后30秒（burst_time >= 30）：
        #   单体：根除（虚空射线好了+噬欲时刻）> 接虚空射线 > 坍缩之星（地上>=10+身上>=36或怒气<50）> 吞噬
        #   AOE：坍缩之星 > 根除（虚空射线好了+噬欲时刻）> 虚空射线 > 吞噬
        #
        # 躺平模式额外逻辑：
        #   - 不释放坍缩之星和根除
        #   - 仅用虚空射线和吞噬堆碎片
        #   - 身上>=10魂 且 地上>=10魂后停手，等待变身自然结束
        # ══════════════════════════════════════════════════════════════
        if collapsing_star_exists:

            # ── 躺平模式：变身中停止坍缩之星和根除，堆碎片等退出变身 ────
            if lying_flat_mode == "turn_on":
                # 身上和地上各>=10魂后停手，等待变身自然结束
                if soul_fragments >= 10 and scattered_souls_fragments_count >= 10:
                    return self.idle("躺平模式：碎片已就绪，等待退出变身")

                # 仅使用虚空射线和吞噬来堆碎片
                if (
                    not player_need_specific_spell_stop
                    and not player.isMoving
                    and target.isInRangedRange
                    and ctx.spell_cooldown_ready("虚空射线", spell_queue_window)
                ):
                    return self.cast("虚空射线")

                if ctx.spell_cooldown_ready("吞噬", spell_queue_window):
                    if main_target is focus:
                        return self.cast("focus吞噬")
                    elif main_target is target:
                        return self.cast("target吞噬")
                    elif player.enemyCount >= 1:
                        return self.cast("就近吞噬")

                return self.idle("躺平模式：爆发中堆碎片，等待CD")

            # ── 正常爆发逻辑 ────────────────────────────────────────────

            # 变身内已持续时间（秒）
            burst_time = float(ctx.burst_time or 0)
            burst_phase_late = burst_time >= 30  # True = 变身30秒后

            # 预先计算各技能是否就绪
            star_ready = (
                not player_need_specific_spell_stop
                and not player.isMoving
                # and soul_fragments >= 30
                and ctx.spell_cooldown_ready("坍缩之星", spell_queue_window)
            )
            void_ray_ready = (
                not player_need_specific_spell_stop
                and not player.isMoving
                and target.isInRangedRange
                and ctx.spell_cooldown_ready("虚空射线", spell_queue_window)
            )
            eradication_craving_ready = (
                moment_of_craving_exists
                and scattered_souls_fragments_count >= 10
                and (
                    (latest_succeeded_cast == "坍缩之星")
                    or (20 <= soul_fragments and fury <= 50)
                )
                and ctx.spell_cooldown_ready("根除", spell_queue_window)
            )  # 坍缩之后秒根除可以强行打断根除的前摇，食欲时刻剩3-2秒的时候打坍缩后秒接根除收益最好

            # 虚空变形后紧接着使用"鲁莽药水"
            if (
                latest_succeeded_cast == "虚空变形"
                and player.burstPotionCooldownUsable
                and ctx.gcd_ready(spell_queue_window)
                and player.enemyCount >= 6
            ):
                return self.cast("鲁莽药水")

            # ── 变身前30秒：原版逻辑 ─────────────────────────────────────
            if not burst_phase_late:
                # 单体：虚空射线（最高优先）> 坍缩之星 > 根除 > 吞噬
                if not is_aoe:
                    # 1. 虚空射线（单体最高优先）
                    if void_ray_ready:
                        return self.cast("虚空射线")

                    # 2. 坍缩之星
                    if star_ready:
                        return self.cast("target坍缩之星")

                    # 3. 根除（噬欲时刻激活 且 地上>=10魂）
                    if eradication_craving_ready:
                        return self.cast("target根除")

                    # 4. 吞噬
                    if ctx.spell_cooldown_ready("吞噬", spell_queue_window):
                        if main_target is focus:
                            return self.cast("focus吞噬")
                        elif main_target is target:
                            return self.cast("target吞噬")
                        elif player.enemyCount >= 1:
                            return self.cast("就近吞噬")

                # AOE：坍缩之星 > 根除 > 虚空射线 > 吞噬
                else:
                    # 1. 坍缩之星
                    if star_ready:
                        return self.cast("target坍缩之星")

                    # 2. 根除（噬欲时刻激活 且 地上>=10魂）
                    if eradication_craving_ready:
                        return self.cast("target根除")

                    # 3. 虚空射线
                    if void_ray_ready:
                        return self.cast("虚空射线")

                    # 4. 吞噬
                    if ctx.spell_cooldown_ready("吞噬", spell_queue_window):
                        if main_target is focus:
                            return self.cast("focus吞噬")
                        elif main_target is target:
                            return self.cast("target吞噬")
                        elif player.enemyCount >= 1:
                            return self.cast("就近吞噬")

            # ── 变身后30秒：根除（触发虚空射线连打） > 坍缩之星 > 虚空射线 > 吞噬
            else:
                # 变身后30秒坍缩之星就绪判断：
                #   非AOE：地上>=10魂 且 身上>=36魂，或恶魔之怒<50时强制使用
                #   AOE：无限制
                _star_base_late = (
                    not player_need_specific_spell_stop
                    and not player.isMoving
                    and ctx.spell_cooldown_ready("坍缩之星", spell_queue_window)
                )
                if is_aoe:
                    star_ready_late = _star_base_late
                else:
                    star_soul_condition = (
                        scattered_souls_fragments_count >= 10 and soul_fragments >= 36
                    )
                    star_fury_emergency = fury < 50
                    star_ready_late = _star_base_late and (
                        star_soul_condition or star_fury_emergency
                    )

                # 变身后30秒根除就绪判断：虚空射线好了 且 有噬欲时刻
                eradication_ready_late = (
                    ctx.spell_cooldown_ready("根除", spell_queue_window)
                    and moment_of_craving_exists
                    and void_ray_ready
                )

                if not is_aoe:
                    # 单体：先根除再虚空射线 > 坍缩之星 > 吞噬
                    if eradication_ready_late:
                        return self.cast("target根除")

                    # 根除后立即接虚空射线
                    if latest_succeeded_cast == "根除" and void_ray_ready:
                        return self.cast("虚空射线")

                    if star_ready_late:
                        return self.cast("target坍缩之星")

                    if ctx.spell_cooldown_ready("吞噬", spell_queue_window):
                        if main_target is focus:
                            return self.cast("focus吞噬")
                        elif main_target is target:
                            return self.cast("target吞噬")
                        elif player.enemyCount >= 1:
                            return self.cast("就近吞噬")
                else:
                    # AOE：坍缩之星 > 根除 > 虚空射线 > 吞噬
                    if star_ready_late:
                        return self.cast("target坍缩之星")

                    if eradication_ready_late:
                        return self.cast("target根除")

                    if void_ray_ready:
                        return self.cast("虚空射线")

                    if ctx.spell_cooldown_ready("吞噬", spell_queue_window):
                        if main_target is focus:
                            return self.cast("focus吞噬")
                        elif main_target is target:
                            return self.cast("target吞噬")
                        elif player.enemyCount >= 1:
                            return self.cast("就近吞噬")

            return self.idle("爆发中：等待CD")

        # ══════════════════════════════════════════════════════════════
        # 常态段逻辑（虚空变形外，collapsing_star_exists == False）
        #
        # 优先级：
        #   1. 收割/根除 - 如果已经拥有3层虚落
        #   2. 虚空变形  - 如虚空变形可用
        #   3. 根除      - 噬欲时刻激活 且 地上>=10魂
        #   4. 虚空射线
        #   5. 灵魂献祭  - 如果未激活（理想情况下仅在变身外使用）
        #   6. 吞噬
        #   7. 收割      - 地上>=4魂 且 本次收割可触发虚空变形
        # ══════════════════════════════════════════════════════════════

        # ── 1. 收割/根除：已拥有3层虚落 ────────────────────────────────
        if voidfall_count >= 3:
            # 优先根除（若噬欲时刻激活且地上>=10魂）
            if (
                moment_of_craving_exists
                and scattered_souls_fragments_count >= 10
                and ctx.spell_cooldown_ready("根除", spell_queue_window)
            ):
                return self.cast("target根除")
            # 否则施放收割
            if ctx.spell_cooldown_ready("收割", spell_queue_window):
                return self.cast("target收割")

        # ── 2. 虚空变形：怪物血量充足且可用时立即触发（躺平模式下跳过）────
        if (
            lying_flat_mode == "turn_off"
            and ctx.spell_cooldown_ready("虚空变形", spell_queue_window)
            and main_target.healthPercent > reaper_health_threshold
            and not player.isMoving
        ):
            return self.cast("虚空变形")

        # ── 3. 根除：噬欲时刻激活 且 地上>=10魂 ───────────────────────
        if (
            moment_of_craving_exists
            and scattered_souls_fragments_count >= 10
            and ctx.spell_cooldown_ready("根除", spell_queue_window)
        ):
            return self.cast("target根除")

        # ── 4. 虚空射线 ──────────────────────────────────────────────
        if (
            not player_need_specific_spell_stop
            and not player.isMoving
            and fury >= 100
            and target.isInRangedRange
            and ctx.spell_cooldown_ready("虚空射线", spell_queue_window)
        ):
            return self.cast("虚空射线")

        # ── 5. 灵魂献祭：未激活时使用（理想情况下仅在变身外使用）────────
        # 注意：灵魂献祭在持续时间内可回复24%最大生命值，应急时可忽略此优先级限制
        if not soul_immolation_exists and ctx.spell_cooldown_ready(
            "灵魂献祭", spell_queue_window
        ):
            return self.cast("灵魂献祭")

        # ── 6. 吞噬：主要填充技能 ────────────────────────────────────
        if ctx.spell_cooldown_ready("吞噬", spell_queue_window):
            if main_target is focus:
                return self.cast("focus吞噬")
            elif main_target is target:
                return self.cast("target吞噬")
            elif player.enemyCount >= 1:
                return self.cast("就近吞噬")

        # # ── 7. 收割：地上>=4魂 且 本次收割可触发虚空变形 ───────────────
        # # （用于为下次爆发蓄势）
        # if (
        #     scattered_souls_fragments_count >= 4
        #     and soul_fragments >= 31
        #     and ctx.spell_cooldown_ready("收割", spell_queue_window)
        # ):
        #     return self.cast("target收割")

        return self.idle("当前没有合适动作")
