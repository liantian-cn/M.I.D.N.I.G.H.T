from __future__ import annotations

from terminal.context import Context
from .base import BaseRotation

HAND_OF_GULDAN = "古尔丹之手"
IMP = "召唤小鬼"
DREADSTALKERS = "召唤恐惧猎犬"
FELGUARD = "召唤恶魔卫士"
DEMONBOLT = "恶魔之箭"
SHADOW_BOLT = "暗影箭"
IMPLOSION = "内爆"
DOOMGUARD = "召唤末日守卫"
DEMONIC_TYRANT = "召唤恶魔暴君"
GRIMOIRE_FELGUARD = "魔典：邪能破坏者"
DEMON_HEALTHSTONE = "恶魔治疗石"
GREATER_HEALING_POTION = "强效治疗药水"
MORTAL_COIL = "死亡缠绕"
AXE_TOSS = "巨斧投掷"
SPELL_LOCK = "法术封锁"
LANGUAGE_CURSE = "语言灾厄"


DEMON_CORE = "恶魔之核"
WILD_IMP = "野生小鬼"
ARGUS_PORTAL = "阿古斯传送门"
DEMONIC_TYRANT_BUFF = "恶魔暴君"
FOOD_AND_DRINK = "食物和饮料"


class WarlockDemonology(BaseRotation):
    name = "恶魔术灵魂收割者"
    desc = "恶魔学识术士灵魂收割者大秘境循环。"

    def __init__(self) -> None:
        super().__init__()

        self.macroTable = {
            f"target{HAND_OF_GULDAN}": "ALT-NUMPAD1",
            f"focus{SPELL_LOCK}": "ALT-NUMPAD2",
            IMP: "ALT-NUMPAD3",
            f"target{DREADSTALKERS}": "ALT-NUMPAD4",
            FELGUARD: "ALT-NUMPAD5",
            f"target{DEMONBOLT}": "ALT-NUMPAD6",
            f"target{SHADOW_BOLT}": "ALT-NUMPAD7",
            IMPLOSION: "ALT-NUMPAD8",
            f"target{DOOMGUARD}": "ALT-NUMPAD9",
            f"target{DEMONIC_TYRANT}": "ALT-NUMPAD0",
            f"target{GRIMOIRE_FELGUARD}": "SHIFT-NUMPAD1",
            f"focus{AXE_TOSS}": "SHIFT-NUMPAD2",
            f"focus{LANGUAGE_CURSE}": "SHIFT-NUMPAD3",
            f"target{LANGUAGE_CURSE}": "SHIFT-NUMPAD4",
            DEMON_HEALTHSTONE: "SHIFT-NUMPAD5",
            GREATER_HEALING_POTION: "SHIFT-NUMPAD6",
            f"target{SPELL_LOCK}": "SHIFT-NUMPAD7",
            f"target{AXE_TOSS}": "SHIFT-NUMPAD8",
            f"target{MORTAL_COIL}": "SHIFT-NUMPAD9",
        }

    def main_rotation(self, ctx: Context) -> tuple[str, float, str]:
        if not ctx.enable:
            return self.idle("总开关未开启")

        if ctx.delay:
            return self.idle("延迟开关开启")

        spell_queue_window = float(ctx.spell_queue_window or 0.3)
        player = ctx.player
        target = ctx.target
        focus = ctx.focus
        latest_succeeded_cast = ctx.latest_succeeded_cast
        combat_time = float(ctx.combat_time or 0.0)
        interrupt_blacklist = ctx.interrupt_blacklist

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

        if player.hasBuff(FOOD_AND_DRINK):
            return self.idle("正在吃喝")

        if not player.isInCombat:
            return self.idle("未进入战斗")

        if not (target.exists and target.canAttack and target.isInRangedRange):
            return self.idle("没有合适的远程目标")

        soul_shards_cell = ctx.spec.cell(0)
        soul_shards_ratio = (
            0.0 if soul_shards_cell is None else soul_shards_cell.decimal
        )
        soul_shards = round(soul_shards_ratio * 5)
        pet_interrupt_family_cell = ctx.spec.cell(1)
        pet_interrupt_family = "unknown"
        if pet_interrupt_family_cell is not None:
            if pet_interrupt_family_cell.mean >= 200:
                pet_interrupt_family = "felguard"
            elif pet_interrupt_family_cell.mean >= 80:
                pet_interrupt_family = "felhunter"

        burst_mode_cell = ctx.setting.cell(0)
        burst_mode_enabled = (
            False if burst_mode_cell is None else burst_mode_cell.mean < 200
        )

        demon_core_stacks = player.buffStack(DEMON_CORE)
        wild_imp_stacks = player.buffStack(WILD_IMP)

        dreadstalkers_ready = ctx.spell_cooldown_ready(
            DREADSTALKERS, spell_queue_window
        )
        implosion_ready = ctx.spell_cooldown_ready(IMPLOSION, spell_queue_window)
        hand_ready = ctx.spell_cooldown_ready(HAND_OF_GULDAN, spell_queue_window)
        demonbolt_ready = ctx.spell_cooldown_ready(DEMONBOLT, spell_queue_window)
        shadow_bolt_ready = ctx.spell_cooldown_ready(SHADOW_BOLT, spell_queue_window)
        tyrant_ready = ctx.spell_cooldown_ready(DEMONIC_TYRANT, spell_queue_window)
        doomguard_ready = ctx.spell_cooldown_ready(DOOMGUARD, spell_queue_window)
        grimoire_felguard_ready = ctx.spell_cooldown_ready(
            GRIMOIRE_FELGUARD, spell_queue_window
        )

        portal_window = player.hasBuff(ARGUS_PORTAL)
        tyrant_window = player.hasBuff(DEMONIC_TYRANT_BUFF)
        burst_window = portal_window or tyrant_window
        enemy_count = player.enemyCount
        warlock_health_threshold = 60
        tyrant_target_health_threshold = 30

        if player.healthPercent < warlock_health_threshold:
            if ctx.spell_cooldown_ready(MORTAL_COIL, spell_queue_window):
                return self.cast(f"target{MORTAL_COIL}")

            if ctx.spell_cooldown_ready(DEMON_HEALTHSTONE, spell_queue_window):
                return self.cast(DEMON_HEALTHSTONE)

            if ctx.spell_cooldown_ready(GREATER_HEALING_POTION, spell_queue_window):
                return self.cast(GREATER_HEALING_POTION)

        focus_need_interrupt = False
        target_need_interrupt = False

        if focus.exists and focus.canAttack and focus.isInRangedRange:
            if focus.anyCastIcon is not None and focus.anyCastIsInterruptible:
                if focus.anyCastIcon not in interrupt_blacklist:
                    focus_need_interrupt = True

        if target.exists and target.canAttack and target.isInRangedRange:
            if target.anyCastIcon is not None and target.anyCastIsInterruptible:
                if target.anyCastIcon not in interrupt_blacklist:
                    target_need_interrupt = True

        pet_interrupt_spell = None
        if pet_interrupt_family == "felguard":
            pet_interrupt_spell = AXE_TOSS
        elif pet_interrupt_family == "felhunter":
            pet_interrupt_spell = SPELL_LOCK

        if pet_interrupt_spell and ctx.spell_cooldown_ready(
            pet_interrupt_spell, spell_queue_window, ignore_gcd=True
        ):
            if focus_need_interrupt:
                return self.cast(f"focus{pet_interrupt_spell}")
            if target_need_interrupt:
                return self.cast(f"target{pet_interrupt_spell}")

        if ctx.spell_cooldown_ready(
            LANGUAGE_CURSE, spell_queue_window, ignore_gcd=True
        ):
            if focus_need_interrupt:
                return self.cast(f"focus{LANGUAGE_CURSE}")
            if target_need_interrupt:
                return self.cast(f"target{LANGUAGE_CURSE}")

        # 爆发模式预铺：暴君就绪后暂停古手，铺关键召唤物，并把碎片补到暴君后可满 5 片。/cast 119898
        if (
            burst_mode_enabled
            and tyrant_ready
            and not burst_window
            and target.healthPercent > tyrant_target_health_threshold
        ):
            if dreadstalkers_ready:
                return self.cast(f"target{DREADSTALKERS}")

            if doomguard_ready:
                return self.cast(f"target{DOOMGUARD}")

            if grimoire_felguard_ready:
                return self.cast(f"target{GRIMOIRE_FELGUARD}")

            if soul_shards < 2 and shadow_bolt_ready:
                return self.cast(f"target{SHADOW_BOLT}")

            if soul_shards >= 2:
                return self.cast(f"target{DEMONIC_TYRANT}")

            return self.idle("爆发模式预铺：等待暴君前置资源")

        # 传送门期间：围绕古手循环，优先把传送门返片转化成更多古手。
        if burst_window:
            if hand_ready and soul_shards >= 3:
                return self.cast(f"target{HAND_OF_GULDAN}")

            if demonbolt_ready:
                return self.cast(f"target{DEMONBOLT}")

            if shadow_bolt_ready:
                return self.cast(f"target{SHADOW_BOLT}")

            if dreadstalkers_ready and soul_shards >= 2:
                return self.cast(f"target{DREADSTALKERS}")

            if implosion_ready and wild_imp_stacks >= 6:
                return self.cast(IMPLOSION)

            return self.idle("传送门期间：等待古手循环资源")

        # 平稳期：末日守卫用于 4 目标以上，或每次战斗开场直接使用。
        if doomguard_ready and (enemy_count >= 4 or combat_time <= 5):
            return self.cast(f"target{DOOMGUARD}")

        # 平稳期：魔典尽可能留给单体场景使用。
        if grimoire_felguard_ready and enemy_count <= 1:
            return self.cast(f"target{GRIMOIRE_FELGUARD}")

        if dreadstalkers_ready and soul_shards >= 2:
            return self.cast(f"target{DREADSTALKERS}")

        # 平稳期：小狗卡 CD，内爆 6 鬼打，避免碎片和恶魔之核溢出。
        if implosion_ready and wild_imp_stacks >= 6:
            return self.cast(IMPLOSION)

        if hand_ready and soul_shards >= 4:
            return self.cast(f"target{HAND_OF_GULDAN}")

        if demon_core_stacks >= 3 and demonbolt_ready:
            return self.cast(f"target{DEMONBOLT}")

        if hand_ready and soul_shards >= 3 and not dreadstalkers_ready:
            return self.cast(f"target{HAND_OF_GULDAN}")

        if demon_core_stacks >= 1 and demonbolt_ready:
            return self.cast(f"target{DEMONBOLT}")

        if shadow_bolt_ready:
            return self.cast(f"target{SHADOW_BOLT}")

        return self.idle("当前没有合适动作")
