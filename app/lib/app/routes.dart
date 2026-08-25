/// Route paths, in one place so no screen writes a path literal.
class AppRoutes {
  const AppRoutes._();

  static const String home = '/';

  /// The foundation shell kept from F1, now reachable from the explore screen
  /// rather than being the first thing anyone sees.
  static const String shell = '/shell';
  static const String typeSpecimen = '/type-specimen';
  static const String checkpoints = '/checkpoints';
  static const String map = '/map';
}
