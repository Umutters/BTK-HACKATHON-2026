/// Cyber-Finance Forge — Spacing & Shape tokens
/// Base unit: 4px
class AppDimensions {
  AppDimensions._();

  // ─── Spacing (4px base unit) ──────────────────────────────────────────────
  static const double spaceXXS = 2.0;
  static const double spaceXS = 4.0;
  static const double spaceS = 8.0;
  static const double spaceM = 12.0;
  static const double spaceL = 16.0;
  static const double spaceXL = 24.0;
  static const double spaceXXL = 24.0;
  static const double space3XL = 40.0;
  static const double space4XL = 40.0;
  static const double space5XL = 48.0;

  // ─── Border Radius ────────────────────────────────────────────────────────
  static const double radiusXS = 4.0; // 0.25rem
  static const double radiusS = 8.0; // 0.5rem — inputs, small cards
  static const double radiusM = 12.0; // 0.75rem
  static const double radiusL =
      16.0; // 1rem   — large containers / glass panels
  static const double radiusXL = 24.0; // 1.5rem
  static const double radiusXXL = 24.0;
  static const double radiusFull = 9999.0; // pill buttons

  // ─── Icon sizes ───────────────────────────────────────────────────────────
  static const double iconXS = 14.0;
  static const double iconS = 18.0;
  static const double iconM = 24.0;
  static const double iconL = 32.0;
  static const double iconXL = 48.0;

  // ─── Component sizes ──────────────────────────────────────────────────────
  static const double progressBarHeight = 6.0;
  static const double questCardWidth = 200.0;
  static const double questCardHeight = 198.0;
  static const double bottomNavHeight = 72.0;
  static const double navIconSize = 26.0;
  static const double levelBadgeSize = 36.0;

  // ─── Page layout ─────────────────────────────────────────────────────────
  static const double pagePaddingH = 20.0; // margin-mobile: 20px
  static const double pagePaddingV = 16.0; // gutter: 16px

  // ─── Blur ─────────────────────────────────────────────────────────────────
  static const double blurCard = 20.0;
  static const double blurNav = 30.0;
}
