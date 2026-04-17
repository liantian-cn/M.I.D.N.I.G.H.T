# Full Rotation Patterns

Use this reference after the user has supplied a complete spec. It summarizes the repo's existing full rotation structure so the final code matches local style.

## Scope Of A Complete Rotation

A complete rotation in this repo is not just `Terminal/terminal/rotation/<Spec>.py`.

It includes:

- `DejaVu/DejaVu_<Spec>/Global.lua`
- `DejaVu/DejaVu_<Spec>/Spec.lua`
- `DejaVu/DejaVu_<Spec>/Spell.lua`
- `DejaVu/DejaVu_<Spec>/Config.lua`
- `DejaVu/DejaVu_<Spec>/Macro.lua`
- `Terminal/terminal/rotation/<Spec>.py`

If any one of these is missing, the build is incomplete.

## Existing Full Rotation Shapes

### `DeathKnightBlood`

- single-file Terminal rotation with direct config decoding near the top of `main_rotation`
- clear guard chain
- melee main-target model
- explicit interrupt branch
- explicit survival branch
- explicit resource and buff handling
- explicit filler branch

### `DruidGuardian`

- same direct decode pattern as Blood DK
- uses setting-controlled modes such as interrupt logic, incarnation logic, ironfur logic
- mixes opener, survival, interrupt, aoe, and filler sections in a readable policy order

### `DruidRestoration`

- heavier business model
- uses helper methods for config reading and party scoring because the rotation needs derived metrics
- still keeps the final `main_rotation` readable as policy
- proves that helper methods are acceptable only when they preserve business readability

## DejaVu Side Responsibilities

## `Global.lua`

- class/spec gate
- addon disable on wrong class
- immediate return on wrong spec
- set base ranges when needed

## `Spell.lua`

- register everything Terminal reads by name
- split `cooldownSpells` and `chargeSpells`

## `Spec.lua`

- encode spec-only business state into `y=13`
- use only `Cell`
- keep comment style and update rhythm aligned with repo examples

## `Config.lua`

- encode user settings into `y=12`
- one business setting per `do ... end` block
- callback registration plus initial callback execution

## `Macro.lua`

- macro titles are the public contract
- titles must be mirrored verbatim by Terminal `macroTable`

## Terminal Side Responsibilities

## Base Skeleton

The standard shape is:

1. class metadata
2. `self.macroTable`
3. optional helper methods if the business model needs them
4. `main_rotation(ctx)`

## Guard Chain

The first major section usually contains these checks in some spec-specific order:

- `ctx.enable`
- `ctx.delay`
- `player.alive`
- `player.isChatInputActive`
- `player.isMounted`
- `player.castIcon`
- `player.channelIcon`
- `player.isEmpowering`
- `player.hasBuff("食物和饮料")`
- combat requirement
- form requirement
- target availability

If the user wants a different guard chain, they must say so explicitly.

## Decode Strategy

Two common patterns exist:

### Inline decode at top of `main_rotation`

Used by:

- `DeathKnightBlood.py`
- `DruidGuardian.py`

Best when:

- config count is moderate
- no large derived model is needed before the guard chain

### Helper methods before `main_rotation`

Used by:

- `DruidRestoration.py`

Best when:

- the rotation needs derived business objects
- several settings map onto instance fields
- the spec needs a scoring model or target ranking model

Do not invent helper methods unless the user-supplied spec actually requires them.

## Main Target Model

The existing examples show that target policy is a first-class part of the rotation contract.

Common questions that must be answered by user input:

- is `focus` preferred over `target`
- is `mouseover` only used for special casts
- is `nearest` a fallback or a core cast mode
- does the spec require melee-only or ranged fallback behavior

Never assume these from class familiarity.

## Rotation Phase Order

A typical complete phase order is:

1. guards
2. target resolution
3. emergency survival
4. interrupt or utility
5. opener
6. burst
7. maintenance buffs or debuffs
8. spenders
9. generators
10. filler
11. final `idle`

The user may require a different order. If so, follow the user's order exactly.

## Derived Business Model

Only add derived formulas when the user supplied them.

Examples already present in repo:

- healer party `health_score`
- `hot_count`
- `abundance_stack_limit`
- derived resource from percentage and configured limit
- mode state from brightness threshold

If a formula is not directly given by the user, stop and request it in the template instead of guessing.

## Acceptance Examples Are Mandatory

The existing repo rotations are business scripts, not generic engines. They only become trustworthy when the user provides scenario-based expected actions.

Acceptance examples must cover:

- at least one idle or blocked case
- at least one interrupt case
- at least one survival case
- at least one burst or opener case
- at least one filler case

Without those examples, the skill must not proceed.

## Final Sanity Checklist

Before claiming the rotation is ready, verify all of these are true:

- the DejaVu plugin and Terminal rotation use the same macro titles
- the DejaVu plugin and Terminal rotation use the same slot map
- every Terminal spell check has matching DejaVu registration
- every Terminal config decode has matching DejaVu encode
- every user-specified phase exists in the final rotation
- every user-specified acceptance example can be traced to a concrete branch in the code
