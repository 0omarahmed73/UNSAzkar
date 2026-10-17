# UNS Critical Real-Device Fixes Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Fix real-device haptics + notifications, restore agreed visuals, reduce Azkar lag, and add visible splash animation with verified evidence.

**Architecture:** Keep current app architecture (GetX + stores + existing pages). Apply minimal targeted fixes in production paths, validate on the connected Samsung device, and avoid broad refactors.

**Tech Stack:** Flutter, Dart, GetX, flutter_local_notifications, geolocator, existing theme/design system.

**Spec:** User request in current thread (Critical Real-Device Fixes & Design Restoration — أُنس | UNS).

## Global Constraints

- Preserve package/application IDs and existing data.
- Use existing approved SVG/logo assets only.
- No overlapping Flutter test/build commands.
- Check disk/process safety before cleanup/build.
- No commit before full verification/report.

## Tasks

### Task 1: Safety preflight + baselines
- [ ] Capture git status/diff, disk (`df -h /`), running flutter/gradle processes.
- [ ] Inventory existing APKs, splash config/assets, and screenshot references.
- [ ] Stop only stale test/build processes related to this repo.

### Task 2: Real-device haptics root cause + fix
- [ ] Trace production path: settings -> service -> callsites -> Android behavior.
- [ ] Ensure production service wiring cannot be overridden by test fakes at runtime.
- [ ] Keep enabled/disabled semantics and no duplicate completion trigger.
- [ ] Validate with focused tests first, then full file test.
- [ ] Install APK on Samsung and perform enabled/disabled physical vibration checks.

### Task 3: Notifications delivery root cause + fix
- [ ] Audit permission-status detection and mismatch with user-visible warning.
- [ ] Audit schedule chain (channel, timezone, ids, reschedule/cancel).
- [ ] Improve diagnostics copy in Arabic to distinguish permission vs scheduling vs delivery.
- [ ] Validate through tests and real-device test-notification + future reminder delivery.

### Task 4: Restore agreed design
- [ ] Compare current UI against provided references (home, tasbeeh, azkar light/dark).
- [ ] Restore visual tokens/layout without changing content semantics.
- [ ] Keep UNS/أُنس branding and approved assets intact.
- [ ] Capture updated screenshots for comparison.

### Task 5: Azkar navigation lag investigation + fix
- [ ] Measure opening/navigation latency baseline on device (profile/release observable timings).
- [ ] Remove repeated expensive work from Azkar navigation path.
- [ ] Re-measure and report before/after timings.

### Task 6: Visible splash animation
- [ ] Keep native launch + Flutter splash boundary clean.
- [ ] Add lightweight visible Flutter-side animation using approved branding.
- [ ] Verify cold-launch transition (recording/screenshots).

### Task 7: Final verification
- [ ] `dart format` on touched files.
- [ ] `flutter analyze` with separated errors/warnings/infos.
- [ ] Focused tests sequentially, then full suite.
- [ ] Re-check disk, then fresh APK build/install.
- [ ] Final evidence report split by: automated/emulator/physical-device.
