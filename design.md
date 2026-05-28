# PetFolio Design System

## Typography
- **Primary Font**: `Nunito` (Weights: 400, 600, 700, 800, 900)
- **Display Font**: `Fraunces` (Weights: 500, 700) for large headers and emotive text.

## Color Palette (Light Mode Default)
- **Background & Surfaces**
  - `--cream`: `#FFF4E6` (Main background)
  - `--surface`: `#FFFFFF` (Cards, panels)
  - `--line`: `#F4E2CB`
  - `--line-2`: `#EFD8BB`
- **Text & Ink**
  - `--ink-950`: `#261308` (Primary text, headings)
  - `--ink-700`: `#5E3A28` (Secondary text)
  - `--ink-500`: `#957762` (Tertiary text, labels)
- **Accents (Primary, Soft, Dark 700 variants)**
  - **Tangerine**: `#FF8A4C` | Soft: `#FFE0CB` | Dark: `#E0651E`
  - **Poppy**: `#FF3D3D` | Soft: `#FFE0E0` | Dark: `#C41818`
  - **Mint**: `#2FCBA0` | Soft: `#BFF1E0` | Dark: `#198C6E`
  - **Sunny**: `#FFC53D` | Soft: `#FFEDB3` | Dark: `#C68B0F`
  - **Lilac**: `#A98BFF` | Soft: `#E2D6FF` | Dark: `#6E4DDB`
  - **Sky**: `#6EC8FF` | Soft: `#CDEAFF`

## Shadows & Elevations
- **Card Shadow**: `0 2px 0 0 rgba(120,60,20,0.04), 0 12px 28px -16px rgba(120,60,20,0.18)`
- **Soft Shadow**: `0 8px 24px -10px rgba(120,60,20,0.18)`

## Core Components
- **Squircle Cards**: White background, `28px` border radius, `1px solid var(--line)`, elevated with `--shadow-card`.
- **Pill Buttons**: Fully rounded (`border-radius: 999px`), very bold font (`800` weight). Primary variants have a 3D effect shadow (e.g., `0 6px 0 0 var(--tangerine-700)`).
- **Wave Headers**: Colored hero sections at the top of screens that end with an organic SVG wave cutout overlapping the cream background.
- **Icon Buttons**: Circular buttons (`44x44`), elevated with soft shadow, containing vector icons.
- **Pet Avatars**: Soft radial gradient backgrounds with an inner emoji, optionally encircled by a colorful conic-gradient ring for the active state.
- **Bottom Navigation**: Floating pill-shaped bar (`border-radius: 32px`) at the bottom of the screen containing 5 tabs. Active tabs have a colored background mix and filled icon.

## Overall Vibe
Playful, organic, gamified, and modern. Lots of soft gradients, micro-interactions, and cheerful colors.
