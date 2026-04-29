# Rotation Config Patterns

Use this reference after reading `SKILL.md`. It distills the repo's existing examples into a mirrored checklist for DejaVu and Terminal work.

## Example Set

Read these examples together, not in isolation:

- `DejaVu/DejaVu_Druid/Restoration`
- `DejaVu/DejaVu_Druid/Guardian`
- `DejaVu/DejaVu_DeathKnight/Blood`
- `DejaVu/DejaVu_Priest/Discipline`
- `DejaVu/DejaVu_DemonHunter/Devourer`
- `Terminal/terminal/rotation/DruidRestoration.py`
- `Terminal/terminal/rotation/DruidGuardian.py`
- `Terminal/terminal/rotation/DeathKnightBlood.py`

The important pattern is not "copy one file". It is "keep both sides aligned".

## Shared Cell Map

### `spec`

| Index | Coordinate | Terminal read |
| --- | --- | --- |
| 0 | `(55, 13)` | `ctx.spec.cell(0)` |
| 1 | `(56, 13)` | `ctx.spec.cell(1)` |
| 2 | `(57, 13)` | `ctx.spec.cell(2)` |
| 3 | `(58, 13)` | `ctx.spec.cell(3)` |
| 4 | `(59, 13)` | `ctx.spec.cell(4)` |
| 5 | `(60, 13)` | `ctx.spec.cell(5)` |
| 6 | `(61, 13)` | `ctx.spec.cell(6)` |
| 7 | `(62, 13)` | `ctx.spec.cell(7)` |
| 8 | `(63, 13)` | `ctx.spec.cell(8)` |
| 9 | `(64, 13)` | `ctx.spec.cell(9)` |
| 10 | `(65, 13)` | `ctx.spec.cell(10)` |
| 11 | `(66, 13)` | `ctx.spec.cell(11)` |
| 12 | `(67, 13)` | `ctx.spec.cell(12)` |
| 13 | `(68, 13)` | `ctx.spec.cell(13)` |

### `setting`

| Index | Coordinate | Terminal read |
| --- | --- | --- |
| 0 | `(55, 12)` | `ctx.setting.cell(0)` |
| 1 | `(56, 12)` | `ctx.setting.cell(1)` |
| 2 | `(57, 12)` | `ctx.setting.cell(2)` |
| 3 | `(58, 12)` | `ctx.setting.cell(3)` |
| 4 | `(59, 12)` | `ctx.setting.cell(4)` |
| 5 | `(60, 12)` | `ctx.setting.cell(5)` |
| 6 | `(61, 12)` | `ctx.setting.cell(6)` |
| 7 | `(62, 12)` | `ctx.setting.cell(7)` |
| 8 | `(63, 12)` | `ctx.setting.cell(8)` |
| 9 | `(64, 12)` | `ctx.setting.cell(9)` |
| 10 | `(65, 12)` | `ctx.setting.cell(10)` |
| 11 | `(66, 12)` | `ctx.setting.cell(11)` |
| 12 | `(67, 12)` | `ctx.setting.cell(12)` |
| 13 | `(68, 12)` | `ctx.setting.cell(13)` |

Terminal decodes these through:

- `matrix.readCellList(55, 13, 14)` for `spec`
- `matrix.readCellList(55, 12, 14)` for `setting`

That extractor contract already exists. Do not redefine it from `rotation/`.

## DejaVu Side Pattern

## `Global.lua`

- Guard the class first.
- Disable the addon if the class is wrong.
- Return immediately if the spec is wrong.
- Set default `DejaVu.RangedRange` and `DejaVu.MeleeRange` when the spec examples do.

## `Spell.lua`

- Add every skill the rotation reads by name.
- Put charge-based skills into `DejaVu.chargeSpells`.
- Put non-charge skills into `DejaVu.cooldownSpells`.
- If the rotation depends on charges and you only register the cooldown spell, Terminal will read the wrong shape.

## `Spec.lua`

- Use `After(2, function() ... end)`.
- Create an `eventFrame` if the value needs timed refresh.
- Use plain `Cell:New(x, 13)`.
- Follow the local comment style:
  - cell creation gets the 3-line location/purpose/update comment
  - update functions get the 3-line description/event/timer comment
- Common examples:
  - combo points encoded as `power * 51 / 255`
  - ready runes encoded as `readyRunes * 10 / 255`

## `Config.lua`

- Each setting lives in its own `do ... end`.
- Typical shape:
  - create `Config("key")`
  - `insert(ConfigRows, { ... })`
  - `After(2, function() ... end)`
  - create matching `Cell:New(x, 12)`
  - define callback encoder
  - register callback
  - execute initial callback with current value
- Use business names in the key and comments. Do not create anonymous numeric settings.

## `Macro.lua`

