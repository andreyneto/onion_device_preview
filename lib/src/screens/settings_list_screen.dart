import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';

import '../core/asset_resolver.dart';
import '../core/mock_data.dart';
import '../device/device_state.dart';
import 'theme_render_context.dart';
import 'widgets/theme_list_item.dart';

/// A generic settings/tweaks list — mirrors `list.h`'s toggle/multivalue
/// rendering (already exercised by [ThemeListItem]), plus submenu
/// navigation the firmware's own `list.h` doesn't cover at all (that's
/// higher up in MainUI, closed-source). Submenu depth, per-level
/// selection memory, and toggle/multivalue edits are tracked on
/// [OnionPreviewController] itself (`pushSettingsSubmenu`/
/// `popSettingsSubmenu`) so the shared header can show the current
/// level's breadcrumb title; toggle/multivalue *values* are mock-only
/// local overrides here, since the underlying mock items are immutable
/// consts.
///
/// A/B are entering-a-submenu and going-back; a multivalue's option is
/// cycled forward by A rather than dedicated left/right arrows — the
/// screen-level horizontal cursor real firmware would use for that is
/// already spoken for by the main menu's tab carousel and the game
/// grid's columns, and adding a second, per-row axis just for this
/// mocked preview wasn't worth the extra state to plumb through.
class SettingsListScreen extends StatefulWidget {
  const SettingsListScreen({super.key, required this.controller, required this.ctx});

  final OnionPreviewController controller;
  final ThemeRenderContext ctx;

  @override
  State<SettingsListScreen> createState() => _SettingsListScreenState();
}

class _SettingsListScreenState extends State<SettingsListScreen> {
  static const _kVisibleRows = 6;

  final Map<OnionMockToggleItem, bool> _toggleOverrides = {};
  final Map<OnionMockMultiValueItem, int> _multiOverrides = {};

  /// Leading skin icons (themable — MainUI_012 shows them on the real
  /// Settings menu), resolved on demand by name. Mostly `icon-*.png`, but
  /// not all: the Display and Menu sound rows use `color.png` and
  /// `sound-icon.png`, which don't follow that prefix.
  final Map<String, ui.Image?> _icons = {};

  /// Same edge-triggered scroll window as the rom list (device model).
  int _windowStart = 0;

  @override
  void initState() {
    super.initState();
    widget.controller.bindScreenHandlers(OnionScreenKind.settingsList, onConfirm: _activate, onCancel: _back);
    _loadIcons();
  }

  Future<void> _loadIcons() async {
    final resolver = AssetResolver(widget.controller.theme);
    final names = <String>{
      for (final item in _allItems(OnionMockData.settings))
        if (item.iconSkinName != null) item.iconSkinName!,
    };
    for (final name in names) {
      _icons[name] = await resolver.resolveImageAt('skin/$name.png');
    }
    if (mounted) setState(() {});
  }

  static Iterable<OnionMockSettingsItem> _allItems(List<OnionMockSettingsItem> items) sync* {
    for (final item in items) {
      yield item;
      if (item is OnionMockSubmenuItem) yield* _allItems(item.children);
    }
  }

  @override
  void dispose() {
    widget.controller.unbindScreenHandlers(OnionScreenKind.settingsList);
    super.dispose();
  }

  List<OnionMockSettingsItem> get _items => widget.controller.settingsRoot;

  int get _activeIndex =>
      _items.isEmpty ? 0 : widget.controller.selectionFor(OnionScreenKind.settingsList).clamp(0, _items.length - 1);

  bool _toggleValue(OnionMockToggleItem item) => _toggleOverrides[item] ?? item.value;
  int _multiValue(OnionMockMultiValueItem item) => _multiOverrides[item] ?? item.selectedIndex;

  void _activate() {
    if (_items.isEmpty) return;
    final item = _items[_activeIndex];
    if (item is OnionMockSubmenuItem) {
      widget.controller.pushSettingsSubmenu(item.children, item.label);
    } else if (item is OnionMockToggleItem) {
      setState(() => _toggleOverrides[item] = !_toggleValue(item));
    } else if (item is OnionMockMultiValueItem) {
      setState(() => _multiOverrides[item] = (_multiValue(item) + 1) % item.options.length);
    } else if (item is OnionMockSimpleItem) {
      widget.controller.showDialog(title: item.label, message: item.description ?? 'No further options.');
    }
  }

