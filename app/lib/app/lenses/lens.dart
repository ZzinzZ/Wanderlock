/// A way of experiencing the same unlocked map.
///
/// A lens changes what you see and never what you have unlocked. Two of the
/// five are built: Fog of War, and Collection as the thin second one that
/// gives the first something to be compared against.
///
/// Lives in `app/` rather than in a feature because knowing that both fog and
/// collection exist is exactly the knowledge no lens is allowed to have. The
/// composition layer is the only place permitted to hold the list.
enum Lens {
  fog,
  collection;

  /// The lens shown on a cold start.
  static const Lens initial = Lens.fog;
}
