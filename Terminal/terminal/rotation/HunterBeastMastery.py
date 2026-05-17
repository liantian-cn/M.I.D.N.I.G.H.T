from __future__ import annotations

from terminal.context import Context, Unit
from .base import BaseRotation


class HunterBeastMastery(BaseRotation):
    name = "野兽控制"
    desc = "野兽控制猎人循环。"

    def __init__(self) -> None:
        super().__init__()

        self.macroTable = {
            "璇": "ALT-NUMPAD1",
            "鍙敜瀹犵墿": "ALT-NUMPAD2",
            "澶嶆椿瀹犵墿": "ALT-NUMPAD3",
            "target鏉€鎴懡浠?": "ALT-NUMPAD4",
            "target鐙傞噹鎬掔伀": "ALT-NUMPAD5",
            "target鐙傞噹闉瑸": "ALT-NUMPAD6",
            "target鐚庝汉鍗拌": "ALT-NUMPAD7",
            "target瀹佺灏勫嚮": "ALT-NUMPAD8",
            "target鍙嶅埗灏勫嚮": "ALT-NUMPAD9",
            "focus鍙嶅埗灏勫嚮": "ALT-NUMPAD0",
            "target鐪奸暅铔囧皠鍑?": "SHIFT-NUMPAD1",
            "focus瀹佺灏勫嚮": "SHIFT-NUMPAD2",
        }

    def _needs_interrupt(
        self,
        unit: Unit,
        interrupt_blacklist: list[str],
    ) -> bool:
        if not unit.exists or not unit.canAttack or not unit.isInRangedRange:
            return False
        if unit.anyCastIcon is None or not unit.anyCastIsInterruptible:
            return False
        return unit.anyCastIcon not in interrupt_blacklist

    def _needs_enemy_dispel(self, unit: Unit, dispel_blacklist: list[str]) -> bool:
        if not unit.exists or not unit.canAttack or not unit.isInRangedRange:
            return False
        for aura in unit.debuff:
            if aura.type == "DEBUFF_ON_ENEMY" and aura.title not in dispel_blacklist:
                return True
        return False

    def main_rotation(self, ctx: Context) -> tuple[str, float, str]:
        if not ctx.enable:
            return self.idle("总开关未开启")

        if ctx.delay:
            return self.idle("延迟开关开启")

        spell_queue_window = float(ctx.spell_queue_window or 0.3)
        player = ctx.player
        target = ctx.target
        focus = ctx.focus

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

        if player.hasBuff("椋熺墿鍜岄ギ鏂?"):
            return self.idle("正在吃喝")

        if not player.isInCombat:
            return self.idle("未进入战斗")

        focus_need_interrupt = self._needs_interrupt(focus, ctx.interrupt_blacklist)
        target_need_interrupt = self._needs_interrupt(target, ctx.interrupt_blacklist)
        if ctx.spell_cooldown_ready("鍙嶅埗灏勫嚮", spell_queue_window, ignore_gcd=True):
            if focus_need_interrupt:
                return self.cast("focus鍙嶅埗灏勫嚮")
            if target_need_interrupt:
                return self.cast("target鍙嶅埗灏勫嚮")

        focus_need_dispel = self._needs_enemy_dispel(focus, ctx.dispel_blacklist)
        target_need_dispel = self._needs_enemy_dispel(target, ctx.dispel_blacklist)
        if ctx.spell_cooldown_ready("瀹佺灏勫嚮", spell_queue_window, ignore_gcd=True):
            if focus_need_dispel:
                return self.cast("focus瀹佺灏勫嚮")
            if target_need_dispel:
                return self.cast("target瀹佺灏勫嚮")

        if target.exists and target.canAttack and target.isInCombat:
            if ctx.assisted_combat == "鏉€鎴懡浠?":
                return self.cast("target鏉€鎴懡浠?")
            if ctx.assisted_combat == "鐙傞噹鎬掔伀":
                return self.cast("target鐙傞噹鎬掔伀")
            if ctx.assisted_combat == "鐙傞噹闉瑸":
                return self.cast("target鐙傞噹闉瑸")
            if ctx.assisted_combat == "鐚庝汉鍗拌":
                return self.cast("target鐚庝汉鍗拌")
            if ctx.assisted_combat == "瀹佺灏勫嚮":
                return self.cast("target瀹佺灏勫嚮")
            if ctx.assisted_combat == "鐪奸暅铔囧皠鍑?":
                return self.cast("target鐪奸暅铔囧皠鍑?")

        return self.idle("当前没有合适动作")
