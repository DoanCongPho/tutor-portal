# Design System
# Tutor Matching Platform — Mobile Client

**Version:** 0.1
**Status:** Draft
**Last Updated:** 2026-05-30

The brand voice is **warm, bright, and trustworthy**. Parents and tutors come
to this app to get out of messy Zalo threads — the UI should feel friendly
without being childish and clean without being cold. Single signature color,
generous whitespace, calm type.

---

## 1. Brand Color

The primary brand color is a saturated, warm **coral-orange**. It is
deliberately not blue (the default edtech color) so the product reads as
approachable and human at first glance, and it scores well against the
"bright" directive without crossing into neon.

```
Brand seed: #FF6F3C
```

Material 3 derives the rest of the tonal palette from this seed. We override
**surface** to keep the warm cast — M3's seeded surface drifts cool.

### Roles (light)

| Role | Value | Use |
|---|---|---|
| Primary | `#FF6F3C` (seed) | The single primary CTA on each screen, active states, brand marks |
| On Primary | `#FFFFFF` (derived) | Text/icons placed on Primary |
| Primary Container | derived (tinted coral) | Soft brand-tinted surfaces — chips, selected segments |
| Secondary | derived | Less-emphatic actions, supporting accents |
| Tertiary | derived | Optional accent for badges / status |
| **Surface** | `#FFFAF6` (warm cream) | App background, cards, sheets |
| Surface Container High | derived | Filled input backgrounds, list dividers' background |
| On Surface | derived (`~#1F1611`) | Default body text |
| Outline Variant | derived | Thin separators, secondary borders |
| Error | derived (M3 red) | Form errors, destructive actions |

### Roles (dark)

| Role | Value |
|---|---|
| Primary | derived (lightened coral, ≈ `#FFB59B`) |
| **Surface** | `#1A1410` (warm dark) |
| On Surface | derived (`~#F2E5DC`) |

Why coral-orange:

- Warm hues read as friendly in Vietnamese visual culture.
- Coral is bright enough to read as energetic, not aggressive like pure red.
- High chroma satisfies "bright color" without becoming neon.
- Distinctive against the all-blue edtech competition.

### Rules

**Do**

- Use **Primary on exactly one element per screen** — the primary CTA. Anything else dilutes the call to action.
- Use **Primary Container** for soft highlights: input field backgrounds on auth screens, selected segments, the brand-mark backdrop.
- Keep surfaces warm. Pure `#FFFFFF` looks clinical against the coral primary and breaks the brand cast.

**Don't**

- Hardcode hex values in widgets. Read from `Theme.of(context).colorScheme.{primary, onSurface, ...}` — the theme is configured in `frontend/lib/core/theme/app_theme.dart` from the seed.
- Use Primary and Tertiary together as competing accents on the same screen.
- Use color alone to signal state (error, success). Pair with an icon or label.

---

## 2. Typography

Material 3 default type scale (Roboto on Android, San Francisco on iOS).
Token mapping per screen role:

| Token | Size · Weight | Use |
|---|---|---|
| displaySmall | 36 · w700 | Auth hero heading ("Welcome / back.") |
| headlineSmall | 24 · w600 | Screen / card titles |
| titleMedium | 16 · w600 | List item titles, section headers |
| bodyLarge | 16 · w400 | Default body content |
| bodyMedium | 14 · w400 | Secondary text, captions |
| labelLarge | 14 · w600 | Buttons |

For the display heading on auth screens, render the heading in two lines with
the **second line in Primary** to reinforce the brand (e.g. *"Welcome"* on
surface, *"back."* in primary).

**Vietnamese diacritics:** Roboto / SF handle them correctly but spacing
drifts on stacks like `ậ`, `ặ`, `ỹ`. When localization lands, switch the
font to **Be Vietnam Pro** (Google Fonts, designed for VN).

---

## 3. Spacing

4dp grid. Use only these values:

```
4 · 8 · 12 · 16 · 20 · 24 · 32 · 40 · 48 · 64
```

