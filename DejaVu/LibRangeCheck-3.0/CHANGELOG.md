# Lib: RangeCheck-3.0

## [1.0.17](https://github.com/WeakAuras/LibRangeCheck-3.0/tree/1.0.17) (2024-08-25)
[Full Changelog](https://github.com/WeakAuras/LibRangeCheck-3.0/compare/1.0.16...1.0.17) [Previous Releases](https://github.com/WeakAuras/LibRangeCheck-3.0/releases)

- Hero Talent spell overrides don't check range.  
    Living Flame, Smite and Lightning Bolt can be temporarily replaced by an override spell, rendering the spell useless for range checks.  
    This adds "fallback" spells with a higher priority which will be picked instead.  
    Emerald Blossom is available and unmodified for Pres and Aug Evoker.  
    Mind Blast is available for Disc Priest, where the override happens and no SW:P is available.  
    Earth Shock and Elemental blast share the same choice node and act as a replacement for Lightning Bold in this case for Elemental Shaman.  
- Offspec spells won't work either. (#33)  
    * Offspec spells won't work either.  
    This covers unlearned spells from off-specs which appear in the spellbook.  
- Remove "Future Spells" from available checks. (#32)  
    * Remove "Future Spells" from available checks.  
    With 11.0.2.56196 unlearned spells don't work anymore with `C\_Spell.IsSpellInRange`, similar to how `C\_SpellBook.IsSpellBookItemInRange` works.  