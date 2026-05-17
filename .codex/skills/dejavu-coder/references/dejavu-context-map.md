# DejaVu Context Map

Load the fixed base set first:

- `AGENTS.md`
- `.context/README.md`
- `.context/Common/01_shared_protocol.md`
- `.context/Common/03_color_conventions.md`
- `.context/DejaVu/README.md`
- `.context/DejaVu/00_project_overview.md`
- `.context/DejaVu/04_dev_rules.md`

Then load only the task-specific docs that match the work:

- Combat data, health, power, cooldowns, casts, auras, threat, identity:
  - `.context/DejaVu/00_secret_values.md`
  - `.context/DejaVu/06_wow_api_query_playbook.md`
  - `.context/DejaVu/07_secret_values_api_checklist.md`
- API replacement, namespace migration, deprecated interfaces:
  - `.context/DejaVu/01_api_migration.md`
- Frame, event, widget, mixin, layout, scroll, callback wiring:
  - `.context/DejaVu/02_ui_events.md`
- Module placement, architecture, SavedVariables, config ownership:
  - `.context/DejaVu/03_architecture_and_data.md`
- Fast routing when you only need to decide where code belongs:
  - `.context/DejaVu/05_dejavu_quick_reference.md`
- Display-first implementations, percent APIs, duration objects, visual state mapping:
  - `.context/DejaVu/08_display_first_patterns.md`
- Personal event ordering, instance comments, update-function comments:
  - `.context/DejaVu/09_personal_style_cell_event_comments.md`

Load both the map and the source docs. This file is only a router, not the source of truth.