| Context | Value |
|---|---|
| Tight inner padding (chip, badge) | 4 – 8 |
| Adjacent label / input | 8 |
| Within a section (between fields) | 12 – 16 |
| Between sections / blocks | 24 – 32 |
| Screen edge padding (phone) | 24 |
| Screen edge padding (tablet) | 40 |

---

## 4. Shape

| Element | Radius |
|---|---|
| Input fields | 12 |
| Buttons | 14 |
| Cards | 16 |
| Brand mark / logo container | 20 |
| Bottom sheets | 24 (top corners only) |

---

## 5. Components

### 5.1 Brand Mark

A 64×64 rounded square (radius 20) filled with Primary, containing a white
icon (currently `Icons.school_rounded`, swap for the real logo glyph when
assets land). On the login/landing screen, pair with the wordmark "Tutor
Portal" in `titleLarge`.

Use a soft shadow in Primary @ 35% alpha, blur 20, offset (0, 10) — the only
elevation in the auth flow. It anchors the brand without competing with the
heading.

### 5.2 Buttons

| Variant | Component | Min height | Use |
|---|---|---|---|
| Primary | `FilledButton` | 56 | The single main action per screen |
| Secondary | `OutlinedButton` | 48 | Alternate path (e.g., "Create account" on /login footer) |
| Tertiary | `TextButton` | n/a | In-flow links, dialog actions |

Loading state: replace `child` with
`SizedBox(22, 22, CircularProgressIndicator(strokeWidth: 2))` and set
`onPressed: null`. Don't render a disabled button alongside a separate spinner.

### 5.3 Inputs

- Default style: **filled** (`InputDecoration(filled: true)`) with
  `surfaceContainerHigh` background.
- On the **auth screens specifically**, use **Primary Container @ ~35% alpha**
  as the fill so the brand cast reads through. This variant is configured
  per-call until we have a second auth-style surface.
- Leading icon when meaning isn't obvious from the label alone (phone → 📞).
- Border: none until focus → 2dp Primary. Error state: 1.5dp `error`, 2dp on focus.
- Error text below the field. Don't rely on color alone — Material's default
  error iconography is sufficient.

### 5.4 Auth screens (specific layout)

```
┌────────────────────────────────┐
│  24                            │
│  [BRAND MARK] Tutor Portal     │
│  32                            │
│  Welcome                       │  ← displaySmall on surface
│  back.                         │  ← displaySmall on primary
│  8                             │
│  Sign in with your phone …     │  ← bodyMedium on surface variant
│  32                            │
│  [Phone field, filled coral]   │
│  20                            │
│  [Send code  ───────────────►] │  ← FilledButton 56h, full width
│  32                            │
│         New here? Create acct  │  ← TextButton centered
│  24                            │
└────────────────────────────────┘
```

Max content width: **480**. On tablets/foldables, center the column and let
the surface fill around it.

---

## 6. Dark Mode

Required from day one (the app inherits the system setting). Brand seed
stays the same; M3 produces the lighter primary tone for sufficient contrast
on dark surface. Surface is overridden to a warm dark (`#1A1410`) so the
brand cast carries through.

---

## 7. Accessibility

- Text contrast: WCAG **AA** minimum (4.5:1 body, 3:1 large text).
- Touch targets ≥ 48×48 dp (Material spec).
- State conveyed by color **plus** icon or label, never color alone.
- Test at `textScaleFactor` up to 1.3× — layouts must not break.
- Honor `MediaQuery.disableAnimations` for users with reduced-motion preferences.

---

## 8. Not Decided Yet

- **Icon set**: Material Icons today. `phosphor_flutter` is a likely
  upgrade once we have more screens and want a distinctive icon style.
- **Illustrations** (empty states, onboarding): defer until a visual
  designer is onboarded.
- **Motion**: M3 default durations + curves until there's a specific UX
  reason to override.
- **Logo asset**: placeholder `Icons.school_rounded` in the brand mark.
  Replace with the SVG logo when produced.
