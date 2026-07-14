---
name: Athletic Modernist
colors:
  surface: '#faf9ff'
  surface-dim: '#ccdaff'
  surface-bright: '#faf9ff'
  surface-container-lowest: '#ffffff'
  surface-container-low: '#f1f3ff'
  surface-container: '#e9edff'
  surface-container-high: '#e1e8ff'
  surface-container-highest: '#d8e2ff'
  on-surface: '#051a3e'
  on-surface-variant: '#3e4942'
  inverse-surface: '#1d3054'
  inverse-on-surface: '#edf0ff'
  outline: '#6e7a71'
  outline-variant: '#bdcac0'
  surface-tint: '#006c47'
  primary: '#006b47'
  on-primary: '#ffffff'
  primary-container: '#00875a'
  on-primary-container: '#ffffff'
  inverse-primary: '#71dba6'
  secondary: '#825500'
  on-secondary: '#ffffff'
  secondary-container: '#feaa00'
  on-secondary-container: '#684300'
  tertiary: '#00667a'
  on-tertiary: '#ffffff'
  tertiary-container: '#008199'
  on-tertiary-container: '#fffeff'
  error: '#ba1a1a'
  on-error: '#ffffff'
  error-container: '#ffdad6'
  on-error-container: '#93000a'
  primary-fixed: '#8df7c1'
  primary-fixed-dim: '#71dba6'
  on-primary-fixed: '#002113'
  on-primary-fixed-variant: '#005235'
  secondary-fixed: '#ffddb3'
  secondary-fixed-dim: '#ffb950'
  on-secondary-fixed: '#291800'
  on-secondary-fixed-variant: '#624000'
  tertiary-fixed: '#afecff'
  tertiary-fixed-dim: '#48d7f9'
  on-tertiary-fixed: '#001f27'
  on-tertiary-fixed-variant: '#004e5d'
  background: '#faf9ff'
  on-background: '#051a3e'
  surface-variant: '#d8e2ff'
typography:
  headline-lg:
    fontFamily: Plus Jakarta Sans
    fontSize: 24px
    fontWeight: '700'
    lineHeight: 32px
    letterSpacing: -0.02em
  headline-md:
    fontFamily: Plus Jakarta Sans
    fontSize: 20px
    fontWeight: '700'
    lineHeight: 28px
  body-lg:
    fontFamily: Plus Jakarta Sans
    fontSize: 16px
    fontWeight: '500'
    lineHeight: 24px
  body-md:
    fontFamily: Plus Jakarta Sans
    fontSize: 14px
    fontWeight: '400'
    lineHeight: 20px
  label-caps:
    fontFamily: Plus Jakarta Sans
    fontSize: 12px
    fontWeight: '700'
    lineHeight: 16px
    letterSpacing: 0.05em
  button-text:
    fontFamily: Plus Jakarta Sans
    fontSize: 16px
    fontWeight: '600'
    lineHeight: 24px
rounded:
  sm: 0.25rem
  DEFAULT: 0.5rem
  md: 0.75rem
  lg: 1rem
  xl: 1.5rem
  full: 9999px
spacing:
  base: 4px
  xs: 4px
  sm: 8px
  md: 16px
  lg: 24px
  xl: 32px
  gutter: 16px
  margin-mobile: 16px
  margin-desktop: 48px
---

## Brand & Style

The design system is built for the intersection of high-performance sports and seamless utility. It evokes an **energetic yet professional** atmosphere, utilizing a **Corporate / Modern** base with athletic cues. 

The personality is reliable and action-oriented. The visual language relies on significant whitespace, a vibrant "pitch-green" primary accent, and soft structural shapes that prevent the UI from feeling overly rigid. The goal is to provide a frictionless booking experience that mirrors the efficiency of professional sports management.

## Colors

The palette is centered around a high-visibility primary green, chosen for its direct association with turf and sports fields. 

- **Primary Green (#00875A):** Used for key actions (booking), active states, and critical brand touchpoints.
- **Secondary Orange (#FFAB00):** Reserved for ratings, map pins, and navigational highlights to provide high-contrast alerts.
- **Surface Strategy:** The system uses a tiered light mode. Backgrounds are primarily white (`#FFFFFF`), with a secondary light grey (`#F4F5F7`) used to create sectional separation (e.g., the review area or amenity container).
- **Interactive Greys:** Borders and unselected states use a light stroke (`#DFE1E6`) to maintain a clean, airy feel.

## Typography

The design system utilizes **Plus Jakarta Sans** across all levels to achieve a contemporary, welcoming, and athletic look. 

- **Headlines:** Use Bold (700) weights with slightly tight letter spacing for a punchy, editorial feel suitable for venue names.
- **Labels:** Secondary headers (like "AMENITIES") use a specialized uppercase label style with increased letter spacing to provide clear visual hierarchy without needing large font sizes.
- **Body:** Standardized at 14px for general information, ensuring high legibility on mobile devices while maintaining a clean aesthetic.

## Layout & Spacing

The system follows a **fluid grid** model optimized for mobile-first consumption. 

- **Rhythm:** An 8px base grid drives all padding and margin decisions. 
- **Safe Areas:** Mobile views utilize a 16px side margin. Content is grouped into high-level containers with 24px vertical spacing between sections to ensure clear breathing room.
- **Grid:** Elements like "Amenities" or "Sports Selection" use a flexible column layout (typically 2 columns on mobile) with 12px gutters.

## Elevation & Depth

This design system prioritizes **Tonal Layers** over heavy shadows to maintain a "flat-modern" appearance.

- **Stacking:** Depth is conveyed by placing white cards on light grey backgrounds. 
- **Shadows:** When used (e.g., the floating "Open in Maps" button), shadows are extremely soft and diffused: `0px 4px 12px rgba(0, 0, 0, 0.08)`.
- **Outlines:** Most interactive containers (Amenities, Sport Chips) use a 1px solid stroke in a light neutral rather than a shadow, reinforcing a clean and systematic structure.

## Shapes

The shape language is defined by **rounded, approachable geometry**. 

- **Containers:** Main cards and content blocks use a 16px (`rounded-xl`) corner radius.
- **Interactive Elements:** Buttons and selection chips utilize a 12px (`rounded-lg`) radius, balancing a friendly feel with the professional precision of the platform.
- **Icons:** Should reside in 40px circular or softly rounded containers to maintain consistency with the UI's curved corners.

## Components

### Buttons
- **Primary:** Full-width green background (`#00875A`) with white text. High-contrast, no shadow, 12px border radius.
- **Secondary/Outline:** 1px green border with green text. Used for secondary actions or multi-select filters.
- **Disabled:** Soft grey background (`#EBECF0`) with white text, removing all visual prominence.

### Chips & Selection
- **Sport Selectors:** Large cards with an icon and label. Active state features a green border and light green tint background; inactive state is a subtle grey border.
- **Category Chips:** Small pill-shaped tags with a 10% opacity primary green background for "Selected" and transparent for "Unselected."

### Input Fields & Search
- Inputs are outlined with a 1px neutral-light border, transitioning to primary green on focus. Label text is positioned outside the field for clarity.

### Cards
- Venue and Review cards use a white background with a 16px border radius. Content inside cards follows a consistent 16px internal padding.