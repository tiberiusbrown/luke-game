# AGENTS.md

## Project

This is a Godot 4.7.1 game targeting Android.

Use:
- Standard Godot build, not Godot .NET
- Typed GDScript
- Mobile renderer
- Desktop execution for the normal development loop
- Android exports for device testing

## Project structure

- `game/` contains gameplay features.
- Keep each feature's scenes, scripts, and feature-specific assets together.
- `game/main/` contains the application's root scene.
- `core/` contains reusable systems that are not tied to one scene.
- `assets/` contains assets shared across multiple features.
- `tests/` contains automated test code and test fixtures.
- `docs/` contains design and implementation documentation.
- `build/` contains generated exports and must not be committed.

## Naming

- Use `snake_case` for files, folders, methods, variables, and signals.
- Use PascalCase for node names and `class_name` types.
- Use descriptive names rather than abbreviations.
- Keep resource paths lowercase to avoid Android case-sensitivity bugs.

## GDScript

- Use typed GDScript.
- Give function parameters and return values explicit types.
- Give member variables explicit types whenever practical.
- Treat warnings as problems to fix rather than ignore.
- Prefer small scripts with one clear responsibility.
- Keep game rules separate from rendering and input when practical.
- Prefer signals or direct ownership relationships over global lookups.
- Do not add an autoload unless the system is genuinely global.
- Do not add third-party plugins without approval.

## Scenes and resources

- Prefer text `.tscn` and `.tres` resources over binary `.scn` and `.res`.
- Do not hand-edit a large scene file when creating or changing it through a
  small script would be safer.
- Preserve existing node names and paths unless the change requires renaming.
- Update references when moving or renaming resources.

## Verification

Codex must not launch the Godot editor or a graphical game process. Graphical
execution is a manual user verification step because the native Windows
sandbox may not provide a compatible desktop or user profile.

After modifying scripts or resources, run:

    powershell -ExecutionPolicy Bypass -File tools/verify.ps1

This script provides project-local APPDATA, LOCALAPPDATA, TEMP, and TMP
directories and performs:

1. A headless resource import.
2. The vendored GUT test suite from `tests/unit` and `tests/integration`.
3. A short headless main-scene smoke test.

Testing requirements:

- Keep isolated project-logic tests under `tests/unit`.
- Keep scene and multi-node behavior tests under `tests/integration`.
- Name test scripts with the `test_` prefix and use typed GDScript.
- When a test accesses a scene node, give that node a stable unique name with
  `unique_name_in_owner = true` and access it through its unique-name path.
- Run all verification through `powershell -ExecutionPolicy Bypass -File
  tools/verify.ps1`; do not launch Godot graphically from Codex.
- Godot command output is redirected to `.codex-runtime` by the verifier.

Report:
- Files changed
- Verification command and exit code
- Godot warnings or errors
- Behavior that still requires manual graphical verification
