# Capturas nativas 640×480 do device

Screenshots do Miyoo Mini Plus rodando OnionOS **v4.4.0-beta2-f11f7a0d** com o
tema **"Silky by DiMo"** do repo `Themes/` — não a Silky embutida no firmware,
que é outro tema (não traz `skin/extra/`, então nunca exercita as barras
customizadas do Game Switcher).

São a referência de calibração: `docs/spec-1a1.md` §11–§13 cita medições feitas
contra estes arquivos, e `device_conformance_test.dart` compara renders contra
eles a cada execução.

| arquivo | tela | origem |
|---|---|---|
| `dev_gs_empty.png` | Game Switcher sem histórico | captura direta (Menu+Power) |
| `dev_gs_dialog.png` | Game Switcher, "Remove from history" | captura direta |
| `dev_gs_time.png` | Game Switcher com tempo no header | captura direta |
| `dev_settings.png` | Settings | recortado de `docs/images/device-vs-render.png` |
| `dev_game_list.png` | lista de roms (Arcade) | idem |
| `dev_game_systems.png` | grade de sistemas | idem |
| `dev_pop_menu.png` | pop menu sobre a lista | idem |

Os quatro últimos vieram da coluna esquerda daquele composite, que é onde os
`MainUI_004..013` originais sobreviveram — eles tinham sido perdidos com o
scratchpad da sessão que os usou. **Este diretório existe para que isso não se
repita**: capturas novas entram aqui, não num diretório temporário.

Boot, charging e shutdown não estão aqui: o MainUI não está rodando nesses
momentos para atender o atalho de screenshot, então só existem como vídeo de
celular — bom para validar presença e posição relativa, não geometria ao pixel.
