# SONAR Bank Premium Dashboard Design System

## Purpose

This document captures the visual system used in the premium dashboard redesign so the same language can be reused across upcoming pages such as transfers, cards, accounts, settings, and onboarding.

The goal is a calm, high-end banking interface for a tablet-first NUI viewport. The design should feel structured, cinematic, and spacious without becoming empty.

## Core principles

- **Identity first:** The SONAR v3 monogram is the primary brand anchor. It should be visible, confident, and never treated as a small utility icon.
- **Integrated shell:** Navigation, header, and page content should merge with the same atmospheric background instead of looking like disconnected blocks.
- **Low-density hierarchy:** One hero decision per region. Avoid many equal cards competing for attention.
- **Premium darkness:** Black is the base canvas. Orange is the signature energy. White is used for legibility and active emphasis.
- **Soft separation:** Prefer rounded glass surfaces, gradients, thin borders, and inner highlights over hard lines.
- **Tablet-first fit:** The ideal target remains 1280×800. Pages should avoid outer scrolling unless the route is naturally list-heavy.

## Color language

- **Canvas:** near-black surfaces around `oklch(0.02-0.08 ...)`.
- **Brand accent:** SONAR v3 orange, visually aligned with `#FF5100` / `oklch(0.70 0.22 40)`.
- **Text primary:** soft white, never pure high-contrast white for every label.
- **Text secondary:** muted gray for supporting copy.
- **Positive state:** restrained green for gains, income, and confirmation.
- **Negative state:** soft red/orange for outgoing amounts and risk.

Orange should not flood every element. It works best as:

- Primary CTA background.
- Chart stroke/glow.
- Brand logo glow.
- Top/right rail atmospheric gradient.
- Small status or highlight moments.

## Layout architecture

The dashboard uses three structural zones:

1. **Left sidebar rail**
   - Fixed vertical pill.
   - Rounded corners around the entire rail.
   - Icon-only navigation for calm density.
   - SONAR v3 monogram at the top, large enough to read as brand identity.

2. **Integrated topbar**
   - Transparent/glass header integrated with background.
   - Search on the left.
   - Keyboard shortcut capsule in the center.
   - Utility icons and profile chip on the right.
   - Future/disabled features should produce clear feedback instead of appearing broken.

3. **Main dashboard grid**
   - Central content column for financial overview.
   - Right rail for card, transfer shortcuts, and recent activity.
   - Bottom central area split between promotional carousel and cash actions.

## Dashboard composition

### Balance and graph hero

The balance/graph card is the main visual anchor.

- Use large, light-weight numeric typography.
- Keep chart tabs visible and functional.
- Use an orange area chart with soft glow and low-opacity fill.
- Keep legends minimal and aligned to the lower edge.
- The chart should look like a financial instrument, not a generic analytics widget.

### Promo carousel

The promo panel uses unused lower space without adding operational noise.

Recommended content types:

- Crypto custody.
- Investment vaults.
- Premium benefits.
- Future roadmap features.

Rules:

- Auto-advance slowly.
- Keep one clear headline and one CTA.
- Use warm gradients and subtle decorative depth.
- CTA can be informational until the feature exists.

### Money actions

`Ingresar` and `Retirar` should be calm operational actions.

- Use two stacked buttons.
- Distinguish tone subtly: green for deposit, orange for withdrawal.
- If endpoint does not exist yet, show toast feedback rather than doing nothing.

### Right card rail

The right rail should feel like a premium banking module, not a generic sidebar.

- Background uses orange-to-black vertical gradient.
- Cards are stacked with perspective/depth.
- The front card should reuse the real card visual component from the cards page when possible.
- `Request` and `Transfer` buttons should route to the transfer experience.
- Recent transactions use illustrated avatars and clear amount color direction.

## Avatar system

Avatars should feel illustrated and reusable.

Current implementation uses DiceBear-compatible illustrated SVG avatars through deterministic seeds, with a local initials fallback.

Usage rules:

- Always pass stable semantic names as seeds.
- Keep fallback initials for offline/NUI network restrictions.
- Use small ring/border treatment on stacked avatars.
- Reuse the same avatar primitive in account creation, contacts, transfer recipients, and recent transactions.

## Card visual reuse

When a dashboard shows cards, prefer reusing the actual `CardVisual` component from the cards route instead of drawing a separate fake card.

Benefits:

- Visual consistency.
- Design registry is respected.
- Any future card design automatically propagates.
- The dashboard rail can still add perspective and stacking around the real component.

## Interaction rules

- **Functional tabs:** If a control is visible, it must change state or show feedback.
- **Future features:** Use explicit toast feedback such as “Disponible próximamente”.
- **Primary movement:** Use subtle hover lift and press scale, not large motion.
- **Route actions:** Transfer/request actions should navigate to `/transferir`.
- **Disabled or planned modules:** Never leave decorative icons without response.

## Spacing and density

- Avoid compressed cards and permanent internal scroll in dashboard regions.
- Give each region breathing room with `gap-4` to `gap-5` at tablet scale.
- Use `h-full min-h-0` through shell, route transition, and page wrappers so the grid consumes available height.
- If a page leaves empty space, first check parent height propagation before changing the design itself.

## Border radius and surfaces

Preferred radii:

- Sidebar rail: approximately `2rem`.
- Main cards: `1.55rem` to `1.75rem`.
- Buttons/chips: full pill or `1rem+`.

Surface recipe:

- Dark translucent background.
- `1px` low-opacity white border.
- Inner top highlight.
- Optional radial accent glow.
- Avoid flat gray panels.

## Typography

- Product UI should remain neutral and legible.
- Use large light-weight numbers for balances.
- Use semibold for module titles.
- Use small uppercase tracking sparingly for labels.
- Avoid stencil/display fonts inside product UI.

## Reuse checklist for future pages

Before implementing a new page, verify:

- Does it preserve the integrated shell/background feeling?
- Is there one clear hero module?
- Are visible controls functional or explicitly marked as future?
- Does it reuse `BankAvatar` for people/entities?
- Does it reuse `CardVisual` when showing bank cards?
- Does it keep orange as brand energy rather than full saturation everywhere?
- Does the route fill `h-full min-h-0` without accidental empty bottom space?
- Does it work at 1280×800 without unnecessary outer scroll?
