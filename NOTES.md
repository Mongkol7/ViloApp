# Vilo App Notes & Quick Reference

This file serves as a root navigation guide for all project notes, documentation, architecture records, and troubleshooting manuals across the **Vilo** repository.

---

## 📁 Notes Directory Structure

- **`docs/notes/`** — Comprehensive engineering notes:
  - [`docs/notes/README.md`](docs/notes/README.md) — Engineering guide, architectural patterns, and UI/UX conventions.
  - [`docs/notes/RELEASE_NOTES.md`](docs/notes/RELEASE_NOTES.md) — Detailed version release notes, changelogs, and recent features.
- **`.ai/`** — AI & developer system notes:
  - [`.ai/ACTIVE_TASKS.md`](.ai/ACTIVE_TASKS.md) — Roadmap milestones, completed tasks, and active tasks.
  - [`.ai/CONTEXT.md`](.ai/CONTEXT.md) — App concept, topology diagram, and feature modules breakdown.
  - [`.ai/DECISIONS.md`](.ai/DECISIONS.md) — Architectural Decision Records (ADRs 001–009).
  - [`.ai/MEMORY.md`](.ai/MEMORY.md) — Learned quirks, platform gotchas, and troubleshooting solutions.
  - [`.ai/SYSTEM.md`](.ai/SYSTEM.md) — Core tech stack rules, design system guidelines, and guardrails.

---

## ⚡ Quick Operational Cheat Sheet

```powershell
# 1. Clean port 3000 if occupied
Get-NetTCPConnection -LocalPort 3000 | ForEach-Object { Stop-Process -Id $_.OwningProcess -Force }

# 2. Run backend (Spring Boot 3.4.1)
cd backend; .\mvnw.cmd spring-boot:run

# 3. Analyze Flutter codebase
flutter analyze lib/features/feed/ lib/features/profile/

# 4. Run tests
flutter test
```
