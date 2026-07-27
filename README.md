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

> **Escopo**: projeto pessoal, publicado por visibilidade. Funciona e é testado,
> mas não tem compromisso de suporte, roadmap ou estabilidade de API. Fique à
> vontade para forkar; issues e PRs podem ficar sem resposta.

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
  (bgm + som de navegação do tema), `setApplyThemeIcons` (usar a pasta `icons/`
  do tema, como o ThemeSwitcher do device), navegação via
  `pressA/B/X/Y/Start/Select/Menu` e `moveUp/Down/Left/Right`.
- **Teclado** (layout RetroArch): setas = D-pad, `X` = A, `Z` = B, `A` = Y,
  `S` = X, `Enter` = Start, `Shift` = Select, `Esc` = Menu (abre o Game
  Switcher).

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
| `src/core/` | `OnionThemeBundle` (zip em memória, packs), `OnionThemeConfig` (parser tolerante com os fallbacks do firmware), `AssetResolver` (tema → skin default → null), `IconPackResolver` (`icons/`, `icons/sel/`, `icons/app/` → pack Default), `OnionFontResolver` (fontes do zip via FontLoader; fontes de sistema embutidas, com a `wqy-microhei.ttc` registrada sob demanda), mock data |
| `src/device/` | `OnionPreviewController` (ChangeNotifier: tema resolvido, navegação em pilha, cursores, handlers por tela, sons), `MiyooDeviceShell`, `InputMapper`, `OnionSoundBank` |
| `src/screens/` | As telas do OnionUI em blits de coordenada fixa (main menu, game systems, listas, apps, Game Switcher, dialog, pop menu, boot/charging/shutdown) + header/footer compartilhados |
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

## Licença e assets de terceiros

O código é **GPL v3** (`LICENSE`) — mesma licença do
[OnionUI/Onion](https://github.com/OnionUI/Onion), de onde vem o conteúdo de
`assets/default_skin/`: skin padrão, `config.json`, o pack de ícones `Default`,
a arte de boot/shutdown e a animação de charging. Esses arquivos são
redistribuídos aqui porque são o fallback que o próprio firmware aplica quando
um tema não traz um asset — sem eles o preview teria buracos que o device real
não tem.

As fontes de sistema em `assets/default_skin/fonts/` são as que os temas
referenciam por caminho absoluto (`/mnt/SDCARD/miyoo/app/...`) e nunca
empacotam:

| fonte | licença |
|---|---|
| `Exo-2-Bold-Italic.ttf` | SIL OFL |
| `BPreplayBold.otf` | SIL OFL |
| `wqy-microhei.ttc` | GPL v3 com exceção de fonte / Apache 2.0 |
| `HENB.TTF` | proprietária (Adobe/Linotype) — ver nota abaixo |

`HENB.TTF` é HelveticaNeue-Bold e é a fonte de sistema mais referenciada pelos
temas reais (23 dos 202 do repo `Themes`). Está aqui pelo mesmo motivo que está
no firmware Onion: sem ela esses temas renderizam na face errada. A
`Helvetica-Neue-2.ttf`, cuja licença proíbe redistribuição explicitamente, foi
**deliberadamente deixada de fora** — apenas 1 tema a referencia, e ele cai no
fallback.

Screenshots do device em `test/fixtures/device/` são capturas próprias, de um
Miyoo Mini Plus rodando OnionOS.