  void _back() {
    if (!widget.controller.popSettingsSubmenu()) {
      widget.controller.goBack();
    }
  }

  @override
  Widget build(BuildContext context) {
    final items = _items;
    widget.controller.setItemCount(OnionScreenKind.settingsList, items.length);

    if (items.isEmpty) return const SizedBox.shrink();

    final activeIndex = _activeIndex;
    final maxStart = (items.length - _kVisibleRows).clamp(0, items.length);
    if (activeIndex < _windowStart) _windowStart = activeIndex;
    if (activeIndex > _windowStart + _kVisibleRows - 1) _windowStart = activeIndex - _kVisibleRows + 1;
    _windowStart = _windowStart.clamp(0, maxStart);
    final lastIndex = (_windowStart + _kVisibleRows).clamp(0, items.length);

    // Same 2px row offset as the rom list (device rows at y=62, 122...);
    // offsets accumulate since description rows are 90px, not 60.
    final rows = <Widget>[];
    var top = 2.0;
    for (var i = _windowStart; i < lastIndex; i++) {
      final item = items[i];
      rows.add(Positioned(left: 0, top: top, child: _row(item, i == activeIndex)));
      top += _isLarge(item) ? 90 : 60;
    }
    return Stack(clipBehavior: Clip.hardEdge, children: rows);
  }

  static bool _isLarge(OnionMockSettingsItem item) =>
      item is OnionMockSimpleItem && (item.description?.isNotEmpty ?? false);

  /// A row's leading icon: Settings rows use a themable *skin* icon,
  /// Apps rows an *icon pack* icon (whose focused variant may differ —
  /// the device's `iconsel`). See [OnionMockSettingsItem].
  ui.Image? _iconFor(OnionMockSettingsItem item, bool selected) {
    final packName = item.iconPackName;
    if (packName != null) return widget.ctx.packIcon(packName, selected: selected);
    final skinName = item.iconSkinName;
    return skinName == null ? null : _icons[skinName];
  }

  Widget _row(OnionMockSettingsItem item, bool selected) {
    final large = _isLarge(item);
    // Submenus carry no chevron on the device (MainUI_012: WIFI/Display
    // rows look identical to plain ones) — the label is shown as-is.
    final label = item.label;

    var control = OnionListItemControl.none;
    var toggleOn = false;
    String? multivalueText;
    if (item is OnionMockToggleItem) {
      control = OnionListItemControl.toggle;
      toggleOn = _toggleValue(item);
    } else if (item is OnionMockMultiValueItem) {
      control = OnionListItemControl.multivalue;
      multivalueText = item.options[_multiValue(item)];
    }

    return ThemeListItem(
      width: 640,
      large: large,
      selected: selected,
      selectedBackground: widget.ctx.image(large ? ThemeAsset.bgListLarge : ThemeAsset.bgListSmall),
      icon: _iconFor(item, selected),
      // Skin icon = the Settings menu, which starts labels at a fixed x;
      // pack icon = the Apps list, which starts them after the icon.
      fixedIconColumn: item.iconSkinName != null,
      label: label,
      description: item is OnionMockSimpleItem ? item.description : null,
      listStyle: widget.ctx.config.list,
      listFontFamily: widget.ctx.fontFamily(widget.ctx.config.list.font),
      descriptionColor: widget.ctx.config.grid.color,
      control: control,
      toggleOn: toggleOn,
      toggleOnImage: widget.ctx.image(ThemeAsset.toggleOn),
      toggleOffImage: widget.ctx.image(ThemeAsset.toggleOff),
      multivalueText: multivalueText,
      leftArrowImage: widget.ctx.image(ThemeAsset.leftArrow),
      rightArrowImage: widget.ctx.image(ThemeAsset.rightArrow),
    );
  }
}
