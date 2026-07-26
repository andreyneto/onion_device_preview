# onion_device_preview

Package Flutter que renderiza um mockup do **Miyoo Mini / Mini+** rodando
[OnionOS](https://github.com/OnionUI/Onion), aplicando um tema OnionUI a partir
dos bytes de um `.zip` — com estado de device mockado (bateria, wi-fi, telas,
navegação por teclado) para pré-visualizar temas sem um console na mão.

![Main menu com o skin default (Silky)](docs/images/main-menu.png)

O rendering é calibrado **1:1 contra o firmware**: coordenadas derivadas do
código C aberto do Onion (`src/common/theme/render/*`) e, onde o MainUI é
fechado, medidas por template matching contra screenshots nativos do device
(≤2px de desvio — ver `docs/spec-1a1.md`).

![Device real vs render deste package](docs/images/device-vs-render.png)

## Uso da API

```dart
import 'package:onion_device_preview/onion_device_preview.dart';

final controller = OnionPreviewController();

// Tema de um zip (ex.: baixado do repo OnionUI/Themes)...
final bundle = OnionThemeBundle.fromZipBytes(zipBytes);
await controller.loadTheme(bundle); // atômico: falha mantém o tema anterior

// ...ou o skin default (Silky) embutido:
await controller.loadTheme(OnionThemeBundle.defaultTheme());

// Na árvore de widgets:
MiyooDeviceShell(controller: controller)   // device completo clicável
OnionScreen(controller: controller)        // só a tela 640x480 (zoom fit/1x/1.5x/2x)
ThemeInspector(controller: controller)     // painel diagnóstico do tema
```

- **Packs** (zip com vários temas): `bundle.isPack` / `bundle.availableRoots` /
  `bundle.withRoot(path)`.
- **Estado mockado**: `setBatteryPercent`, `setCharging`, `setWifi`,
  `setExpertMode`, `setShowRecents`, `setForceHideLabels`, `setSoundEnabled`
  (bgm + som de navegação do tema), navegação via `pressA/B/Start/Select/Menu`
  e `moveUp/Down/Left/Right`.
- **Teclado** (layout RetroArch): setas = D-pad, `X` = A, `Z` = B,
  `Enter` = Start, `Shift` = Select, `Esc` = Menu.

## Rodando o example (web)

```bash
cd example
flutter run -d chrome        # ou: flutter run -d web-server --web-port=8765
```

O example tem drop zone para `.zip` de tema (arraste sobre a janela), file
picker, seletor de subtema para packs, painel de controle completo e o
inspector. Build de produção: `flutter build web --release`.

### Gerando um zip de teste

Qualquer tema do repo [OnionUI/Themes](https://github.com/OnionUI/Themes)
serve — os prontos estão em `release/*.zip`, ou zipe uma pasta de
`themes/<Nome>/` (o zip pode ter `config.json` + `skin/` na raiz ou um nível
abaixo).

## Arquitetura (resumo)

| Camada | O quê |
|---|---|
| `src/core/` | `OnionThemeBundle` (zip em memória, packs), `OnionThemeConfig` (parser tolerante com os fallbacks do firmware), `AssetResolver` (tema → skin default → null), `OnionFontResolver` (fontes do zip via FontLoader; `.ttc` → Roboto), mock data |
| `src/device/` | `OnionPreviewController` (ChangeNotifier: tema resolvido, navegação em pilha, cursores, handlers por tela, sons), `MiyooDeviceShell`, `InputMapper`, `OnionSoundBank` |
| `src/screens/` | As telas do OnionUI em blits de coordenada fixa (main menu, game systems, listas, dialog, pop menu, boot/charging/shutdown) + header/footer compartilhados |
| `src/inspector/` | `ThemeInspector` (config com proveniência tema/default, assets encontrados/ausentes, fontes) |

Princípio de implementação: **nenhum layout flexível nas telas** — só blit em
coordenada fixa no canvas lógico 640×480, espelhando o `SDL_BlitSurface` do
firmware. A especificação completa, com evidência por coordenada
([SRC]/[MEAS]/[IMG]), está em [`docs/spec-1a1.md`](docs/spec-1a1.md).

## Testes

```bash
flutter test                          # inclui goldens das telas calibradas
flutter test --update-goldens         # regenera goldens deliberadamente
```

`test/real_themes_robustness_test.dart` roda o parser contra todos os
`config.json` do checkout irmão `../Themes` (pulado se ausente). Os assets do
skin default vêm de `../Onion` via `tool/copy_default_skin.sh`.
