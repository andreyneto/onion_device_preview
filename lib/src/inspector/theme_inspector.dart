import 'package:flutter/widgets.dart';

import '../core/asset_resolver.dart';
import '../core/icon_pack.dart';
import '../core/theme_config.dart';
import '../device/device_state.dart';
import '../screens/theme_render_context.dart';

/// Diagnostic panel over the controller's active theme: the parsed
/// `config.json` with every field's value and whether it came from the
/// theme itself or a firmware default/fallback, which skin assets were
/// found in the zip vs. served by the bundled default skin vs. missing,
/// and how each referenced font resolved. See `plan.md` §5-F5 / T5.3.
///
/// Built with plain widgets (no Material dependency) and its own compact
/// dark look, so it can be embedded in any host app. It shrink-wraps
/// vertically — put it inside a scroll view if space is tight.
class ThemeInspector extends StatelessWidget {
  const ThemeInspector({super.key, required this.controller});

  final OnionPreviewController controller;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final theme = controller.theme;
        final config = theme.config;
        final raw = theme.rawConfigJson;
        final ctx = controller.renderContext;

        return DefaultTextStyle(
          style: const TextStyle(fontSize: 12, color: _Palette.text),
          child: Container(
            decoration: BoxDecoration(
              color: _Palette.background,
              borderRadius: BorderRadius.circular(8),
            ),
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _header(theme.config, raw),
                if (controller.themeLoading) const _StatusLine('Carregando tema…', _Palette.dim),
                if (controller.themeLoadError != null)
                  _StatusLine('Falha ao carregar: ${controller.themeLoadError}', _Palette.bad),
                const SizedBox(height: 8),
                _Section(title: 'Config', initiallyExpanded: true, child: _configTable(config, raw)),
                if (ctx != null) ...[
                  _Section(
                    title: 'Assets — do tema (${ctx.assetsFoundInTheme.length})',
                    child: _assetList(ctx.assetsFoundInTheme, _Palette.good),
                  ),
                  _Section(
                    title: 'Assets — do skin default (${ctx.assetsFromDefaultSkin.length})',
                    child: _assetList(ctx.assetsFromDefaultSkin, _Palette.dim),
                  ),
                  _Section(
                    title: 'Assets — ausentes (${ctx.assetsMissing.length})',
                    initiallyExpanded: ctx.assetsMissing.isNotEmpty,
                    child: _assetList(ctx.assetsMissing, _Palette.bad),
                  ),
                  _Section(
                    title: 'Ícones (pack) — ${_iconPackSummary(ctx)}',
                    child: _iconPackList(ctx),
                  ),
                  _Section(title: 'Fontes', initiallyExpanded: true, child: _fontTable(ctx)),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _header(OnionThemeConfig config, Map<String, dynamic>? raw) {
    final theme = controller.theme;
    final name = config.name.isEmpty ? '(tema sem nome)' : config.name;
    final byline = [
      if (config.author.isNotEmpty) 'por ${config.author}',
      if (theme.isPack) 'pack com ${theme.availableRoots.length} temas',
      if (raw == null) 'config.json ausente/inválido — defaults do firmware',
    ].join(' · ');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: _Palette.text)),
        if (byline.isNotEmpty) Text(byline, style: const TextStyle(color: _Palette.dim)),
        if (config.description.isNotEmpty) Text(config.description, style: const TextStyle(color: _Palette.dim)),
      ],
    );
  }

  // --- Config table ---

  Widget _configTable(OnionThemeConfig config, Map<String, dynamic>? raw) {
    bool has(List<String> path) => _rawHas(raw, path);

    // `hideLabels` and battery `textAlign` honor legacy keys
    // (`hideIconTitle`, `onleft`) — count those as "set by the theme" too.
    final hasHideLabels = has(const ['hideIconTitle']);
    final hasOnLeft = has(const ['batteryPercentage', 'onleft']);

    final rows = <_ConfigRow>[
      _ConfigRow('hideLabels.icons', '${config.hideLabels.icons}', has(const ['hideLabels', 'icons']) || hasHideLabels),
      _ConfigRow('hideLabels.hints', '${config.hideLabels.hints}', has(const ['hideLabels', 'hints']) || hasHideLabels),
      ..._fontStyleRows('title', config.title, raw),
      ..._fontStyleRows('hint', config.hint, raw),
      ..._fontStyleRows('currentpage', config.currentpage, raw),
      ..._fontStyleRows('total', config.total, raw),
      ..._fontStyleRows('list', config.list, raw),
      _ConfigRow('grid.font', _shortFont(config.grid.font), has(const ['grid', 'font'])),
      _ConfigRow('grid.grid1x4', '${config.grid.grid1x4}', has(const ['grid', 'grid1x4'])),
      _ConfigRow('grid.grid3x4', '${config.grid.grid3x4}', has(const ['grid', 'grid3x4'])),
      _ConfigRow('grid.color', _hex(config.grid.color), has(const ['grid', 'color']), swatch: config.grid.color),
      _ConfigRow('grid.selectedcolor', _hex(config.grid.selectedColor), has(const ['grid', 'selectedcolor']),
          swatch: config.grid.selectedColor),
      _ConfigRow('batteryPercentage.visible', '${config.batteryPercentage.visible}',
          has(const ['batteryPercentage', 'visible'])),
      _ConfigRow('batteryPercentage.font', _shortFont(config.batteryPercentage.font),
          has(const ['batteryPercentage', 'font'])),
      _ConfigRow('batteryPercentage.size', '${config.batteryPercentage.size}', has(const ['batteryPercentage', 'size'])),
      _ConfigRow('batteryPercentage.color', _hex(config.batteryPercentage.color),
          has(const ['batteryPercentage', 'color']),
          swatch: config.batteryPercentage.color),
      _ConfigRow('batteryPercentage.textAlign', config.batteryPercentage.textAlign.name,
          has(const ['batteryPercentage', 'textAlign']) || hasOnLeft),
      _ConfigRow('batteryPercentage.fixed', '${config.batteryPercentage.fixed}',
          has(const ['batteryPercentage', 'fixed'])),
      _ConfigRow('batteryPercentage.offsetX', '${config.batteryPercentage.offsetX}',
          has(const ['batteryPercentage', 'offsetX'])),
      _ConfigRow('batteryPercentage.offsetY', '${config.batteryPercentage.offsetY}',
          has(const ['batteryPercentage', 'offsetY'])),
      _ConfigRow('frame.border-left', '${config.frame.borderLeft}', has(const ['frame', 'border-left'])),
      _ConfigRow('frame.border-right', '${config.frame.borderRight}', has(const ['frame', 'border-right'])),
    ];

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [for (final row in rows) row.build()],
    );
  }

  List<_ConfigRow> _fontStyleRows(String key, OnionFontStyle style, Map<String, dynamic>? raw) {
    return [
      _ConfigRow('$key.font', _shortFont(style.font), _rawHas(raw, [key, 'font'])),
      _ConfigRow('$key.size', '${style.size}', _rawHas(raw, [key, 'size'])),
      _ConfigRow('$key.color', _hex(style.color), _rawHas(raw, [key, 'color']), swatch: style.color),
    ];
  }

  static bool _rawHas(Map<String, dynamic>? raw, List<String> path) {
    Object? node = raw;
    for (final key in path) {
      if (node is! Map<String, dynamic>) return false;
      node = node[key];
    }
    return node != null;
  }

  /// Config font paths are long (`/mnt/SDCARD/miyoo/app/...`); show just
  /// the filename, which is what identifies the font.
  static String _shortFont(String path) {
    if (path.isEmpty) return '(vazio)';
    return path.split('/').last;
  }

  static String _hex(Color color) {
    final argb = color.toARGB32();
    return '#${(argb & 0xFFFFFF).toRadixString(16).padLeft(6, '0').toUpperCase()}';
  }

  // --- Assets / fonts ---

  // --- Icon pack ---
  //
  // Icons are a pack, not part of the skin (see IconPackResolver): the
  // theme's own `icons/` dir replaces the SD's, per-icon, and only when
  // "aplicar ícones" is on.

  String _iconPackSummary(ThemeRenderContext ctx) {
    if (!ctx.themeHasIconPack) return 'o tema não traz icons/';
    if (!ctx.appliedThemeIcons) return 'tema traz icons/, não aplicado';
    final fromTheme = ctx.packIconSources.values.where((s) => s == IconPackSource.theme).length;
    return '$fromTheme do tema';
  }

  Widget _iconPackList(ThemeRenderContext ctx) {
    final sources = ctx.packIconSources;
    if (sources.isEmpty) return const Text('(nenhum)', style: TextStyle(color: _Palette.dim));
    final names = sources.keys.toList()..sort();
    return Wrap(
      spacing: 6,
      runSpacing: 4,
      children: [
        for (final name in names)
          _chip(
            name,
            switch (sources[name]!) {
              IconPackSource.theme => _Palette.good,
              IconPackSource.defaultPack => _Palette.dim,
              IconPackSource.missing => _Palette.bad,
            },
          ),
      ],
    );
  }

  Widget _chip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      decoration: BoxDecoration(
        color: _Palette.chip,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(label, style: TextStyle(fontSize: 11, color: color)),
    );
  }

  Widget _assetList(Set<ThemeAsset> assets, Color color) {
    if (assets.isEmpty) return const Text('(nenhum)', style: TextStyle(color: _Palette.dim));
    final names = assets.map((a) => a.logicalName).toList()..sort();
    return Wrap(
      spacing: 6,
      runSpacing: 4,
      children: [for (final name in names) _chip(name, color)],
    );
  }

  Widget _fontTable(ThemeRenderContext ctx) {
    final families = ctx.fontFamiliesByPath;
    final failed = ctx.fontsFailed;
    if (families.isEmpty) return const Text('(nenhuma)', style: TextStyle(color: _Palette.dim));
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final entry in families.entries)
          Padding(
            padding: const EdgeInsets.only(bottom: 2),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: Text(_shortFont(entry.key), style: const TextStyle(color: _Palette.dim))),
                Text(
                  failed.contains(entry.key) ? 'fallback' : entry.value,
                  style: TextStyle(color: failed.contains(entry.key) ? _Palette.bad : _Palette.good),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _StatusLine extends StatelessWidget {
  const _StatusLine(this.message, this.color);

  final String message;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Text(message, style: TextStyle(color: color)),
    );
  }
}

