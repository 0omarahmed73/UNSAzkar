# Implementation Plan (concise)

Full task-level plan: `docs/superpowers/plans/2026-10-18-azkar-redesign.md` (supersedes the P0 plan for this phase).

Status 2026-10-17:
- Tasks 1–9 implemented with TDD (RED observed for every behavior fix).
- Task 10 in progress: analyze 0/0, full suite green, `git diff --check` clean, debug+release APKs built; emulator visual verification booting.

Deliberate choices: keep Get/GetStorage (no framework churn); preserve Arabic text verbatim; new GetStorage keys namespaced `v2.*`; no fake buttons; launcher icon NOT integrated (user asset pending — SVGs in uploads treated as references only); no Quran-reader expansion, no audio, no accounts.
