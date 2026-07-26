import 'dart:typed_data';

import 'package:desktop_drop/desktop_drop.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:onion_device_preview/onion_device_preview.dart';

void main() {
  runApp(const PreviewExampleApp());
}

class PreviewExampleApp extends StatelessWidget {
  const PreviewExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Onion Theme Previewer',
      theme: ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple)),
      home: const PreviewHomePage(),
    );
  }
}

class PreviewHomePage extends StatefulWidget {
  const PreviewHomePage({super.key});

  @override
  State<PreviewHomePage> createState() => _PreviewHomePageState();
}

class _PreviewHomePageState extends State<PreviewHomePage> {
  final _controller = OnionPreviewController();
  bool _screenOnly = false;
  OnionZoom _zoom = OnionZoom.fit;
  bool _dragging = false;

  /// The last zip successfully loaded, so "recarregar" can re-run the
  /// pipeline (e.g. after editing the file on disk and re-exporting).
  Uint8List? _lastZipBytes;
  String? _lastZipName;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // --- Theme loading (T5.4) ---

  Future<void> _pickZip() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['zip'],
      withData: true,
    );
    final file = result?.files.firstOrNull;
    if (file == null) return;
    final bytes = file.bytes;
    if (bytes == null) {
      _snack('Não foi possível ler o arquivo selecionado.');
      return;
    }
    await _loadZip(bytes, file.name);
  }

  Future<void> _onDropped(DropDoneDetails detail) async {
    setState(() => _dragging = false);
    final file = detail.files.firstOrNull;
    if (file == null) return;
    if (!file.name.toLowerCase().endsWith('.zip')) {
      _snack('Solte um tema OnionUI em .zip (recebi "${file.name}").');
      return;
    }
    await _loadZip(await file.readAsBytes(), file.name);
  }

  Future<void> _loadZip(Uint8List bytes, String name) async {
    OnionThemeBundle bundle;
    try {
      bundle = OnionThemeBundle.fromZipBytes(bytes);
    } on InvalidThemeZipException catch (e) {
      _snack(e.message);
      return;
    }

    if (bundle.isPack) {
      final rootPath = await _pickPackRoot(bundle);
      if (rootPath == null) return;
      bundle = bundle.withRoot(rootPath);
    }

    final swapped = await _controller.loadTheme(bundle);
    if (!mounted) return;
    if (swapped) {
      setState(() {
        _lastZipBytes = bytes;
        _lastZipName = name;
      });
      final themeName = bundle.config.name.isEmpty ? name : bundle.config.name;
      _snack('Tema "$themeName" carregado.');
    } else if (_controller.themeLoadError != null) {
      _snack('Falha ao carregar o tema: ${_controller.themeLoadError}');
    }
  }

  Future<void> _reloadZip() async {
    final bytes = _lastZipBytes;
    final name = _lastZipName;
    if (bytes == null || name == null) return;
    // Same bytes → same roots; keep the currently selected subtheme
    // instead of re-asking.
    OnionThemeBundle bundle;
    try {
      bundle = OnionThemeBundle.fromZipBytes(bytes);
    } on InvalidThemeZipException catch (e) {
      _snack(e.message);
      return;
    }
    final currentRoot = _controller.theme.activeRootPath;
    if (bundle.availableRoots.any((r) => r.path == currentRoot)) {
      bundle = bundle.withRoot(currentRoot);
    }
    final swapped = await _controller.loadTheme(bundle);
    if (!mounted) return;
    _snack(swapped ? 'Tema recarregado.' : 'Falha ao recarregar: ${_controller.themeLoadError}');
  }

  Future<void> _selectSubtheme(String rootPath) async {
    final swapped = await _controller.loadTheme(_controller.theme.withRoot(rootPath));
    if (!mounted) return;
    if (!swapped && _controller.themeLoadError != null) {
      _snack('Falha ao trocar de subtema: ${_controller.themeLoadError}');
    }
  }

  Future<String?> _pickPackRoot(OnionThemeBundle bundle) {
    return showDialog<String>(
      context: context,
      builder: (context) => SimpleDialog(
        title: Text('Pack com ${bundle.availableRoots.length} temas — escolha um'),
        children: [
          for (final root in bundle.availableRoots)
            SimpleDialogOption(
              onPressed: () => Navigator.pop(context, root.path),
              child: Text(root.displayName),
            ),
        ],
      ),
    );
  }

  void _snack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  // --- Layout ---

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Onion Theme Previewer'),
        actions: [
          IconButton(
            tooltip: 'Carregar tema (.zip)',
            onPressed: _pickZip,
            icon: const Icon(Icons.folder_open),
          ),
          IconButton(
            tooltip: _lastZipName == null ? 'Nenhum zip carregado ainda' : 'Recarregar $_lastZipName',
            onPressed: _lastZipBytes == null ? null : _reloadZip,
            icon: const Icon(Icons.refresh),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: DropTarget(
        onDragEntered: (_) => setState(() => _dragging = true),
        onDragExited: (_) => setState(() => _dragging = false),
        onDragDone: _onDropped,
        child: Stack(
          children: [
            Row(
              children: [
                Expanded(
                  child: Center(
                    child: _screenOnly
                        ? OnionScreen(controller: _controller, zoom: _zoom)
                        : MiyooDeviceShell(controller: _controller),
                  ),
                ),
                const VerticalDivider(width: 1),
                SizedBox(
                  width: 380,
                  child: _ControlPanel(
                    controller: _controller,
                    screenOnly: _screenOnly,
                    zoom: _zoom,
                    lastZipName: _lastZipName,
                    onScreenOnlyChanged: (v) => setState(() => _screenOnly = v),
                    onZoomChanged: (z) => setState(() => _zoom = z),
                    onPickZip: _pickZip,
                    onSelectSubtheme: _selectSubtheme,
                  ),
                ),
              ],
            ),
            // Drag-over veil: the whole window is the drop zone.
            if (_dragging)
              Positioned.fill(
                child: IgnorePointer(
                  child: Container(
                    color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.15),
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text('Solte o .zip do tema para carregar', style: TextStyle(fontSize: 18)),
                      ),
                    ),
                  ),
                ),
              ),
            // Loading veil while a theme resolves.
            ListenableBuilder(
              listenable: _controller,
              builder: (context, _) => _controller.themeLoading
                  ? const Positioned.fill(
                      child: ColoredBox(
                        color: Color(0x66000000),
                        child: Center(child: CircularProgressIndicator()),
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }
}

class _ControlPanel extends StatelessWidget {
  const _ControlPanel({
    required this.controller,
    required this.screenOnly,
    required this.zoom,
    required this.lastZipName,
    required this.onScreenOnlyChanged,
    required this.onZoomChanged,
    required this.onPickZip,
    required this.onSelectSubtheme,
  });

  final OnionPreviewController controller;
  final bool screenOnly;
  final OnionZoom zoom;
  final String? lastZipName;
  final ValueChanged<bool> onScreenOnlyChanged;
  final ValueChanged<OnionZoom> onZoomChanged;
  final VoidCallback onPickZip;
  final ValueChanged<String> onSelectSubtheme;

  /// The screens the panel can jump to directly. Dialog/pop-menu are
  /// overlays pushed with demo payloads; gameList opens the first mock
  /// system's roms.
  static const _screenChoices = <(OnionScreenKind, String)>[
    (OnionScreenKind.boot, 'Boot'),
    (OnionScreenKind.mainMenu, 'Main menu'),
    (OnionScreenKind.gameSystems, 'Game systems'),
    (OnionScreenKind.gameList, 'Rom list'),
    (OnionScreenKind.settingsList, 'Settings'),
    (OnionScreenKind.dialog, 'Dialog'),
    (OnionScreenKind.popMenu, 'Pop menu'),
    (OnionScreenKind.charging, 'Charging'),
    (OnionScreenKind.shutdown, 'Shutdown'),
  ];

  void _showScreen(OnionScreenKind kind) {
    switch (kind) {
      case OnionScreenKind.boot:
      case OnionScreenKind.mainMenu:
      case OnionScreenKind.charging:
      case OnionScreenKind.shutdown:
        controller.resetTo(kind);
      case OnionScreenKind.gameSystems:
        controller.resetTo(OnionScreenKind.mainMenu);
        controller.goTo(OnionScreenKind.gameSystems);
      case OnionScreenKind.gameList:
        final system = OnionMockData.gameSystems.first;
        controller.resetTo(OnionScreenKind.mainMenu);
        controller.openGameList(system.roms, system.name);
      case OnionScreenKind.settingsList:
        controller.resetTo(OnionScreenKind.mainMenu);
        controller.openSettingsTree(OnionMockData.settings, 'Settings');
      case OnionScreenKind.dialog:
        controller.resetTo(OnionScreenKind.mainMenu);
        controller.showDialog(
          title: 'Confirmação',
          message: 'Um diálogo de exemplo.\nA confirma, B cancela.',
          showHint: true,
        );
      case OnionScreenKind.popMenu:
        final system = OnionMockData.gameSystems.first;
        controller.resetTo(OnionScreenKind.mainMenu);
        controller.openGameList(system.roms, system.name);
        controller.showPopMenu(
          const ['Add to favorites', 'Game info'],
          onSelect: (_) => controller.goBack(),
        );
    }
  }

  /// Which panel choice the current navigation stack corresponds to (so
  /// the dropdown follows in-preview navigation too, not just its own
  /// selections).
  OnionScreenKind _currentChoice() {
    final current = controller.currentScreen;
    return _screenChoices.any((c) => c.$1 == current) ? current : OnionScreenKind.mainMenu;
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final theme = controller.theme;
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text('Tema', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: onPickZip,
              icon: const Icon(Icons.folder_open),
              label: Text(lastZipName ?? 'Carregar tema (.zip) — ou arraste aqui'),
            ),
            if (theme.isPack) ...[
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                initialValue: theme.activeRootPath,
                decoration: const InputDecoration(labelText: 'Subtema (pack)', isDense: true),
                items: [
                  for (final root in theme.availableRoots)
                    DropdownMenuItem(value: root.path, child: Text(root.displayName)),
                ],
                onChanged: (path) {
                  if (path != null) onSelectSubtheme(path);
                },
              ),
            ],
            const Divider(height: 32),
            Text('Tela', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            DropdownButtonFormField<OnionScreenKind>(
              initialValue: _currentChoice(),
              decoration: const InputDecoration(isDense: true),
              items: [
                for (final (kind, label) in _screenChoices) DropdownMenuItem(value: kind, child: Text(label)),
              ],
              onChanged: (kind) {
                if (kind != null) _showScreen(kind);
              },
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Só a tela (sem o device)'),
              value: screenOnly,
              onChanged: onScreenOnlyChanged,
            ),
            if (screenOnly)
              Wrap(
                spacing: 8,
                children: [
                  for (final z in OnionZoom.values)
                    ChoiceChip(
                      label: Text(switch (z) {
                        OnionZoom.fit => 'Fit',
                        OnionZoom.x1 => '1x',
                        OnionZoom.x1_5 => '1.5x',
                        OnionZoom.x2 => '2x',
                      }),
                      selected: zoom == z,
                      onSelected: (_) => onZoomChanged(z),
                    ),
                ],
              ),
            const Divider(height: 32),
            Text('Estado do device', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.battery_5_bar, size: 18),
                Expanded(
                  child: Slider(
                    value: controller.batteryPercent.toDouble(),
                    max: 100,
                    divisions: 100,
                    label: '${controller.batteryPercent}%',
                    onChanged: (v) => controller.setBatteryPercent(v.round()),
                  ),
                ),
                SizedBox(width: 40, child: Text('${controller.batteryPercent}%', textAlign: TextAlign.end)),
              ],
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Carregando (na tomada)'),
              value: controller.charging,
              onChanged: controller.setCharging,
            ),
            DropdownButtonFormField<OnionWifiState>(
              initialValue: controller.wifi,
              decoration: const InputDecoration(labelText: 'Wi-Fi', isDense: true),
              items: const [
                DropdownMenuItem(value: OnionWifiState.off, child: Text('Desligado')),
                DropdownMenuItem(value: OnionWifiState.locked, child: Text('Bloqueado')),
                DropdownMenuItem(value: OnionWifiState.signal1, child: Text('Sinal 1/4')),
                DropdownMenuItem(value: OnionWifiState.signal2, child: Text('Sinal 2/4')),
                DropdownMenuItem(value: OnionWifiState.signal3, child: Text('Sinal 3/4')),
                DropdownMenuItem(value: OnionWifiState.signal4, child: Text('Sinal 4/4')),
              ],
              onChanged: (v) {
                if (v != null) controller.setWifi(v);
              },
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Aba Recents'),
              value: controller.showRecents,
              onChanged: controller.setShowRecents,
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Modo expert (RetroArch)'),
              value: controller.expertMode,
              onChanged: controller.setExpertMode,
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Sons do tema (bgm + navegação)'),
              value: controller.soundEnabled,
              onChanged: controller.setSoundEnabled,
            ),
            const SizedBox(height: 8),
            Text('Labels (tabs e hints)', style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 4),
            SegmentedButton<bool?>(
              segments: const [
                ButtonSegment(value: null, label: Text('Tema')),
                ButtonSegment(value: false, label: Text('Mostrar')),
                ButtonSegment(value: true, label: Text('Ocultar')),
              ],
              selected: {controller.forceHideLabels},
              onSelectionChanged: (selection) => controller.setForceHideLabels(selection.first),
            ),
            const Divider(height: 32),
            Text(
              'Teclado: setas = D-pad · X = A · Z = B · Enter = Start · Shift = Select · Esc = Menu',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const Divider(height: 32),
            Text('Inspector', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            ThemeInspector(controller: controller),
          ],
        );
      },
    );
  }
}
