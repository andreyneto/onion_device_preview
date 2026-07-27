# Native 640×480 device captures

Screenshots from a Miyoo Mini Plus running OnionOS **v4.4.0-beta2-f11f7a0d**
with the **"Silky by DiMo"** theme from the `Themes` repo — not the Silky built
into the firmware, which is a different theme (it ships no `skin/extra/`, so it
never exercises the Game Switcher's custom bars).

These are the calibration reference: `docs/spec-1a1.md` §11–§13 cites
measurements taken against them, and `device_conformance_test.dart` compares
renders against them on every run.

| file | screen | origin |
|---|---|---|
| `dev_gs_empty.png` | Game Switcher, no history | direct capture (Menu+Power) |
| `dev_gs_dialog.png` | Game Switcher, "Remove from history" | direct capture |
| `dev_gs_time.png` | Game Switcher with playtime in the header | direct capture |
| `dev_settings.png` | Settings | cropped from `docs/images/device-vs-render.png` |
| `dev_game_list.png` | rom list (Arcade) | idem |
| `dev_game_systems.png` | systems grid | idem |
| `dev_pop_menu.png` | pop menu over the list | idem |

The last four came from that composite's left column, which is where the
original `MainUI_004..013` survived — they had been lost along with the
scratchpad of the session that used them. **This directory exists so that
doesn't happen again**: new captures go here, not into a temp dir.

Boot, charging and shutdown aren't here: MainUI isn't running at those moments
to serve the screenshot shortcut, so they only exist as phone video — good for
validating presence and relative position, not pixel geometry.
