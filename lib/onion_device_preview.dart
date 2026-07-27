/// Renders a Miyoo Mini / Mini+ device mockup applying an OnionUI theme.
///
/// Feed it a theme zip's bytes ([OnionThemeBundle.fromZipBytes]) — or start
/// from the built-in "Silky" default ([OnionThemeBundle.defaultTheme]) —
/// and it renders the OnionOS firmware UI (main menu, rom lists, settings,
/// dialogs, boot/charging screens...) at the device's native 640×480,
/// driven by mocked device state.
///
/// Typical usage:
///
/// ```dart
/// final controller = OnionPreviewController();
/// await controller.loadTheme(OnionThemeBundle.fromZipBytes(zipBytes));
/// // then, in a widget tree:
/// MiyooDeviceShell(controller: controller)          // full device mockup
/// OnionScreen(controller: controller)               // or just the screen
/// ThemeInspector(controller: controller)            // diagnostics panel
/// ```
library onion_device_preview;

export 'src/core/asset_resolver.dart' show ThemeAsset, batteryAssetFor;
export 'src/core/font_loader.dart' show kBundledSystemFontFamilies, kOnionFallbackFontFamily;
// `IconPackResolver` itself stays internal (like `AssetResolver`), but its
// result types surface through `ThemeRenderContext.packIconSources`.
export 'src/core/icon_pack.dart' show IconPackSource, ResolvedIcon;
export 'src/core/mock_data.dart';
export 'src/core/theme_bundle.dart';
export 'src/core/theme_config.dart';
export 'src/device/device_shell.dart';
export 'src/device/device_state.dart';
export 'src/device/zoom.dart';
export 'src/inspector/theme_inspector.dart';
export 'src/screens/onion_screen.dart' show OnionScreen;
export 'src/screens/theme_render_context.dart' show ThemeRenderContext;