/// One config field: dotted json path, displayed value, and whether the
/// theme's own `config.json` set it (vs. a firmware default/fallback).
class _ConfigRow {
  const _ConfigRow(this.path, this.value, this.fromTheme, {this.swatch});

  final String path;
  final String value;
  final bool fromTheme;
  final Color? swatch;

  Widget build() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: Text(path, style: const TextStyle(color: _Palette.dim))),
          if (swatch != null)
            Container(
              width: 10,
              height: 10,
              margin: const EdgeInsets.only(right: 4, top: 2),
              decoration: BoxDecoration(
                color: swatch,
                borderRadius: BorderRadius.circular(2),
                border: Border.all(color: _Palette.chipBorder),
              ),
            ),
          Text(value),
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            decoration: BoxDecoration(
              color: fromTheme ? _Palette.goodBg : _Palette.chip,
              borderRadius: BorderRadius.circular(3),
            ),
            child: Text(
              fromTheme ? 'tema' : 'default',
              style: TextStyle(fontSize: 10, color: fromTheme ? _Palette.good : _Palette.dim),
            ),
          ),
        ],
      ),
    );
  }
}

/// A collapsible titled block (plain-widgets stand-in for Material's
/// ExpansionTile).
class _Section extends StatefulWidget {
  const _Section({required this.title, required this.child, this.initiallyExpanded = false});

  final String title;
  final Widget child;
  final bool initiallyExpanded;

  @override
  State<_Section> createState() => _SectionState();
}

class _SectionState extends State<_Section> {
  late bool _expanded = widget.initiallyExpanded;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => setState(() => _expanded = !_expanded),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              children: [
                Text(_expanded ? '▾ ' : '▸ ', style: const TextStyle(color: _Palette.dim)),
                Expanded(
                  child: Text(
                    widget.title,
                    style: const TextStyle(fontWeight: FontWeight.bold, color: _Palette.text),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (_expanded)
          Padding(
            padding: const EdgeInsets.only(left: 14, bottom: 6),
            child: widget.child,
          ),
      ],
    );
  }
}

abstract final class _Palette {
  static const background = Color(0xFF1E1F26);
  static const chip = Color(0xFF2C2E38);
  static const chipBorder = Color(0xFF4A4D5A);
  static const text = Color(0xFFE6E6E6);
  static const dim = Color(0xFF9A9DA8);
  static const good = Color(0xFF7DC87D);
  static const goodBg = Color(0xFF24352A);
  static const bad = Color(0xFFE07A7A);
}
