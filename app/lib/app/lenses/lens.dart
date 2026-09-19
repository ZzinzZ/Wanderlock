/// A way of experiencing the same unlocked map.
///
/// A lens changes what you see and never what you have unlocked. Four of the
/// five are built: Fog of War, Collection, and — behind the Journey tab —
/// Quest and the itinerary. Story is the one still missing, and it is blocked
/// on content rather than on code.
///
/// Lives in `app/` rather than in a feature because knowing that both fog and
/// collection exist is exactly the knowledge no lens is allowed to have. The
/// composition layer is the only place permitted to hold the list.
enum Lens {
  fog,
  collection,

  /// Quest and the itinerary, behind one tab.
  ///
  /// Two lenses on one chip because section 5.4 of the scope specifies a
  /// three-item bar — Map, Collection, Journey — and because the two are the
  /// same question asked twice: a route someone else planned, and the one you
  /// planned yourself. Splitting them into four chips would put the rarest
  /// destination in the bar at the same weight as the map.
  journey;

  /// The lens shown on a cold start.
  static const Lens initial = Lens.fog;
}
