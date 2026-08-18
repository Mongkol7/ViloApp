# Architectural Decision Records (ADR)

## ADR-001: Feature-Driven Clean Architecture

- **Status**: Accepted
- **Context**: Need a modular codebase supporting distinct features (Feed, Shop, Search, Creator, Profile) without coupling.
- **Decision**: Organize codebase by feature (`features/<name>/data|domain|presentation`), backed by shared `core/` tokens.

## ADR-002: Obsidian Pulse Design System

- **Status**: Accepted
- **Context**: Need high-density, futuristic dark-mode UI with technical precision for video and commerce.
- **Decision**: Standardize on Obsidian Pulse: monochromatic palette (`#080808` Void, `#141414` Surfaces), 1px hairline borders (`rgba(255,255,255,0.08)`), Inter font, and Glassmorphic refraction.

## ADR-003: 5-Phase Apple Liquid Glass & Instagram Dynamic Scroll Navigation Bar

- **Status**: Accepted
- **Context**: Need a world-class floating navigation dock that maximizes screen space on scroll while feeling fluid and tactile.
- **Decision**: Implemented dual-edge viscous stretching spring model with hysteresis-based scroll compression (compresses to 48pt & 70% opacity on downward scroll $>20\text{pt}$, restores on upward scroll $<-6\text{pt}$).

## ADR-004: Exclusion of Live Video Streaming

- **Status**: Accepted
- **Context**: Scope is strictly short-form pre-recorded video content and integrated commerce.
- **Decision**: Omit live streaming protocols (RTMP, WebRTC rooms) to optimize video buffer efficiency and app bundle size.
