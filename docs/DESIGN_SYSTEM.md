# Design System

Tokens (`lib/design/tokens.dart`): navy #0A1B2D, gold #D8B75A, ivory #F7F4EE, card-dark #18334B; semantic error/success/warning; radii 16–24; 48dp targets.

Themes (`lib/design/app_theme.dart`): `buildLightTheme()` (ivory scaffold), `buildDarkTheme()` (navy scaffold), `buildAmoledTheme()` (pure black). Almarai Arabic font, Orbitron numerals only in tasbeeh display. Persisted `themeMode` light|dark|amoled.

Components (`lib/design/components.dart`): shared cards, buttons, repeat pills, section headers. No per-page theme maps.