- Build `macroList`.
- Create secure action buttons with `CreateFrame`.
- Set `"type"` to `"macro"`.
- Set `"macrotext"` and bind via `SetOverrideBindingClick`.
- Macro `title` is the public contract that Terminal mirrors in `self.macroTable`.

## Terminal Side Pattern

## File Shape

- Keep one rotation class per file.
- Inherit from `BaseRotation`.
- Define `name`, `desc`, and `self.macroTable`.
- Decode cells early in `main_rotation`.
- Give every decoded slot a default value.
- Then run the business logic.

## Macro Mapping

- Mirror DejaVu macro titles exactly.
- The macro key string in `self.cast(...)` must also exist in `self.macroTable`.
- If Lua title and Python key drift, the rotation will return casts that cannot be sent.

## Common Decode Patterns

| DejaVu encode | Terminal decode | Typical use |
| --- | --- | --- |
| `value / 255` | `cell.mean` or `int(cell.mean)` | raw slider values |
| `value * 10 / 255` | `round(cell.mean / 10)` or `int(cell.mean / 10)` | enemy count, rune count |
| `value * 20 / 255` | `round(cell.mean / 20)` or `int(cell.mean / 20)` | stack or count thresholds |
| `255 / 255` vs `127 / 255` | `mean >= 200 ? mode_a : mode_b` | two-state combo |
| `255 / 255` vs `127 / 255` vs `0 / 255` | `mean > 200`, `mean > 100`, else | three-state combo |

If you choose a different mapping, document both sides before coding.

## Worked Example

Use one mirrored example as the sanity check before inventing a new mapping.

### Two-state setting

DejaVu side:

```lua
local interrupt_logic = Config("guardian_interrupt_logic")

local function set_guardian_interrupt_logic(value)
    if value == "blacklist" then
        guardian_interrupt_logic_cell:setCellRGBA(255 / 255)
    else
        guardian_interrupt_logic_cell:setCellRGBA(127 / 255)
    end
end
```

Terminal side:

```python
guardian_interrupt_logic_cell = ctx.setting.cell(7)
if guardian_interrupt_logic_cell is None:
    interrupt_logic = "blacklist"
else:
    interrupt_logic = "blacklist" if guardian_interrupt_logic_cell.mean >= 200 else "any"
```

This is the baseline pattern for a 2-state combo setting:

- DejaVu writes one of two stable brightness levels.
- Terminal decodes by threshold, not by exact float equality.
- Both sides define the same default.

### Count-like spec value

DejaVu side:

```lua
local readyRunes = 0
cells.ReadyRunes:setCellRGBA(readyRunes * 10 / 255)
```

Terminal side:

```python
runes_cell = ctx.spec.cell(0)
if runes_cell is None:
    runes = 1
else:
    runes = int(runes_cell.mean / 10)
```

This is the baseline pattern for count-like spec attributes:

- choose an explicit scale factor
- decode with the inverse math
- set a business default if the cell is absent

## Mirrored Checklist

For each new business attribute or setting, confirm all of these:

| Item | DejaVu | Terminal |
| --- | --- | --- |
| Class/spec gate | `Global.lua` | n/a |
| Spell registration | `Spell.lua` | reads via `ctx.spell_*` |
| Spec cell | `Spec.lua` | `ctx.spec.cell(index)` |
| Setting cell | `Config.lua` | `ctx.setting.cell(index)` |
| Macro | `Macro.lua` | `self.macroTable` and `self.cast(...)` |
| Default value | callback init | decode fallback |

Missing any one of these is the common cause of broken mirrored behavior.

## Failure Patterns to Catch Early

- Missing `chargeSpells` entry for a charge-based skill.
- `Config.lua` uses index `n` but Python still reads the old meaning from `ctx.setting.cell(n)`.
- `Macro.lua` title says one thing and `macroTable` key says another.
- `Spec.lua` or `Config.lua` uses `BadgeCell` or `MegaCell` in the reserved cell rows.
- Python decodes combo brightness with the wrong threshold band.
- The task only needed `rotation/`, but the implementation started changing `context/` or `pixelcalc/`.

## Minimal Authoring Template

Use this template when freezing a new slot map before coding:

| Area | Index | Coord | Name | DejaVu encode | Python decode | Default |
| --- | --- | --- | --- | --- | --- | --- |
| `setting` | 0 | `(55, 12)` | `example_threshold` | `value / 255` | `int(cell.mean)` | `50` |
| `setting` | 1 | `(56, 12)` | `example_mode` | `255/127/0` | `>200 / >100 / else` | `"manual"` |
| `spec` | 0 | `(55, 13)` | `example_resource` | `value * 10 / 255` | `int(cell.mean / 10)` | `0` |

Do this on paper first. Then implement.
