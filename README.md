# SekaiRPG

A 2D turn-based tactical RPG built with **Godot 4.6**, inspired by the Project Sekai universe. Explore story maps, fight on an Action-Value timeline with elemental weaknesses and Break, and climb the Holo-Simulation roguelite tower.

Dialogue and in-game text are in Vietnamese.

## Features

- **Action Value combat** — speed decides turn order; the turn strip at the top of the battle screen shows who acts next.
- **5-element chart and Weakness Break** — hitting an enemy's weakness drains its Break gauge; empty gauge means a stunned turn and a knock-back on the timeline.
- **Story mode** — 10 quests from the prologue ambush to the highway finale, driven by `Quests/` definitions and `Data/storyline/*.json` dialogue.
- **6 playable characters, 12 enemy types**, crits, status effects (Bleed, Poison, Stun), cooldowns and once-per-battle ultimates.
- **Holo-Simulation** — a 10-floor roguelite tower with 8 blessings and two rest stops.
- **Economy** — credits, treasure chests, a vending machine and consumables usable in battle.
- **Sandbox** — pick any team and enemies and fight; also upgrade stats with skill points.
- **Save system** — multiple slots in `user://saves/`, quick save, autosave.
- **Mobile controls** — virtual joystick and buttons on Android (`gl_compatibility` renderer, landscape).

## Running

1. Install [Godot 4.6](https://godotengine.org/download/).
2. Open `project.godot` in the editor and press **F5**.

Controls: arrow keys / WASD to move, Enter or Space to interact and advance dialogue, Esc to pause.

## Tests

Headless unit tests (auto-discovers every `Tests/Unit/Test*.gd`):

```bash
godot --headless --path . res://Tests/TestRunnerScene.tscn
```

Run only some suites by naming them after `--`:

```bash
godot --headless --path . res://Tests/TestRunnerScene.tscn -- TestResources TestCombat
```

`TestResources` loads every script, scene and resource in the project, so it catches parse errors and broken paths even in code the other suites never touch. New tests: add a `func test_*()` to a suite in `Tests/Unit/` (see `BaseTest.gd` for `assert_*` helpers).

Screenshots of UI screens for visual checks (needs a window, not headless):

```bash
godot --path . res://Tests/CaptureScreenshotsScene.tscn -- start_menu battle dialogue
```

Output goes to `screenshots/` (git-ignored). The shot names are listed at the top of `Tests/CaptureScreenshots.gd`.

## Project layout

```text
Assets/     Audio, fonts, icons, portraits, SVG sprites, Kenney micro-roguelike tiles
Data/       Dialogue (storyline/*.json) and mission battle teams (battles/*.json)
Entities/   Entity.gd base class, Characters/ (6), Enemies/ (12)
Maps/       Overworld maps; most build themselves in code with Scripts/Overworld/MapUtils
Quests/     QuestDefinition resources and QuestRegistry
Scripts/    Battle/ (engine, scenarios, HoloSim), Core/ (GameManager, SaveManager, StoryState), Overworld/, Systems/
Tests/      TestRunner, Unit/ suites, screenshot tool
UI/         UITheme (design tokens), Battle/, Menus/, Popups/, Systems/
addons/     godot_mcp (editor tooling, see below)
```

How it fits together:

- **`GameManager`** (autoload) holds the party, credits, inventory and `StoryState` flags, and routes battles and scene changes. `SaveManager` serialises it to JSON.
- **`Scripts/Battle/Main.gd`** runs the turn loop. `BattleInitializer` builds the teams and picks a `BattleScenario` (default, prologue, harbor boss, street survival, prime minister, holo-sim); scenarios hook into the loop (`on_start`, `on_turn_start`, `on_action_executed`, `on_entity_died`, `check_battle_end`...).
- Persistent party members live across battles and into saves, so in-battle stat changes must go through `Entity.add_temp_mod()`; they are reverted when the battle scene exits.
- **Combat rules** — damage = `(ATK × skill − DEF) × (1 − RES/100) × element`, minimum 5% of ATK. Element chart: Cool > Happy > Cute > Cool, and Pure ↔ Mysterious, ×1.25 (×0.8 when resisted). Break damage is `0.4 × dmg + 25` on a weakness hit and `0.15 × dmg + 10` on a neutral hit; breaking an enemy stuns it one turn and pushes it back 3000 AV.

## UI

All styling comes from `UI/UITheme.gd`: colour tokens (tinted neutrals, one amber accent, teal for allies, coral for enemies), a 6-step type scale (14–44 px), a 4 px spacing scale and StyleBox builders. `default_theme.tres` is generated from it — after changing tokens, regenerate with:

```bash
godot --headless --path . --script res://Scripts/Editor/BuildTheme.gd
```

Rules the screens follow: one primary action per screen, no text under 14 px, 48 px minimum touch targets, text contrast of at least 4.5:1 (checked by `TestUITheme`), visible hover/focus/disabled states.

## Editor tooling (MCP)

`addons/godot_mcp` lets an MCP client drive the editor (scene/node/script edits, running the game, input and screenshots). The runtime half of the addon removes itself outside the editor, so exported builds don't expose it. `tools/` (the Node server and its `node_modules`) is local-only and git-ignored.

## Exporting

Presets for Windows and Android are in `export_presets.cfg` (output goes to the git-ignored `Export/`). Tests and screenshots are excluded from exports.

## Credits

- Tiles: [Kenney Micro Roguelike](https://kenney.nl/assets/micro-roguelike) (CC0).
- UI icons, portraits and character/enemy sprites are project-made (SVG/PNG).
- Fonts: [Chakra Petch](https://fonts.google.com/specimen/Chakra+Petch) (headings, buttons, numbers) and [Be Vietnam Pro](https://fonts.google.com/specimen/Be+Vietnam+Pro) (dialogue and body), both SIL OFL 1.1 with full Vietnamese coverage; the licence texts are next to the fonts in `Assets/Fonts/`.
- Music in `Assets/Audio/`: confirm licences before publishing a build.
