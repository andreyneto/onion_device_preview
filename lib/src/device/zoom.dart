/// How large [OnionScreen] renders: scaled to fill whatever space its
/// parent gives it ([fit], via `FittedBox` — not necessarily an integer
/// multiple of its logical 640x480 size), or at an exact multiple of it
/// ([x1]/[x1_5]/[x2]). Every image draw in this package already uses
/// `FilterQuality.none`, so a fixed zoom level renders pixel-perfect;
/// [fit] can land on a fractional scale and blur slightly.
enum OnionZoom {
  fit(null),
  x1(1),
  x1_5(1.5),
  x2(2);

  const OnionZoom(this.multiplier);

  /// `null` for [fit].
  final double? multiplier;
}
