---
name: Obsidian Pulse
colors:
  surface: '#141414'
  surface-dim: '#131313'
  surface-bright: '#3a3939'
  surface-container-lowest: '#0e0e0e'
  surface-container-low: '#1c1b1b'
  surface-container: '#201f1f'
  surface-container-high: '#2a2a2a'
  surface-container-highest: '#353534'
  on-surface: '#e5e2e1'
  on-surface-variant: '#c4c7c8'
  inverse-surface: '#e5e2e1'
  inverse-on-surface: '#313030'
  outline: '#8e9192'
  outline-variant: '#444748'
  surface-tint: '#c6c6c7'
  primary: '#ffffff'
  on-primary: '#2f3131'
  primary-container: '#e2e2e2'
  on-primary-container: '#636565'
  inverse-primary: '#5d5f5f'
  secondary: '#c6c6cb'
  on-secondary: '#2f3034'
  secondary-container: '#46464b'
  on-secondary-container: '#b5b4ba'
  tertiary: '#ffffff'
  on-tertiary: '#2f3131'
  tertiary-container: '#e2e2e2'
  on-tertiary-container: '#636565'
  error: '#ffb4ab'
  on-error: '#690005'
  error-container: '#93000a'
  on-error-container: '#ffdad6'
  primary-fixed: '#e2e2e2'
  primary-fixed-dim: '#c6c6c7'
  on-primary-fixed: '#1a1c1c'
  on-primary-fixed-variant: '#454747'
  secondary-fixed: '#e3e2e7'
  secondary-fixed-dim: '#c6c6cb'
  on-secondary-fixed: '#1a1b1f'
  on-secondary-fixed-variant: '#46464b'
  tertiary-fixed: '#e2e2e2'
  tertiary-fixed-dim: '#c6c6c7'
  on-tertiary-fixed: '#1a1c1c'
  on-tertiary-fixed-variant: '#454747'
  background: '#131313'
  on-background: '#e5e2e1'
  surface-variant: '#353534'
  surface-stroke: rgba(255, 255, 255, 0.08)
  action-secondary: '#242426'
  glass-dark: rgba(28, 28, 30, 0.75)
  glass-light: rgba(255, 255, 255, 0.85)
typography:
  headline-lg:
    fontFamily: Inter
    fontSize: 28px
    fontWeight: '700'
    lineHeight: 34px
    letterSpacing: -0.5px
  headline-sm:
    fontFamily: Inter
    fontSize: 18px
    fontWeight: '600'
    lineHeight: 24px
  body-lg:
    fontFamily: Inter
    fontSize: 15px
    fontWeight: '600'
    lineHeight: 20px
  body-md:
    fontFamily: Inter
    fontSize: 13px
    fontWeight: '400'
    lineHeight: 18px
  label-caps:
    fontFamily: Inter
    fontSize: 11px
    fontWeight: '700'
    lineHeight: 12px
    letterSpacing: 0.5px
rounded:
  sm: 0.25rem
  DEFAULT: 0.5rem
  md: 0.75rem
  lg: 1rem
  xl: 1.5rem
  full: 9999px
spacing:
  container-padding: 16px
  stack-gap: 12px
  inline-gap: 8px
  edge-margin: 24px
  section-margin: 32px
---

## Brand & Style

The design system is defined by a high-density, premium tactile aesthetic that merges extreme minimalism with technical precision. It is engineered for power users who value clarity, speed, and a sophisticated "pro-tool" atmosphere.

The visual direction follows a **Modern Minimalist** movement with **Glassmorphic** accents. It utilizes a pitch-dark canvas to create a void-like depth, where content surfaces appear to float via subtle illumination and refractive glass properties. The emotional response is one of focused intensity, quiet luxury, and technological cutting-edge.

Key visual pillars include:
- **High-Density Information:** Efficient use of space without sacrificing legibility.
- **Material Contrast:** The juxtaposition of matte obsidian surfaces against ultra-glossy "liquid glass" elements.
- **Tactile Precision:** Crisp 1px borders and high-contrast interactions that mimic physical hardware.

