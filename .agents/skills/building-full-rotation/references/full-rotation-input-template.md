# Full Rotation Input Template

The user must fill every section before implementation begins.

```md
# Full Rotation Spec

## 1. Spec Base Info

- class:
- spec:
- DejaVu plugin name:
- Terminal rotation file name:
- short description:

## 2. Skill List

| skill name | purpose | target type | cooldown or charge | notes |
| --- | --- | --- | --- | --- |
|  |  |  |  |  |

## 3. Spell Registration Split

### cooldownSpells

- 

### chargeSpells

- 

## 4. Macro Requirements

| macro title | target type | macro text | keybind | purpose |
| --- | --- | --- | --- | --- |
|  |  |  |  |  |

## 5. Settings

| key | type | default value | min/max or options | purpose |
| --- | --- | --- | --- | --- |
|  |  |  |  |  |

## 6. Spec And Setting Slot Mapping

| area | index | DejaVu coord | business name | Lua encode | Python decode | default |
| --- | --- | --- | --- | --- | --- | --- |
|  |  |  |  |  |  |  |

## 7. Target Selection Rules

- main target priority:
- focus usage:
- mouseover usage:
- nearest target usage:
- ranged vs melee fallback:

## 8. Guard And Idle Rules

- total enable rule:
- delay rule:
- death rule:
- chat rule:
- mount rule:
- casting rule:
- channel rule:
- empowering rule:
- food/drink rule:
- combat requirement:
- extra idle rules:

## 9. Movement And Form Limits

- required form or stance:
- when to shift form:
- movement restricted skills:
- standing-only skills:
- mouse-required skills:

## 10. Rotation Phase Order

List the phases in exact execution order.

1. 
2. 
3. 

## 11. Rotation Rules

Describe the actual business rules in execution order.

### opener

- 

### burst

- 

### interrupt

- 

### survival

- 

### single target

- 

### aoe

- 

### filler

- 

## 12. Priority And Trigger Conditions

| phase | rule name | trigger condition | cast result |
| --- | --- | --- | --- |
|  |  |  |  |

## 13. Buff Debuff Aura Rules

| unit | aura name | type | check | threshold or condition | purpose |
| --- | --- | --- | --- | --- | --- |
|  |  |  |  |  |  |

## 14. Derived Business Formulas

List every derived metric that is not a direct Context field.

| formula name | inputs | formula | purpose |
| --- | --- | --- | --- |
|  |  |  |  |

## 15. Defaults

| name | default value | why |
| --- | --- | --- |
|  |  |  |

## 16. Acceptance Examples

Give at least 5 examples.

| situation | expected action |
| --- | --- |
|  |  |
```

When this template is incomplete, the skill must stop and ask the user to finish it.