## Colors

The palette is strictly monochromatic to emphasize form and hierarchy over hue.

- **The Void:** The background (`#080808`) serves as the foundation, providing infinite depth.
- **Elevated Surfaces:** UI containers use `#141414`, distinguished from the background not by shadows, but by hair-line strokes.
- **Typography:** Primary information is rendered in pure White (`#FFFFFF`), while secondary metadata uses Muted Silver (`#8E8E93`) to reduce visual noise.
- **Action Inversion:** The primary interaction model uses a complete color inversion—solid white backgrounds with black text—to create an undeniable focal point.

## Typography

This design system utilizes **Inter** for its systematic, utilitarian precision. The typographic scale is compact, favoring high information density while maintaining a clear hierarchy through weight and color.

- **Headlines:** Use tight letter-spacing and bold weights to anchor screens.
- **Readability:** Body text is set at 15px with semi-bold weights to ensure "pop" against the dark background.
- **Metadata:** Secondary information is significantly reduced in size and color contrast to ensure it stays in the periphery until needed.

## Layout & Spacing

The layout follows a **Fluid Grid** model with a focus on internal container padding and consistent vertical stacking.

- **Safe Zones:** Content should maintain a minimum 24px margin from the screen edges on mobile.
- **Rhythm:** A base unit of 4px governs all spacing. Vertical stacks between cards should consistently use 12px to maintain high density without feeling cramped.
- **Mobile-First:** On mobile devices, the primary navigation is a floating dock. On desktop/tablet, the layout expands into a multi-column view while maintaining the 12px gap between content modules.

## Elevation & Depth

Depth in this design system is communicated through **Tonal Layering** and **Refraction** rather than traditional drop shadows.

- **Level 0 (Base):** The pitch-black `#080808` canvas.
- **Level 1 (Cards):** Surfaces at `#141414` with a 1px border of `rgba(255, 255, 255, 0.08)`. This creates a subtle "lit from the edge" effect.
- **Level 2 (Floating/Overlays):** Glassmorphic elements. These use a high-saturation backdrop blur (20px to 25px).
    - **Dark Glass:** For contextual menus or secondary bars, using `rgba(28, 28, 30, 0.75)`.
    - **Liquid Glass:** For the primary navigation dock, using a high-contrast `rgba(255, 255, 255, 0.85)` to pull the element into the foreground.

## Shapes

The shape language is sophisticated and "soft-geometric." It avoids the harshness of sharp corners but maintains enough structure to feel professional.

- **Standard Containers:** Cards and input fields use a 20px (`rounded-lg`) radius.
- **Interactive Elements:** Primary buttons and navigation docks use a fully pill-shaped (circular) radius (30px+) to distinguish them from content containers.
- **Avatars:** Circular with a fine 1px white outline at 15% opacity to prevent them from bleeding into the dark background.

## Components

### Buttons
- **Primary CTA:** Solid White background, Black text. Height is fixed at 52px. It should include a trailing icon (in a circular black container) to drive the visual "pulse" of the action.
- **Secondary Pills:** Subtle dark backgrounds (`#242426`) or low-opacity white (`rgba(255, 255, 255, 0.1)`). These are smaller (32-36px height) and used for inline actions like "Message" or "Follow."

### Card Containers
- Every card must have the 1px border.
- Cards should use `flex` layouts to justify content, typically placing primary identity on the left and secondary actions on the right.

### Input Fields
- Background matches the card surface (`#141414`).
- Borders should brighten to `rgba(255, 255, 255, 0.2)` on focus.

### Glassmorphic Floating Dock
- The primary navigation is a detached floating element, positioned 24px from the bottom.
- It uses the "Liquid Glass" style. Icons inside should be black, with an opacity of 0.5 for inactive states and 1.0 for active states.

### Lists
- Lists are composed of stacked cards with 12px margins.
- Avoid dividers; use the card's border and the background's negative space to define separation.
